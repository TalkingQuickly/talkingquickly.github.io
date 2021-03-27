---
layout : post
title: Capistrano & Puma; service puma is not active, cannot reload
date: 2021-03-14 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/capistrano-puma-is-not-active-cannot-reload'
---

When trying to use the Capistrano Puma gem to restart Puma via systemd, we may run into an error along the lines of:

```
puma_APP_NAME.service is not active, cannot reload
```

This typically happens either because the service was never enabled or because in the time which elapsed between it being enabled and the first deploy taking place, it has crashed a sufficient number of times that it is no longer active.

The behaviour we want in this scenario is to reload the service if it is active, otherwise to restart it.

Happily systemctl [supports this out of the box]<https://www.freedesktop.org/software/systemd/man/systemctl.html> with `systemctl reload-or-restart`.

We can add the following to `lib/capistrano/tasks` to add a task which uses this to the puma namespace provided by the capistrano puma gem:

```ruby
namespace :puma do
  namespace :systemd do
    desc 'Reload the puma service via systemd by sending USR1 (e.g. trigger a zero downtime deploy)'
    task :reload do
      on roles(fetch(:puma_role)) do
        if fetch(:puma_systemctl_user) == :system
          sudo "#{fetch(:puma_systemctl_bin)} reload-or-restart #{fetch(:puma_service_unit_name)}"
        else
          execute "#{fetch(:puma_systemctl_bin)}", "--user", "reload", fetch(:puma_service_unit_name)
          execute :loginctl, "enable-linger", fetch(:puma_lingering_user) if fetch(:puma_enable_lingering)
        end
      end
    end
  end
end

after 'deploy:finished', 'puma:systemd:reload'
```

This should be used in conjunction with including the puma systemd tasks in our `Capfile` using the `load_hooks: false` option which prevents the default restart task from being called.

```ruby
install_plugin Capistrano::Puma::Systemd, load_hooks: false
```

The use of the above task also allows for zero downtime deploys when used with the relevant puma configuration and systemd unit file. See [this post](/capistrano-puma-neither-valid-executable-nor-absolute-path) for more on the systemd unit file and [this repository](https://github.com/TalkingQuickly/rdra_rails6_example) for a working example.