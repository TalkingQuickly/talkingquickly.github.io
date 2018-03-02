---
layout : post
title: "Deploying Multiple Rails Applications to a Single VPS"
date: 2013-11-06 19:03:00
categories: rails devops
biofooter: false
bookfooter: true
---

When I announced the release of my book, [deploying rails applications](https://leanpub.com/deploying_rails_applications), one of the most common questions I got was whether it covered deploying multiple apps to a single VPS. It does and since there was so much interest, I've put together a brief tutorial and sample code on the basics.

<!--more-->

## Pre-requisites

I'm assuming you have a VPS setup with Nginx and your database server of choice. You'll need to have SSH access to this server and I'll assume you've already copied your public key across.

This tutorial has been tested with my example configuration, full instructions for setting up a VPS with this configuration is available here: <http://www.talkingquickly.co.uk/2013/09/using-chef-to-provision-a-rails-and-postgres-server/>

## Which version of Capistrano to use

Capistrano 3 is currently available however in this tutorial I'll be using Capistrano 2. The focus of this tutorial is primarily on the configuration required for running multiple applications on a single VPS rather than how to use Capistrano so it should still be relevant even if you prefer Capistrano 3.

I'm generally quite conservative on which tools to use for provisioning and deployment, as version 3 gains more traction and becomes better tested, I'll look at doing an updated version.

## Setting up

Begin by adding the Capistrano Gem to your gemfile in the development group:

``` ruby
group :development do
  gem 'capistrano', '~>2.15'
end
```

You'll also need to the Unicorn Gem:

``` ruby
group :production do
  gem 'unicorn'
end
```


And then run `bundle install`.

Once this completes, in the root of your project, run:

``` bash
capify .
```


This will create two files:

```
./Capfile
./config/deploy.rb
```

In the simplest possible configuration, your deployment target can be defined directly in `deploy.rb` and deployments can be initiated by a simple `cap deploy`. We'll take a slightly more modular approach which allows for the easy addition of multiple environments - for example testing and staging - at a later date.

Update deploy.rb to contain the following:

``` ruby
require "bundler/capistrano"

# enable multistage
require 'capistrano/ext/multistage'

# define our stages, remember that if it isn't defined here
# it won't be picked up.
set :stages, %w(production)
set :default_stage, "production"

# simple method to create a file from an erb template. Used
# to generate dynamic configuration files.
def template(from, to)
    erb = File.read(from)
    put ERB.new(erb).result(binding), to
end
```

This enables Capistrano Multistage and defines the different stages we're going to want to deploy to, to begin with just a production environment. It then defines a simple helper method for taking an erb template and generating a file.

Next create a new directory `deploy` within the config directory.

## Defining a production stage

A very simple production capistrano staging template is available at:

<https://github.com/TalkingQuickly/capistrano_stage>

Or you can download a zip here: <https://github.com/TalkingQuickly/capistrano_stage/archive/master.zip>

Copy these files into `config/deploy` and open production.rb.

This file is named to correspond with the stage name defined in deploy.rb. Later when we run `cap production deploy`, capistrano will look for the file config/deploy/production.rb and deploy to the stage defined there.

The file is commented in detail so we'll only cover the key elements here.

To begin with the following variables will need to be set for your application:

``` ruby
# this should be the the server address or ip you'll be deploying to
server "your-server-address-or-ip", :web, :app, :db, primary: true

# set RAILS_ENV
set :rails_env, :production

# the name of your application
set :application_name, "your_app_name"

# the domain you'll be deploying your application to
set :application_domain, "domain.example.com"

...

# the details of the source control where the codebase should be
# retrieved from from
set :scm, "git"
set :repository, "your_git_repo"
set :branch, "master"
```

These variables are then propogated automatically to the config files created in setup.

## Setup

production.rb defines a task `setup_config` which is called when we run `cap deploy production:setup`. This task is responsible for creating all configuration specific to our application on the server we're deploying to.

In this simple stage definition there are four key pieces of configuration which are created.

### database.yml

It's good practice not to store details of our production database in source control. Therefore the setup task will copy the databaes.sample.yml template to the shared folder on the remote server and you can SSH in, rename this file to database.yml and enter the production database details.

Whenever the application is deployed, the task `symlink_config` will create a link from app_root/config/database.yml to this shared file.

### unicorn.rb.erb

This defines the configuration for the Unicorn web server. It also ensures that pidfiles are created for the unicorn worker processes which allows them to be monitored and managed if you choose to implement zero downtime deployments.

The key variable to set here is:

``` ruby
worker_processes 1
```

This defines the number of worker processes which unicorn will spawn. The more worker processes, the more concurrent connections can be handled. Worker processes will run continually and consume a fairly consistent amount of RAM irrespective of whether they are handling a request or not. You'll therefore need to tune the number of worker processes depending on:

*   The amount of RAM available
*   The number of applications running on the server
*   the number of cores available

### unicorn_init.sh.erb

This is copied to `/etc/init.d/unicorn_application` and manages the starting, stopping and restarting of unicorn worker processes. The following key commands are available:

``` bash
/etc/init.d/unicorn_application restart
/etc/init.d/unicorn_application start
/etc/init.d/unicorn_application stop
```

### nginx.conf

This is an nginx virtual host file which directs traffic to the domain set as application_domain in production.rb to the unicorn workers.

## Deploying

Once you've populated production.rb with the details of your application. Run:

``` bash
cap production deploy:setup
```


This will create the configuration files on the remote server. Then SSH into the server, navigate to the shared directory and copy the database.example.yml to database.yml and enter the details of your database server.

You're then ready to deploy your application for the first time:

``` bash
cap production deploy
```

## Additional Applications

Using this approach, each application is responsible for maintaing its own configuration and nginx will proxy requests back to the correct unicorn workers depending on the domain which is accessed so the only limit to the number of rails applications which can be deployed to a single server is the resources available.

{% include also-read-rails.html %}
