---
layout : post
title: "Tailing log files with Capistrano 3"
date: 2013-12-21 21:37:00
categories: rails devops
biofooter: false
bookfooter: true
---
When deploying Rails Applications with Capistrano 2 it was common to
have tasks to tail log files on production servers so that
they could be viewed locally without sshing into the remote
machine(s). In this post I'll cover how to do this with Capistrano 3.

<!--more-->

In Capistrano 2, our streaming code would look something like this:

``` ruby
namespace :logs do
  desc "tail rails logs"
  task :tail_rails, :roles => :app do
    trap("INT") { puts 'Interupted'; exit 0; }
    run "tail -f #{shared_path}/log/#{rails_env}.log" do |channel, stream, data|
      puts "#{channel[:host]}: #{data}"
      break if stream == :err    
    end
  end
end
```

In Capistrano 3, it's even simpler:

``` ruby
namespace :logs do
  desc "tail rails logs"
  task :tail_rails do
    on roles(:app) do
      execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log"
    end
  end
end
```

The above task should be added to `lib/capistrano/tasks/logs.cap` and
can be invoked with:

``` bash
cap production logs:tail_rails
```

And stopped with `ctrl c`.

This will tail the rails  log files from all hosts defined as having the role
`:app`. Additional tasks can be defined for other logs you wish to tail
such as unicorn.

This can be made even more flexible using the following definition:

``` ruby
namespace :logs do
  task :tail, :file do |t, args|
    if args[:file]
      on roles(:app) do
        execute "tail -f #{shared_path}/log/#{args[:file]}.log"
      end
    else
      puts "please specify a logfile e.g: 'rake logs:tail[logfile]"
      puts "will tail 'shared_path/log/logfile.log'"
      puts "remember if you use zsh you'll need to format it as:"
      puts "rake 'logs:tail[logfile]' (single quotes)"
    end
  end
end
```

This takes advantage of Capistrano tasks just being rake tasks with some
extra magic thrown in. We can therefore pass variables into Capistrano
task invocations as we would with any rake task.

The above allows us to invoke:

``` bash
rake logs:tail[production]
```

to tail `rails_app_path/shared/log/production.log` or:

``` bash
rake logs:tail[unicorn]
```

to tail `rails_app_path/shared/log/unicorn.log`.

Unfortunately, if you're using ZSH, if you try to pass an
argument to a rake task in the above format you'll receive an error
similar to:

``` bash
zsh: no matches found: logs:tail[production]
```

You can get around this by wrapping the task in quotes so the invocation
would instead be:

``` bash
rake 'logs:tail[production]'
```

Which works for any rake tasks when invoked using ZSH.

{% include also-read-rails.html %}
