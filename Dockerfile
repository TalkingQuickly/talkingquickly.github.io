FROM ruby:2.7-buster

# Install apt based dependencies required to run Rails as
# well as RubyGems. As the Ruby image itself is based on a
# Debian image, we use apt-get to install those.
RUN apt-get update && apt-get install -y \
  build-essential \
  nodejs \
  rsync

RUN useradd -ms /bin/bash deploy

USER deploy

RUN git config --global user.email "ben@talkingquickly.co.uk"
RUN git config --global user.name "Ben Dixon"

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
RUN mkdir -p /home/deploy/app
WORKDIR /home/deploy/app

RUN mkdir /home/deploy/release
RUN mkdir /home/deploy/.ssh
RUN chown deploy:deploy /home/deploy/.ssh

# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler:1.16.1 && bundle install --jobs 20 --retry 5
