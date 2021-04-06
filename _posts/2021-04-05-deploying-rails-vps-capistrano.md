---
layout : post
title: Deploying Rails to a VPS with Capistrano V3
date: 2021-04-04 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/deploying-rails-to-a-vps-with-capistrano-v3-and-systemd'
---

Deploying Rails to a VPS with Capistrano remains one of the simplest and most reliable methods for getting a Rails app up-and running. With the likes of Hetzner Cloud, Digital Ocean and Linode providing inexpensive, reliable virtual machines, Rails app serving substantial amounts of traffic can be hosted with minimal cost and complexity.

In the previous post we used Chef to prepare an Ubuntu 20.04 server for deployment of our Rails application. This included installing Nginx, PostgreSQL, Redis and our Ruby version of choice. We used Chef for this rather than entering command manually so that we can trivially create additional identical servers in future without needing to remember lots of terminal commands and config file edits.

In this tutorial we'll use Capistrano to automate deployment of our application, including generating all required config files, obtaining a free SSL certificate with Lets Encrypt and enabling zero downtime deployment.

<!--more-->

This tutorial is in two parts:

- [Setting up a VPS for Rails app Deployment](/setting-up-ubuntu-20-04-focal-fossa-vps-for-rails-app-deployment)
- **[Deploying Rails to Ubuntu 20.04 with Capistrano](/deploying-rails-to-a-vps-with-capistrano-v3-and-systemd)**


Note that this post is intended to be a tutorial rather than a reference, so the focus will be on the steps that need to be completed rather than exploring the why.

## Setting up DNS

In order to obtain an SSL certificate for our application, we will need to have public DNS setup.

So if we want our application to be available on `https://myapp.example.com` then we would need to own the domain `example.com` and be able to create DNS records for it.

Assuming our server had the IP address `203.0.113.1` we should now create an "A" record for `myapp.example.com` with content `203.0.113.1`.

We can check that our DNS entry has been created correctly using `dig myapp.example.com`. Replacing `myapp.example.com` with your domain.

If you don't have a domain yet, you can still follow this tutorial, but it won't be possible to obtain an SSL certificate. In this scenario simply add the following line to your local hosts file `/etc/hosts`:

```
SERVER_IP LOCALHOSTNAME
```

So, for example:

```
203.0.113.1 myapp.local
```

This will allow you to access the app over http (but not https) on `myapp.local`.

## Adding Gems

We then add the following to our Gemfile:

```
# The puma application server, we probably already have this
gem 'puma', '~> 5.0'

group :development do
  # Including capistrano cookbook will automatically includes
  # the correct version of capistrano and other plugins
  gem 'capistrano-cookbook', require: false
end
```

and run `bundle install`.

## Generating Local Configuration

Capistrano Cookbook is a convenience gem that provides some helper tasks and a Rails Generator for bootstrapping the typical configuration used when deploying a Rails application both with or without Sidekiq.

To generate configuration execute the following:

```
bundle exec rails g capistrano:reliably_deploying_rails:bootstrap --sidekiq --production_hostname='YOUR_HOSTNAME' --production_server_address='SERVER_IP' --certbot_enable --certbot_email='YOUR_EMAIL'
```

Replacing:

- `YOUR_HOSTNAME` with the address our application will be accessible on. Note that if we are not creating a DNS entry and instead are creating an entry in our local hosts file then we **must** remove the `--certbot_*` flags
- `SERVER_IP` with the IP address of the VPS you are deploying to. In single server configurations this could also be the same as `YOUR_PRODUCTION_HOSTNAME` but that approach adds some fragility if, in the future, you decide to add additional frontend servers behind a load balancer to handle additional load.
- `YOUR_EMAIL` with the email email address LetsEncrypt can send certificate expiry notifications to. These notifications are generally for information only as our configuration automatically renews certificates when the expire so you may want to add a suffix, e.g. "youremail+letsencrypt" to make it easy to filter these emails with automated rules.

And optionally keeping or removing this flags:

- `--sidekiq` removing this flag if we are not using Sidekiq for background jobs. If this flag is present the generator will include the required logic and templates to have Sidekiq automatically deployed and restarted alongside the core Rails application
- `--certbot_enable` and `--certbot_email` we should remove these flags if we do not want to have a free SSL certificate for `YOUR_HOSTNAME` generated. we'll definitely want to remove these flags if we're testing locally with something like vagrant or if you don't yet have a domain with DNS setup, e.g. when using local hosts file to map domains to IP's.

This will generate the following files and folders:

```
Capfile
config
  ├── deploy.rb
  └── deploy
      ├── production.rb
      ├── staging.rb
      └── templates
          ├── nginx_conf.erb
          ├── puma_monit.conf.erb
          ├── puma.rb.erb
          ├── puma.service.erb
          ├── sidekiq_monit.erb
          └── sidekiq.service.capistrano.erb
```

The files in `templates` are primarily overrides for the default configuration files created by the excellent `capistrano-puma` and `capistrano-sidekiq` gems which addresses some [issues that can arise](/capistrano-puma-neither-valid-executable-nor-absolute-path) when using systemd and `capistrano-rbenv`.

It also generates Monit definitions which are compatible with systemd. While in some respects systemd and Monit serve similar functions - both can ensure that our application and background workers are always running and started at boot - Monit can provide a layer of additional verification, for example checking ports are accessible and HTTP response codes and taking actions if this changes, so we'll generally require both for a robust configuration. 

## Configuring Stages

The file `deploy.rb` contains our general deployment configuration, and looks something like this:

```ruby
# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

set :application, 'rdra_rails6_example'
set :deploy_user, 'deploy'

# setup repo details
set :repo_url, 'git@github.com:TalkingQuickly/rdra_rails6_example.git'

# setup rbenv.
set :rbenv_type, :system
set :rbenv_ruby, '3.0.0'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}

# setup certbot for SSL via letsencrypt
set :certbot_enable_ssl, true
set :certbot_redirect_to_https, true
set :certbot_email, "ben@talkingquickly.co.uk"
set :certbot_use_acme_staging, false

# setup puma to operate in clustered mode, required for zero downtime deploys
set :puma_preload_app, false
set :puma_init_active_record, true
set :puma_workers, 3
set :puma_systemctl_user, fetch(:deploy_user)
set :puma_enable_lingering, true


set :sidekiq_systemctl_user, fetch(:deploy_user)
set :sidekiq_enable_lingering, true


# how many old releases do we want to keep
set :keep_releases, 5

# Directories that should be linked to the shared folder
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'
append :linked_files, 'config/database.yml', 'config/master.key'

# this:
# http://www.capistranorb.com/documentation/getting-started/flow/
# is worth reading for a quick overview of what tasks are called
# and when for `cap stage deploy`

namespace :deploy do
end
```

This is where we set configuration that is the same no matter whether we're deploying to production, staging or any other environment.

`capistrano-cookbook` will have attempted to infer the following values:

- `application` from the name of the Rails application
- `repo_url` from the current folders git `origin`

And the following values should be manually set according to our apps requirements:

- `rbenv_ruby` to the Ruby version the app requires

The two other files which contain deployment configuration are `production.rb` and `staging.rb`. These are known as stages in Capistrano.

When we run Capistrano commands we will do so in the form `cap STAGE_NAME COMMAND`. So if we were to run `cap production COMMAND` then the contents of `config/deploy/production.rb` would be evaluated before executing `COMMAND`.

Our `production.rb` by default looks something like this:

```ruby
set :stage, :production
set :branch, "master"

# This is used in the Nginx VirtualHost to specify which domains
# the app should appear on. If you don't yet have DNS setup, you'll
# need to create entries in your local Hosts file for testing.
set :nginx_server_name, 'rdr-rails6-example.staging.talkingquickly.co.uk'

# used in case we're deploying multiple versions of the same
# app side by side. Also provides quick sanity checks when looking
# at filepaths
set :full_app_name, "#{fetch(:application)}_#{fetch(:stage)}"


# Name sidekiq systemd service after the app and stage name so that
# multiple apps and stages can co-exist on the same machine if needed
set :sidekiq_service_unit_name, "sidekiq_#{fetch(:full_app_name)}"


server '65.21.54.211', user: 'deploy', roles: %w{web app db}, primary: true

set :deploy_to, "/home/#{fetch(:deploy_user)}/apps/#{fetch(:full_app_name)}"

# dont try and infer something as important as environment from
# stage name.
set :rails_env, :production
```

Where `nginx_server_name` is set to our production server and the first argument being passed to `server` is our production servers IP address.

The only value we may want to tweak is `:branch` which defines which branch should be used to deploy to this server. So if we were following a "git flow" type model, we might set this to `master` in `production.rb` and `develop` in `staging.rb`.

## Generating Remote Configuration

Now that we've confirmed all of our local configuration is correct, we can upload all of our one time configuration to the remote server.

This is accomplished with the [task](https://github.com/TalkingQuickly/capistrano-cookbook/blob/master/lib/capistrano/cookbook/tasks/setup_config.cap) `deploy:setup_config`.

This task is responsible for copying one time configuration to the remote server, specifically:

1. Systemd unit files
2. Monit definitions 
3. The Rails master key
4. Log rotation definitions

As well as enabling the relevant systemd services, requesting the SSL certificate and having certbot update our nginx configuration file to reference it.

We can execute this task with:

```
bundle exec cap production deploy:setup_config
```

## Setting up our database

The final step required before deploying our application for the first time is setting up our database.

If we are using Postgres, `capistrano-cookbook` includes the [task](https://github.com/TalkingQuickly/capistrano-cookbook/blob/master/lib/capistrano/cookbook/tasks/create_database.cap) `database:create` which will:

1. Create a `database.yml` with a random password
2. Create the database using the master Postgres user
3. Create the user specified in `database.yml` and grants them access to the database

So we can simply execute:

```
bundle exec cap production database:create
```

And our database will be ready for use.

If we wish to setup our database manually, we will need to create the appropriate database and user, then create a suitable `database.yml` file on our remote server in `/home/deploy/apps/FULL_APP_NAME/shared/config` replacing `FULL_APP_NAME` with the value that will be generated for `:full_app_name` in our `production.rb`. This is typically `APP_NAME_STAGE` e.g. `my_rails_app_production`.

## Disabling Passwordless Sudo (optional)

Our configuration commands require the ability for our deploy user to execute sudo commands without being prompted for a password.

Now that we have finished the initial configuration, this is not required as our deploy tasks are carefully designed to not require any root access (see [this post](/managing-puma-with-systemd-user-instance-and-monit) for more on working with userspace systemd).

We can therefore optionally return to our Chef repository from the [previous](/setting-up-ubuntu-20-04-focal-fossa-vps-for-rails-app-deployment) tutorial and use `knife node edit NODE_NAME` to add the following under the `normal` key:

```json
"authorization": {
    "sudo": {
      "passwordless": false
    }
  }
```

and then run:

```
knife zero converge "NODE_NAME" --ssh-user PROVISIONING_USER
```

To update the node to not allow passwordless sudo.

This provides us with some level of additional security because if - through some exploit - an attacker gained the ability to execute arbitrary shell commands as our app user, they would not automatically be able to execute commands as root.

## Deploying our application

We're now ready to deploy our application. It's important to note here that Capistrano uses SSH Keychain Forwarding to clone the repository specified in `config/deploy.rb` at the branch specified in `config/deploy/STAGE_NAME.rb`.

This means that if we have local changes which we have not yet pushed to the repository we are deploying from, these changes will not be deployed.

Once we've ensured everything has been pushed, we can deploy with:

```
bundle exec cap production deploy
```

Our configuration is setup to allow zero downtime deploys, so when we deploy future versions, our newly deployed code will be loaded in the background and then traffic seamlessly transferred over to this new version.

## Next

If you've run into any issues, please feel free to ping me on Twitter where I'm [@talkingquickly](https://www.twitter.com/talkingquickly) or open an issue on the [capistrano cookbook repository](https://github.com/TalkingQuickly/capistrano-cookbook) and I'll do my best to help.

There's also an example Rails app available [here](https://github.com/TalkingQuickly/rdra_rails6_example) which shows this configuration in action.