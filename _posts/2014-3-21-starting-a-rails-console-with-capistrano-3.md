---
layout : post
title: "Starting a Rails Console with Capistrano 3"
date: 2014-3-21 19:36:00
categories: rails devops
biofooter: false
bookfooter: true
---

When deploying with Capistrano 3, it's often useful to be able to start a rails console without having to ssh into the target host and set it up manually. This can be particularly challenging if you're using rbenv as you have to ensure that `rails console` is called with suitable environment variables set set to ensure that the rbenv Ruby is used not the system Ruby.

The below snippet works with Capistrano 3 and will attempt to use `rbenv_ruby` if it is configured in Capistrano, otherwise it will fall back to the default system Ruby.

```ruby
namespace :rails do
  desc "Start a rails console, for now just with the primary server"
  task :c do
    on roles(:app), primary: true do |role|
      rails_env = fetch(:rails_env)
      execute_remote_command_with_input "#{bundle_cmd_with_rbenv} #{current_path}/script/rails console #{rails_env}"
    end
  end
 
  def execute_remote_command_with_input(command)
    port = fetch(:port) || 22
    puts "opening a console on: #{host}...."
    cmd = "ssh -l #{fetch(:deploy_user)} #{host} -p #{port} -t 'cd #{deploy_to}/current && #{command}'"
    exec cmd
  end
 
  def bundle_cmd_with_rbenv
    if fetch(:rbenv_ruby)
      "RBENV_VERSION=#{fetch(:rbenv_ruby)} RBENV_ROOT=#{fetch(:rbenv_path)}  #{File.join(fetch(:rbenv_path), '/bin/rbenv')} exec bundle exec"
    else
      "ruby "
    end
  end
end
```


{% include also-read-rails.html %}