---
layout : post
title: Web application authentication and authorization with Keycloak and OAuth2 Proxy on Kubernetes
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/webapp-authentication-keycloak-OAuth2-proxy-kubernetes'
---

Many third party applications we run on Kubernetes will already support either OIDC or LDAP based login. Some however will not. In addition we may wish to deploy our own applications and use Keycloak to manage access to them without going through the work of adding OIDC or LDAP integration to them.

In this post we'll use OAuth2 Proxy to add authentication to a simple Ruby application. We'll then go one step further and get information about the logged in user and their group membership from within our web application. In it's simplest form, this would allow us to protect internal admin applications. In a more complete setup, we could setup a "customers" realm within Keycloak and delegate all of our authentication and authorization to Keycloak.

Note that OAuth2 Proxy is the [suggested replacement](https://www.keycloak.org/2020/08/sunsetting-louketo-project.adoc) for Keycloaks Gatekeeper / Louketo project which reached EOL in August 2020.

<!--more-->

{% include kubernetes-sso/contents.html active="webapp" %}

{% include kubernetes-sso/pre-reqs.html %}

This post assumes you've completed the "Installing Keycloak" section and have a working Keycloak installation.

## Keycloak authentication for an Nginx server

First we'll configure OAuth2 Proxy to work with our Keycloak installation and deploy it using a helm chart. 

Then we'll deploy the [official Nginx container](https://hub.docker.com/_/nginx) image using a helm chart as an example application and then we'll restrict access to it via Keycloak using ingress annotations.

We'll then look at how the app we're authenticating can access information about the logged in user and how this information could be used to implement more fine-grained access control.

## Keycloak authentication for a Ruby app

Here we'll build out a more complete example of using Keycloak for authentication by creating a simple Ruby application which includes some basic authorization in the form of allowing access to different pages depending on the groups the authenticated user is a member of.
