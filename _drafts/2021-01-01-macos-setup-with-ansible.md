---
layout : post
title: Automating MacOS Development setup with Ansible
date: 2021-01-01 09:00
categories: devops ansible automation 
biofooter: true
bookfooter: false
docker_book_footer: false
---

[Ansible](https://www.ansible.com) is a tool most commonly associated with the setup of servers and infrastructure. But more broadly it's an excellent tool for automating the setup of any computer, including laptops and workstations. Of all the configuration management tools out there it's by far the easiest one to use - requiring no devops background at all - and has an amazing community supporting it.

This posts outlines the setup I've evolved over the previous few years which means setting up a new Macbook pro for fairly broad development (Rails, Javascript, Elixir, Python, Android & iOS) now takes just a couple of commands. This includes loading all my shell customisations and general utility apps like Chrome, Office, Virtualbox etc.

<!--more-->

The repository for this post is here; <https://github.com/TalkingQuickly/ansible-osx-setup>. It's structured to be simple to understand and work with for inexperienced Ansible users.

## tldr;

If you're a "tear open the box and throw away the instructions" type then I salute you, here's how to get started quickly:

1. Clone the repo with `git clone https://github.com/TalkingQuickly/ansible-osx-setup`
1. Switch to the cloned repo `cd ansible-osx-setup`
1. Run `bin/bootstrap` 

When asked, provide your `sudo` password, make a cup of tea and wait for everything to install.

If executing a random shell script from someone on the internet you've never met then giving it your sudo password un-nerves you (it should!) then read on for what it does, how it works and how to customise it.

## What are we setting up

The core components we are setting up with this automation are:

1. ZSH + Oh My Zsh as the primary shell
1. Homebrew for package management
1. ASDF for version management (along with plugins and default versions for ruby, python, javascript, elixir and erlang, this replaces using individual tools for ruby, node, python etc)
1. Virtualbox, Vagrant and Docker
1. VSCode + default plugins and configuration
1. Command line tools for interacting with Kubernetes clusters (helm, kubectl, kubectx, kubens)

## Reading the playbook

The easiest way to understand what's being installed is to read <https://github.com/TalkingQuickly/ansible-osx-setup/blob/master/ansible_osx.yml>. This is an Ansible playbook.

A playbook is made up of a list of tasks. Here's anb excerp from the above file:

```yaml
---
- hosts: localhost
  tasks:
    - name: Install homebrew
      include_role:
        name: geerlingguy.homebrew
```

Without worrying too much about the implementation details of the above, it's fairly intuitive to understand that the above task is responsible for ensuring that Homebrew - the package manager for MacOS - is installed.

We then have:

```yaml
- name: 'add custom homebrew repos'
  community.general.homebrew_tap:
    name: [
      adoptopenjdk/openjdk,
      fishtown-analytics/dbt,
```