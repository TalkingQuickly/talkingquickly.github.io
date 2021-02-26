---
layout : post
title: Gitea SSO with Keycloak, OpenLDAP and OpenID Connect
date: 2021-02-16 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/gitea-sso-with-keycloak-openldap-openid-connect'
---

Gitea is a lightweight open source git service. As an aside, Gitea - especially when combined with Drone CI - is one of my favourite pieces of open source software!

It's minimal footprint and easy to use interface make it perfect for running on clusters to facilitate git push deploys and CI.

Here we'll configure OpenLDAP for centralised user management and single sign on. We'll optionally configure OpenID Connect but with several caveats on its usage.

This post is part of a series on single sign on for Kubernetes.

<!--more-->

{% include kubernetes-sso/contents.html active="gitea" %}

{% include kubernetes-sso/pre-reqs.html %}

This post assumes you've completed the "Installing OpenLDAP", "Installing Keycloak" and "Linking Keycloak and OpenLDAP" sections.

## Installing Gitea

For the purposes of this post, we're only installing Gitea as a test case for OpenID Connect authentication, so we'll only take the time to configure the web frontend.

Depending on your cluster configuration, you'll want to customise `gitea/values-gitea.yml` with an ingress address and whether or not SSL should be enabled:

```yaml
gitea:
  domain: gitea-keycloak.ssotest.staging.talkingquickly.co.uk 
  protocol: http
  installLock: "false"

ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
  hosts:
    - host: gitea-keycloak.ssotest.staging.talkingquickly.co.uk
      paths: ['/']
  tls:
   - secretName: gitea-keycloak-https-secret
     hosts:
       - gitea-keycloak.ssotest.staging.talkingquickly.co.uk
```

We can then install Gitea with:

```
helm3 upgrade --install gitea-keycloak ./charts/gitea --values ./gitea/values-gitea.yml
```

Gitea should now be available on the chosen Ingress URL, in the example configuration above; `gitea-keycloak.ssotest.staging.talkingquickly.co.uk`.

We can then use this command to create an initial user with the username `administrator`, by executing the gitea CLI inside its pod. Remember to change `YOUR_PASSWORD` and `YOUR_EMAIL` to something:

```
kubectl exec -it --namespace identity \
      $(kubectl get pods -n identity --selector='app.kubernetes.io/instance=gitea' -o jsonpath='{.items[0].metadata.name}') \
      -- gitea admin user create --username YOUR_EMAIL --password YOUR_PASSWORD --email YOUR_EMAIL --admin --access-token --must-change-password=false
```

We should then be able to login to our Gitea instance.

## Configuring Gitea to use LDAP

While Gitea does support OIDC login, this is only for existing accounts, so it's not suitable for centralised user management. So here we'll be using LDAP.

[This Github Issue](https://github.com/go-gitea/gitea/issues/1124?_pjax=%23js-repo-pjax-container#issuecomment-284911694) on the Gitea repository explains the difference in behaviour between OIDC and LDAP.

Begin by logging back into Gitea as the `administrator` user and going to "Site Administration" and then then "Authentication Sources" tab. Choose "Add Authentication Source" and then select "LDAP (via BindDN)" as the source, select the following values:

- *Authentication Name*: `OpenLDAP`
- *Security Protocol*: `Unencrypted`
- *Host*: `openldap.identity.svc.cluster.local`
- *Port*: `389`
- *Bind DN*: `cn=readonly,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk`
- *Bind Password*: This should be the password you selected for the read only user in the `values-openldap.yml` file
- *User Search Base*: `ou=People,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk` remembering to replace the `dc` components with your own
- *User Filter*: `(&(objectClass=inetOrgPerson)(uid=%s))` This will allow all users to log into Gitea, you could create a more complex filter that would only let users in certain groups (e.g. "Engineers") [this article on search filters](https://confluence.atlassian.com/kb/how-to-write-ldap-search-filters-792496933.html) has some inspiration on how write these. `uid=%s` matches on uid, so people will be able to login with their username, you could modify this filter to match on both email and username.
- *Username Attribute*: `uid`
- *First Name Attribute*: `cn`
- *Surname attribute*: `sn`
- *Email Attribute*: `mail`

The [Gitea LDAP documentation](https://docs.gitea.io/en-us/authentication/) provides more detail on what each of these fields does.

If we then go back to the Gitea sign in page, we'll find that we can login directly with the credentials for the user we created in Keycloak. There's no re-direction, password authentication is performed behind the scenes. If we go to the security settings for the account, we'll see that because this user is managed externally, the password cannot be changed from with Gitea, only from within Keycloak.

## Configuring Gitea to use OpenID Connect

While OpenID connect cannot be used for "full" SSO in Gitea, e.g. the underlying users must already exist, it's possible (@TODO confirm) for users who have already logged in, to configure Keycloak OIDC as an additional login, so that they can go through the Keycloak flow rather than entering their keycloak username and password in Gitea.

The only real benefit of this approach is that where Keycloak is used extensively, the user may have an ongoing session there, so using that flow to login may be marginally more convenient than entering a username and password. So this option is included for completeness rather than as a typical user case. 

In the Keycloak admin interface, go to "Clients" in the side menu and choose "Create". Enter gitea for the `Client ID` and choose `openid-connect` for the "Client Protocol". Then enter:

- *Name*: Gitea
- *Access Type*: `confidential` (this is required to generate the client secret)
- *Valid Redirect URI's*: `https://GITEA_INGRESS_URL/*` (so in the case of my example above, this would be `https://gitea-keycloak.k4stest4.talkingquickly.co.uk/*`)

Once we've saved, we can then find the client secret by going back to the "Credentials" tab.

In gitea go to "Site Administration" and choose "Authentication Sources". Then choose "Add Authentication Source" and choose the following options:

- *Authentication Type*: `OAuth2`
- *Authentication Name*: `Keycloak`
- *OAuth2 Provider*: `OpenID Connect`
- *Client ID*: `gitea` (the value entered for id when creating the client)
- *Client Secret*: `YOUR_SECRET` the secret displayed on the credentials tab of the Keycloak Client page for the `gitea` client we created
- *OpenID Connect Auto Discovery URL*: `https://YOUR_KEYCLOAK_INGRESS_URL/auth/realms/master/.well-known/openid-configuration` replacing `YOUR_KEYCLOAK_INGRESS_URL` with the Ingress domain chosen for keycloak. 

It's important to note that Gitea will validate the certificate on creation of the provider and will not work without a valid SSL cert.

Before we try and login, we'll need to set a password for the user we created in KeyCloak. We can do this by going to the User in Keycloak, choosing the "Credentials" tab and setting a password, if we leave the "Temporary" switch on that page set to 1, then when the user signs in, they'll be asked to set a new password.

We can then go to the sign in page in Gitea and click on the "Sign in with OpenID Connect" option (we'll need to sign out if we're currently signed in as the administrator user). This will re-direct us the Keycloak login page where we can login with the user we created earlier in Keycloak. In my example this was `talkingquickly1` with the email `ben+1@hillsbede.co.uk`. 

Once we've signed in with our Keycloak credentials, we'll be re-directed back to Gitea.

Here we're asked to enter credentials for an existing user and can enter our keycloak users username and password so that in future we can login using the Keycloak auth flow.

{% include kubernetes-sso/contents.html active="gitea" %}