---
layout : post
title: "Rails Development with Docker Compose"
date: 2017-12-27 08:00:00
categories: rails devops docker
biofooter: true
bookfooter: false
docker_book_footer: true
---

I've been keen on Docker since it was first released, but for many
things it's felt like it wasn't quite ready, like it wasn't really
making things easier. Docker with Docker Compose has now reached the
point where I find it dramtically easier and faster to get a
development environment up and running with Docker Compose than I do a
traditional local setup.

This post explains a fairly typical Docker Compose setup, along with
some tweaks which make development more efficient and lay the groundwork
for re-using the configuration for production deployment. Production
deployment using a Compose file and Docker swarm will be covered in a
separate post.

For completeness, this post includes generating a new Rails application
using Docker, so that it's never required to have Rails installed
locally. This is completely optional and everything works the same if
adding to an existing Rails application.

This article is written for OSX but should work nearly identically on
any platform which has Docker available.

## Installing Docker

Installation instructions are [Provided by
Docker Here](https://docs.docker.com/engine/installation/) so I won't
replicate them. You can check if Docker is installed by entering:

```
docker --version
```

As long as you get output similar to:

```
Docker version 17.09.0-ce, build afdb6d4
```

Rather than `command not found` then you're good to go.

## The Dockerfile

If you're working with an existing Rails project then simply add the
following file to the root of your project.

If you're planning on starting a new project then create a new empty
folder and put the `Dockerfile` in there.

```
FROM ruby:2.4.2
MAINTAINER ben@talkingquickly.co.uk

# Install apt based dependencies required to run Rails as
# well as RubyGems. As the Ruby image itself is based on a
# Debian image, we use apt-get to install those.
RUN apt-get update && apt-get install -y \ 
  build-essential \ 
  nodejs


# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
RUN mkdir -p /app
WORKDIR /app

# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY . /app
```

This is a fairly standard `Dockerfile` for a Ruby application, the main
point to note is that we copy the `Gemfile` and `Gemfile.lock` into the
container and then install gems before we copy the rest of the apps
files in.

This is because Docker builds containers in layers, one per line. If
there have been no relevant changes since the last time a layer is
built, then a cached version will be used. But if any layer has changed,
all subsequent layers must be rebuilt.

By copying the `Gemfile` and `Gemfile.lock` in separately, whenever we
re-build our image to include the new application code, we only need to
re-install Gems if the `Gemfile` or `Gemfile.lock` have been changed.
This makes the process of building new images much faster.

## The Compose File

The `Dockerfile` tells Docker how to create an image for running our
Rails application. The Compose file defines what else needs to be
running for our application to work (for example a database server) and
how to create these and link them together.

Like the `Dockerfile`, this `docker-compose.yml` file should be placed
in the root folder of your project:

```
version: "3"
services:
  app:
    build: .
    command: rails server -p 3000 -b '0.0.0.0'
    volumes:
      - .:/app:delegated
    ports:
      - "3000:3000"
    links:
      - postgres
      - redis

  postgres:
    image: postgres
    volumes:
      - postgresdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis
    command: redis-server --appendonly yes
    volumes:
      - redisdata:/data
    ports:
      - "6379:6379"

volumes:
  postgresdata:
  redisdata:
```

### Services

Each of the services represents a process we want to be running in order
to run our application. In this case we have:

* `app`
* `postgres`
* `redis`

These are fairly standard services to rely on while building Rails
applications. But these can be any processes we want to be continually
running while we develop. So, for example, if we used a standalone gulp
build process for a React frontend, we could have a separate process for
this and Docker Compose would take care of making sure it was always
running as part of our development environment.

The `app` service includes the line:

```
build: .
```

which means that the container image should be built from the
`Dockerfile` in the current directory. This could equally be a
subdirectory containing another Dockerfile.

Instead of specifying a path to find a `Dockerfile` to build from, the
other services specify an image:

```
image: redis
```

Which means that the `redis` image will be pulled from a remote
registry, in this case the official Docker registry.

If we specify both `build` and `image` then the name we specify in
`image` will be used to tag the resulting image when we tell Docker
Compose to build any neccessary images.

### Volume Mounts

### Data Persistance

## Generating a new Rails application (Optional)

<http://blog.jasonmeridth.com/posts/create-rails-application-in-current-directory/>

## Configuring the database

## Starting the server

## Running Migrations

## Running a console

## Running specs
