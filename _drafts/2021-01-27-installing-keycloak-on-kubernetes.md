---
layout : post
title: Installing Keycloak on Kubernetes
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/installing-keycloak-kubernetes-helm'
---

Keycloak is a widely used open source identity and access management system. Think Okta but open source. This is where users will actually enter their username and password for services and where we'll configure which users can login to which applications. It will also provide users with a single directory of applications they can login to.

In this post - as part of the larger series on Kubernetes SSO - we cover how to install Keycloak on Kubernetes.

<!--more-->

{% include kubernetes-sso/contents.html active="keycloak" %}


{% include kubernetes-sso/pre-reqs.html %}

## Install Keycloak

Helm 3 is migrating charts out of it's centrally managed repository and into decentralised ones, so to access the Keycloak Chart we'll need to add the relevant repository.

```
helm repo add codecentric https://codecentric.github.io/helm-charts
```

We can see [details of the chart itself here](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak).

For a basic configuration, we need to configure Ingress and enable Postgres as the data store. 

This assumes you're working on a cluster with support for Ingress and Persistent Volumes. In this case I have a wildcard DNS record for `*.ssotest.staging.talkingquickly.co.uk` which points at my test cluster. So our initial values file `keycloak/values-keycloak` looks something like:

```yaml
extraEnv: |
  - name: KEYCLOAK_LOGLEVEL
    value: DEBUG
  - name: KEYCLOAK_USER
    value: admin
  - name: KEYCLOAK_PASSWORD
    value: as897gsdfs766dfsgjhsdf
  - name: PROXY_ADDRESS_FORWARDING
    value: "true"

ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
  rules:
    - host: sso.ssotest.staging.talkingquickly.co.uk
      paths:
        - /
args:
  - -Dkeycloak.profile.feature.docker=enabled

  tls:
  - hosts:
    - sso.ssotest.staging.talkingquickly.co.uk
    secretName: keycloak-tld-secret

postgresql:
  enabled: true
  postgresqlPassword: asdfaso97sadfjylfasdsf78
```

We can then install it with:

```
helm upgrade --install keycloak codecentric/keycloak --values keycloak/values-keycloak.yml
```

We've set the initial username and password of the keycloak user in the environment variables `KEYCLOAK_USER` and `KEYCLOAK_PASSWORD` in our `values-keycloak.yml`, well need these to login to the administrative console.

We can then go to whichever URL we've selected for Ingress, in my case this was `https://sso.ssotest.staging.talkingquickly.co.uk`.

{% include kubernetes-sso/contents.html active="keycloak" %}