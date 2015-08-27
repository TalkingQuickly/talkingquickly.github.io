---
layout: page
title: Ben Dixon - CV
---

I'm a senior Ruby/ Rails & Android developer, also proficient in several other languages, I've written production code in Ruby, Java, Javascript, Python, Go, .NET and PHP.

I believe in shipping new features quickly and regularly but without compromising on code quality or test coverage. I generally give greater weight to integration tests than unit tests but see the importance of both.

I primarily work with startups or small companies. Over the last 8 years I've worked as both a contractor and on several startups of my own. I'm the author of "Reliably Deploying Rails Applications" and spoke at Railsconf in 2014 on deployment and in 2015 on integrating Docker with Rails.

I have a technical blog at [www.talkingquickly.co.uk](http://www.talkingquickly.co.uk) where I primarily write about Rails and Docker.

Outside of work I like to climb and travel. I write about travel at [www.talkingquickly.co.uk/travel](http://www.talkingquickly.co.uk/travel).

## Work History - Contracting

### Activeintime 2011 - 2015

Working as a contract senior developer for a health and fitness startup. I had final responsibility for all backend code that went into production and was accountable for the uptime of all backend systems.

#### Ruby on Rails

* Managed and implemented new features for 3 Rails 3.2 applications, one of which is responsible for serving timetables for many of the largest leisure centers in the UK including the London Olympic Pool
* Managed the live migration of a high traffic Rails application - the backend for a major global health and fitness brands mobile App - from Rails 2 to Rails 3
* Ensured the resulting Rails 3 application had, and continues to have, the complete test coverage the Rails 2 application lacked
* Dealt with scaling a Rails 3 application from 10's of requests per minute to 10's per second. This included query optimisation and implementing caching strategies
* Co-ordinated work across a team of 2 - 3 Rails developers to ensure new features were released on time 
* Worked with a mixed stack which included Rails 3.2, Rails 4, Memcached, Redis, MongoDB, MySQL and PostgreSQL

#### Devops

* Managed the migration from Heroku to self managed Linode and Digital Ocean infrastructure of 3 high traffic applications
* Setup Chef based automatic provisioning from scratch including; Rails Frontends, Memcached, Redis, MySQL, PostgreSQL and MongoDB 
* Dealt with the complexities of part hosting applications within China

#### Android

* Developed the companies first Android application from scratch, including integration with the Pebble smart watch

#### Pebble Watch

* Built the prototype application and algorithm for the worlds first swim tracking app on the Pebble Smart Watch. This application used an accelerometer to detect turns when the wearer was swimming and so count laps
* This included developing an internal tool-chain for testing potential lap detection algorithms and co-ordinating with iOS developers to build a fully integrated tool-chain

### Nearest2ThePin.com - 2011

#### Ruby on Rails

* Developed from scratch a Rails 3.2 application to allow golfers to connect with each other. This included instant messaging and geographic search

### Dynamic 50 2010 - 2011

#### Ruby on Rails

* Maintained and developed new features for two high traffic Rails applications for a prominent none governmental organisation 
* Developed plugins for the open source Redmine project management system

## Own Projects

### Online Learn to Code Platform (MakeItWithCode.com), Co-Founder

Created an online e-learning platform for teaching none developers practical Ruby. The technical side consisted of:

* A Rails 4 Appication for delivering course content. This was backed by Postgres and Redis.
* A custom docker orchestration tool (<https://github.com/talkingquickly/dacker>) for creating isolated browser based environments where students could write and run code

In addition to this I was responsible for writing over 30 in depth lessons for beginners learning Ruby. 

### Mousemet Electronic Von Frey (mousemet.com), Software Lead

The Mousemet ([www.mousemet.com](http://www.mousemet.com)) is an instrument used in veterinary science for applying and measuring force very accurately, on the patent for which I'm a named author. My role consisted of:

* Creating the Python based GUI used by researches on a daily basis for interacting with the instruent
* Writing and maintaining the code (a C variant) for the micro-controller which interfaces with the device itself

### Crowsourced Fashion Analytics (ShopOfMe.com), Co-Founder

ShopOfMe was a browser extension (Chrome & Safari) which collected data about items of clothing users viewed online and then alerted them when these items subsequently went on sale. The system consisted of:

* Chrome and Safari extensions written in Javascript. For this we created a custom framework which standardised API's across the two browsers so we could work from a completely common codebase and efficiently maintain feature parity between the two
* A Postgres backed Rails 3.2 application for collecting the data from the extension
* A second Postgres backed Rails 3.2 application which was responsible for scraping item pages regularly and selecting which users should be alerted when prices went down

At it's peak ShopOfMe handled ~200 requests/ second and stored around 5.2 million datapoints of items users had viewed.

### SaaS based Guidebooks (InGuide), Co-Founder

A self service guidebook platform which allowed art galleries and museums to enter data about their exhibits and then have Android and iOS users access this in guidebook format from our single app. The system consisted of:

* A Rails 3.2 application providing a CMS to galleries and museums where they could enter data about exhibits and the venue structure.
* An initial Phonegap and later Titanium based iOS and Android app for accessing the above Rails app's API and displaying the guidebook to a user. The app featured a compass based orientation feature so a visitor could hold up the guidebook and have a virtual wall move with them to match what they were looking at

## Previous Employment

### PwC - Management Consultant

Providing management consultancy services to large companies, key roles included:

* The day to day management of the project management office for a change program in one one of the UK's largest construction companies
* Building and maintaining internal MI systems
* Modeling pricing scenarios for a large UK telecoms provider and creating tools to allow none technical staff to continue creating such models

### Thorlabs - .NET Developer

Creating software in .NET to calibrate and analyse the behavior of high precision movement systems.

## Getting in touch

Please email [ben@talkingquickly.co.uk](mailto:ben@talkingquickly.co.uk).

My Github is [github.com/talkingquickly](https://github.com/talkingquickly).

I'm also active on twitter as [@talkingquickly](http://www.twitter.com/talkingquickly).

## Recruiters

Please get in touch via email in the first instance. Please do not pass this CV onto anybody without my prior approval.
