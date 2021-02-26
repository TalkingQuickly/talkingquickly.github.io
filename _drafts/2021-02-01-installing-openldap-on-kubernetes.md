---
layout : post
title: Installing OpenLDAP on Kubernetes with Helm
date: 2021-02-01 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/installing-openldap-kubernetes-helm'
---

In this post we cover how to install OpenLDAP on Kubernetes and how to test that it is working using the command line.

LDAP while an older - and in some ways more challenging to work with - approach to SSO than something like OIDC, is still the de-facto standard.

There are many popular applications which don't support OIDC but do support LDAP. This is likely to be the case for many years to come so for now, any robust SSO solution is likely to need to support LDAP.

This post is part of a series on single sign on for Kubernetes

<!--more-->

{% include kubernetes-sso/contents.html active="openldap" %}

{% include kubernetes-sso/pre-reqs.html %}

## Installing OpenLDAP

The Helm chart for OpenLDAP was deprecated as part of the deprecation of the `stable` chart repository. So while we await a replacement to appear, the most recent version is mirrored in the repo for this tutorial.

. We'll want to create a `openldap/values-openldap.yml` file and customise the following variables:

```yaml
# Default configuration for openldap as environment variables. These get injected directly in the container.
# Use the env variables from https://github.com/osixia/docker-openldap#beginner-guide
env:
  LDAP_ORGANISATION: "Talking Quickly Demo"
  LDAP_DOMAIN: "ssotest.staging.talkingquickly.co.uk"
  LDAP_BACKEND: "hdb"
  LDAP_TLS: "true"
  LDAP_TLS_ENFORCE: "false"
  LDAP_REMOVE_CONFIG_AFTER_SETUP: "true"
  LDAP_READONLY_USER: "true"
  LDAP_READONLY_USER_USERNAME: readonly
  LDAP_READONLY_USER_MASSWORD: password

# Default Passwords to use, stored as a secret. If unset, passwords are auto-generated.
# You can override these at install time with
# helm install openldap --set openldap.adminPassword=<passwd>,openldap.configPassword=<passwd>
adminPassword: admin
configPassword: 9h8sdfg9sdgfjsdfg8sdgsdfjgklsdfg8sdgfhj

customLdifFiles:
  initial-ous.ldif: |-
    dn: ou=People,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk
    objectClass: organizationalUnit
    ou: People

    dn: ou=Group,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk
    objectClass: organizationalUnit
    ou: Group
```

In this case `dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk` is the base domain I'm using for my test Kubernetes cluster. For the purposes of setting up our LDAP server, this is just an internal identifier, so does not need to map to any sort of DNS.

The `customLdifFiles` section is being used to pre-seed the LDAP database. In this case with two `organizationalUnit`'s, one `People` will be used to store individual users and another `Group` will be used to store Groups. `OU`s can be though of simplistically as analogous to folders in a traditional file system, [this article on ous](ttps://www.theurbanpenguin.com/openldap-ous/) is well worth a read to get a better understanding for how they fit together.

We can install OpenLDAP with the following command:

```bash
helm upgrade --install openldap ./charts/openldap --values openldap/values-openldap.yml
```

Once it installs, you should see some output confirming success and some examples of how to access the server.

Importantly this will includes the commands which will give instructions for getting the config and administration passwords, e.g:

```
kubectl get secret --namespace identity openldap -o jsonpath="{.data.LDAP_ADMIN_PASSWORD}" | base64 --decode; echo
kubectl get secret --namespace identity openldap -o jsonpath="{.data.LDAP_CONFIG_PASSWORD}" | base64 --decode; echo
```

## Using The OpenLDAP CLI

Although we'll primarily manage our LDAP directory through KeyCloak, it's useful to have a basic familiarity with the CLI for testing purposes. [Splunk has a great introduction to the CLI here](https://www.splunk.com/en_us/blog/tips-and-tricks/ldapsearch-is-your-friend.html).

We'll start by using `kubectl proxy` to expose our LDAP server locally:

```bash
kubectl port-forward --namespace identity \
      $(kubectl get pods -n identity --selector='release=openldap' -o jsonpath='{.items[0].metadata.name}') \
      3890:389
```

In a separate terminal execute (most unix systems, inc OSX, come with ldapsearch installed, if yours does not, you'll need to download it, for debian based distributions you'll need `ldap-utils`):

```bash
ldapsearch -x -H ldap://localhost:3890 -b dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk -D "cn=admin,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk" -w password
```

This return something along the lines of:

```
objectClass: organization
o: Talking Quickly's Demo
dc: k4stest4

# admin, k4stest4.talkingquickly.co.uk
dn: cn=admin,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword:: e1NTSEF9YjM1a0hLYXVwcDlvcGU5R1N2UE5qcFBLd3FxdUorWFk=

# People, k4stest4.talkingquickly.co.uk
dn: ou=People,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk
objectClass: organizationalUnit
ou: People

# Group, k4stest4.talkingquickly.co.uk
dn: ou=Group,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk
objectClass: organizationalUnit
ou: Group

# search result
search: 2
result: 0 Success

# numResponses: 6
# numEntries: 4
```

It's worth perusing [this Stack Overflow post](https://stackoverflow.com/questions/18756688/what-are-cn-ou-dc-in-an-ldap-search) to understand a little more about the `dn`, `dc` terminology.

Note that my test domain `ssotest.staging.talkingquickly.co.uk` results in a `dn` (Distinguished Name) made up of a comma separated list of `dc` (Domain Components)  `dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk`. We can also see that our `ou`s from the `customLdiffFiles` have been created.

So now we have an LDAP server and have a simple way of checking what's stored in it. We can now move onto installing Keycloak.

{% include kubernetes-sso/contents.html active="openldap" %}