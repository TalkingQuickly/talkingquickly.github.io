Docker and Docker Compose makes it a single command to bring up a development environment on any system which docker supports. This removes the need to invest substantial time setting up local development environments. This tutorial explains how to use Docker for Rails development.

<!--more-->

This tutorial is not a comprehensive introduction to either Docker or Docker Compose, for this this I highly recomend the [official docker compose tutorial](https://docs.docker.com/compose/gettingstarted/) as a starting point.

## Installing Docker

We'll need have Docker installed locally <https://docs.docker.com/install/>. We'll also need `docker-compose` installed, for OSX then this is included, for Linux, instructions are here; <https://docs.docker.com/compose/install/#install-compose>.

## Adding files

If you already have a Rails application you wish to add Docker to, then the files below should be added to the root of your projects. If you don't have a project yet, then create an empty directory with the name of your project and create the files here. We'll cover generating the Rails application itself using Docker below.

First we add a file called `Dockerfile` which defines how to build the runtime environment for our application:

```
FROM ruby:2.4.2
MAINTAINER YOUR_EMAIL

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
RUN rm -rf tmp/*
```

Replacing `YOUR_EMAIL` with your email address.

Then add a second file called `docker-compose.yml` containing the following:

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

  postgres:
    image: postgres:9.4
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

## The compose file

As mentioned at the start, this tutorial isn't an in depth introduction to Docker or Compose, but a few elements of this compose file are worth noting as they differ from the many other Rails compose files out there:

* We don't use `links`, these are [no longer the recommended approach](https://docs.docker.com/compose/compose-file/#links) for establishing communication between containers. Instead services are available by hostname where the hostname will be the name of the service. E.g. in this case our `app` conainer can access postgres via the hostname `postgres` and redis via the hostname `redis`
* The `:delegated` option on the volume mount for our app directory. This is specific to Docker for Mac, although won't cause problems on other platforms. Details of what this does are [available here](https://docs.docker.com/compose/compose-file/#caching-options-for-volume-mounts-docker-for-mac) but it provides a substantial improvement in filesystem performance on OSX, without which day to day development of Rails applications can be painful.

## Generating a new application

If you are working with an existing Rails application, you can skip this section. Using Docker to generate the entire application is especially useful when trying to maintain no local development environment at all, so you can develop Rails applications without ever needing a local Ruby install.

You'll need to add a `Gemfile` containing the following:

```
source 'https://rubygems.org' do
  gem "rails"
end
```

and a blank `Gemfile.lock`

Then execute the following to build the initial Docker image:

```
docker-compose build
```

Then execute:

```
docker-compose run app rails new . --database=postgresql
```

Note this will create a Rails application called `App` and is the equivilant of running `rails new app` since it will be inferred from the `app folder` in the Dockerfile. There are a few approaches to changing this but the simplest is to replace all references to `app` in the `Dockerfile` with the desired name of your app before running `docker-compose build`.

If you pass in an application name instead of `.` then the application will be created in a sub-folder of the current directory and you'll need to move everything into the root.

Once the rails application is created, re-run:

```
docker-compose build
```

To re-build the image with all required gems.

## Dockerising the application

Our `docker-compose.yml` file will bring up not only our rails application, but supporting Postgres and Redis instances. We'll make some changes to our Rails application so that all configuration is taken from environment variables. We'll then update our `docker-compose.yml` file to set some environment variables. This lays the groundwork for using something like Hashicorp's [envconsul](https://github.com/hashicorp/envconsul) for managing configuration in production at a later date. It's also a core tenand of building [12 factor](https://12factor.net/config) applications.

First we'll modify `database.yml` to pull connection details from envionment variables by adding these three lines:

```
username: <%= ENV.fetch("DB_USERNAME") %>
password: <%= ENV.fetch("DB_PASSWORD") %>
host: <%= ENV.fetch("DB_HOST") %>
```

These can either be added to the `default` section or individually to the `development` and `test` sections.


It may look like we could skip this entirely and just use the standard `DATABASE_URL` environment variable with something like `postgres://username:password@postgres/DB_NAME` but this will cause problems when running commands such as `rake db:migrate`. These do not reload environment variables between operating on the test and development databases and therefore raise exceptions when trying to apply migrations to test and development as these will both try and use the same database.

We can then update our `docker-compose.yml` file to set these environment variables, to do this we update the definition of the app service as follows:

```
services:
  app:
    build: .
    command: rails server -p 3000 -b '0.0.0.0'
    volumes:
      - .:/app:delegated
    ports:
      - "3000:3000"
    environment:
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - DB_HOST=postgres
```

the `environment` section allows us to set up the environment variables which will be set within the container. As discussed above, the `postgres` service will be available to our container automatically on the hostname `postgres`. The default credentials for the official postgres image are `postgres` and `postgres` and there's [more about customising here](https://hub.docker.com/_/postgres/).

We can apply the same approach to the `config/secrets.yml` file if needed as well as anywhere else in the application we want to pass in configuration dynamically. If something like [dotenv](https://github.com/bkeepers/dotenv) is in use then we can simply update our local `.env` file with the above environment variables, rather than defining them in the compose file.

## Starting the rails application

We can now build the docker image based on our `Dockerfile` by executing:

```
docker-compose build
```

Once this is complete we can start our application with:

```
docker-compose up
```

This will start postgres, redis and our rails application, exposing the rails application on port 3000 so that we can access it by visiting <http://localhost:3000> as usual.

## Using with pry

If we want to use something like `pry-rails` to debug our rails application, instead of executing `docker-compose up`, we should use:

```
docker-compose run --service-ports app
```

## Running one off commands

Usually when setting up a rails application we would run `rake db:create` and `rake db:migrate`. If dockerising an existing application, we're likely to find that we're greeted with an error page that the database does not exist.

To run one off commands using `docker-compose` we use the `run` command in the format:

```
docker-compose run SERVICE_NAME CMD
```

So to run `rake db:create db:migrate` within the context of our rails application we would use:

```
docker-compose run app rake db:migrate db:create
```

Similarly to start a console we would run:

```
docker-compose run app rails console
```

We could run `rspec` tests with:

```
docker-compose run app rspec spec
```

## Adding Gems

When adding new gems, we first update the Gemfile, then execute:

```
docker-compose run app bundle
```

To update the `Gemfile.lock` and then:

```
docker-compose build
```

To cache the gems in the image.

## Bash

We can launch a bash shell in our app container using:

```
docker-compose run app bash
```

It's important to bear in mind that each invocation of the above runs in a separate, completely isolated, container and so outside the `/app` directory which is bind mounted to our local directory, the file-systems are transitory and independent of one another.

Being able to run a shell within our app container can be the key to avoiding a lot of frustrating workflow issues when working in a docker development environment.

A great example is when upgrading a Rails version. The workflow is typically:

* Update the version of GEM1 within the Gemfile
* Execute `bundle update GEM1`
* Look to see which dependency issues are raised
* Update the Gemfile again
* etc etc

This can be slow and painful if a separate `docker-compose run app ...` is required every time. Instead we can use `docker-compose run app bash` once and then iterate within that container as many times as we want. Once it works we simply jump out of the container and execute `docker-compose build` to persist the new gems to the image.

## Deploying to production

Part two covers how to deploy this application to a Docker Swarm Cluster running on our own servers using just a few additional Docker Compose style files.

Subscribe below to receive updates when this post is available.
