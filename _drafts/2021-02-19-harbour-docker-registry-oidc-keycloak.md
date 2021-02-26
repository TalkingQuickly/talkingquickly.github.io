---
layout : post
title: Comprehensive docker registry on Kubernetes with Harbor and Keycloak for single sign on
date: 2021-02-19 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/harbor-docker-registry-on-kubernetes-authentication-with-keycloak'
---

In this post we'll install a feature rich but lightweight docker registry and integrate login and authorization with Keycloak and Keycloak groups. 

[Harbor](https://goharbor.io) is a open source registry which can serve multiple types of cloud artifacts and secure them using fine grained access control. In this case we'll be focussed on using harbor as a docker image registry and linking it's authentication with Keycloak but it is also capable of serving multiple other types of artifact, including helm charts.

This post is part of a series on single sign on for Kubernetes.

<!--more-->

{% include kubernetes-sso/contents.html active="harborregistry" %}

{% include kubernetes-sso/pre-reqs.html %}

This post assumes you've already completed the "Installing Keycloak" section.

## Installing harbor

The official helm chart for installing harbor can be found here: <https://github.com/goharbor/harbor-helm>.

As with most helm charts, we learn a lot by inspecting the [values file which can be found here](https://github.com/goharbor/harbor-helm/blob/master/values.yaml).

In this tutorial we're going to customise the sections which define ingress and TLS certificate generation. OIDC configuration has to be done post installation and can either be done using the HTTP API or the web UI.

Our initial values file will look something like this:

```yaml
expose:
  type: ingress
  tls:
    certSource: secret
    secret:
      secretName: harbor-ingress-tls
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-production

    hosts:
      core: core.harbor.ssotest.staging.talkingquickly.co.uk
      
harborAdminPassword: 85nsafg87ehfgk0fgsgfg6u
externalURL: https://core.harbor.ssotest.staging.talkingquickly.co.uk
secretKey: "8d10dlskeit8fhtg"

notary:
  enabled: false

metrics:
  enabled: true
```

Important things to note here:

- `certSource: secret` combined with `secretName: harbor-ingress-tls` mean that harbor will use the certificate generated for the ingress (by cert manager) rather than generating it's own certificates. This avoids errors such as `x509: certificate signed by unknown authority` when running `docker login`
- The `core:` ingress url should be replaced with the URL you wish Harbour to run on, which should have appropriate DNS records to point it to your NGINX ingress
- `harbourAdminPassword`, `externalURL` and `secretKey` should all be customised with your own values, `secretKey` should be a random 16 character value

We can then add the helm repository and install harbor with:

```
helm repo add harbor https://helm.goharbor.io
helm upgrade --install harbor-registry harbor/harbor --values=./harbor/values-harbor.yml
```

Once this command completes, we'll be able to access the Harbor UI using the ingress URL we selected for `core` with the username `admin` and the password we specified in `harborAdminPassword`. It takes a while for the various components to start and it's not unusual to see a few pods in `CrashLoopBackoff` for a while while this is happening.

Note that we cannot `docker login` with our admin user and we don't currently have any regular users. We should not create any regular users because we can only switch to OIDC based login if no users other than `admin` have been created.

If we create a test user now and then subsequently delete it, we still won't be able to switch to OIDC based login.

## Creating a client in Keycloak

In the KeyCloak clients UI create a new client with Client ID `harbor` and Client Protocol "openid-connect" with the following configuration:

- **Access Type**: `confidential`
- **Valid Redirect URIs**: `https://YOUR_HARBOR_INGRESS_DOMAIN/c/oidc/callback`

Then save the client and make a note of the "Client Secret" in the newly appeared credentials tab.

Finally head to the "Mappers" tab for the client and create the following Protocol Mapper:

- **Name**: Groups
- **Mapper Type**: Group Membership
- **Token Claim Name**: `groups`
- **All Other Options**: On

## Configuring Harbor OIDC via the admin UI

Login to the Harbour web UI available at the ingress URL you selected using the username `admin` and the password you specified in `harborAdminPassword`.

Head to `Administration` and then `Configuration` and choose the `Authentication` tab. Change the `Auth Mode` to `OIDC` and then enter the following configuration:

- **OIDC Provider Name**: Keycloak
- **OIDC Endpoint**: `https://YOUR_KEYCLOAK_BASE_URL/auth/realms/YOURREALM`
- **OIDC Client ID**: `harbor`
- **OIDC Client Secret**: The secret from keycloak clients credentials tab
- **Group Claim Name**: `groups`
- **OIDC Scope**: `openid,profile,email,offline_access`
- **Verify Certificate**: checked if you're using a valid SSL cert
- **Automatic Onboarding**: checked
- **Username Claim**: `preferred_username`

We can then use the "Test OIDC Server" button to make sure everything is working and once it is, choose "Save".

## Testing that it works

If we now logout from our admin user (or use a private browsing tab), and return to our Harbor core ingress URL, we now have the option to "Login with OIDC Provider". If we select this we'll be redirected to Keycloak to login. Here we should login with a regular Keycloak user from the realm we're using (by default master), **NOT** our keycloak admin user.

We'll then be logged into Harbor and an account automatically created for us based on our Keycloak preferred username.

If we now log back in as our admin user and go to "Administration" and "Groups" we'll see that any Keycloak groups the user was a member of have now been replicated into Harbor. This means we can link certain groups to certain projects to automatically give users access to the correct projects.

Note that by default, all users can create projects. Since all Keycloak users can login to Harbor by default, it may be preferred to limit project creation to admins which can be done by choosing Administration/ Configuration/ System Settings and setting "Project Creation" to Admin Only.

As an example we can then as an admin user, create a private project called "test1", then head to the "Members" tab of this project and choose "+ Group". We can then enter `/Administrators` as the Group Name and choose "Project Admin" as the role. Any users in the `Administrators` Keycloak group will then automatically be given the `Project Admin` role for this project.

## Use with Docker

Assuming we have created the `test1` private project above and given our Keycloak user access to it, we can login to the docker registry from our local CLI with the following command:

```
docker login YOUR_HARBOR_CORE_INGRESS_URL
```

So in my example case this would be:

```
docker login core.harbor.ssotest.staging.talkingquickly.co.uk
```

We can then use our keycloak username. For a password, we should not use our Keycloak password (this won't work) we should instead obtain our CLI Secret from Harbor by clicking on our username in the top right hand corner, choosing "User Profile" and copying the CLI secret.

We can then tag an image to be pushed to this repository with:

```
docker tag SOURCE_IMAGE[:TAG] core.harbor.ssotest.staging.talkingquickly.co.uk/test1/REPOSITORY[:TAG]
```

and push it with:

```
docker push core.harbor.ssotest.staging.talkingquickly.co.uk/test1/REPOSITORY[:TAG]
```

When we need to give things like CI servers or Kubernetes access to the repository, we can head to the "Robot Accounts" tab in Harbor to generate limited access tokens for exactly this.

## Configuring Harbor OIDC from the command line

In any sort of automated environment (e.g. Ansible, Chef etc) it's desirable to be able to configure everything without touching the UI. For this Harbor offers a comprehensive API. To view the API documentation login as the admin user and click on the "Habor API V2.0" option at the bottom which will take you to the swagger documentation.

By default the API will be available on 

```
YOUR_INGRESS_URL/api/v2.0/
```

So for example to view the current configuration we can use:

```
curl -u "admin:HARBOR_ADMIN_PASSWORD" -H "Content-Type: application/json" -ki YOUR_INGRESS_URL/api/v2.0/configurations
```

Note that at time of writing, the docs at <https://goharbor.io/docs/1.10/install-config/configure-user-settings-cli/> were slightly behind the current version and while this is the case, getting the existing configuration object provides a better overview of the configuration options available.

So to set up OIDC auth via CLI:

```
curl -X PUT -u "admin:YOUR_ADMIN_PASSWORD" -H "Content-Type: application/json" -ki YOUR_HARBOR_CORE_INGRESS_URL/api/v2.0/configurations -d'{"auth_mode":"oidc_auth", "oidc_name":"Keycloak Auth", "oidc_endpoint":"YOUR_KEYCLOAK_REALM_INGRESS", "oidc_client_id":"harbor", "oidc_client_secret":"YOUR_KEYCLOAK_CLIENT_SECRET", "oidc_scope":"openid,profile,email,offline_access", "oidc_groups_claim":"groups", "oidc_auto_onboard":"true", "oidc_user_claim":"preferred_username"}'
```

A 200 response indicates that we have Succesfully setup Keycloak auth.

We could then restrict project creation to admins only with:

```
curl -X PUT -u "admin:YOUR_ADMIN_PASSWORD" -H "Content-Type: application/json" -ki YOUR_HARBOR_CORE_INGRESS_URL/api/v2.0/configurations -d '{"project_creation_restriction":"adminonly"}'
```

The Habor API is comprehensive e.g. we can also create projects and give groups permission to access these projects entirely via the API so it's well worth spending time with the Swagger documentation.

## Use with Kubernetes

In order to access images in the registry we'll need to create appropriate image pull secrets as described [here in the kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) for this we should use project "Robot Tokens". 

## Summary

We now have a self hosted registry for docker images which is fully integrated with Keycloak for authentication. We can also configure this via the command line if we want to automate setup with a configuration management tool such as Chef or Ansible.