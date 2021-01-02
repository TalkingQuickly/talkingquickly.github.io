---
layout : post
title: "The lure of hard easy problems"
date: 2020-11-28 09:00:00
categories: decisionmaking
biofooter: true
bookfooter: false
docker_book_footer: false
---

A matrix I find myself referring to a lot when deciding how to approach a problem is this:

@TODO image

It breaks problems into:

1. Easy to execute, little or no uncertainty (easy easy)
2. Easy to execute, lots of uncertainty (easy hard)
3. Hard to execute, lots of uncertainty (hard hard) 
2. Hard to execute, little or no uncertainty (hard easy)

tldr; solving hard-easy problems, while fun, is almost always time consuming and generally only value-creating when done it such a way that the solutions are re-usable by others or that we learn something we can later leverage.

<!--more-->

## Easy Easy problems

Easy to execute, low uncertainty problems almost don't qualify as problems. Some typical examples would be:

- Implementing sign in for a web application
- Attaching a shelf to a wall
- Cooking fajitas from a "make your own fajitas" kit

These types of problem are typically fully commoditised and easily outsourced. It can be satisfying to "solve" these kinds of problems - which in many spheres is reason enough to do so - but they very rarely lead to the creation of anything new. When optimising for return on time, this kind of problem is rarely a good place to invest significant amounts of time.

## Easy hard problems

Easy to execute, high uncertainty problems are relatively rare. Or at least it's often hard to categorise a problem into this quadrant prior to it being solved because by definition the work that needs to be done is partly or largely unknown.

## Hard Hard problems

Hard to execute, high uncertainty problems are where new ground is broken. Many of the most successful startups (but importantly by no means most startups) have a hard hard problem at their core. Electric vehicles, space travel and human longevity focussed ventures are the classic examples of this type of problem but equally niche problems such as classifying someone's language ability from a thirty second recording or fully automating package upgrades in production systems would likely fall into this category.

## Hard easy problems

Hard to execute, low uncertainty problems are abundant, especially in technology. Some examples of hard-easy problems would be:

- Deploying and maintaining a Kubernetes cluster and supporting services
- Building and administering a VPS hosting service from scratch
- Building a boat from scratch
- Becoming good at a sport

These types of problem are generally relatively easy to outsource although relatively expensive compared to easy easy problems. 

## Hard-easy problems as sources of value

Hard easy problems - specifically crafting solutions which are re-usable can be an excellent avenue for building businesses. By definition solving hard-easy problems yourself tends to be time consuming, and so unless such a problem is core to what you're trying to achieve, you're likely to be prepared to pay somebody else to solve it for you as long as the all-in cost is lower than solving it yourself.

Hosting - all the way from AWS to Hetzner - is a great example of solving a hard-easy problem. Most competent engineers could - given some time to research it - deploy a Hypervisor, install a database server, add some monitoring etc. But if all we do is solve this problem for ourselves, then nothing new has been created and so we've created very little new value.

When somebody creates a hosting company, they create an abstraction over the hard-easy problem of managing common types of server and services, which allows their single solution to be re-used by many people.

Generally if we can create a solution to a hard-easy problem which is usable by others as a direct replacement for them solving it themselves, then something valuable has been created.

The most obvious form of value is cash in the form of creating a business. The entire SaaS industry is primarily focussed on taking hard easy problems and solving them with software which we then pay a subscription to access.

But valuable doesn't need to mean cash generative. In the engineering world, one of the most common examples is open source libraries. Creating a wrapper for language X around a complex API may well be a hard-easy problem; you first have to understand the API, how it handles errors, it's possible response types and so-on, and then translate that into primitives which make sense in the chosen language, but there's little or no un-certainty that it's possible or about the approximate steps that are involved.

Blog posts are one of the simplest and smallest examples of hard-easy problems as sources of value. If I look at my most-read posts, many of them are technical tutorials which explain how to solve a hard-easy problem (e.g. deploying rails to a VPS or using a pre-made Arduino EKG shield). I'd imagine that many of the people reading them could have solved them directly, but the blog post allowed them to solve them more quickly (creating value for them) and some of those people signed up to by mailing list, bought my book or started an interesting conversation with me (creating value for me). 

## Hard-easy problems as addictive time sinks

Solving hard-easy problems can also be dangerously fun. In addition to managing Kubernetes clusters; computer games, sports, sudoku and crosswords are all examples of hard-easy problems. They require significant mental and/ or physical exertion to solve and as a result of being hard, to many driven, intelligent individuals, this gives a strong sense of satisfaction when completed. And we know that they can be completed (they easy part of hard-easy), which helps to avoid demotivation.

Re-factoring often falls into this bucket. The value-add from re-factors follows a fairly clear 80/20 distribution, 80% of the value add comes from 20% of the refactors (these 20% should be aggressively prioritised, but that's a different topic). Unfortunately coming up on 100% of refactors are intellectually satisfying. So given an un-pleasant ticket (say something in hard-head territory or even a harder hard-easy problem), it's very easy to be sucked into a satisfying if not especially value adding refactor.

When I spend several hours playing Star Wars Squadrons - despite a few attempts to convince myself it's good for my hand-eye co-ordination - I'm under no illusion that I'm creating value. It's something I do purely for enjoyment. Importantly - at least in my world-view - this doesn't in any way make it a bad way to spend time.

But especially within software engineering, there are a myriad of sudoku-like hard-easy problems we'll be tempted with every day.

## Hard-easy problems as paths to expertise

It's rare to find a hard-hard problem we can just jump into and start solving. Most modern problem solving involves standing on the shoulders of giants, and a great way to fully internalize this knowledge is to spend time solving those already solved problems yourself.

I co-founded Make It With Code - a coding school focussed on teaching by doing - based on exactly this belief; that learning by doing is by far the most effective way to learn. In the case of software that means by actually working out how to build things.

So to take the Kubernetes example, there are currently many un-solved problems, upgrades and persistence would top my list. But to understand that these problems exist let alone have any chance of solving them, you probably first need to develop a deep understanding of the fundamentals of how to deploy and manage a cluster.

Likewise to become a truly innovative chef, you probably need to learn the basics of sautéing, seasoning and chopping before you can go-on to create your own dishes.

## Being deliberate about hard-easy problems

This framework has helped me to be more deliberate about how I approach hard-easy problems, by giving me a way to assess "why" am I investing time into it. Sometimes, be it golf or squadrons, it's just for satisfaction. For some, like Kubernetes, it's both to gain expertise and as a path to create value (blog posts, books, screencasts etc). But for many of them, it's simple inertia, for these the framework allows me to consciously eject and look at whether I can outsource, delegate or avoid solving them entirely.