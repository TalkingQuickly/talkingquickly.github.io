---
layout : post
title: Capistrano & Puma with Systemd; Permission denied @ rb_io_reopen
date: 2021-03-16 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/capistrano-puma-systemd-permission-denied-@rb_io_repopen'
---

When using the capistrano puma gem with systemd, we may get the error:

```
Permission denied @ rb_io_reopen - /home/deploy/LOG_FILE_PATH/shared/log/puma_access.log (Errno::EACCES)
```

This may be caused by doubling up on the puma app servers logging.

Typically our systemd unit will contain something like:

```
StandardOutput=append:/home/deploy/LOG_FILE_PATH/shared/log/puma_access.log
```

Which means that any data written to standard output will be appended to the log file specified by systemd.

If we're getting the above error, it's also likely that our `puma.rb` configuration file contains something like:

```
stdout_redirect '/home/deploy/LOG_FILE_PATH/shared/log/puma_access.log', true
```

Which tells puma itself to write to a log file instead of to stdout.

This doubling up leads to the following:

- systemd creates the log file as the root user
- puma which we will generally have running as a different user then tries to write to this same file, but it doesn't have permission because it was created by root

The solution to this is simple, we can complete remove this line from `puma.rb`:

```
stdout_redirect '/home/deploy/LOG_FILE_PATH/shared/log/puma_access.log', true
```

Since the redirection of stdout is already being handled by systemd.