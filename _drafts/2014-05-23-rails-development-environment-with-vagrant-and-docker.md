---
layout : post
title: "Quick, Repeatable Rails Development Environments with Docker and Vagrant"
date: 2014-05-23 12:00:00
categories: devops
biofooter: false
bookfooter: true
---

# Why

Onboarding new developers to a Rails projects is still a far harder task than it should be. A big part of this is that setting up a development environment for an app or suite of apps, getting the correct ruby versions, database versions etc running locally, can in many cases take upwards of a day.

Vagrant has gone a long way to alleviating this but with Docker we can go one step further. Not only can we have a fully functional development environment (for both new and existing devs) up in a matter of a minutes, we can use almost the same containers we create in development to deploy to production. This goes even further to avoiding the classic "it worked in dev" problem.

In this tutorial I'll show how to use a combination of Vagrant and Docker to setup a fully functional Rails + Postgres + Redis development environment. In a follow up tutorial I'll show how to deploy the containers we create here to production.

# Vagrant Docker Provider

Vagrant 1.6 added native support for Docker as a provider, if we're developing on a linux machine, it will run Docker natively, otherwise it will transparently spin up a virtual machine to use as the Docker host.

In this tutorial I won't be using this provider. This is for two reasons:

* Later when designing a production docker configuration it's really important to understand the docker options and command line switches. The Vagrant provider abstracts this away to a more Ruby friendly but arguably no simpler DSL.
* By simply using Vagrant to setup an Ubuntu VM which matches our eventual production VM, we can be sure that the development configuration is as close to identical to the production configuration as possible.

Therefore here Vagrant is used to setup a standard Ubuntu VM and install Docker on it, everything else is done using standard Docker shell commands.

# The End Result

Our final system will require a simple

`vagrant up`

To setup a complete Docker based development environment. This development environment will consist of:

* A VirtualMachine running Ubuntu with Docker Installed
* Separate Docker containers for our Rails application, Postgres and Redis
* A shared folder linked to the Docker container so we can carry on editing Rails code as we do now
* A simple interface for running all the Rails commands we're used to (`rake db: migrate`, `rails c` etc) in our Docker environment

# Steps

## Pre-requisites

* Vagrant 1.6+ <https://www.vagrantup.com/downloads.html>
* Virtualbox 4.3.10+ <https://www.virtualbox.org/wiki/Downloads>

I've tested this tutorial on OSX and Ubuntu 12.04, it should work on other nix flavours, it almost certainly won't work on Windows.

## Dockerising the app

I'm starting with a standard Rails 4.1.0 application generated with `rails new`. The full source for this is available at @TODO Github Repo.

The app stores all secret values (api keys etc) in environment variables and uses the dotenv gem for loading these in development. This includes database usernames and passwords.

## Shared Folder

## Vagrant Up

Run `vagrant up` in the root of your project to start the new development environment.

You'll be asked for your sudo password, this is required for nfs shared folders.

You may run into the below error on mounting shared folders the first time you run `vagrant up`:

```
Failed to mount folders in Linux guest. This is usually because
the "vboxsf" file system is not available. Please verify that
the guest additions are properly installed in the guest and
can work properly. The command attempted was:

mount -t vboxsf -o uid=`id -u vagrant`,gid=`getent group vagrant | cut -d: -f3` vagrant /vagrant
mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g vagrant` vagrant /vagrant
```

Due to a bug in Virtualbox 4.3.10. You can resolve this by running:

```
vagrant ssh -c 'sudo ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions'
vagrant reload
```

This will then create an Ubuntu VirtualMachine, install docker on it and proceed to running the script defined in our `$setup` variable in the Vagrantfile.

This start by stopping and removing any running Docker contains. Just in case we're rebuilding an existing system:

``` bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

It then proceeds to build our Docker images from our Dockerfiles and tag them with user friendly names (`postgres`, `rails` and `redis` respectively):

``` bash
docker build -t postgres /app/docker/postgres
docker build -t rails /app
docker build -t redis /app/docker/redis/
```

Remember that `/app` on the Ubuntu virtual machine is shared back to the root of our Rails directory. So this is using the Dockerfiles which we can view and edit as we normally would any file in our rails project.

This process can take a long time. Something I've encountered on quite a few occassions with the OSX + Vagrant + Docker combination is that any sort of interruption in network connection can cause the build process to hang indefinitely.

If this happens, there's no harm in killing the vagrant provisioner (ctrl c twice), logging in with `vagrant ssh` and then running the commands manually.

Once the three images are built, the script starts containers from those images, the first two of these are quite simple:

``` bash
docker run -d --name postgres postgres:latest
docker run -d --name redis redis:latest
```

Breaking these down:

`-d` means run in the background

`--name xyz` gives the container the friendly name `xyz` which we can refer to it by when we want to later stop it or link it to another container

`xyz:latest` means start our container from the latest image tagged with `xyz`

I find it useful to think of images (from `docker build`) like class definitions and containers (from `docker run`) like instances. `docker run` creates an instance of the class.

The final `docker run` is a little more complicated:

``` bash
docker run -d -p 3000:3000 -v /app:/app --link postgres:postgres --link postgres:postgres --name rails rails:latest
```

In addition to the operations already discussed for the postgres and redis containers;


`-p 3000:3000` makes port 3000 from the container available as port 3000 on the host (the Virtualbox VM). Since we have Vagrant configured to forward port 3000 of the VM to our local machine 3000, we can therefore access this container port 3000 on our development machine as we would the normal Rails dev server

`--link postgres:db` established a link between the container we're starting (our rails app) and the postgres container we started previously. This is in the format `name:alias` and will make ports exposed by the Postgres container available to the rails container.

Further to this, it will also make the environment variables from the postgres container available to the rails container with the prefix `ALIAS`. When we expose a port in a container, a corresponding environment variable is created within that container.

The postgres container exposes port 5432 which leads to a corresponding environment variable `PORT_5432_TCP_ADDR` which will contain the IP address of the postgres container. We use this in our `database.yml` to automatically connect to the postgres container database irrespective of whether its IP has changed.

Therefore in our case, we use `ENV['DB_PORT_5432_TCP_ADDR']` to access this value in our `database.yml`.

It's worth reading <http://docs.docker.io/reference/run/#env-environment-variables> for more on the environment variables available.

### Why make this a shell script?

The few lines in our `$setup` script are everything we need to build and run our application on any machine with Docker installed. If we wanted to run this application in development on a Linode, we could just create a new node, install docker, upload our code and run this same script, and we'd have a working version of our application on this server.

Later in this series of tutorials I'll demonstrate how the commands in this script can be adapated to form the basis of a production deployment with Docker. Getting familiar with the commands as part of the day to day development workflow means that working with the production stack is much less of a learning curve for any developer on the team.

# Interacting with the Rails app

This part could equally be described as "Where did `rails c` go?!"

# Future Extensions (Planned Tutorials)

* Setting up a private index so we can build our docker images centrally and then just pull them when we start a new development environment rather than rebuilding each time
* Building production images
* Deploying production images with Capistrano + a Private Index
