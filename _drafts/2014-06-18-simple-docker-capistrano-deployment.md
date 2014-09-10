---
layout : post
title: "Simple Docker Based Deployment with Capistrano"
date: 2014-06-18 08:00:00
categories: devops
biofooter: false
bookfooter: false
docker_book_footer: true
---

Docker makes packaging applications into containers incredibly simple but it's often hard to see how these containers fit into our existing workflows. In this tutorial we cover a really simple approach to using Capistrano to deploy an application to a VPS. This example uses a Rails application but a similar approach could be applied to almost any stack.

When first working with Docker it's easy to get overwhelmed by the possibilities and before you know it, you're trying to build a complete PaaS with automated infinitely scalable service discovery. The aim of this tutorial is to provide a simple entry point for beginning to take advantage of Docker.

What it will do:

* Deploy the applications complete environment to a single VPS, including supporting services such as databases
* Use Docker to provide containers which include the runtime environment but not code or data so that the containers can safely be kept on a public registry

What it will not do:

* Work out of the box across multiple servers there will be no automated service discovery or firewall management
* Automate any sort of zero downtime, background startup of the application