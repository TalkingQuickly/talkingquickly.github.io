---
layout: post
title: "Some unreasonable things I believe about large language models"
date: 2025-08-26
permalink: /unreasonable-things-i-believe-about-llms/
biofooter: true
---

The more I work with large language models, the more blown away I am by how fundamentally I think they're going to change everything about how we build software. 

Belief and intuition are words engineering and science often object to.

But startups are as much about belief and intuition as they are data; by the time it's proven with data, the opportunity is gone.

So I can't prove any of the below, but based on a year of being deeply immersed in building with AI, I'd happily bet large sums of money that these things turn out to be true:

1. Every time you say "models can't / won't be able to do this" you'll be proven wrong within 12 months
2. OK, not every time, just 99% of the time, but there's no upside in being the person who says "this won't work", and lots of upside in being the person who proves that it can. So if you want to do interesting work that makes a difference in the world, be that person
3. "What if I just let the model figure this out" should be the mantra of everyone building software today 
4. LLMs aren't actually much less deterministic than regular software or at least regular software development, so a good answer to a lot of the "how do we make sure the model…" is just "you don't" (but yes, you still need evals!)
5. A disproportionate number of tasks we use traditional ML for will turn out to be replaced by LLMs 
6. The ML tasks that aren't will be largely replaced by LLMs writing and maintaining their own ML sub agents, this will happen bit by bit then all at once 
7. Large language models are already "better" at writing code than people (quality, maintainability, understandability, convention following etc.)
8. Pretty much every example of "models can't write this type of code" is just an instance of "the user hasn't learned how to use models for this yet" 
9. The actual speed up available to developers using LLMs as they are today with no further improvement is closer to 10x than 2x, pretty much irrespective of task, the difference is purely down to the level of investment that's been made in learning the tools 
10. The exception to that is that some codebases need re-engineering to be optimised to prioritise LLMs working on them over people. We should embrace and prioritise this optimisation. Often this will look like moving towards smaller standalone services earlier than we otherwise would have
11. Chat + on demand UIs are going to replace an awful lot of special purpose software
12. Weirdly that will lead to way more software and software engineering jobs not less
13. A disproportionate number of "rules engines" will be replaced with plain text descriptions and LLM harnesses; and they'll work far better than what they replaced

I'm not making any attempt to refute that the above is somewhat crazy, I just think it's probably true.

If you believe equally crazy things, I'd love to chat, please get in touch.