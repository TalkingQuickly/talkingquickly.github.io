---
layout : post
title: "Integrations are hard"
date: 2024-02-07 15:40:00
categories: culture
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/integrations'
---

Best in breed procurement, where many systems - the best in class for each system - are procured independently then integrated with one another has had a tricky decade.

The underlying principle was good. Take lots of vendors who do just one thing really well and connect them to one another to form one fully integrated super system. 

But multiple studies suggest that 70-85% of the integration projects which are essential to make these systems work together fail to achieve their objectives.

This post looks at what it’s necessary to consider to avoid these failures, especially in the workforce management space and breaks out specific things to explore when considering an integration project.

<!--more-->

## Which system owns which data (“source of truth”)?
If you’ve ever been part of a project where there was no central project tracking, instead everyone kept their own todo lists and then met periodically to talk about what had been done and what needed to be done then you’re probably experienced the source of truth problem.

Different people have different ideas about the state of individual tasks, in-between alignment sessions several people may try and work on the same task or change the same document and it becomes incredibly difficult to work out what the true state of the project is at any given time.

Integrations can suffer from the same problem. If there are two places where someone can book holiday and they have different data about one persons holiday bookings, which one is true?

So one of the most fundamentals requirements for a successful integration strategy is being completely clear on which systems are the “source of truth” or owners of each piece or category of data.

Only the source of truth system generally stores this data and is responsible for defining the interface by which other systems can alter and perform workflows against it.

## Which system owns which workflows?
In the same way data being in multiple places can cause problems, workflows spanning multiple systems or worse being duplicated across system can cause substantial problems.

Imagine a system where people are asked to go to one place to build their roster and another to approve timesheets. To approve timesheets they need to open the roster in another system and manually compare timesheets to the roster.

In this example it’s not impossible, but it is painful. If your goal is to get company wide engagement with a technology programme, it’s friction like this that will stop it from happening.

If you take it one step further you can imagine a system where people are asked to put availability into one system, holiday into another and sickness into another.

People being people, they will forget which system they need to go to for what, especially for workflows they don’t have to do very often. 

In the best case scenario here this drives up queries to internal support desks. In the worst case scenario it will drive down compliance and usage of the newly rolled out technology, directly preventing the technology programme from reaching and demonstrating it’s goals.

A good rule of thumb is that somebody shouldn’t need to change systems part way through a workflow and generally shouldn’t need to overtly access multiple systems to complete a single task. 

## Big pieces vs small pieces
It can be tempting to read the above and think “great, so we’ll just create a 1000 line spreadsheet of all our data and all our workflows and decide on the owner, job done”. I’ve seen this approach multiple times at an impressive level of detail!

The problem with this is that data has dependencies. Yes it’s theoretically possible to store a users national insurance number and address in two separate systems. But in practice the unit of data you’ll most often want to work with is “user data”, not “national insurance numbers”. And changing address or national insurance number may mutually have implications for the payroll system.

In general when defining sources for truth for both data and workflows, try and work with big pieces not small pieces.

Another example is holiday & sickness. It’s tempting to think of these as separate things which could sit in different systems. In practice sickness can impact holiday and vice versa so splitting them is generally a challenging process. It’s far better to think in terms of “absence” as an overall concept.

## User Interface vs Data Integrations
So far we’ve primarily talked about data. About which systems own data and perform workflows against that data. 

Another type of integration is a user interface integration. Where you want to take an existing system and include the user interface of another system in it so that the user feels like they’re doing everything in one piece of software.

An important thing to be aware of is that this is very hard to do at the level of “parts” of a screen. 

There are no standard or easy ways of modifying the user interface of a piece of software to include the user interface of another alongside it.

If a piece of software already has a box where some information is displayed and you want the information in that box to come from another system, that’s fine, that’s a data integration, the box is already there. 

If you want to take the box from another piece of software, maybe including some buttons and “embed” it in the interface of another piece of software alongside their existing interface, expect this to be hard and expensive and for the results to feel somewhat clunky.

The main exception to this is where vendors have a deep partnership with one another and so typically one vendor has actually replicated the UI of the other product in their own. This is expensive for the vendor to do and so is rarely done for any one customer, instead it is done when those vendors have some form of ongoing strategic partnership.

There are two intermediate steps which are possible:

1. “Iframing”  Is a way to define a rectangular area of a webpage or web app and have another webpage or web app appear in that rectangular box. This can work as an approach where your goal is “I want someone to access a different system from within the first system without needing to change pages”. There’s no deep UI integration here, it just saves people going to a different page or screen.
2. Single Sign On allows you to have users click on a link to another piece of software and be automatically signed in rather than having to login manually. This can have an extremely positive impact on engagement as people drop off surprisingly heavily when asked to login. If all systems are white labelled this can lead to a near seamless experience if the goal is simply to make moving between systems easier.

Importantly both iframeing and SSO can be good solutions, it’s just important to be clear what you’re getting when discussing a UI integration because there’s far more variability in what this could mean than there is for data integrations.

It’s an unfortunate truth that deep UI integration between multiple systems remains a largely unsolved problem in software. It’s a technically hard problem and it’s not for lack of trying that it hasn’t been solved in the industry.

## Read vs write, one way vs two way
A simple but important distinction is read vs write integrations.

In a read integration, one system needs to get data from another system for storage or display. It has no need to ever change this data and push those changes back into the original system. 

It either needs to do this once (e.g. an Applicant Tracking  System integration) or repeatedly (e.g. when pulling daily forecasts in).

This is typically simpler and less error prone than an integration that needs to pull data in, manipulate it and then push data back out again (write / two way).

## Data Warehouse Integrations
An important sub-category of integration are data warehouse integrations.

A data warehouse is when an organisation has a single central location they collate all of their data, typically for the purposes of reporting and analytics.

If an organisation has a data warehouse initiative, it’s common for it to be a requirement that all vendors can provide a way to get raw data out of the vendors system and into the 

Generally the onus is on the vendor to provide a standard method for accessing this data, typically via either direct access to a database or API. 

How this gets from this standard interface to the customer data warehouse generally sits with the customer.

Typical options for this include:

1. Many vendors will build a further bridge between their standard interface and the customer data warehouse for a fee
2. Many data warehouse vendors offer some form of integration service
3. There are third parties which specialise entirely in building data warehouse connectors
4. There are third parties who maintain huge libraries of data warehouse connectors for common vendors

It is a huge red flag if a vendor refuses to provide data warehouse access to customers. 
## Push vs Pull
Push vs pull is terminology that gets used to describe whether one vendor “pushes” data in or the other vendor “pulls” it out. It’s helpful as a short-hand when combined with read vs write above but it tends to mix a few different concepts:

1. Who builds & owns the integration
2. Which company’s interfaces are used to build the integration
3. How is the data transfer actually triggered

We’ll look at each of these individually.
## Who builds and owns the integration?
A typical integration will involve somebody writing some “glue” code to link the two systems together, the options for this are typically:

1. The vendors already have a “deep” integration which they commit to supporting. It’s worth asking more about this relationship as generally one vendor will have assumed responsibility for the technical work of maintaining the integration and so be your point of contact if something goes wrong
2. The integration is being built by one of the vendors specifically for this client. In this case it’s worth drilling into whether the other vendor has committed to providing the resources and technical functionality and being looped into this process as most integrations require mutual co-operation and commitment of resource.
3. The integration is being build by a third party company commissioned by the client. This gives the client more control but it’s essential to ensure costs and resource commitments from the vendors are agreed upfront because a third party building the integration does not mean no costs or resource requirements from the vendors.
4. The integration is being built in-house. If an organisation has the capability to do this, this is extremely powerful subject to the maintenance point below. 

In all of these situations it’s essential to be clear on where the responsibility for maintaining the integration over-time sits.

As with any software initiative, more of the lifetime cost will sit in maintenance rather than implementation so understanding how this will work is as important as understanding how it will get built to begin with.

## Which company’s interfaces are used to build the integration?
Companies generally talk about having API’s - Application Programming Interfaces - which are tools for software systems to communicate with each other. There are broadly two core models for an integration:

1. One vendor uses the others API 
2. The two vendors API’s are linked together with “glue” code

Both are valid approaches, increasingly (2) is preferred because of the standardisation which this enables. 

It’s important before commencing a project to understand if the vendors have the required interfaces for the integration request and where they don’t, to have commitments to build these.

## What about CSV’s
CSV’s are one of the oldest data transfer methods still in-use. A CSV is essentially a human readable text file of data. There can be some snobbery about CSV’s along the lines of “but it’s not an API”.

CSV’s are incredibly powerful, it’s an integration method that is disproportionately well supported across many systems and fairly easy to automate and debug.

So especially for simple one way integrations, CSV’s should not be overlooked or excluded on the basis that API’s are in some way “better”.

## How is the data transfer actually triggered (technical)
There are three technical concepts which come up and cause confusion. 

1. **API**: This is the grouping for the endpoints and webhooks which make up a vendors interface for building integrations
2. **Endpoints**: API Endpoints are web addresses that a third party can request data from or send data to
3. **Webhooks**: These allow one system to “notify” another system when something happens instead of that system having to “ask”. Put the other way, this allows one system to “subscribe” to be told about changes from the other.

A typical integration will use both endpoints and webhooks and a Webhook from Vendor 1 may be configured to “call” an “Endpoint” from Vendor 2. The distinction is not important from the perspective of agreeing an integration and this is only covered here because mis-use of this terminology drives a surprising amount of confusion. 

## Conclusion
In the end it’s up to software vendors to be both flexible and honest to facilitate successful integration programmes. 

Deep cross vendor UI integration is still a largely unsolved problem and so we should exercise skepticism when anyone claims to have solved it.

Best of breed is by no means dead, but the pieces are going to be bigger and so the number of vendors smaller as we learn more and more about where it’s practical to draw integration boundaries and where it isn’t. 