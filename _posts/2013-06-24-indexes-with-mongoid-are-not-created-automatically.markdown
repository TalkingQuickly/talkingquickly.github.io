---
layout : post
title: "Indexes with Mongoid are not created automatically"
date: 2013-06-26 11:34:00
categories: rails devops
biofooter: false
bookfooter: true
---

When coming from Mongoid from an Activerecord background, there are some
subtle differences around uniqueness and indexes which can cause hard to
debug problems.

<!--more-->

If you’re used to standard Active Record, then you’d expect the following:

``` ruby
validates_uniqueness_of :attribute
```

To throw an exception if you try to persist a model with a duplicate value for attribute. That comes with its own gotchas, in particular that the constraint exists at the ORM level not database level making it possible to create duplicate entries in specific race conditions. Mongoid has a gotcha of its own. It’s easy to assume that adding the following to a Mongoid document:

``` ruby
index({attribute: 1}, {unique: true})
```

will operate in the same way as `validates_uniqueness_of`.

It doesn’t.

What it does is tell Mongoid that there should be an index on “attribute” and that it should only allow unique values. It does not create this index. If you simple add that line, it will still be possible to create duplicate values for the attribute.

In order to have the index constraints enforced you must first create it using:

``` ruby
rake db:mongoid:create_indexes
```

This gotcha is particularly easy to get caught out by when deploying. A developer may add the index to the document, create the index on his local machine and commit the change. When it is deployed however, the index will not exist on production and so duplicate records can be created.

In traditional Active Record this problem was less common as migrations are usually run as part of the deployment process which includes index generation. If you’re deploying a mongoid application in production with Capistrano, it’s worth adding the above index generation command as an extra task, triggered by `after: update`
