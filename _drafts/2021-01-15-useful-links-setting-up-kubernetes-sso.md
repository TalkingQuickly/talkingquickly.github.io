---
layout : post
title: Useful Links when Setting up SSO on Kubernetes
date: 2021-01-15 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/kubernetes-sso-links'
---

While creating the comprehensive guide to Kubernetes SSO, I leant heavily on many great pieces of existing content, a lot of them are included here.

<!--more-->

{% include kubernetes-sso/contents.html active="links" %}

LDAP section of the Keycloak manual: <https://www.keycloak.org/docs/6.0/server_admin/#_ldap>

Tutorial on Keycloak + OpenLDAP: <https://geek-cookbook.funkypenguin.co.nz/recipes/keycloak/authenticate-against-openldap/>

Using Keycloak to authenticate general web applications (sidecar approach): <https://www.openshift.com/blog/adding-authentication-to-your-kubernetes-web-applications-with-keycloak>

Gatekeeper (by Keycloak) <https://www.keycloak.org/docs/latest/securing_apps/index.html#_keycloak_generic_adapter>

Gatekeeper (by Keycloak) on docker hub: <https://hub.docker.com/r/keycloak/keycloak-gatekeeper/>

Replacement for Gatekeeper (which is now EOL) <https://github.com/oauth2-proxy/oauth2-proxy>

Docker registry authentication with Keycloak: <https://developers.redhat.com/blog/2017/10/31/docker-authentication-keycloak/>

Gitea authentication documentation: <https://docs.gitea.io/en-us/authentication/>

oAuth 2 with Nginx Ingress; <https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/>

oAuth2Proxy which supports keycloak as a provider: <https://github.com/oauth2-proxy/oauth2-proxy>

Another tutorial on using oauth-proxy with nginx auth: <https://www.digitalocean.com/community/tutorials/how-to-protect-private-kubernetes-services-behind-a-github-login-with-oauth2_proxy>

Introduction to the ldapsearch cli utility: <https://www.splunk.com/en_us/blog/tips-and-tricks/ldapsearch-is-your-friend.html>

Deep dive into LDAP password encryption: <https://www.redpill-linpro.com/techblog/2016/08/16/ldap-password-hash.html>

Introduction to "OUs' (organisational units) in LDAP: <https://www.theurbanpenguin.com/openldap-ous/>

Article on synchronising groups between LDAP and Keycloak: <https://www.janua.fr/mapping-ldap-group-and-roles-to-redhat-sso-keycloak/>

Selection of examples of `ldapsearch` usage: <https://docs.oracle.com/cd/E19450-01/820-6169/ldapsearch-examples.html>

Thread on How Gitea treats Oauth2 and LDAP etc logins differently: <https://github.com/go-gitea/gitea/issues/1124?_pjax=%23js-repo-pjax-container#issuecomment-284911694>

Gitea LDAP documentation: <https://docs.gitea.io/en-us/authentication/>

Some examples of LDAP search filters: <https://confluence.atlassian.com/kb/how-to-write-ldap-search-filters-792496933.html>

How to enable the `memberOf` feature in OpenLDAP: <https://technicalnotes.wordpress.com/2014/04/19/openldap-setup-with-memberof-overlay/>

LDIF files for enabling the `memberOf` feature in OpenLDAP: <https://www.adimian.com/blog/2014/10/how-to-enable-memberof-using-openldap/>

Detailed Github issue on getting `memberOf` to work with the docker openldap image: <https://github.com/osixia/docker-openldap/issues/304>

Kubernetes Day 2 operations inc OIDC (this article is fantastic) <https://medium.com/@mrbobbytables/kubernetes-day-2-operations-authn-authz-with-oidc-and-a-little-help-from-keycloak-de4ea1bdbbe>

Kubernetes docs on configuring OIDC <https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuring-the-api-server>

Kube OIDC Proxy, tool for allowing OIDC configuration on managed clusters that don't allow it by default, e.g. EKS, AWS etc; <https://github.com/jetstack/kube-oidc-proxy>

Loads of great content about keycloak <https://github.com/thomasdarimont/awesome-keycloak>

Web application for generating kubeconfig files when working with OIDC <https://github.com/heptiolabs/gangway>

AWS article on the use of `kube-oidc-proxy` <https://aws.amazon.com/blogs/opensource/consistent-oidc-authentication-across-multiple-eks-clusters-using-kube-oidc-proxy/>

Tool for logging into kubectl via OIDC; <https://github.com/int128/kubelogin/blob/master/docs/setup.md>

More on debugging OIDC login; <https://github.com/int128/kubelogin/issues/156>

More on different kubelogin flows, e.g. browser vs password (https://github.com/int128/kubelogin/blob/master/docs/usage.md)

Grafana OIDC info: <https://grafana.com/docs/grafana/latest/auth/generic-oauth/>

{% include kubernetes-sso/contents.html active="links" %}