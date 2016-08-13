---
layout : post
title: "Setting up a VPS for Rails using Chef Zero & Knife Zero"
date: 2016-06-13 19:03:00
categories: rails devops
biofooter: false
bookfooter: true
---

Still one of the most visited posts on this blog is one from 2013 on how to setup a VPS for Rails using Chef & Knife Solo. A lot has changed in the Chef ecosystem since then, in particular the evolution of Chef Zero means that it's no-longer neccessary to use Knife Solo, we can use Zero to interact with remote servers from our local development machine using exactly the same tools and commands required for a large scale Chef Server install.

This blog post includes all commands needed to setup a VPS ready for hosting a Rails application and complete source code is available here:

<https://github.com/talkingquickly/rails-server-template/tree/develop>

The default stack we'll be setting up is:

* Ubuntu 16.04 LTS
* Ruby 2.3.1
* Postgres 9.5
* Redis 3.0

But it's easy to customise to fit your exact requirements.

## Steps

### Install ChefDK

ChefDK bundles together various gems required for a typical Chef
workflow. As a Ruby developer used to relying on directory specific
Gemfiles to ensure the correct gem versions, ChefDK may feel jarring.

ChefDK installs into its own directory - on OSX this is `/opt/chefdk` -
and maintains its own Ruby version and Gemset. The rationale for this is
that Chef is used by many non-ruby-developers - whose focus is primarily
devops - and so this allows them to setup a consistent Chef environment
without requiring an understanding of how to maintain a Ruby
environment.

For this to work, we are required to add `/opt/chefdk/bin` to our
`$PATH` before anything else Ruby related, e.g. before `.rbenv/shims`.
The primary concern from this is whether elements of the Chefdk install
will override the local development setup. In practice, as long as we
are using `bundle exec` in development, this issue should not occur.

To understand exactly what gems ChefDK is using, we can just inspect
`/opt/chefdk/Gemfile`.

Install ChefDK from <https://downloads.chef.io/chef-dk/> and ensure that
`PATH` is setup correctly.

Executing `which chef` should give the ChefDK path, e.g:
`/opt/chefdk/bin/chef`.

### Setup a server

Begin by creating a VPS, this has been tested on Linode & Digital Ocean. Provision the new server with Ubuntu 16.04 and boot it up.

If you're re-using an existing IP address (e.g. re-provisioning a server)you'll need to remove existing references to the server from `known_hosts` with `ssh-keygen -R SERVER_IP_OR_HOSTNAME`.

Now copy your SSH public key across to allow passwordless access:

```
ssh-copy-id root@SERVER_IP_OR_HOSTNAME
```

If you're on OSX and get an error that the command `ssh-copy-id` doesn't exist, you can install it using homebrew; `brew install ssh-copy-id`.

Once this is complete you can test that this works by sshing into the server as root:

```
ssh root@SERVERI_IP_OR_HOSTNAME
```

If everything has gone to plan, the login will complete without asking for a password.

### Get the example code

Now on your local machine, clone a copy of the base template.

```
git clone -b develop git@github.com:TalkingQuickly/rails-server-template.git
```

Here we're specifically cloning the develop branch which contains the updated, Chef Solo (not Knife Solo) based version.

Move into the newly created project folder `cd rails-server-template` and run `bundle install` to install the required gems.

In the same directory, run `berks vendor`. [Berkshelf](https://github.com/berkshelf/berkshelf) is essentially Bundler for Chef Cookbooks. In Chef terminology, Cookbooks are the individual modules which tell chef how to install a particular pice of software.

A look at an extract from our Berksfile (like a Gemfile):

```
...
#cookbook 'memcached', github: 'opscode-cookbooks/memcached'
cookbook 'memcached', '~> 3.0.0'

#cookbook 'mysql', github: 'opscode-cookbooks/mysql'
cookbook 'mysql', '~> 5.6.3'

#cookbook 'ntp', github: 'gmiranda23/ntp'
cookbook 'ntp', '~> 2.0.0'

#cookbook 'openssh', github: 'opscode-cookbooks/openssh'
cookbook 'openssh', '= 1.2.2'

cookbook 'postgresql', '~> 4.0.6'
...
```

Shows the similarity to working with bundler. We have cookbooks for system components such as `memcached` & `postgresql`. Also like bundler, we can define constraints as to which versions should be installed. When we install cookbooks, a `Berksfile.lock` is created which captures the entire dependancy tree so we can be certain we always end up with the same versions.

The use of `berks vendor` ensures we have the correct cookbooks available in the folder `berks-cookbooks` which is the source location specified in `knife.rb`. It's important to remember to re-run `berks vendor` after making changes to `Berksfile`.

### Configure the new node

In a terminal in the same folder, add the node to chef:

```
knife zero bootstrap SERVER_IP --ssh-user root --node-name NODE_NAME
```

Replacing `NODE_NAME` with a descriptive name of the node.

This will connect to the remote server, install chef and generate the local file `nodes/demo-server-2.json`. This is the file where all details about the node and what should be installed on it will be stored.

We can then use the `knife node run_list add` command to add recipes and roles which should be installed on the node.

A role is a way of grouping together recipes. For example a postgres role might include the cookbooks to install postgres along with cookbooks for related monitoring and maintenance tools.

To add the required roles for this server enter the following:

```
knife node run_list add NODE_NAME 'role[server],role[nginx-server],role[postgres-server],role[rails-app],role[redis-server]'
```

Replacing `NODE_NAME` with the node name used when running `knife zero bootstrap`.

You can check that the roles have been added using `knife node show NODE_NAME` which will return something like the following:

```
Environment: _default
FQDN:        ubuntu.members.linode.com
IP:          139.162.229.194
Run List:    role[server], role[nginx-server], role[postgres-server], role[rails-app], role[redis-server]
Roles:
Recipes:
Platform:    ubuntu 16.04
Tags:
```

You can also see that the roles have been added to the run list by viewing the JSON directly with `knife node edit NODE_NAME`:

```
{
  "name": "demo-server-3",
  "chef_environment": "_default",
  "normal": {
    "knife_zero": {
      "host": "139.162.229.194"
    },
    "tags": [

    ]
  },
  "policy_name": null,
  "policy_group": null,
  "run_list": [
    "role[server]",
    "role[nginx-server]",
    "role[postgres-server]",
    "role[rails-app]",
    "role[redis-server]"
  ]
}
```

####

@TODO Setup monit etc

### Setup users

The `users` cookbook handles creation of users. In this example we'll create a single user called `deploy`. To do this, begin by copying `data_bags/users/deploy.json.example` to data_bags/users/deploy.json`.

`deploy.json` will look like this:

```
{
  "id": "deploy",
  // generate this with: openssl passwd -1 "plaintextpassword"
  "password": "REPLACE",
  // the below should contain a list of ssh public keys which should
  // be able to login as deploy
  "ssh_keys": [
  ],
  "groups": [ "sysadmin"],
  "shell": "\/bin\/bash"
}
```

Generate an encrypted password with:

```
openssl passwd -1 "plaintextpassword"
```

and update the value of the `password` field. Then add your public key (usually `~/.ssh/id_rsa.pub`) to the `ssh_keys` array.

E.g:

```
"ssh_keys": [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCWdcYOVux0i4n85DQD4ImkAMsv9ZaL9kS+nA5FKbpjPN/pmccwuuFRBEItzeCuFbY6L+LXIZ/zUW3OXA//LlK2ZdkMF3S5hMPuUyMnQmaX1B+guAYBgG0Wxr/4Lg5sVUVbzVqo8gb+d5wRdSQf/VPn8RiAp81mwsyxyQJBesEyDL70He1+M1GsUJB6FkDHU3xlGpn1i0GdKudtu8Nzff2m+0oZXP/6xJ+dbqTKPs4XWDJzlRpXh1FWK4YJnBRCvR8iEQAVtfibt2FuUOi3FP+WyHVAYsjSXBHpa8HleETxniznzAtYZNtMwo183jSpSIsUmnONUWHq2Ms5e2wGlYd7 ben@ben-laptop"
  ],
```

Groups specifies the groups this user will be a member of. The `sudo` cookbook we use makes `sudo` available to all users in this group.

### Apply configuration to node

At this point, our local definition of the node has been updated, but no changes have been made to the actual server. To apply these changes, we use `knife zero converge`:

```
knife zero converge "name:NODE_NAME" --ssh-user root
```

Replacing `NODE_NAME` with the node name used when running `knife zero bootstrap`.

This will take a while, especially compiling Ruby. At the end of it, the node will be configured and ready for use as a Rails application host.

You sould be able to login via ssh with `ssh deploy@SERVER_IP`.

The aim is to now use Chef to make all changes to our node, after updating the node definition, we use:

```
knife zero converge "name:NODE_NAME" --ssh-user root
```

To apply the new changes. This makes deploying new, identical servers in the future, completely painless.

## Editing a node directly

To edit a nodes JSON directly, set to the path to your editor in knife.rb:

```
knife[:editor] = '/usr/local/bin/sublime'
```

In the above example, the editor is set to Sublime Text. To use vim you might set:

```
knife[:editor] = /usr/local/bin/vim
```

This will open the node definition JSON in the chosen editor. When saving and closing the editor, knife will parse the node defintiion to make sure it is valid before saving it.

## Useful Commands

`knife search node` will return all nodes

`knife search node "name:some_string"` will return a list of nodes with `some_string` in the name. `knife search` is hugely powerful and it's worth spending some time reading the [full documenation](https://docs.chef.io/knife_search.html).

`knife ssh "name:some_title" --ssh-user root hostname` will run the command `hostname` on any servers which  

## Useful Links

* <http://knife-zero.github.io/20_getting_started/>
