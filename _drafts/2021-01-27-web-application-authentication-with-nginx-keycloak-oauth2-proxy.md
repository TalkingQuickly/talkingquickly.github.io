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

## Putting an application behind auth

Now that we've setup OAuth2 Proxy, we can install an example application and add annotations to the ingress definition to have it protected behind the auth.

In this example we're going to simply install an instance of NGINX which serves up the default "Welcome to nginx!" page but require that users login with Keycloak before they can access it. Note that this is completely separate to the [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/) that we're using for Kubernetes.

We're going to be using the bitnami nginx helm chart for this so first we'll need to add the repo with:

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

We then configure our NGINX demo application along the lines of:

```yaml
serverBlock: |
  log_format    withauthheaders '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status  $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" "$http_x_auth_request_access_token"';
                    
    add_header    x-auth-request-access-token "$http_x_auth_request_access_token";

  # HTTP Server
  server {
      # Port to listen on, can also be set in IP:PORT format
      listen  8080;

      include  "/opt/bitnami/nginx/conf/bitnami/*.conf";

      location /status {
          stub_status on;
          access_log   off;
          allow 127.0.0.1;
          deny all;
      }

      access_log /dev/stdout withauthheaders;
  }

ingress:
  enabled: true
  hostname: nginx-demo-app2.ssotest.staging.talkingquickly.co.uk
  tls: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/auth-url: "https://oauth.ssotest.staging.talkingquickly.co.uk/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth.ssotest.staging.talkingquickly.co.uk/oauth2/start?rd=$scheme://$best_http_host$request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user, x-auth-request-email, x-auth-request-access-token"
    acme.cert-manager.io/http01-edit-in-place: "true"
  
service:
  type: ClusterIP
```

The custom `serverBlock` is nothing to do with the actual authentication process. It instead does the following two things to facilitate using NGINX as a demo for the auth functionality:

- Modifies the logging so that the `x-auth-request-access-token` header will be include in log output, this allows us to watch the logs and extract the tokens for analysis and testing
- It automatically appends the `x-auth-request-access-token` header from the incoming request to the final user response, so that we can inspect it in the browser

Note that especially outputting access tokens to logs is a security risk and should never be done in production.

The lines associated with the authentication are the following:

```yml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth.ssotest.staging.talkingquickly.co.uk/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth.ssotest.staging.talkingquickly.co.uk/oauth2/start?rd=$scheme://$best_http_host$request_uri"
    nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user, x-auth-request-email, x-auth-request-access-token"
    acme.cert-manager.io/http01-edit-in-place: "true"
```

The first, `nginx.ingress.kubernetes.io/auth-url` specifies the URL which should be used for checking if the current user is authenticated.

When a request comes in, NGINX auth will first send the request onto this URL, note that it will not send the request body, only the headers, most importantly, any cookies which are associated with the request.

The service at this URL (in our case OAuth2 Proxy) is responsible for validating, based on any cookies or headers present, whether the user is authenticated.

If the user is authenticated, then the service returns a 2xx status code, and the request is passed onto our application. If it is not authenticated, then it is passed to the URL specified in `nginx.ingress.kubernetes.io/auth-signin` to kick off the authentication flow.

This is why we had to set the cookie domain of OAuth2 Proxy to explicitly be the base domain, so that the cookie is available on all of the subdomains that we wish to authenticate from.

Because of the `set_authorization_header = true` in our configuration, When a request is authenticated, OAuth2 Proxy will set the `x-auth-request-access-token` header on the 2xx response it sends back to NGINX to contain the auth token, in this case a JWT containing information about the user and their session.

By default, there's no way for our original application to access this token and if we want our application to know which user is logging in or which groups they are a member of, it will need this information. 

To rectify this, the annotation `nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user, x-auth-request-email, x-auth-request-access-token"` instructs the NGINX Ingress to take the listed headers from the returned 2xx response and append them to the response which goes to the backend application.

Our backend application can then take this header and decode the JWT to gain information about the user.

In the case of this simple example we simply output it to the logs (insecurely) and append it to the response sent to the user. So if we now go to our Ingress URL for our nginx demo app, in the example case this was https://nginx-demo-app2.ssotest.staging.talkingquickly.co.uk we'll be asked to login and then redirected to the "Welcome to nginx!" page. 

We can then inspect the request using the network tab in our browser and we'll see that the `x-auth-request-access-token` is set on the response.

If we copy the value of this header into a decoder such as the one at <https://jwt.io/> we'll see something like:

```json
{
...
  "scope": "openid email profile",
  "email_verified": false,
  "name": "Ben Dixon",
  "groups": [
    "/DockerRegistry",
    "/KubernetesAdmins",
    "/Administrators"
  ],
  "preferred_username": "talkingquickly",
  "given_name": "Ben",
  "family_name": "Dixon",
  "email": "ben@talkingquickly.co.uk"
}
```

Which in a more complex system, could then be used by our backend application to show different content depending on group membership or surface profile information to the user.

## Limiting access to certain groups