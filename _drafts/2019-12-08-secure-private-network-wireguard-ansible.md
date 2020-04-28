---
layout : post
title: A secure private network with Wireguard and Ansible
date: 2019-12-08
categories: devops ansible wireguard
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: /secure-private-network-wireguard-and-ansible
---

Wireguard allows us to create on the fly, secure, networks. We can use this when working with multiple servers to establish a trusted, encrypted network between peers rather than trusting the network which is available. This post demonstrates how to setup such a network using Ansible, the main difference between this configuration and many others available online is that this one allows adding and removing peers without downtime.

<!--more-->

This has become my preferred approach when working with Virtual Private Servers on any provider. Rather than trusting their internal network and relying on perfect firewall configuration to manage traffic between hosts, I use wireguard to create a trusted network between each server and run all internal traffic on this network. The firewalls on the primary network of each server allow only ports required for external ingress and for the wireguard network itself.

