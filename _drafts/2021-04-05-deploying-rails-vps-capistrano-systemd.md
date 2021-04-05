---
layout : post
title: Setting up Ubuntu 20.04 for Rails app Deployment
date: 2021-04-04 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/setting-up-ubuntu-20-04-focal-fossa-vps-for-rails-app-deployment'
---

Deploying Rails to a VPS with Capistrano remains one of the simplest and most reliable methods for getting a Rails app up-and running. With the likes of Hetzner Cloud, Digital Ocean and Linode providing inexpensive, reliable virtual machines, Rails app serving substantial amounts of traffic can be hosted with minimal cost and complexity.

We'll first use Chef to provision a VPS including securing and hardening the server, installing the correct Ruby version(s) and setting up Postgres and Redis. We'll then use Capistrano to deploy our Rails app, including appropriate systemd units to ensure our services are started automatically on boot .

This tutorial is in two parts:

- **[Setting up a VPS for Rails app Deployment](/setting-up-ubuntu-20-04-focal-fossa-vps-for-rails-app-deployment)**
- [Deploying Rails to Ubuntu 20.04 with Capistrano](/deploying-rails-to-a-vps-with-capistrano-and-systemd)

<!--more-->

Note that this post is intended to be a tutorial rather than a reference, so the focus will be on the steps that need to be completed rather than exploring the why.

## The Stack

- Ubuntu 20.04 Focal Fossa (Current [LTS](https://ubuntu.com/about/release-cycle))
- PostgreSQL 13 (Other versions selectable)
- Ruby 3.0 (Other versions selectable)
- Redis, Memcached (optional)

## Chef

Rather than executing lots of commands by hand, we'll use Chef to automate the setup of the server. This means that when we need to provision another, identical server, we need just one command rather than having to try and remember all the shell commands. Chef is similar to tools such as Puppet or Ansible with the advantage for our use case that it's both written in and leverages for configuration, Ruby.

## Installing Chef

On OSX we can Install Chef by executing the following in a terminal:

```
curl https://packages.chef.io/files/stable/chef-workstation/21.2.303/mac_os_x/11.0/chef-workstation-21.2.303-1.x86_64.dmg --output /tmp/chef-workstation.dmg
hdiutil attach /tmp/chef-workstation.dmg
```

Then visiting the newly mounted "Chef Workstation" volume in finder, double clicking on the `.pkg` and following the installation prompts.

On Ubuntu / Debian based systems, Chef Workstation can be installed with:

```
curl https://packages.chef.io/files/stable/chef-workstation/21.2.303/debian/10/chef-workstation_21.2.303-1_amd64.deb --output /tmp/chef-workstation.deb
sudo dpkg -i /tmp/chef-workstation.deb
```

Alternatively the latest version can be downloaded from `https://downloads.chef.io/products/workstation`, this tutorial has been tested with version `21.2.303` but should be broadly compatible with `21.x` releases.

Once this step is complete, executing `chef` in a local terminal should give help output from Chef, rather than a command not found error.

## Installing Knife

Knife is the CLI tool that we will use to interact with Chef, we can install it by executing:

```
chef gem install knife-zero
```

Note this command should not be executed from within a folder with a `Gemfile` as this may lead to hard to debug `bundler not found` errors.

## Creating a VPS

We should now head to our favourite VPS provider. My current preference is Hetzner Cloud with Digital Ocean and Linode in close second. 

For a non-trivial Rails application we probably don't want to go below 1GB of RAM, likewise since we're going to be running both our application and database servers on a single machine, we probably want at least 2 cores. 3 Cores and 4GB RAM is generally a comfortable starting point which is equivalent to Hetzners CPX21.

We can now choose Ubuntu 20.04 as the system image, boot it up and make a note of the IP address.

## Setup key based SSH

If we configured key based authentication as part of the VPS creation process, this step can be skipped.

If however when we execute `ssh USERNAME@SERVER_IP` (where `USERNAME` is the username our VPS provider gave us to use and `SERVER_IP` is our servers IP address) we are required to enter a password then we need to setup key based auth.

Key based authentication allows us to authenticate using our local public / private key pair rather than a password. This is important because as part of the server hardening process, we will later disable password based authentication completely.

We can copy our public key to the server with:

```
ssh-copy-id USERNAME@SERVER_IP
```

This will prompt us for our password one more time and then add our public key to the list of allowed keys in the remote servers `~/.ssh/authorized_keys`.

We should then be able to execute `ssh USERNAME@SERVER_IP` to login to our remote server without being required to enter a password. Note if we're still being required to enter the passphrase for our local SSH key, we can avoid this by executing `ssh-add` to temporarily store credentials in the local ssh agent.

## Getting the sample code

Next we need to clone the sample Chef [repository](https://github.com/TalkingQuickly/rails-server-template):

```
git clone git@github.com:TalkingQuickly/rails-server-template.git
```

And then enter the sample code folder with `cd rails-server-template`

## Preparing the node

We can now prepare the server (node in Chef terminology) for provisioning with the following command:

```
knife zero bootstrap SERVER_IP --connection-user SSH_USER --node-name NODE_NAME
```

replacing `SERVER_IP` with our servers IP address, `SSH_USER` with the same username we used when setting up key based login above and `NODE_NAME` with a friendly name for the node, e.g. `rails_app_server`. 

This will connect to the remote server, install Chef and generate the local file `nodes/NODE_NAME.json`. This is the file where all details about the node and what should be installed on it will be stored.

If we've never connected to the node via SSH before, we may be asked to confirm the servers fingerprint by entering `Y` and pressing enter.

## Configuring the Node

The above step created a JSON file which stores information about the node in `nodes/NODE_NAME.json` but we should not edit that file directly.

Instead we can use the following command to edit the node definition:

```
knife node edit NODE_NAME
```

Replacing `NODE_NAME` with the name used above. This will open a JSON file in the editor defined in `knife.rb`, by default this will be `vim`, but we can change it to any editor we want by updating the `knife[:editor]` variable in `knife.rb`, e.g. `code --wait` for VSCode or `subl -n -w` for sublime text.

We can then update our configuration 

```json
{
  "name": "NODE_NAME",
  "chef_environment": "_default",
  "normal": {
    "postgresql": {
      "version" : "POSTGRES_VERSION",
      "password": {
        "postgres": "SOME_RANDOM_PASSSWORD"
      }
    },
    "rbenv": {
      "rubies": [
        "RUBY_VERSION"
      ],
      "global": "RUBY_VERSION",
      "gems": {
        "RUBY_VERSION": [
          {
            "name": "bundler"
          }
        ]
      }
    },
    "knife_zero": {
      "host": "SERVER_IP"
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
    "role[redis-server]",
    "role[memcached-server]"
  ]
}
```

Replacing:

- `NODE_NAME` with the node name we've been using
- `SERVER_IP` with the server ip address 
- `SOME_RANDOM_PASSWORD` with the password we want to be set for the postgres master user
- `RUBY_VERSION` in three places with the Ruby version we need for our Rails application
- `POSTGRES_VERSION` with the Postgres version we want, if in doubt 13 is the current stable release and should work for most setups

We can then save and close the node definition.

## Setting up users 

Our final step is to create a non-root user which will later be used by Capistrano to deploy our application.

To do this we first generate a password for the user by executing the following locally:

```
openssl passwd -1 "SOME_RANDOM_PASSWORD"
```

And making a note of the output.

We then create a Chef data bag called `users` with an entry `deploy` using the following command:

```
knife data_bag create users deploy
```

This will create the file `data_bags/users/deploy.json` which we should then open and replace the contents with:

```json
{
  "id": "deploy",
  "password": "ENCRYPTED_PASSWORD",
  "ssh_keys": [
    "PUBLIC_KEY"
  ],
  "groups": [
    "sysadmin"
  ],
  "shell": "/bin/bash"
}
```

Replacing `ENCRYPTED_PASSWORD` with the output of the `openssl` command above and `PUBLIC_KEY` with your public key, generally the contents of your local `~/.ssh/id_rsa.pub`.

## Applying configuration to the node

We're now ready to apply our configuration to the node with the following command:

```
knife zero converge "name:NODE_NAME" --ssh-user `SSH_USER`.
```

Replacing `NODE_NAME` with the name we used above and `SSH_USER` with the user we setup key based authentication for (often `root`).

The first time we run this, it will take a while as it has to install all of the servers components including compiling our Ruby version.

If we make changes to our configuration, for example by editing the node definition and overriding more values from roles, we simply run the above command again to have the changes applied.

## What we've set up

We now have a hardened server, ready to deploy a Rails application for. We can create an unlimited number of identical servers simply by following the above process.

The [book](https://leanpub.com/deploying_rails_applications) provides more detail on exactly what's going on behind the scenes and how to customise it but at a high level we have:

- Installed a firewall which limits access to ports 22 (SSH), 80 (HTTP) and 443 (HTTPS)
- Disabled password based SSH login and installed fail2ban to block suspicious logins
- Enabled automatic OS and core package updates 
- Installed Nginx, Postgres, Redis and Memcached

## Next

Assuming everything has gone well, we can now continue to [deploying our Rails application with Capistrano](deploying-rails-to-a-vps-with-capistrano-and-systemd)

If you've run into any issues, please feel free to ping me on Twitter where I'm [@talkingquickly](https://www.twitter.com/talkingquickly) or open an issue on the [sample code repository](https://github.com/TalkingQuickly/rails-server-template) and I'll do my best to help.