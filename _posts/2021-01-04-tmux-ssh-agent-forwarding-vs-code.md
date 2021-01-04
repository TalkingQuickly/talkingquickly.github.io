---
layout : post
title: tmux, docker and SSH agent forwarding when developing remotely with VSCode
date: 2021-01-04 00:00
categories: devops automation vscode
biofooter: true
bookfooter: false
docker_book_footer: false
---

SSH agent forwarding is kind of like magic. Say you're using VSCode remote development to develop on a remote VM and you want to pull from a private repository. By default you might either generate a new keypair on the remote machine and add them to Github. Or you might copy your existing private key to the remote development machine. The former is fiddly and the latter raises some security concerns. With SSH Agent Forwarding you can allow the remote machine to authenticate requests using the keys on your local machine, without the keys ever leaving your local machine.

One hiccup with this is that if you're a tmux user, you'll find that this works initially but then stops working in subsequent sessions. This post offers a simple solution to this.

<!--more-->

## tldr;

To enable SSH forwarding for a particular remote host, add the following to the **local** machines `~/ssh/config`:

```
Host A_FRIENDLY_NAME_FOR_THE_HOST
  ForwardAgent yes
  HostName ADDRESS_OR_IP_ADDRESS
  User SSH_USERNAME
  Port THE_SSH_PORT
```

You can then connect to this host locally with `ssh A_FRIENDLY_NAME_FOR_THE_HOST` and it will show up as `A_FRIENDLY_NAME_FOR_THE_HOST` in the VSCode remote explorer. SSH forwarding should "just work".

To make SSH Forwarding play nicely with tmux, add the following to the **remote** machines `${shell}rc`, I use `zsh` so for me that's `~/.zshrc`:

```bash
# Make tmux play nicely with SSH Agent forwarding
if [ -z ${TMUX+x} ]; then
  # If this is not a tmux session then symlink $SSH_AUTH_SOCK
  if [ ! -S ~/.ssh/ssh_auth_sock ] && [ -S "$SSH_AUTH_SOCK" ]; then
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
  fi
else
  # If this is a tmux session then use the symlinked SSH_AUTH_SOCK
  export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
fi
```

If you're using any version of my [Debian development environment](https://github.com/TalkingQuickly/debian_dev_env) this is done automatically, specifically in [this file](https://github.com/TalkingQuickly/debian_dev_env/blob/master/dotfiles/.zshrc.personal.after).

## So what's going on

When you connect to a remote machine with SSH Agent forwarding enabled, ssh-agent creates a temporary socket which other applications can then use, the location of which is stored in `SSH_AUTH_SOCK`.

When you first create a new tmux session, this environment variable is copied over to the tmux session. However when you disconnect, the temporary socket is then invalidated. When you next reconnect to the remote machine, a new value for `SSH_AUTH_SOCK` is created on the host, but when you reconnect to the tmux session, the old value is still there and so SSH agent forwarding won't work inside the pre-existing session.

The solution to this (not mine originally, see "thanks to" below) is to add another level of indirection. We update the remote machines shell rc file so that when we connect, it creates a symlink from the temporary socket to a known permanent location; ` ~/.ssh/ssh_auth_sock`. We then detect if we're in a tmux session and if we are, replace `SSH_AUTH_SOCK` with this unchanging, permanent location.

## Use within Docker

Since `SSH_AUTH_SOCK` is a unix socket it's essentially just like any other file and so can be mounted into docker containers and accessed from these. This is useful if you have CLI type docker containers. The below shows a very simple `docker-compose.yml` which assuming the above configuration, gives a bash shell with access to the docker hosts ssh agent (which can in turn be forwarded from another host).

```yaml
version: "3"
services:
  shell:
    image: ubuntu
    command: bash
    volumes:
      - "${SSH_AUTH_SOCK}:/home/deploy/ssh_auth_sock"
    environment:
      SSH_AUTH_SOCK: /home/deploy/ssh_auth_sock
```

## Thanks to

This is based heavily on the approach outlined [here](https://werat.github.io/2017/02/04/tmux-ssh-agent-forwarding) which didn't quite work for me; specifically I couldn't make setting `SSH_AUTH_SOCK` in `.tmux.conf` work.