---
layout : post
title: Single Sign on to Kubernetes
date: 2020-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
---

In this series of posts we cover how to setup a comprehensive group based single sign on system for Kubernetes including `kubectl`, any web application with ingress, a docker registry, gitea and Kibana.

The full solution uses Keycloak backed by OpenLDAP. OpenLDAP is required for the Gitea and Harbour Docker Registry components, but can be skipped for the other components, including OIDC based SSO for `kubectl`.

<!--more-->

1. Installing OpenLDAP
1. Installing Keycloak
1. Linking Keycloak and OpenLDAP
1. OIDC Kubectl authentication and authorization
1. Arbitrary webapp authentication
1. Gitea (requires LDAP)
1. Simple Docker Registry
1. Harbour Docker Registry (requires LDAP)
1. Grafana

Finally there were a lot of excellent resources I leant on when creating this series, there's a summary of the key ones [here](@todo link).