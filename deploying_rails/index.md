---
layout: page
title: Deploying Rails
---

Resources from the Railsconf 2014 Presentation by Ben Dixon ([@talkingquickly](http://www.twitter.com/talkingquickly))

<iframe width="560" height="315" src="//www.youtube.com/embed/hTofBnxyBUU" frameborder="0" allowfullscreen></iframe>

### Provisioning a VPS for a rails application. 

This tutorial covers how to use Chef Solo to prepare a Digital Ocean, Linode or Rackspace cloud VPS for deployment of a Rails VPS. Estimated completion time: 1 hour.

[Setting up a Rails VPS with Chef](/2013/09/using-chef-to-provision-a-rails-and-postgres-server/)

### Using Capistrano 3 to deploy to a VPS. 

This tutorial covers using Capistrano 3 to deploy a new or existing Rails 3 or 4 application to a VPS which has been prepared using the previous tutorial. Estimated completion time: 30 minutes.

[Deploying With Capistrano 3](/2014/01/deploying-rails-apps-to-a-vps-with-capistrano-v3/)

## Code

### Chef Solo Sample Code.

This is the sample code for the provisioning tutorial above, it is the base code which I use for deploying many different Rails and Sinatra applications on a daily basis.

<https://github.com/TalkingQuickly/rails-server-template>

### Capistrano 3 Sample Code

This is the sample code for the Capistrano 3 Tutorial above.

<https://github.com/TalkingQuickly/capistrano-3-rails-template>

All of the helper tasks as well as some extra ones are also available packaged into a gem:

<https://github.com/TalkingQuickly/capistrano-cookbook>

## Further Reading

The Reliably Deploying Rails Applications book builds on exactly the same sample code as the above tutorials and covers the detail of how to create your own chef recipes, setup and debug zero downtime deployment and automate day to day maintenance tasks.

<https://leanpub.com/deploying_rails_applications>

Until the end of May it's available to attendees of Railsconf 2014 at a discount using this link:

<http://leanpub.com/deploying_rails_applications/c/railsconf>

Feel free to get in touch on twitter <http://www.twitter.com/talkingquickly> with any questions.