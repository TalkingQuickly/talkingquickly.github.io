---
layout : post
title: Deploying Rails to a VPS with Capistrano
date: 2021-04-04 15:40:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
permalink: '/deploying-rails-to-a-vps-with-capistrano-and-systemd'
---

Deploying Rails to a VPS with Capistrano remains one of the simplest and most reliable methods for getting a Rails app up-and running. With the likes of Hetzner Cloud, Digital Ocean and Linode providing inexpensive, reliable virtual machines, Rails app serving substantial amounts of traffic can be hosted with minimal cost and complexity.

We'll first use Chef to provision a VPS including securing and hardening the server, installing the correct Ruby version(s) and setting up Postgres and Redis. We'll then use Capistrano to deploy our Rails app, including appropriate systemd units to ensure our services are started automatically on boot and automatic SSL with LetsEncrypt.

This tutorial is in two parts:

- [Setting up a VPS for Rails app Deployment](/setting-up-ubuntu-20-04-for-rails-app-deployment)
- **[Deploying Rails to Ubuntu 20.04 with Capistrano](/deploying-rails-to-a-vps-with-capistrano-and-systemd)**

<!--more-->

Note that this post is intended to be a tutorial rather than a reference, so the focus will be on the steps that need to be completed rather than exploring the why.

## ReCap

## Setting up DNS



