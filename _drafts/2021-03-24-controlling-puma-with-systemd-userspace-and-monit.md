---
layout : post
title: Managing puma with the systemd user instance and monit
date: 2021-03-23 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/managing-puma-with-systemd-user-instance-and-monit'
---

Many guides to deploying Rails with Capistrano will use systemd to have it auto-started when the system boots. This is often done using the system instance of systemd which by default can only be controlled by root.

The typical workaround for this is either to grant our Capistrano deployment user passwordless sudo access or to grant them passwordless sudo access to just the commands required to restart the rails (and potentially sidekiq) systemd services.

This can be avoided by using the systemd user instance, which allows persistent services to be managed as a non-root user. This is compatible with the default systemd configuration in Ubuntu 20.04.

<!-- More -->

There are multiple locations systemd user instance units can be located, there's more [here](https://wiki.archlinux.org/index.php/systemd/User), in this case we'll be using: 

```
~/.config/systemd/user/
```

In here we'll put a systemd unit file similar to the following:

```
[Unit]
Description=Puma HTTP Server for RAILS APP NAME (ENVIRONMENT)
After=network.target

[Service]
Type=simple

WorkingDirectory=/home/deploy/apps/APP_NAME/current
ExecStart=/usr/local/rbenv/bin/rbenv exec bundle exec puma -C /home/deploy/apps/APP_NAME/shared/puma.rb
ExecReload=/bin/kill -USR1 $MAINPID
ExecStop=/bin/kill -TSTP $MAINPID
StandardOutput=append:/home/deploy/apps/APP_NAME/shared/log/puma_access.log
StandardError=append:/home/deploy/apps/APP_NAME/shared/log/puma_error.log

Environment=RBENV_VERSION=3.0.0
Environment=RBENV_ROOT=/usr/local/rbenv

Restart=always
RestartSec=1

SyslogIdentifier=APP_NAME

[Install]
WantedBy=default.target
```

The `capistrano-puma` Gem can auto-generate this file and the `capistrano-cookbook` gem provides and overridden version of the template which fixes some rbenv compatibility issues and allows for zero downtime deploys (as well as also generating all other capistrano configuration automatically).

You can see the most recent Capistrano Cookbooks unit file template - which may be useful as a reference - [here](https://github.com/TalkingQuickly/capistrano-cookbook/blob/master/lib/generators/capistrano/reliably_deploying_rails/templates/puma.service.erb) which is a tweaked version of the version in `capistrano-puma`.

Note a few things about this unit file:

- There is no `User` directive, user services will run as the user in question, including a `User` directive may lead to non-descriptive `service start request repeated too quickly, refusing to start` type errors
- Our Environment variables are not included in the `ExecStart` command, they're in separate `Environment` lines, [this is explained here](http://www.talkingquickly.co.uk/capistrano-puma-neither-valid-executable-nor-absolute-path)
- `WantedBy` is set to `default.target` which is the correct value for user services if we want them to be started at boot

In order for our service to be started at boot, we then need to enable this service with:

```
systemctl --user enable UNIT_FILE_NAME
```

Note that this is different to starting the unit. We can start a unit immediately with `systemctl --user start UNIT_FILE_NAME` but this does not set the unit to be started on boot, so we must enable it as well. This is taken care of automatically if you're using the `deploy:setup_config` task from `capistrano-cookbook`.

Our next challenge is that by default, user instance systemd services are only started when the user starts a session and will continue to run only while the user in question has an active session.

To resolve this we must enable [lingering](http://manpages.ubuntu.com/manpages/xenial/man1/loginctl.1.html), lingering ensures that a manager for the user in question in spawned on boot so that the user can manage long run services.

We can enable lingering with:

```
loginctl enable-linger USERNAME
```

Where USERNAME is the capistrano deployment user. This is taken care of automatically if you're using the `deploy:setup_config` task from `capistrano-cookbook`.

Finally we may want to monitor our systemd service with Monit. While there is crossover between systemd and monit, both will monitor that a process is running and start it if not.

Monit however adds some additional capabilities on top of systemd, it can allow for significantly more complex checks such as making sure that our service is responding on a given port and even check the contents of certain healthcheck responses and issuing restarts if these aren't matched.

Monit however runs as root and we need it to control a systemd user service.

We may initially think we can use something like:

```
start program = "/usr/bin/systemctl --user start SYSTEMD_SERVICE_UNIT_FILE" as uid "deploy" and gid "deploy"
```

As our start program where `deploy` is our Capistrano user. We might expect this to be equivalent to running `systemctl --user start` as the deploy user in a shell. While the command will be run as that user, due to some missing environment variables, we're likely to get an error along the lines of:

```
Failed to get D-bus connection: no such file or directory
```

This is due to `XDG_RUNTIME_DIR` [not being set correctly](https://serverfault.com/questions/936985/cannot-use-systemctl-user-due-to-failed-to-get-d-bus-connection-permission) when users are switched in this way. The same issue can happen if we try and use `su` in Capistrano to change users before executing a `systemctl --user` command.

We can resolve is by modifying our start command to set this environment variable manually. So a simple monit definition might look like this:

```
check process APP_NAME
  with pidfile "/home/deploy/apps/APP_NAME/shared/tmp/pids/puma.pid"
  start program = "/bin/bash -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) /usr/bin/systemctl start --user SYSTEMD_SERVICE_UNIT_FILE'" as uid "deploy" and gid "deploy"
  stop program = "/bin/bash -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) /usr/bin/systemctl stop --user SYSTEMD_SERVICE_UNIT_FILE'" as uid "deploy" and gid "deploy"
```

You can see the most recent version of `capistrano cookbooks` monit definition [here](https://github.com/TalkingQuickly/capistrano-cookbook/blob/master/lib/generators/capistrano/reliably_deploying_rails/templates/puma_monit.conf.erb) which may be useful as a reference.

With all of this completed, we should now have puma being managed by a systemd service, which will auto start at boot, and is monitored with monit.