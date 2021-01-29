---
layout : post
title: Keycloak and OpenLDAP on Kubernetes
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/keycloak-and-openldap-on-kubernetes'
---

In this post we'll cover how - having installed Keycloak and OpenLDAP separately on Kubernetes - to link the two together so that Keycloak users OpenLDAP as it's primary store for user data.

This post is part of a series on single sign on for Kubernetes.

<!--more-->

{% include kubernetes-sso/contents.html active="keycloak_openldap" %}

{% include kubernetes-sso/pre-reqs.html %}

This post assumes you've already completed the "Intalling OpenLDAP" and "Installing Keycloak" sections.

## Configuring OpenLDAP in Keycloak

After logging into Keycloak with our admin user, head to User Federation and select `ldap` from the "Add Provider` dropdown. Then choose the following options:

- **Edit Mode**: `Writable`
- **Sync Registrations**: `On`
- **Vendor**: `Other`
- **Connection URL**: `ldap://openldap.identity.svc.cluster.local`; you'll need to change `identity` to match the namespace you're working in)
- **Users DN**: `ou=People,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk`; you'll need to change the `dc` entries to match your base dn. Note that here we're telling Keycloak that users are stored in our `People` ou, created from the `customLdiffFiles`.
- **Authentication Type**: `simple`
- **Bind DN**: `cn=admin,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk` again, updating the `dc` entries to match your base dn
- **Bind Credentials**: Set this to the admin password we used for `ldapsearch` earlier

Once we've entered all of these details, we can use the "Test connection" and "Test authentication" buttons to make sure that everything works. Assuming it does, we can select "Save" to complete the addition of a User Federation provider.

At this point we've configured Keycloak so that it knows how to synchronise user with OpenLDAP, but currently it has no concept of groups. With more than a handful of users, we'll want to be able to allocate people to groups and determine their access to systems according to group membership. 

For this we need to go back to the "User Federation" entry on the left menu, choose our ldap entry and select the "Mappers" tab.

We then need to select "Create", enter `group` as the Name for our federation mapper and select `group-ldap-mapper` as the "Mapper Type". Then select the following:

- **LDAP Groups DN**: `ou=Group,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk` (updating to match your configuration)
- **Group Object Classes**: `groupOfUniqueNames`
- **Membership LDAP Attribute**: `uniqueMember`
- **User Groups Retrieve Strategy**: `LOAD_GROUPS_BY_MEMBER_ATTRIBUTE`

And choose save. This configuration is slightly different to the default and ensures that the `memberOf` attribute works correctly. There's a long Github issue on it [here](https://github.com/osixia/docker-openldap/issues/304). This is required by some applications - including the harbour docker registry - to manage access based on groups.

Note that in order to test that `memberOf` is working correctly, we'll need to include "+" as part of our `ldapsearch` command e.g:

```
ldapsearch -x -H ldap://localhost:3890 -b dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk -D "cn=admin,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk" "+" -w password
```

To [include operational attributes](https://docs.oracle.com/cd/E19623-01/820-6169/searching-for-special-entries-and-attributes.html).

To run the commands locally you'll need to forward the OpenLDAP port to your local machine with:

```bash
kubectl port-forward --namespace identity \
      $(kubectl get pods -n identity --selector='release=openldap' -o jsonpath='{.items[0].metadata.name}') \
      3890:389
```

## Managing users and testing that it works

We can now use Keycloak to add a user by going to the "Users" option in the left hand pane and choosing Add user. After populating and saving the new user form, we can use `ldapsearch` to check that the user has been created in `openldap`. To run the commands locally you'll need to forward the OpenLDAP port to your local machine with:

```bash
kubectl port-forward --namespace identity \
      $(kubectl get pods -n identity --selector='release=openldap' -o jsonpath='{.items[0].metadata.name}') \
      3890:389
```

We can then execute the `ldapsearch` command:

```
ldapsearch -x -H ldap://localhost:3890 -b dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk -D "cn=admin,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk" "+" -w password
```

Replacing `password` with the password we chose in `values-openldap.yml`.

Included in the output, we should see something like this:

```
# talkingquickly, People, ssotest.staging.talkingquickly.co.uk
dn: uid=talkingquickly1,ou=People,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk
uid: talkingquickly1
objectClass: inetOrgPerson
objectClass: organizationalPerson
mail: ben+1@hillsbede.co.uk
sn: Dixon
cn: Ben
```

Which shows that our user has been successfully created in OpenLDAP! Now onto groups. If we head over to the "Groups" page in Keycloak and add an "Administrators" group and then re-run our `ldapsearch` search command we'll see that nothing has changed, our group won't be there.

If however we then return to the Users page, select or newly created user and head to the Groups tab, we can then add our user to the Administrators group. Note that when viewing the "Users" tab, we'll sometimes see an empty list and have to click "View all users" to see everyone.

Having done this, if we re-run our `ldapsearch` command, we should see something like the following included in the output:

```
# Administrators, Group, k4stest4.talkingquickly.co.uk
dn: cn=Administrators,ou=Group,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk
objectClass: groupOfNames
cn: Administrators
member: cn=empty-membership-placeholder
member: uid=talkingquickly,ou=People,dc=k4stest4,dc=talkingquickly,dc=co,dc=uk
```

This shows that both our `Administrators` group has been created and that our user is a part of it.

If we then look at the entry for our user, assuming we have used the "+" option to enable the display of operational fields, we'll see that it includes a line something like:

```
memberOf: cn=Administrators,ou=Group,dc=ssotest,dc=staging,dc=talkingquickly,dc=co,dc=uk
```

Which means the `memberOf` functionality we configured earlier is working. This is required by some applications - including the harbour docker registry - to manage access based on groups.

This series of posts won't explore the use of `ldapsearch` much further, but it's a powerful tool and [this page](https://docs.oracle.com/cd/E19450-01/820-6169/ldapsearch-examples.html) is a handy cookbook of how it can be used. 

{% include kubernetes-sso/contents.html active="keycloak_openldap" %}