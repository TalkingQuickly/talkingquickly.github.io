---
layout: post
title: "Vibe coding is real, and that's a good thing"
date: 2024-06-15
permalink: /vibe-coding-is-real/
biofooter: true
---

**tldr;** AI Coding ("vibe coding") is real and it has fundamentally changed what it means to be a software engineer forever.

The single thing that will define which businesses and which engineers are successful over the coming years is how quickly they are able to adapt to this.

This post is a summary of the topics that are coming up again and again when discussing this with other engineers and engineering leaders.

<!--more-->

## What is AI Coding (it's not auto-complete)

By AI coding I'm talking about a dynamic where an engineer builds software by talking in natural language to some sort of software agent; asking it to perform actions that result in the modification of one or more files without specifying exactly what those modifications should be or how they should be made.

So I'm explicitly excluding:

1. AI powered auto complete, even if it's completing whole files
2. Stubbing function heads and having AI fill in the blanks

From this definition of AI coding.

So prompting an AI:

> "Could you modify this to spawn tasks for each item and keep track of the spawned tasks, I've attached a screenshot of what the UI should look like and given you access to both the UI and the underlying interface"

**is** AI coding.

But for the purposes of this post, defining a function head `do_thing_using_async_tasks`, writing comments that explain how it should work then having an AI "fill in the blanks" is **not**.

## The mental model is more important than the tool

When evaluating AI coding, people are spending a lot of time talking about "which tool" and "which model".

For all practical purposes the leading foundation models perform similarly and most of the tools use these foundation models in approximately similar ways. Different tool and model combinations eek out different advantages daily but mastery of a model tool combination is - excluding any as yet unannounced step changes - far more important than picking a model-tool combination. 

The mental model I've found to be most effective for AI coding is that each and every engineer is now pair programming with a new joiner. 

This new joiner is incredibly smart, knows the language and libraries almost perfectly and can **ship code at approximately 50x the speed of a regular engineer**. Importantly we're not talking about typing speed here - very few programmers are constrained by how fast they can type - we're talking about the time taking to move from an abstract idea of wanting to instruct a computer to do something, to having written, iterated on and debugged the code to make it do that thing.

They are exceptionally good at following instructions, matching existing style and reasoning about complex pieces of existing code. 

They have never seen your codebase before and don't know the business domain.

When given new information, they assimilate it quickly, act on it rationally, and then **forget it when they move onto the next task**.

Think Groundhog day meets the best engineer you've ever met.

## Everything is architecture & context management

If you imagine working with this Groundhog day trapped new joiner, how would you get the most out of them?

What they bring to the table is that they can conceptualise and write code 50x faster than you, rarely have to Google anything and do not need to sleep.

What you - as an experienced engineer in that business with that codebase - bring to the table is that you know the codebase and the domain.

So you are positioned to reason about the big picture in the way that they can't.

Specifically your job is:

1. Guide the new joiner towards which parts of the codebase are relevant and which aren't for the current task (constrain context)
2. Think through the current task in the context of the wider system architecture, domain and future plans and constrain options accordingly
3. Provide all of the implicit context around the evolution of the codebase and business which is rarely - if ever - documented anywhere
4. Help the new joiner to understand where existing documentation is and create new documentation where appropriate (build re-usable context)

This is already what most senior engineers are doing when working on code themselves, it's just that currently there's a fifth step; "write and ship code".

AI coding effectively reduces the time and cognitive load of that "write and ship code" step to zero or close to zero allowing for more iterations in a day. 

## Some tools drive the mental model better than others

In particular tools like Cursor and Claude Code have tried to solve the "context discovery" problem as well as the shipping code problem. So they have tried to provide closer to the magic experience of "given a codebase, point me at it, tell me what you want to do and I'll figure out the rest".

This works brilliantly for extremely small codebases with minimal business context and "history driven complexity" encoded into them (and does truly feel like magic when it works).

But most of the complexity of developing good software in the medium term is accurate understanding & communication of product objectives and managing the domain + business history driven complexity, not writing code.

> "Order forms and order sheets are similar right?" Oh no you see actually in this business domain they're completely unrelated concepts, so the `OrderForms` context and the `OrderSheets` contexts have nothing to do with each other. Except...

How well would you expect a senior engineer to do if on day one you gave them access to a git repo, your company wiki and a big feature brief and said "see you in two weeks, don't talk to anyone"? 

AI Coding tools broadly can't currently really do things human engineers can't do. They can just do some of the things human engineers can do MUCH faster. 

Because tools like Cursor and Claude code TRY to solve this context discovery problem, people tend to try and use it (because it would be cool if it worked right?). 

When it doesn't work, it generates frustration - because learning new tools IS frustrating - and so people are disproportionately likely to give up.

I *think* this has led to a lot of the the "AI Coding doesn't work on large codebases" myths. 

Cursor is capable - and extremely good at - allowing the engineer to manage context themselves, it just doesn't make that the path of least resistance. 

Tools which force you to manage context yourself (e.g. Aider) are therefore in my opinion much better for learning the mental model initially.

## Shipping faster? Shipping more? Shipping Better(er)?

AI coding will mean we build more and better software given the same amount of effort but I don't think it's clear yet the balance between:

1. Shipping the same things faster
2. Shipping the same things at higher quality  
3. Shipping more complete things earlier 
4. Shipping more different things

So it's hard to make blanket statements about efficiency. My early intuition is that it's probably more about items 2-4 above than it is item 1.

There'll be some "shipping the same things faster" effect, e.g. maybe it on-average halves the time it currently takes to ship a given roadmap item.

But some large proportion of shipping stuff is thinking and this is also where 90% of the value of a senior engineer sits.

So if you spend two weeks mainly thinking and two weeks mainly building (obviously a gross over simplification), you save most of the two weeks building and the two weeks thinking remains largely intact.

But while you were thinking you probably didn't just think through the first iteration, you thought through some of the first ten iterations then scope hammered heavily to keep the building down to two weeks. You'd probably done enough thinking for ten weeks of building. 

As the building time approaches zero, you "might as well" include some of iterations two to four, so polish that might otherwise be delayed, sometimes indefinitely, will now be included in version ones. 

Similarly the cost (time investment) of refactoring, adding complex detailed test coverage etc is reduced dramatically which will tend to drive up code quality and product quality for the same or lower engineering investment.

But there's some danger that because it's easy to talk about 3-5x productivity improvements - and I think those are achievable with just what's available now - we equate that with "shipping 3-5x of what we currently ship".

And those two things are not the same.

In practice we'll create more (by some multiple) higher quality software. 

Some of that will be by creating what we already create faster, but probably the majority of it will be by creating more things that we otherwise wouldn't have done or by creating higher quality versions of these things.

## Who writes code and code as a communication tool

One of the fundamental (THE fundamental?) challenges of building software businesses is communicating a cohesive vision of a large objective in such a way that many people can work on it in parallel so that it can be achieved far faster than any one person could do it alone.

This is a problem shared across founders, product managers, engineers and solutions range from "talking to each other" to product requirements documents, clickable prototypes and a thousand other tools.

As a technical founder who's spent the last fifteen years building technology companies, probably my single greatest frustration is having spent hundreds of hours with customers and prospects and being able to see in my head the full outline of the next version of the thing we're trying to create and knowing how woefully inadequate conversation and memo's will be as tools to communicate this. 

AI Coding is especially efficient at the POC stage, so a POC which might have taken 3 months in the past may well be achievable in a week.

This includes time spent iterating in realtime on a POC as "using" it helps your thinking to evolve. 

This makes code as a communication tool far more viable. 

So rather than weeks of meetings and memos, creating a POC - sometimes with the intention of throwing it away - will increasingly be the most efficient way for technical - and eventually product - leaders to communicate concepts. 

This probably means technical leaders become "more technical" insofar as they return to being more involved with code.

## Interlude; it gets more speculative from here

Up until here the majority of the points I'm making are just observations, e.g. what I believe the current state based on what currently exists and is happening. The remainder of this piece is more speculative.

## POC's as the new communication standard generally

In the same way AI pair programmers make POC's a far more viable communication tool for engineering leadership, UI based AI programming tools such as Windsurf, DataButton, Lovable etc make this type of POC accessible to none technical folks.

So it will probably become standard that product managers create clickable prototypes in these tools first and iterate on them with designers and engineers and test these with customers, replacing the more traditional memo + designs type model. 

So far nobody (that I know of?) has successfully bridged the gap between these UI based tools and complex codebases (probably for the context reasons mentioned above) so there's likely to remain separation in the tools used here until somebody makes progress on that.

## Codebases will have to adapt, not the other way around

Realistically most companies - or at least startups - should expect that the amount of their new code which is written by AI will cross 50% in the next 6 months and 80% in the next 12 months. Any company not on this trajectory risks being left behind by competitors who do manage to adapt.

So practically the primary user of the codebase becomes AI tooling with humans a secondary consumer.

This means that in situations where there is a tension between something that makes the codebase better for humans and better for AI, we should choose the thing that makes it better for AI. So the trend will be as much about patterns in codebases developing to support the tooling as it will the other way around.

The good news is that in the vast majority of cases, things that make codebases better for AI's also make them better for humans so this conflict will be rare.

But it may accelerate certain optimisations. E.g. a small team of REALLY good engineers can often paper over a lot of technical debt just by virtue of being incredibly good at reasoning about something which is becoming hard to reason about.

The improved performance of AI once the technical debt is paid back, combined with it being faster to pay it back using AI, may make these types of projects viable sooner.

A specific example of that is clear separation of concerns and enforced boundaries. Separation of concerns and enforced boundaries are to an extent just a formalised way of constraining context, and AI performs far better when context is constrained (as do people).

So we may well see startups prioritising refactoring, technical debt payback and putting in strict rules about code boundaries earlier than they otherwise and historically would.

## Beware intuition over data

AI coding is so new and so different that it breaks most of the existing mental models for what's possible.

So if someone has spent less than 100-200 hours exclusively writing code by collaborating with an AI agent, most of their mental models of what will work and what won't are simply wrong by virtue of lack of information.

A disproportionate quantity of the objections about "why AI coding won't work" come from people in the 0-10 hour range. 

So it's worth building a culture of having people disclose their level of exposure early in conversations and discounting the "haven't really tried it yet" groups views heavily. Of course do so compassionately, but don't confuse fear based reactions with valid data.

Counterintuitively the main reason to do this is so that you DO hear about the valid objections. There are plenty of things that genuinely don't work well yet and understanding and discussing those limitations is an important part of adoption. But often they are lost in the noise of broadly incorrect objections from people without sufficient data.

## Push & Pull people up the adoption curve

In practice the job of every engineer has now changed.

The part that was about writing code (and that **IS** only part of it) is now mainly about instructing AI tools to write code.

I don't think it's realistic that there are many engineering jobs two years from now where the expectation is anything other than this e.g. that it's possible to have those jobs without being an expert in instructing AI tools to write code.

So assuming people want to continue to be software engineers - and I hope they do because coding with AI is SO MUCH more fun than coding without it - learning this skill isn't really optional. 

Some people will naturally dive into this head first and enthusiastically, some will need a nudge, some will completely refuse.

It's important to create an environment where it's easy for those who want to experiment to try things and share their experiences.

Having clear policies (and budget) around which tools and which models helps a lot. As does encouraging people to explain their experiences, both good and bad to wider teams.

For the people who need a nudge and those who completely refuse to engage, it's important to be transparent about what's at stake.

In the same way most people will be fairly reluctant to hire an engineer who wants to build a typical webapp purely in C, people will soon be reluctant to hire engineers who don't know how to leverage these tools. So there's a definite risk of being left behind.

## The craft lives on

Whenever there is a new abstraction invented for creating software people lament the end of writing software as a craft. 

As with every other iteration, it wasn't true then and it isn't true now.

I've always written code for fun as well as for work. I write slightly different code for fun than for work and these days spend more of my time at work collaborating with other engineers than I do shipping code myself.

But using AI tools to write code has made both worlds more fun.

Moving from Basic to Delphi to PHP to Ruby to Elixir over the last 25 years has at each stage, allowed me to realise the visions for things I wanted to exist in the world more fully and often more quickly.

AI coding is just one more step on this journey and I've never been more excited.

Every engineer deserves to experience the moment when by collaborating with an AI, something that would have taken them a week, takes an hour.

It's genuinely the closest thing to magic I've felt in decades.
