---
layout: page
title: Resources for learning to deploy Rails Applications
redirect_from:
  - /resources-for-learning-to-deploy-rails-applications/
---
This is a general collection of links I’ve found useful when learning how to deploy Rails applications, updated regularly as and when I find new things.

### Provisioning without Configuration Management

(I don’t recommend this for anything except learning and experimenting)

<http://railscasts.com/episodes/335-deploying-to-a-vps>

A pattern for deploying a Rails app to a VPS using nginx, Unicorn, PostgreSQL, rbenv (Pro)

<https://ariejan.net/2011/09/14/lighting-fast-zero-downtime-deployments-with-git-capistrano-nginx-and-unicorn/>

Based on and older version of Ubuntu (11.04) but still some good tips

### Chef

<http://docs.opscode.com/chef_solo.html>

Official chef solo documentation

<http://railscasts.com/episodes/339-chef-solo-basics>

Basic of using Chef Solo (pro)

<https://github.com/matschaffer/knife-solo>

Official Knife solo docs, adds some extra commands to knife (the CLI for chef interactions) so you can use it with chef solo.

<http://www.talkingquickly.co.uk/2013/09/using-chef-to-provision-a-rails-and-postgres-server/>

Guide with sample code for automating the provisioning of a Rails server with Postgres (example code allows DB to be swapped for Mongo/ MySQL)

### Puppet

<https://github.com/railsmachine/moonshine/>

Moonshine provides an easy to use layer on top of Puppet and Capistrano to automate application and deployment. Not one I use myself as it blurs the line between provisioning and deployment somewhat.

### Zero Downtime Deployment with Unicorn

<http://railscasts.com/episodes/373-zero-downtime-deployment?view=comments>

Pro Railscast on Zero Downtime Deployment.with Unicorn

<https://github.com/blog/517-unicorn>

Why Github switched to Unicorn

Also see the Monit section below on monitoring unicorn workers

### Choosing an Application Server

<http://stackoverflow.com/questions/4113299/ruby-on-rails-server-options/4113570#4113570>

Very detailed comparison of Rails App Servers (Unicorn, Thin, Webrick, Phusion Pasenger etc)

### VPS providers

Recommendations (Order of Preference)

1) Linode

2) Digital Ocean

3) Rackspace Cloud (for none CPU bound apps)

<http://www.reddit.com/r/rails/comments/1mk2mq/deploying_on_ec2_micro_instances/>

Thread about trying to deploy Rails on EC2 Micro Instances. It’s possible but just don’t, life’s too short. They’re so CPU constrained it’s like watching paint dry.

### Misc

<http://viget.com/extend/server-maintenance-mode-for-rails-capistrano-and-apache2>

Adding a “maintenance” page you can switch on and off to Apache

### Container Based Deployment (The Future?)

<http://www.docker.io/>

Fascinating and rapidly developing open source project for packaging individual server components in lightweight re-usable ‘containers.’ Still quite new in the Rails world but has the potential to complete change how we deploy.

<https://github.com/progrium/dokku>

Dokku, personal mini Heroku powered by Docker

<http://theflyingdeveloper.com/host-and-deploy-your-next-rails-project-with-dokku/#.Umo5vz5ga_R>

Tutorial on using Dokku to deploy a rails app

### Installing Ruby

<http://nicknotfound.com/2013/03/21/switching-from-rvm-to-rbenv-on-a-production-server/>

Comprehensive guide to switching from rvm to rbenv on a production server. I’d recommend doing a complete rebuild with some sort of configuration management tool in this scenario but very useful if this isn’t an option for you. Goes into a lot of detail on dealing with $PATH, cron jobs, and making sure it plays nicely with Unicorn and Capistrano.

<https://github.com/sstephenson/rbenv/wiki/Deploying-with-rbenv>

### Monit

<http://shapeshed.com/managing-unicorn-workers-with-monit/>

Comprehensive guide to monitoring Unicorn worker processes with monit

<http://www.stopdropandrew.com/2010/06/01/where-unicorns-go-to-die-watching-unicorn-workers-with-monit.html>

Simple solution to watching individual unicorn worker processes

### More information

My book, “[Reliably Deploying Rails Applications](https://leanpub.com/deploying_rails_applications)” is available on Leanpub.
