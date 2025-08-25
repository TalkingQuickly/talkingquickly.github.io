---
layout: post
title: "Conversations as Programming Primitives"
date: 2025-08-24
permalink: /conversations-as-programming-primitives/
biofooter: true
---

Over the last few years a reliable way to be wrong has been to predict "chat won't work as an interface for that" and then wait a few weeks.

So it increasingly looks like conversations as a general purpose user interface are here to stay.

Conversations as a fundamental primitive of programming and data storage have been getting less attention.

An LLM-powered CRM agent which makes recommendations about deals could be built by giving an agent access to tools that query certain data, carefully constructing input prompts and then building checking logic which ensures the agent isn't repeating itself.

This is the traditional model of programming, the LLM is a special purpose tool (like any method) and then we write methods which do other things and chain these together in highly structured ways to achieve (pseudo) predictable outputs.

Another way to build that CRM agent is to write a system prompt along the lines of:

> You're going to receive a stream of messages which are updates on a sales deal. Your job is to provide recommendations by calling the set_recommendations tool, don't repeat yourself too often

Where the set recommendations tool shows the user a list of recommendations. This step being entirely optional, we could just ask for a bulleted list.

This approach has some interesting properties:

- There's not a whole lot of programming going on, we just sort of let the LLM do it 
- We defer the structuring of data until the tool call to turn it into something structured (which we could skip completely and just use bullets)
- As a result of deferred structuring, our data model is "just a bunch of text"

Deferred structuring has some interesting implications for portability, both within a loose application boundary and across unrelated or competing applications.

Since the structuring is deferred until the point of output, putting the data through an alternative process or into another system is relatively easy as long as they can accept conversation text as an input.

If there is some standardization as to a structured or semi-structured representation of a conversation, it becomes entirely trivial.

Which leaves me with two main takeaways:

- Engineers should increasingly be asking themselves "do I really need anything more than a conversation to solve this problem" 
- Ownership and portability of conversation data is going to become as - probably more - important as ownership of structured data

"Let the model do the work" is increasingly becoming a very good rule of thumb.