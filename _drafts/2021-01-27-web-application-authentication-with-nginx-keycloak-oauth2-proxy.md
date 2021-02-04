---
layout : post
title: Web application authentication and authorization with Keycloak and OAuth2 Proxy on Kubernetes using Nginx Ingress
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/webapp-authentication-keycloak-OAuth2-proxy-nginx-ingress-kubernetes'
---

Many third party applications we run on Kubernetes will already support either OIDC or LDAP based login. Some however will not. In addition we may wish to deploy our own applications and use Keycloak to manage access to them without going through the work of adding OIDC or LDAP integration to them.

In this post we'll use OAuth2 Proxy to add authentication to a simple Ruby application. We'll then go one step further and get information about the logged in user and their group membership from within our web application. In it's simplest form, this would allow us to protect internal admin applications. In a more complete setup, we could setup a "customers" realm within Keycloak and delegate all of our authentication and authorization to Keycloak.

We'll be able to add this authentication using simple ingress annotations on the ingress definitions, making this a great alternative to basic auth on Kubernetes.

Note that OAuth2 Proxy is the [suggested replacement](https://www.keycloak.org/2020/08/sunsetting-louketo-project.adoc) for Keycloaks Gatekeeper / Louketo project which reached EOL in August 2020.

<!--more-->

{% include kubernetes-sso/contents.html active="webapp" %}

{% include kubernetes-sso/pre-reqs.html %}

This post assumes you've completed the "Installing Keycloak" section and have a working Keycloak installation.

## Keycloak authentication for an Nginx server

First we'll configure OAuth2 Proxy to work with our Keycloak installation and deploy it using a helm chart. 

Then we'll deploy the [official Nginx container](https://hub.docker.com/_/nginx) image using a helm chart as an example application and then we'll restrict access to it via Keycloak using ingress annotations.

We'll then look at how the app we're authenticating can access information about the logged in user and how this information could be used to implement more fine-grained access control.

## How it works

Nginx supports authentication [based on the result of a sub-request](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-subrequest-authentication/). This means that when a request comes in for a protected page, it will make a sub-request to an additional URL, if that URL returns any 2xx response code then the request will be allowed, if it returns a 401 or 403 it will be denied.

In practice we don't need a deep understanding of the above because OAuth2 Proxy links with keycloak on one side for the actual authentication and provides suitable endpoints for the NGinx to use to check whether a user is authenticated or not.

So we simple need to configure OAuth2 Proxy and then add suitable ingress annotations to the service we want to protect.

## Installing OAuth2 Proxy

First we'll need to create a client application with Keycloak. Crate a new OpenID Connection application and set:

- **Client ID**: `oauth2-proxy`
- **Access Type**: `confidential`
- **Valid Redirect URLs**:: `https://oauth.ssotest.staging.talkingquickly.co.uk/oauth2/callback` replacing `oauth.ssotest.staging.talkingquickly.co.uk` with the subdomain you plan to install OAuth2 Proxy on

You'll then need to save the entry and go to the newly available "Credentials" tab and make a note of the "Secret".

Finally we go to the "Mappers" tab, choose "Create" and select:

- **Name**: `Groups`
- **Mapper Type**: `Group Membership`
- **Token Claim Name**: `groups`
- All other options "On"

And then choose save. This ensures that the groups the user is a member of are passed back to OAuth2 Proxy and subsequently to the application itself.

We can then create our configuration for OAuth2 Proxy, an example is included in `oauth2-proxy/values-oauth2-proxy.yml` and looks like this:

```yaml
# Oauth client configuration specifics
config:
  clientID: "oauth2-proxy"
  clientSecret: "YOUR_CLIENT_SECRET"
  # Create a new secret with the following command
  # openssl rand -base64 32 | head -c 32 | base64
  cookieSecret: "GENERATE_A_NEW_SECRET"
  configFile: |-
    provider = "keycloak"
    provider_display_name = "Keycloak"
    login_url = "https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master/protocol/openid-connect/auth"
    redeem_url = "https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master/protocol/openid-connect/token"
    validate_url = "https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master/protocol/openid-connect/userinfo"
    email_domains = [ "*" ]
    scope = "openid profile email"
    cookie_domain = ".ssotest.staging.talkingquickly.co.uk"
    whitelist_domains = ".ssotest.staging.talkingquickly.co.uk"
    pass_authorization_header = true
    pass_access_token = true
    pass_user_headers = true
    set_authorization_header = true
    set_xauthrequest = true

ingress:
  enabled: true
  path: /
  hosts:
    - oauth.ssotest.staging.talkingquickly.co.uk
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
  tls:
    - secretName: oauth-proxy-tls
      hosts:
        - oauth.ssotest.staging.talkingquickly.co.uk
```

The key fields to update with your own values are:

- **clientSecret**: This is the client secret noted down from the Keycloak credentials page
- **cookieSecret**: This can be randomly generated with: `openssl rand -base64 32 | head -c 32 | base64`
- **login_url, redeem_url, validate_url**: which should be updated to match the relevant 
URL's for your Keycloak installation and realm (in the example above I'm using the master realm)
- **cookie_domain, whitelist_domain**: which should be updated to match the base URL you're deploying services on. E.g. in this example configuration I have `sso.ssotest.staging.talkingquickly.co.uk`, `someapp.ssotest.staging.talkingquickly.co.uk`, `oauth.ssotest.staging.talkingquickly.co.uk` etc and so my base domain would be `.ssotest.staging.talkingquickly.co.uk`.
- **ingress hosts**: These should be set the subdomain you wish to deploy OAuth2 Proxy to

Setting the `cookie_domain` and `whitelist_domain` is important because by default, OAuth2 Proxy is configured to work only with the subdomain it is deployed on. So cookies will be specific to that subdomain and redirects will only be allowed to that subdomain.

The `scope = "openid profile email"` line is important because by default, OAuth2 Proxy will request a scope called `api` which does not exist in Keycloak which will result in a 403 Invalid Scopes erorr.

The `set_authorization_header` line ensures that the JWT is passed back to the NGinx ingress, this is important because it allows us to then pass this header back to the authenticating application so that it can access more information about the logged in user.

While we wait for the `OAuth2 Proxy` chart to get a new home following the deprecation of the old helm stable repository, the most recent version is mirrored in the example code for this tutorial, so we can install OAuth 2 Proxy with:

```
helm upgrade --install oauth2-proxy ./charts/oauth2-proxy --values oauth2-proxy/values-oauth2-proxy.yml
```

We can then go the ingress domain that we selected for OAuth2 Proxy and we will see a "Sign in with Keycloak" option.

Note that if we are still signed in as the admin user (rather than as a regular user in the realm we configured OAuth2 Proxy with(), then we will see something along the lines of 403 Permission Denied, Invalid Account. Incognito / private browsing windows are useful for avoiding this.

Once we've successfully logged in with Keycloak, we'll simply be re-directed to a 404 page not found error because at the moment, there is nothing to authenticate. In practice we won't ever go to this URL directly, instead the authentication flow will be triggered automatically by visiting a protected application. So visiting this URL and logging in like this is purely to show that it works.

