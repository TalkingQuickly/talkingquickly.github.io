---
layout : post
title: Kubernetes Single Sign On - A detailed guide
date: 2021-02-25 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/kubernetes-sso-a-detailed-guide'
---

In this series of posts we cover how to setup a comprehensive group based single sign on system for Kubernetes including the `kubectl` cli, any web application with ingress, a docker registry and gitea. We'll cover most of the common SSO models so adapting what's here to other applications such as Gitlab, Kibana, Grafana etc is simple.

The full solution uses Keycloak backed by OpenLDAP. OpenLDAP is required for the Gitea component, but can be skipped for the other components, including OIDC based SSO for `kubectl`.

Some of the highlights this series covers are:

1. Login to the `kubectl` cli using SSO credentials via the browser
1. Replace basic auth ingress annotations with equally simple but much more secure SSO annotations
1. Push and pull to a secure private docker registry with full ACL

{% include kubernetes-sso/contents.html active="contents" %}

Finally there were a lot of excellent resources I leant on when creating this series, there's a summary of the key ones [here](/kubernetes-sso-links).