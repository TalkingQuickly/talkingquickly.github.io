---
layout : post
title: "Running Cron with Docker and the Whenever Gem"
date: 2014-06-07 08:00:00
categories: devops
biofooter: false
bookfooter: false
docker_book_footer: true
---

In order for cron jobs to be processed, the cron daemon (process) must be running. In a docker container created from the basic ubuntu image, none of the usual system processes are started by default and there's no upstart, so cronjobs won't work. In this post I'll look at one approach to running cron jobs with Docker.

There are two potentially solutions to this:

* Explictly run cron in its own container
* Setup the container to run multiple processes and to automatically start the cron daemon in the background

In this post I'll only cover the first option as I prefer the single process per container model. That's not to say there's anything wrong with running multiple processes in a single container (there isn't). If you want to explore this, Phusion provide a base image which includes a working cron daemon. This image is available here <https://github.com/phusion/baseimage-docker>, even if you don't use it, it's worth reading the documentation about why Phusion created it.

## The Whenever Gem

The Whenever Gem <https://github.com/javan/whenever> 

## The Dockerfile

The Dockerfile for cron is very simple, 

```bash
FROM ubuntu:12.04
MAINTAINER talkingquickly.co.uk <ben@talkingquickly.co.uk>

ENV DEBIAN_FRONTEND noninteractive

# REPOS
RUN apt-get -y update
RUN apt-get install -y -q python-software-properties
RUN add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN apt-get -y update

# INSTALL
RUN apt-get install -y -q build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config libmysqlclient-dev libpq-dev make wget unzip git vim nano nodejs mysql-client mysql-server gawk libgdbm-dev libffi-dev

RUN git clone https://github.com/sstephenson/ruby-build.git /tmp/ruby-build && \
    cd /tmp/ruby-build && \
    ./install.sh && \
    cd / && \
    rm -rf /tmp/ruby-build

# Install ruby
RUN ruby-build -v 2.0.0-p481 /usr/local
 
# Install base gems
RUN gem install bundler rubygems-bundler --no-rdoc --no-ri

# Preinstall majority of gems
WORKDIR /tmp 
ADD ./Gemfile Gemfile
ADD ./Gemfile.lock Gemfile.lock
RUN bundle install 

RUN apt-get install cron -y

RUN touch /cron_log.log

ADD . /app

CMD /app/start.sh
```

The start.sh script

``` bash
cd /app && bundle exec whenever --update-crontab
tail -f /cron_log.log &
cron -f
```

The schedule.rb file:

