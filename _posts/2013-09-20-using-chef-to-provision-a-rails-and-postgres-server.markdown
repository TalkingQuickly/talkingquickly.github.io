---
layout : post
title: "Using Chef to provision a Rails and Postgres server"
date: 2013-09-20 11:34:00
categories: rails devops
biofooter: false
bookfooter: true
---
This is a brief overview of how to use chef to automate the provisioning of a server for a Ruby on Rails application. Sample code is provided as a starting point at <https://github.com/TalkingQuickly/rails-server-template>

<!--more-->

## Our Requirements

* Once setup, provisioning a new server should require just a few simple commands
* It should be platform agnostic, any VPS provider will do
* It should be easy to understand what’s happening, no “magic”
* Once setup the server should take care of itself as much as possible and alert us if anything goes wrong

## Our stack

* Ruby 1.9.3+ (this can be selected)
* Postgres
* Redis
* Chef

Chef is a tool which allows us to define the commands to be run on a server using a ruby DSL. Commands are grouped into “recipes” which generally correspond to a piece of software to be installed. One or more recipes can be grouped into a cookbook, so for example a postgres cookbook could contain a recipe for a postgres client and another for a postgres server.

Data which varies from install to install – such as usernames, ports and paths – is defined in JSON files. Recipes and data can be grouped together in “roles,” for example a postgres-server role might combine a postgres recipe with a particular monitoring tool recipe and configuration.

Chef is capable of running on a central server and managing the propagation of recipes to multiple nodes. This is too complicated for the purposes of this single machine setup so we’ll be using the chef-solo gem (<http://docs.opscode.com/chef_solo.html>) along with the knife gem (<http://docs.opscode.com/knife.html>)  to allow us to use cookbooks on the VPS directly from our workstation.

Finally we’ll be using berkshelf (<http://berkshelf.com/>) to manage our cookbooks and the dependencies between them, this can be thought of like bundler for chef cookbooks.

## Steps

1) Install Tools

``` bash
git clone git@github.com:TalkingQuickly/rails-server-template.git
```

The repository includes a `Gemfile` so simply run `bundle install` to install the required tools.

2) Define the server

First we need to define users, inside data\_bags/users copy the file deploy.json.example to deploy.json.

Generate a password for your deploy user with the command:

``` bash
openssl passwd -1 "plaintextpassword"
```

And update deploy.json accordingly. Also copy your SSH public key (cat ~/.ssh/id_rsa.pub) into the public keys array.

Finally you need to download all the cookbooks required for the individual server components:

``` bash
mkdir cookbooks
bundle exec berks install --path ./cookbooks
```

3) Setup a VPS

This setup is designed to work on any Ubuntu 12.04 VPS, it has been tested on Linode, Rackspace and Digital Ocean. For initial experimentation I’d recommend Digital Ocean or for critical applications where support is key, Linode.

Once your VPS is up and running, copy your SSH key across:

``` bash
ssh-copy-id root@yourserverip
```

4) Provision the server

Begin by installing chef on the remote machine:

``` bash
bundle exec knife solo prepare root@yourserverip
```

This will generate a file nodes/yourserverip.json. Copy the contents of rails\_postgres\_redis to this file and change the username and password for monit.

Use the same command as before (openssl passwd -1 “plaintextpassword”) to generate a password for postgresql and add this to the node definition file.

Now run:

``` bash
bundle exec knife solo cook root@yourserverip
```

Sit back, relax and enjoy. This process takes quite a while and once it’s completed, you’ve got a server ready for a Rails + Postgres + Redis app.

## Next Steps

You can read more about using Capistrano to deploy to VPS configured
with this method in [this post](/2013/11/deploying-multiple-rails-apps-to-a-single-vps)

Any queries or corrections you can find me on twitter;
[@talkingquickly](http://www.twitter.com/talkingquickly)

{% include also-read-rails.html %}
