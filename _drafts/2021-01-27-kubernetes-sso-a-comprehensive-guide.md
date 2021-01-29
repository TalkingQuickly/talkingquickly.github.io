---
layout : post
title: Kubernetes Single Sign On - a comprehensive guide
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/kubernetes-sso-a-comprehensive-guide'
---

In this series of posts we cover how to setup a comprehensive group based single sign on system for Kubernetes including `kubectl`, any web application with ingress, a docker registry, gitea and Kibana.

The full solution uses Keycloak backed by OpenLDAP. OpenLDAP is required for the Gitea and Harbour Docker Registry components, but can be skipped for the other components, including OIDC based SSO for `kubectl`.

{% include kubernetes-sso/contents.html active="contents" %}

Finally there were a lot of excellent resources I leant on when creating this series, there's a summary of the key ones [here](@todo link).