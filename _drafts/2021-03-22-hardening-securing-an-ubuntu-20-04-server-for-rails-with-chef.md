---
layout : post
title: Hardening & Securing an Ubuntu 20.04 server for Rails deployment with Chef
date: 2021-03-22 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/hardening-securing-an-ubuntu-20-04-server-for-rails-with-chef'
---

There's nothing worse than waking up in the middle of the night to a message from your hosting provider that malicious activity has been detected from one of your servers. As a rule the only solution is to immediately shutdown the server and stand up a new one. But without proper hardening, it's likely the new server will experience the same fate in little or no time. From the moment a server is publicly accessible it will be probed by numerous automatic scans looking for security vulnerabilities. The good news is that with a few simple steps, we can sleep soundly knowing that our server is secured.

- Enable UFW
- Disable SSH password access
- Enable fail2ban
- Setup unattended upgrades
- Limit sudo to certain users
- Only allow passwordless sudo for deployment commands; https://capistranorb.com/documentation/getting-started/authentication-and-authorisation/#authorisation & https://unix.stackexchange.com/questions/192706/how-could-we-allow-non-root-users-to-control-a-systemd-service
- Use the user space systemd for deployment commands so that they don't need root access