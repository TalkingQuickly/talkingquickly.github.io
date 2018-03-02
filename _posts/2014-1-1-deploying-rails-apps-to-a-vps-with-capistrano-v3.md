---
layout : post
title: "Capistrano 3 Tutorial"
date: 2014-1-1 19:36:00
categories: rails devops
biofooter: false
bookfooter: true
---

One of the most popular posts on this blog is on how to use Capistrano 2 to deploy Rails applications to a VPS, including the scenario when you want to run several different applications on the same server. Capistrano 3 has now been released and having upgraded several large production applications to use it, I've found there to be a lot of worthwhile improvements over v2. This post explains, with sample code, how to use Capistrano 3 to deploy one or several Rails applications to a VPS.

<!--more-->

This post and the sample code has been updated to be compatible with the latest Capistrano 3.1.

## What's new in V3.

For full details see the <a href="http://www.capistranorb.com/2013/06/01/release-announcement.html" target="_blank">release annoucement</a>, but the key bits I think make the upgrade worthwhile are:

* It uses the Rake DSL instead of a specialised Capistrano one, this makes writing Capistrano tasks, exactly like writing rake tasks, something most Rails developers have some familiarity with.
* It uses SSHkit for lower level functions around connecting and interacting with remote machines. This makes writing convenience tasks which do things like streaming logs or checking processes, much easier.

## The Stack

This recipe has been tested on a VPS provisioned using the method described in [this post](/2013/09/using-chef-to-provision-a-rails-and-postgres-server/). In particular it assumes:

- Nginx as the web server
- Unicorn as the app server

As well as using this in production across several sites, this process has been tested on fresh Rails 3.2 and 4.0 projects.

## Upgrading from V2

If you already have a Capistrano V2 configuration for the application to be deployed, I suggest you archive all of this off and start from scratch with Capistrano 3. In general this will mean renaming (for example appenidng .old) all of the following:

``` bash
Capfile
config/deploy.rb
config/deploy/
```

## Step by step

1) Add the following Gems to your Gemfile

``` ruby
gem 'capistrano', '~> 3.1.0'

# rails specific capistrano funcitons
gem 'capistrano-rails', '~> 1.1.0'

# integrate bundler with capistrano
gem 'capistrano-bundler'

# if you are using RBENV
gem 'capistrano-rbenv', "~> 2.0"

# Use the Unicorn app server
gem 'unicorn'
```

Then run `bundle install` if you're adding capistrano 3 for the first time or `bundle update capistrano` if you're upgrading. You may need to do some of the usual Gemfile juggling if you're updating and there are dependency conflicts.

2) Assuming you've archived off any legacy Capistrano configs, you can now run:

``` bash
bundle exec cap install
```

Which generates the following files and directory structure:


```
├── Capfile
├── config
│   ├── deploy
│   │   ├── production.rb
│   │   └── staging.rb
│   └── deploy.rb
└── lib
    └── capistrano
            └── tasks
```

The source for this tutorial is available on [github](https://github.com/TalkingQuickly/capistrano-3-rails-template). I suggest cloning this repository or downloading [the zip](https://github.com/TalkingQuickly/capistrano-3-rails-template/archive/master.zip) and copying these files into your project as you read through the following steps.

3) Add the following line at the end of `Capfile`

``` ruby
Dir.glob('lib/capistrano/**/*.rb').each { |r| import r }
```

This means that as well as loading all .cap files in `lib/capistrano/tasks`, Capistrano will load all .rb files in `lib/capistrano` and its subfolders. This is used later to define simple helper functions for use in tasks.

You'll also probably want to uncomment:

``` ruby
require 'capistrano/bundler'
require 'capistrano/rbenv'
require 'capistrano/rails/migrations'
```

Which will include the capistrano bundler tasks to ensure gems are automatically installed when you deploy. It will also include the rbenv helpers which ensure the rbenv specified ruby is used when executing commands remotely rather than the system default. Finally it will include the migration helpers which ensure migrations are automatically run when you deploy.

4) This approach aims is to keep as much common configuration in `config/deploy.rb` as possible and put only minimal stage specific configuration in the stage files like `config/deploy/production.rb`.

To begin with enter the following in `deploy.rb`

``` ruby
set :application, 'app_name'
set :deploy_user, 'deploy'

# setup repo details
set :scm, :git
set :repo_url, 'git@github.com:username/repo.git'

# setup rvm.
set :rbenv_type, :system
set :rbenv_ruby, '2.1.1'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}

# how many old releases do we want to keep
set :keep_releases, 5

# files we want symlinking to specific entries in shared.
set :linked_files, %w{config/database.yml}

# dirs we want symlinking to shared
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# what specs should be run before deployment is allowed to
# continue, see lib/capistrano/tasks/run_tests.cap
set :tests, []

# which config files should be copied by deploy:setup_config
# see documentation in lib/capistrano/tasks/setup_config.cap
# for details of operations
set(:config_files, %w(
  nginx.conf
  database.example.yml
  log_rotation
  monit
  unicorn.rb
  unicorn_init.sh
))

# which config files should be made executable after copying
# by deploy:setup_config
set(:executable_config_files, %w(
  unicorn_init.sh
))

# files which need to be symlinked to other parts of the
# filesystem. For example nginx virtualhosts, log rotation
# init scripts etc.
set(:symlinks, [
  {
    source: "nginx.conf",
    link: "/etc/nginx/sites-enabled/#{fetch(:full_app_name)}"
  },
  {
    source: "unicorn_init.sh",
    link: "/etc/init.d/unicorn_#{fetch(:full_app_name)}"
  },
  {
    source: "log_rotation",
   link: "/etc/logrotate.d/#{fetch(:full_app_name)}"
  },
  {
    source: "monit",
    link: "/etc/monit/conf.d/#{fetch(:full_app_name)}.conf"
  }
])


# this:
# http://www.capistranorb.com/documentation/getting-started/flow/
# is worth reading for a quick overview of what tasks are called
# and when for `cap stage deploy`

namespace :deploy do
  # make sure we're deploying what we think we're deploying
  before :deploy, "deploy:check_revision"
  # only allow a deploy with passing tests to deployed
  before :deploy, "deploy:run_tests"
  # compile assets locally then rsync
  after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  after :finishing, 'deploy:cleanup'

  # remove the default nginx configuration as it will tend
  # to conflict with our configs.
  before 'deploy:setup_config', 'nginx:remove_default_vhost'

  # reload nginx to it will pick up any modified vhosts from
  # setup_config
  after 'deploy:setup_config', 'nginx:reload'

  # Restart monit so it will pick up any monit configurations
  # we've added
  after 'deploy:setup_config', 'monit:restart'

  # As of Capistrano 3.1, the `deploy:restart` task is not called
  # automatically.
  after 'deploy:publishing', 'deploy:restart'
end
```

The key variables to set here are `application`, `repo_url` and `rbenv_ruby`. The Rbenv Ruby you set must match one installed with rbenv on the machine you're deploying to otherwise the deploy will fail.

This section:

``` ruby
# what specs should be run before deployment is allowed to
# continue, see lib/capistrano/tasks/run_tests.cap
set :tests, []
```

Provides a simple way to run specs before deploying, if the specs fail, the deployment will be halted. If you already have a fully blown continuous integration system setup (or don't want to run specs at all), this can be set to an empty array.

If you were to have this as `set :tests, []` then `bundle exec rspec spec` would be run and would have to pass before deployment would continue.

5) Now edit the stage specific settings in `production.rb`. By default it looks like this:

``` ruby
set :stage, :production
set :branch, "master"

# used in case we're deploying multiple versions of the same
# app side by side. Also provides quick sanity checks when looking
# at filepaths
set :full_app_name, "#{fetch(:application)}_#{fetch(:stage)}"
set :server_name, "www.example.com example.com"

server 'www.example.com', user: 'deploy', roles: %w{web app db}, primary: true

set :deploy_to, "/home/#{fetch(:deploy_user)}/apps/#{fetch(:full_app_name)}"

# dont try and infer something as important as environment from
# stage name.
set :rails_env, :production

# number of unicorn workers, this will be reflected in
# the unicorn.rb and the monit configs
set :unicorn_worker_count, 5

# whether we're using ssl or not, used for building nginx
# config file
set :enable_ssl, false
```

The important variables to update are the server hostname:

``` ruby
server 'www.example.com', user: 'deploy', roles: %w{web app db}, primary: true
```

the server name:

``` ruby
set :server_name, "www.example.com example.com"
```

When you run `cap some_stage_name some_task`, Capistrano will look for a file `config/deploy/some_stage_name.rb` and load it after `deploy.rb`.

You can create as many of these files as you want, for example an additional `staging` configuration.

6) Config Files

Capistrano uses a folder called `shared` to manage files and directories that should persist across releases. The key one is `shared/config` which contains configuration files which are required to persist across deploys.

To integrate with the Rails directory structure, the following:

``` ruby
# files we want symlinking to specific entries in shared.
set :linked_files, %w{config/database.yml config/application.yml}
```

Means that after every deploy, the files listed in the array (remember `%w{items}` is just shorthand for creating an array of string literals) will be automatically symlinked to corresponding files in shared.

Therefore `config/database.yml` will actually be a symlink which points to `shared/config/database.yml`.

This section:

``` ruby
# which config files should be copied by deploy:setup_config
# see documentation in lib/capistrano/tasks/setup_config.cap
# for details of operations
set(:config_files, %w(
  nginx.conf
  database.example.yml
  log_rotation
  monit
  unicorn.rb
  unicorn_init.sh
))

# which config files should be made executable after copying
# by deploy:setup_config
set(:executable_config_files, %w(
  unicorn_init.sh
))
```

Is a custom extension to the standard Capistrano 3 approach to configuration files which makes the initial creation of these files easier by adding the task `deploy:setup_config`.

When this task is run, for each of the files defined in `:config_files`, it will first look for a corresponding .erb file (so for nginx.conf it would look for nginx.conf.erb) in `config/deploy/#{application}_#{rails_env}/`. If it is not found in there it would look for it in `config/deploy/shared/. Once it finds the correct source file, it will parse the erb and then copy the result to the `config` directory in your remote shared path.

This allows you to define your common config files in `shared` which will be used by all stages (staging & production for example) while still allowing for some templates to differ between stages.

Finally this section:

    # remove the default nginx configuration as it will tend
    # to conflict with our configs.
    before 'deploy:setup_config', 'nginx:remove_default_vhost'

    # reload nginx to it will pick up any modified vhosts from
    # setup_config
    after 'deploy:setup_config', 'nginx:reload'

    # Restart monit so it will pick up any monit configurations
    # we've added
    after 'deploy:setup_config', 'monit:restart'

Means that after `deploy:setup_config` is run, we:

* Delete the `default` nginx Virtualhost to stop it over-riding our VirtualHost
* Reload Nginx to pickup any changes to the VirtualHost
* Reload Monit to pickup any changes to the Monit configuration

Check that you're happy with the contents of the configuration files and then copy them to your production server with:

``` bash
cap production deploy:setup_config
```

7) Now SSH into your remote server and cd into `shared/config` to create a database.yml from the example:

``` bash
cp database.yml.example database.yml
```

Edit it with your favourite text editor, e.g:

``` bash
vim database.yml
```

And enter the details of the database the app should connect to. Remember that if you're using Postgres or Mysql, you'll need to create this database first.

8) You're now ready to deploy. Return to your local terminal, ensure that you've committed your changes pushed changes to the remote repository and enter:

``` bash
cap production deploy
```

And wait. The fist deploy can take a while as Gems are installed so be patient.

## Conclusion

This configuration is based heavily on the vanilla capistrano configuration, with some extra convenience tasks added in `lib/capistrano/tasks/` to make workflows I've found to be efficient for big production configurations quick to setup.

I strongly recommend forking my sample configuration and tailoring it to fit the kind of applications you develop. I usually end up with a few different configurations, each of which are used for either a particular type of personal project or all of a particular clients applications.

Any queries or suggestions are welcomed, I'm <a href="http://www.twitter.com/talkingquickly" target="_blank">@talkingquickly</a> on twitter. I'm also happy to include pull requests to the sample configuration.

{% include also-read-rails.html %}
