---
layout : post
title: Capistrano & Puma; neither a valid executable name nor an absolute path
date: 2021-03-14 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/capistrano-puma-neither-valid-executable-nor-absolute-path'
---

When attempting to deploy a Rails application using the puma web sever using the systemd functionality in the capistrano puma gem, we may receive the error message:

```
Neither a valid executable name nor an absolute path
```

When attempting to start the systemd service. This most often occurs when using the capistrano rbenv plugin. This is because the Capistrano rbenv plugin modifies the `SSHKit.config.command_map[:bundle]` path to include the `RBENV_ROOT` and `RBENV_VERSION` environment variables at the start of the `bundle` path. Systemd doesn't support `Exec` command starting with environment variables, instead requiring them to be in separate `Environment` lines.

We can fix this by overriding the `puma.server.erb` template with a new systemd unit file as follows:

```
[Unit]
Description=Puma HTTP Server for <%= "#{fetch(:application)} (#{fetch(:stage)})" %>
After=network.target

[Service]
Type=simple
<%="User=#{puma_user(@role)}" if fetch(:puma_systemctl_user) == :system %>
WorkingDirectory=<%= current_path %>
ExecStart=/usr/local/rbenv/bin/rbenv exec bundle exec puma -C <%= fetch(:puma_conf) %>
ExecReload=/bin/kill -USR1 $MAINPID
ExecStop=/bin/kill -TSTP $MAINPID
StandardOutput=append:<%= fetch(:puma_access_log) %>
StandardError=append:<%= fetch(:puma_error_log) %>
<%="EnvironmentFile=#{fetch(:puma_service_unit_env_file)}" if fetch(:puma_service_unit_env_file) %>
<% fetch(:puma_service_unit_env_vars, []).each do |environment_variable| %>
<%="Environment=#{environment_variable}" %>
<% end %>

Environment=RBENV_VERSION=<%= fetch(:rbenv_ruby) %>
Environment=RBENV_ROOT=/usr/local/rbenv

Restart=always
RestartSec=1

SyslogIdentifier=puma_<%= fetch(:application) %>_<%= fetch(:stage) %>

[Install]
WantedBy=<%=(fetch(:puma_systemctl_user) == :system) ? "multi-user.target" : "default.target"%>
```

Note that this hardcodes the path to rbenv so if the path is different, for example because it's a user install not a system install, this will need updating.

This unit file also adds an `ExecReload` option to allow us to use systemd for zero downtime deploys.

For a fully working example see [this repository](https://github.com/TalkingQuickly/rdra_rails6_example/).

There's more information in [this github issue](https://github.com/seuros/capistrano-puma/issues/313).