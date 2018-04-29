---
layout : post
title: "A Rails Development Environment with Docker and Vagrant"
date: 2014-06-03 08:00:00
categories: devops
biofooter: false
bookfooter: false
docker_book_footer: true
---

Onboarding new developers to a Rails projects is still a far harder task than it should be. A big part of this is that setting up a development environment for an app or suite of apps, getting the correct ruby versions, database versions etc running locally, can in many cases take upwards of a day. A combination of Vagrant and Docker can make this a thing of the past.

<!--more-->

Update April 2018 - Docker has evolved a lot since this post, [an updated approach is documented here](/2018/03/rails-development-environment-with-docker-compose/)

Vagrant alone has already gone a long way to alleviating this but with Docker we can go one step further. Not only can we have a fully functional development environment (for both new and existing devs) up in a matter of a minutes, we can use almost the same containers we create in development to deploy to production. This goes even further to avoiding the classic "it worked in dev" problem.

In this tutorial, I'll show you how to use a combination of Vagrant and Docker to setup a fully functional Rails + Postgres + Redis development environment. In a follow up tutorial I'll demonstrate how to deploy the containers we create here to production.

# Vagrant Docker Provider

Vagrant 1.6 added native support for Docker as a provider. If you're developing on a Linux machine, it will run Docker natively, otherwise it will transparently spin up a virtual machine to use as the Docker host.

I won't be using the providers DSL in this tutorial. This is for two reasons:

* Later, when designing a production Docker configuration, it's really important to understand the Docker options and command line switches. The Vagrant provider abstracts this into a DSL which, while Ruby friendly, is no simpler than Docker's own command line switches
* By simply using Vagrant to setup an Ubuntu VM which matches our eventual production VM, we can be sure that the development configuration is as close to identical to the production configuration as possible

Here, therefore, Vagrant is used to setup a standard Ubuntu VM and install Docker, while everything else is done using standard Docker shell commands.

# The End Result

The final system will require a simple

`vagrant up`

to setup a complete Docker-based development environment. This development environment will consist of:

* A VirtualMachine running Ubuntu with Docker installed
* Separate Docker containers for the Rails application, PostgreSQL and Redis
* A shared folder linked to the Docker container so you can carry on editing Rails code on your development machine as you do now, and see those changes instantly reflected on `http://localhost:3000`
* A simple interface for running all the normal Rails commands (`rake db: migrate`, `rails c` etc) in the Docker environment

# Steps

## Pre-requisites

* Vagrant 1.6+ <https://www.vagrantup.com/downloads.html>
* Virtualbox 4.3.10+ <https://www.virtualbox.org/wiki/Downloads>

I'm assuming a basic understanding of what Docker is. If this is the first you've heard of Docker, they have a great interactive tutorial of the basics on their website <https://www.docker.io/gettingstarted/>.

I've tested this tutorial on OSX and Ubuntu 12.04. It should work on other nix flavours, but it may require more tweaking for use on Windows.

## Dockerising the App

### Configuration

I started with a standard Rails 4.1.0 application generated with `rails new` then added a single model + scaffolding and converted it to use PostgreSQL. The final source for this is available at <https://github.com/TalkingQuickly/docker_rails_dev_env_example>

The Rails app stores all secret values (API keys, anything in `secrets.yml` etc) in environment variables and uses the dotenv gem for loading these in development. Note that in the example application, the `.env` file is included in version control, for any real application, particularly one in a public repository, this should be added to `.gitignore`.

The PostgreSQL access details will be inferred directly from the database container. For more on this, see the section "Environment Variables in Linked Containers" later in this tutorial. In the example application, `database.yml` looks like this:

``` yaml
default: &default
  adapter: postgresql
  pool: 5
  timeout: 5000

development:
  <<: *default
  encoding: unicode
  database: dpa_development
  pool: 5
  username: <%= ENV['DB_ENV_POSTGRESQL_USER'] %>
  password: <%= ENV['DB_ENV_POSTGRESQL_PASS'] %>
  host: <%= ENV['DB_PORT_5432_TCP_ADDR'] %>

test:
  <<: *default
  encoding: unicode
  database: dpa_test
  pool: 5
  username: <%= ENV['DB_ENV_POSTGRESQL_USER'] %>
  password: <%= ENV['DB_ENV_POSTGRESQL_PASS'] %>
  host: <%= ENV['DB_PORT_5432_TCP_ADDR'] %>
```

### Dockerfiles and Scripts

The example configuration requires three Dockerfiles: one for Rails, one for Redis and one for PostgreSQL. The Rails Dockerfile is stored in the root of the Rails project, the others are stored in sub-folders of the `docker/` directory.

Templates for all of these files are available here: <https://github.com/TalkingQuickly/docker_rails_dev_env>

To begin with, copy all of the files and folders from the above repository into the root of your Rails project. If you're adding this to an existing project, the docker specific files and folders you'll be creating are:

```bash
├── Dockerfile
├── Vagrantfile
├── d
└── docker/
    ├── postgres/
    ├── rails/
    ├── redis/
    └── scripts/
```

## Setting Up Vagrant

If you're completely new to Vagrant it's worth briefly going through their getting started tutorial <http://docs.vagrantup.com/v2/getting-started/> at least through to the end of the provisioning section.

### The Vagrantfile

The Vagrantfile should be stored in the root of your Rails project and look like this:

```ruby
# Commands required to setup working docker environment, link
# containers etc.
$setup = <<SCRIPT
# Stop and remove any existing containers
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

# Build containers from Dockerfiles
docker build -t postgres /app/docker/postgres
docker build -t rails /app
docker build -t redis /app/docker/redis/

# Run and link the containers
docker run -d --name postgres -e POSTGRESQL_USER=docker -e POSTGRESQL_PASS=docker postgres:latest
docker run -d --name redis redis:latest
docker run -d -p 3000:3000 -v /app:/app --link redis:redis --link postgres:db --name rails rails:latest

SCRIPT

# Commands required to ensure correct docker containers
# are started when the vm is rebooted.
$start = <<SCRIPT
docker start postgres
docker start redis
docker start rails
SCRIPT

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|

  # Setup resource requirements
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # need a private network for NFS shares to work
  config.vm.network "private_network", ip: "192.168.50.4"

  # Rails Server Port Forwarding
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # Ubuntu
  config.vm.box = "precise64"

  # Install latest docker
  config.vm.provision "docker"

  # Must use NFS for this otherwise rails
  # performance will be awful
  config.vm.synced_folder ".", "/app", type: "nfs"

  # Setup the containers when the VM is first
  # created
  config.vm.provision "shell", inline: $setup

  # Make sure the correct containers are running
  # every time we start the VM.
  config.vm.provision "shell", run: "always", inline: $start
end
```

### The Vagrant Shared Folder

We want our Docker container to use the Rails app directly from our local filesystem so we can make changes on our development machine as we normally would and have these changes instantly reflected on our development server.

Since we're using Vagrant, first we have to share this folder from the local filesystem to the Vagrant virtual machine, which in turn shares this to the Docker container. If this is done using the default Virtualbox shared folders, then Disk IO and, consequently, Rails performance will be terrible. In my tests, it took something like 20 - 30 seconds to render a simple view.

This can be resolved by using NFS shares, which are much faster but require some additional setup and entering the sudo password when starting the virtual machine. The following entry in your `Vagrantfile` ensures NFS is used:

```ruby
config.vm.synced_folder ".", "/app", type: "nfs"
```

For more on NFS shares and what's required to set them up, see <https://docs.vagrantup.com/v2/synced-folders/nfs.html>. On OSX it should work out of the box, on Linux you may need to install `nfsd`.

## Vagrant Up

Run `vagrant up` in the root of your project to start the new development environment.

You'll be asked for your sudo password, this is required for NFS shared folders.

Due to a bug in Virtualbox 4.3.10, you may run into the below error on mounting shared folders the first time you run `vagrant up`:

```
Failed to mount folders in Linux guest. This is usually because
the "vboxsf" file system is not available. Please verify that
the guest additions are properly installed in the guest and
can work properly. The command attempted was:

mount -t vboxsf -o uid=`id -u vagrant`,gid=`getent group vagrant | cut -d: -f3` vagrant /vagrant
mount -t vboxsf -o uid=`id -u vagrant`,gid=`id -g vagrant` vagrant /vagrant
```

You can resolve this by running:

```
vagrant ssh -c 'sudo ln -s /opt/VBoxGuestAdditions-4.3.10/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions'
vagrant reload
```

UPDATE (11/6/2014): This is resolved in Vagrant 1.6.3 so it's definitely worth upgrading.

This will create an Ubuntu Virtual Machine, install Docker on it and proceed to running the script defined in your `$setup` variable in the Vagrantfile. In this example, for completeness, we build all of the containers from scratch rather than pulling them from an Index so the first time you run this, it will take a while.

### The Setup Script

The first time we start the VM, this line in the Vagrantfile:

```ruby
config.vm.provision "shell", inline: $setup
```

Causes the shell script defined in the `$setup` variable at the top of the file to be executed.

This starts by stopping and removing any running Docker containers, just in case we're rebuilding an existing system:

``` bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

It then proceeds to build our Docker images from the Dockerfiles and tag them with user friendly names (`postgres`, `rails` and `redis` respectively):

``` bash
docker build -t postgres /app/docker/postgres
docker build -t rails /app
docker build -t redis /app/docker/redis/
```

Remember that `/app` on the Ubuntu virtual machine is shared back to the root of your Rails directory, so this is using the Dockerfiles that can be viewed and edited as we normally would any file in a Rails project.

This process can take a long time. Something I've encountered on quite a few occasions with the OSX + Vagrant + Docker combination is that any sort of interruption in network connection can cause the build process to hang indefinitely.

If this happens, there's no harm in killing the Vagrant provisioner (`ctrl` `c` twice), logging in with `vagrant ssh` and then running the commands manually.

Once the three images are built, the script starts containers from those images. The first two of these are quite simple:

``` bash
docker run -d --name postgres -e POSTGRESQL_USER=docker -e POSTGRESQL_PASS=docker postgres:latest
docker run -d --name redis redis:latest
```

Breaking these down:

`-d` means run in the background

`--name xyz` gives the container the friendly name `xyz` which we can use to refer to it later when we want to stop it or link it to another container

`-e` allows us to set environment variables in the container we're creating. In this case, we're setting the PostgreSQL username and password. See the section "Environment Variables in Linked Containers" for how we later access these credentials from our Rails app without hard-coding them.

`xyz:latest` means start the container from the latest image tagged with `xyz`

I find it useful to think of a Docker image like a class definition. We use a Dockerfile (basically a list of shell commands) and the `docker build` command to create an image.

We then use the `docker run` command to create a container from that image. The container is like an instance of a class. We can create multiple containers (a new one every time we use `docker run`) from a single image. Each container (instance) is completely isolated from every other container, even if they are created from the same image.

That said, we can also do things like create images based on the state of a container, so the analogy shouldn't be extended much further(!)

The final `docker run` is a little more complicated:

``` bash
docker run -d -p 3000:3000 -v /app:/app --link redis:redis --link postgres:db --name rails rails:latest
```

In addition to the operations already discussed for the Postgres and Redis containers:

`-p 3000:3000` makes port 3000 from the container available as port 3000 on the host (the Virtualbox VM). Since we have Vagrant configured to forward port 3000 of the VM to your local machine 3000, you can access this container on port 3000 on your development machine as you would the normal Rails dev server (e.g. `http://localhost:3000`).

`--link postgres:db` establishes a link between the container you're starting (your Rails app) and the Postgres container you started previously. This is in the format `name:alias` and will make ports exposed by the Postgres container available to the Rails container.

### Environment Variables in Linked Containers

Linking will also make the environment variables from the Postgres container available to the Rails container with the prefix `ALIAS`. When you expose a port in a container, a corresponding environment variable is created within that container.

The Postgres container exposes port 5432 which leads to a corresponding environment variable `PORT_5432_TCP_ADDR` which will contain the IP address of the Postgres container. We use this in our `database.yml` to automatically connect to the Postgres container database, irrespective of whether its IP has changed.

Since we used `db` as our alias for this container, in our Rails container, we will therefore have an environment variable `DB_PORT_5432_TCP_ADDR` available which contains the IP of this container.

Therefore, we use `ENV['DB_PORT_5432_TCP_ADDR']` to access this value in `database.yml`.

The command to build the Postgres image includes:

```bash
-e POSTGRESQL_USER=docker -e POSTGRESQL_PASS=docker
```

which sets environment variables in the docker container with the database access credentials. These will be available in your Rails container as `DB_ENV_POSTGRESQL_USER` and `DB_ENV_POSTGRESQL_PASS` respectively (as seen in `database.yml`). Notice the format `ALIAS_ENV_VARIABLE_NAME`.

It's worth reading <http://docs.docker.io/reference/run/#env-environment-variables> for more on the environment variables available. It's also interesting to inspect the contents of `ENV` from a Rails console once the full environment is up and running.

### Why make this a shell script?

The few lines in our `$setup` script are everything we need to build and run our application on any machine with Docker installed. If you wanted to run this application in development on a Linode, you could just create a new node, install Docker, upload your code and run this same script, and you'd have a working development version of your application on this server.

Later in this series of tutorials I'll demonstrate how the commands in this script can be adapted to form the basis of a production deployment with Docker. Getting familiar with the commands as part of the day-to-day development workflow means that working with the production stack is much less of a learning curve for any developer on the team.

## Interacting with the Rails Application

Once the above process is complete, the Rails application should be available in a browser on your local development machine at `http://localhost:3000`. However, the first thing you're likely to see is an error that the database does not exist.

Normally at this stage we could simply use `bundle exec rake db:create db:migrate` to create the database and apply any migrations. Now that we're running our application in a Docker container, the process is slightly different.

In this configuration, each Docker container runs a single process. In the `$setup` script, the container for the Rails server is started with:

```bash
docker run -d -p 3000:3000 -v /app:/app --link redis:redis --link postgres:db --name rails rails:latest
```

The Docker daemon expects the second, non-parametrised argument to the `run` command to be the command to be executed within the container. Since we don't specify a command to be run within the container, the default command from the `Dockerfile` is run. This is specified in `/Dockerfile` with:

```bash
CMD ["/start-server.sh"]
```

Which makes the default action of the container to run the script in `/start-server.sh`:

```bash
#!/bin/bash
cd /app
bundle install
bundle exec unicorn -p 3000
```

This is equivalent to starting the container with:

```bash
docker run -d -p 3000:3000 -v /app:/app --link redis:redis --link postgres:db --name rails rails:latest bash -c "cd /app && bundle install && bundle exec unicorn -p 3000"
```

To run other commands in the container based on your Rails image, we can construct equivalent `docker run` commands and run them from within the Vagrant virtual machine (`vagrant ssh`). So to run `bundle exec rake db:create db:migrate` we could ssh into the Vagrant host and then use:

```bash
docker run -i -t -v /app:/app --link redis:redis --link postgres:db  --rm rails:latest bash -c "cd /app && bundle exec rake db:create db:migrate"
```

This starts a new container based on the Rails image and runs `db:create` and `db:migrate` with it. Notice the additional command line flags:

`-i -t` attaches the console to Standard In, Out and Error, then assigns a TTY so that we can interact with it. This is required when running interactive commands such as `bundle exec rails console`

`--rm` means that the container will be removed once execution completes.

Doing this every time is cumbersome, so the example configuration includes some simple shell scripts to automate this. The first part of this is the file `d` in the root of the Rails project. This automates sshing into the vagrant host and executing a single command, for example:

```bash
./d rc
```

invokes:

```bash
vagrant ssh -c "sh /app/docker/scripts/rc.sh"
```

Which is the same as sshing into the Vagrant host and executing `./app/docker/scripts/rc.sh`.

The script `/app/docker/scripts/rc.sh` contains a `docker run` command:

```bash
docker run -i -t -v /app:/app --link redis:redis --link postgres:db  --rm rails:latest bash -c "cd /app && bundle exec rails c"
```

Which has the effect of starting a Rails console in a new container.

You can run `./d` without any arguments to see which functions it provides shortcuts for. It also provides a generic `cmd` option:

```bash
./d cmd "bundle exec any_command"`
```

which allows arbitrary commands to be executed within the `/app` directory of a new Rails container. So we could, for example, execute:

```bash
./d cmd "bundle exec rake db:create db:migrate"
```

to create and migrate the database.

These don't have to be Rails commands, we could equally execute:

```bash
./d cmd "ls"
```

to get the directory listing of `/app`.

When interacting with the Rails application like this, it's important to remember that every command is executed in a new container and hence is completely isolated from any other command. Therefore any local resources created in one container are not normally available to any other container and will be lost when the command terminates and the container is discarded.

The exception in the case of this development configuration is the `/app/` directory, which is a shared folder and, therefore, any files created here will persist and be available to all containers. It should be kept in mind that, in a production configuration, there should be no such shared local storage and so this should not be relied upon for any sort of shared state. It's worth reading the Twelve Factor App guide for more on how sharing state should be approached <http://12factor.net/>.

## Bootstrapping the Database

Generally, when setting up a development environment, I want the development database populated with a recent dump of data from production. Sometimes this is a direct dump and sometimes it's a segment of the production data, or modified version of production with sensitive information removed. Either way, this normally takes the form of a .sql file (assuming MySQL or Postgres). It's useful to be able to quickly restore future dumps to the development database.

The `./d` convenience script provides a simple interface to this:

```bash
./d restore-db
```

This will:

* Drop, create and migrate the development database
* Look for a zip file called `db/current.sql.zip` in the Rails directory structure
* Unzip it within a new Docker container
* Import the file `current.sql` from the unzipped files to the development database using the `psql` utility.

Note the naming, it expects a zip archive at `db/current.sql.zip` which contains a single file called `current.sql`.

## Upcoming Tutorials

I'll be releasing further tutorials over the next few months on the topics below, you can follow me on twitter [@talkingquickly](http://www.twitter.com/talkingquickly) for updates. If you run into any issues with this tutorial, feel free to tweet or email me, ben@talkingquickly.co.uk.

* Setting up a private index so you can build your Docker images centrally and then just pull them when you start a new development environment, rather than rebuilding each time
* Building production images
* Automating building production images and pushing them to a private index
* Deploying production images with Capistrano + a Private Index
