---
layout : post
title: Docker Registry Authentication on Kubernetes with Keycloak
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/docker-registry-authentication-with-keycloak'
---

In this post we'll cover how to use Keycloak to provide a simple authentication layer for a Docker registry. Simple meaning that in order to push and pull images to the registry, the user will first need to `docker login` as any valid user in the provided Keycloak realm. Note that there is no additional access control, so all Keycloak users have the ability to perform any action on any image once authenticated. For more fine grained controls, see the section on using Harbour.

This post is part of a series on single sign on for Kubernetes.

<!--more-->

{% include kubernetes-sso/contents.html active="dockerregistry" %}

{% include kubernetes-sso/pre-reqs.html %}

This post assumes you've already completed the "Installing Keycloak" section.

## Configuring Keycloak

When we configured Keycloak, we included the following in the helm values file:

```yaml
args:
  - -Dkeycloak.profile.feature.docker=enabled
```

Which enabled the optional support for the Docker registry.

## Setting up the Docker Registry in Keycloak

Begin by creating a new client in Keycloak with client id "simple-docker-registry" using client protocol `docker-v2`. On the following screen go to the installation tab, choose "Docker Compose YAML" and select the "Download" option. Note that we aren't going to be using Docker Compose, but this provides a convenient method for downloading the certificate files we'll need to create as Kubernetes secrets.

## Creating the certificate secrets

Having downloaded the Docker Compose YAML zip file from Keycloak, extract it to a locally accessible folder and check that it contains a file `certs/localhost_trust_chain.pem`. We can then create a Kubernetes secret containing the file with the following:

```
kubectl create secret generic docker-registry-auth-token-rootcertbundle --from-file YOUR_PATH_TO/certs/localhost_trust_chain.pem
```

Replacing `YOUR_PATH_TO/certs/localhost_trust_chain.pem` with the path to the downloaded file.

This will create a secret called `docker-registry-auth-token-rootcertbundle` containing the certificate contents.

## Configuring the docker registry

The documentation for the helm chart we'll be using to install the Docker Registry is here: <https://github.com/twuni/docker-registry.helm>. Our configuration file will look like this:

```yaml
configData:
  auth:
    token:
      realm: https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master/protocol/docker-v2/auth
      service: simple-docker-registry
      issuer: https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master
      rootcertbundle: /root-cert-bundle/localhost_trust_chain.pem
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
  hosts:
    - registry-keycloak.ssotest.staging.talkingquickly.co.uk

  tls:
  - hosts:
    - registry-keycloak.ssotest.staging.talkingquickly.co.uk
    secretName: keycloak-registry-tls-secret
    
extraVolumes:
  - name: docker-registry-auth-token-rootcertbundle
    secret:
      secretName: docker-registry-auth-token-rootcertbundle

extraVolumeMounts:
  - mountPath: /root-cert-bundle
    name: docker-registry-auth-token-rootcertbundle
    readOnly: true
```

The `configData` section at the top configures the Docker Registry to use token based auth from KeyCloak as per the [Keycloak Docs](https://www.keycloak.org/docs/4.8/securing_apps/#docker-registry-configuration).

You'll then need to update the ingress definitions to reflect the URL you wish to make your docker registry available on, so replacing `registry-keycloak.ssotest.staging.talkingquickly.co.uk` with the subdomain you'll be using.

Note that ingress annotation `nginx.ingress.kubernetes.io/proxy-body-size: "0"` which removes the default limit on the maximum body size NGINX will accept and avoids `413 Request Entity Too Large` when pushing large images.

The `extraVolumes` section creates a volume which will contain the files from the `docker-registry-auth-token-rootcertbundle` secret we created. The `extraVolumeMounts` section instructs Kubernetes to mount this volume at the `/root-cert-bundle` path within the Docker registry container which matches the `rootcertbundle` path that we specified in the `configData` map at the start.

## Installing the Docker Registry

We can then add the repository for the helm chart and install the Docker registry with:

```
helm repo add twuni https://helm.twun.io
helm upgrade --install simple-docker-registry twuni/docker-registry --values ./docker-registry/values-docker-registry.yml
```

## Testing the registry

We'll need to give certificates a small window to be generated via LetsEncrypt, we can check on the progress of the certificates with `kubectl get certificates`. Once they are ready we can login to our registry with:

```
docker login registry-keycloak.ssotest.staging.talkingquickly.co.uk
```

Replacing the URL with the ingress URL we configured. We can then enter the credentials of any Keycloak user in the realm we configured and we'll see something like:

```
Username: someusername
Password:
WARNING! Your password will be stored unencrypted in /home/ben/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

If we want to test that pushing images works we can do something like:

```
docker image tag SOME_IMAGE_REF registry-keycloak.ssotest.staging.talkingquickly.co.uk/SOME_NAME
docker push registry-keycloak.ssotest.staging.talkingquickly.co.uk/SOME_NAME
```

And see that the image is pushed correctly.

We can then test pulling with:

```
docker pull registry-keycloak.ssotest.staging.talkingquickly.co.uk/SOME_NAME
```

We then test that authentication works by logging out with:

```
docker logout registry-keycloak.ssotest.staging.talkingquickly.co.uk
```

And trying to pull the image again:

```
docker pull registry-keycloak.ssotest.staging.talkingquickly.co.uk/SOME_NAME
```

Where we'll receive a permission denied message.

## Use with Kubernetes

In order to access images in the registry we'll need to create appropriate image pull secrets as described [here in the kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).

## Summary

We now have a private Docker Registry which can only be accessed by users authenticated via Keycloak. For more advanced configurations, for example where only certain users should be able to access the registry or where more granular access control is required, see [Harbour Docker Registry with Keycloak](@TODO).