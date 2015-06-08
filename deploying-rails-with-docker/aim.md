# Deploying Rails With Docker

## What are we trying to achieve

- Quick and easy to deploy Rails (and any other web apps) to a shared cluster of nodes
- As much as possible use first party (e.g. official Docker tooling)
- Minimal supporting infrastructure (e.g. distributed key value stores, custom DNS etc)
- Something which is easy to build on later if we want to get more advanced (automated service discovery etc)
- Identical production and dev environment
- Fairly simple and quick horizontal scaling
- Able to run 10's of applications of 10's of nodes

## What we are not trying to achieve

This section is probably more important than what we are trying to achieve. Docker makes it incredibly tempting to do everything. Before I knew it, my first attempt to come up with a workable way to deploy Rails with Docker involved etcd, coreos, dynamic proxies, fully automated service discovery, command line scaling, you name it.

By the end my "infrastructure" was probably more complicated than the applications I was deploying to it. This was both overkill and a disaster waiting to happen. If our current position is one or more servers which we provision using some sort of configuration management tool (or heaven forbid, by hand), and then deploy to with Capistrano, our first attempt to adapt to containeristaion should, in my opinion, be similar to that, but noticeably easier. This leaves us free to iterate in future if something more advanced is needed.

So we are specifically not:

- Building a complete PaaS
	- So we will not have automated service discovery
	- And we will not have automated scaling (although horizontally scaling must be trivial)
- Running 100's or 1000's of applications over 100's or 1000's of nodes
- Designing for untrusted, multi tenancy. We are the users of our cluster. If someone can deploy to the cluster, we broadly trust them
