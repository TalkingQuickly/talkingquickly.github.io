---
layout : post
title: Automating MacOS Development setup with Ansible
date: 2021-01-01 09:00
categories: devops ansible automation 
biofooter: true
bookfooter: false
docker_book_footer: false
render_with_liquid: false
---

Manual repetitive tasks are my nemesis and setting up a new Macbook from scratch is a prime example of this. Using Ansible we can completely automate this process. This is valuable both for individual efficiency and for facilitating standardised "team setups" so that new joiners avoid spending their first days googling obscure node version errors.

[Ansible](https://www.ansible.com) is a tool most commonly associated with the setup of servers and infrastructure. But more broadly it's an excellent tool for automating the setup of any computer, including laptops and workstations. Of all the configuration management tools out there it's by far the easiest one to use - requiring no devops background at all - and has an amazing community supporting it.

This posts outlines the setup I've evolved over the previous few years which means setting up a new Macbook pro for fairly broad development (Rails, Javascript, Elixir, Python, Android & iOS) now takes just a couple of commands. This includes loading all my shell customisations and GUI apps like Chrome, Office, Virtualbox etc.

<!--more-->

{% raw %}

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

## Reading the playbook & Customising 

Begin by cloning the repo;

```
git clone git@github.com:TalkingQuickly/ansible-osx-setup.git
```

The easiest way to understand what's being installed is to read <https://github.com/TalkingQuickly/ansible-osx-setup/blob/master/ansible_osx.yml>. This is an Ansible playbook.

A playbook is made up of a list of tasks. Here's an excerp from the above file:

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
      ...
```

This is responsible for adding any custom homebrew taps we need, in this case for OpenJDK and the awesome DBT. Homebrew taps are third party repositories which allow us to use homebrew to manage software not available in Homebrew core.

Customise this by adding any additional third party repositories you need for software you install. In day to day usage, I try to only add third party repositories using this Ansible playbook, rather than using the CLI directly. This keeps the playbook up to date for when I next need to configure a machine from scratch.

We then have:

```yaml
- name: Install core packages via brew casks
  community.general.homebrew_cask:
    name: "{{ item }}"
  ignore_errors: yes
  with_items:
    - 1password
    - adoptopenjdk/openjdk/adoptopenjdk8
    - android-sdk
    - android-studio
    ...
```

Which is responsible for installing graphical applications using homebrew casks. A huge proportion of GUI applications for MacOS have been packaged as Homebrew casks, so this allows us to automate the installation of everything from Office to Chrome, Firefox or VSCode.

This is using `community.general.homebrew_cask` which is the community maintained ansible module for installing homebrew casks. When we fetch this module later using `ansible-galaxy install -r requirements.yml` we'll see that it's currently set to fetch this module from Github rather than using the version on Ansible Galacy. This is because of a [breaking change in homebrew](https://github.com/ansible-collections/community.general/issues/1524) which leads to the ansible cask module failing with the error `Error: Calling brew cask install is disabled! Use brew install [--cask] instead.` which has been fixed in Ansible but at time of writing not yet released.

We then install ordinary homebrew packages (both from core and the taps we added earlier):

```yaml
- name: "Install homebrew packages"
  community.general.homebrew:
    name: [
      'autoconf',
      'automake',
      'aws-iam-authenticator',
      'awscli',
      ...
```

Note that at time of writing, certain types of exception (e.g. [this one](https://github.com/fishtown-analytics/homebrew-dbt/issues/7) in DBT) produce no logging output which can make failures at this step hard to debug. These types of failure are rare, but in this scenario the quickest way to find the offending package is to comment out half the list, re-run the playbook to see if the failure has gone away, and then continue to bisect the available packages. Once the offending package is found, then try to install it manually with `brew install PACKAGE` and see what the error is.

The next section is responsible for setting up ZSH as the users default shell along with Oh My Zsh for lots of terminal goodness. If you aren't already using it, I can't recommend ZSH + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) enough.

Note that Ansible provides some useful helpers for things like [ensuring that a line exists in a file](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html), e.g:

```yaml
- name: "Ensure homebrew zsh is in allowed shells"
  lineinfile:
    path: /etc/shells
    line: "{{ zsh_path.stdout }}"
  become: true
```

Which is much easier to read than the `sed` magic we'd end up with if we were doing this in a shell script or similar.

Where needed however, there's nothing wrong with using Ansible to just automate the shell commands you'd usually run yourself, e.g. here we install Oh My ZSH and set ZSH as the default shell:

```yaml
- name: Install Oh My ZSH
  shell: sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  args:
    creates: "/Users/{{ lookup('env', 'USER') }}/.oh-my-zsh"

- name: Set ZSH as the default shell
  shell: chsh -s $(which zsh) {{ lookup('env', 'USER') }}
  become: true
```

In many situations this is a great way to get started automating something with Ansible and is already infinitely better than copying and pasting commands into a terminal manually. It's then easy to refactor later if you decide you want to use more specialised ansible modules. It effectively means "anything you can do in the terminal, you can automate with Ansible". 

We then have our first example of an Ansible template:

```yaml
- name: "Create a default ZSH configuration"
  template:
    src: templates/.zshrc.j2
    dest: /Users/{{ lookup('env', 'USER') }}/.zshrc
    owner: "{{ lookup('env', 'USER') }}"
    force: yes
```

This creates a `.zshrc` (think like a `bashrc` but for ZSH) in the users home directory. The contents of this file can be [found here](https://github.com/TalkingQuickly/ansible-osx-setup/blob/master/templates/.zshrc.j2), at a high level it:

- Configures and loads Oh My ZSH
- Loads the ASDF version manager

Most importantly, the default configuration will automatically load any configuration defined in `~/.zshrc.personal.after`.

So when customising, e.g. adding aliases etc, rather than modifying `~/.zshrc` directly (and then loosing these changes the next time you run Ansible), you can add them to `~/.zshrc.personal.after`. I have  `~/.zshrc.personal.after` symlinked to a file in my personal Dropbox for easy sharing.

We then move onto configuring VSCode, first by creating a default configuration file:

```yaml
- name: Create a default VSCode configuration
  template:
    src: templates/vscode-settings.json.j2
    dest: /Users/{{ lookup('env', 'USER') }}/Library/Application Support/Code/User/settings.json
    owner: "{{ lookup('env', 'USER') }}"
    force: no
```

Note the `force: no` here. This means that unlike the `.zshrc` file above, if the file already exists, Ansible will not overwrite it. This is because there's no equivilent (that I know of) to `~/.zshrc.personal.after` for VSCode so I prefer to not have the risk of overwriting my updated config accidentally at the expensive of having to manually update the Ansible template when I make local changes.

We then use a similar task to create some default keybindings.

Finally for VSCode, we install extensions:

```yaml
- name: Install VSCode extensions
  shell: code --install-extension {{ item }}
  with_items:
    - apollographql.vscode-apollo
    - bradlc.vscode-tailwindcss
    - castwide.solargraph
    - clinyong.vscode-css-modules
    ...
```

To find the identifier of an extension to add here, either:

- Open the extensions page in VSCode, then click on the settings icon (the gear) and choose "Copy Extension ID"
- Open the extensions page in a browser, e.g. <https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby> and the identifier is both in the url as `itemName` (e.g. in this case `rebornix.Ruby`) or further down the page in the right bar as "Unique Identifier".

We then move onto installing `asdf`. asdf is a tool for managing versions of runtimes (e.g. ruby, pythong, node etc) and allows us to replace multiple language specific tools (e.g. `nvm`, `brenv` etc) with a single consistent interface.

The `.zshrc` which we looked at above already contains the lines to load asdf, these are:

```bash
# Load asdf
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
```

so we just need to clone the asdf repo which is done by this task:

```yaml
- git:
    repo: https://github.com/asdf-vm/asdf.git
    dest: "/Users/{{ lookup('env', 'USER') }}/.asdf"
    version: v0.7.1
```

asdf is plugin based, e.g. there is a plugin to allow it to manage ruby versions, another to allow it to manage node versions etc. Googling pretty much any `asdf LANGUAGE plugin` variant will yield an existing asdf plugin for managing versions of that language.

So to begin with we install plugins for the languages we use:

```yaml
- name: "Install asdf plugins"
  shell: |
    source /Users/{{ lookup('env', 'USER') }}/.asdf/asdf.sh
    asdf plugin-add {{ item }} || exit 0
  with_items:
    - ruby
    - elixir
    - nodejs
    - python
    - erlang
```

There's a couple of things to note here. Firstly before using the `shell` module to execute `asdf` commands, we have the line `source /Users/{{ lookup('env', 'USER') }}/.asdf/asdf.sh`. This is usually executed when we load a shell via `~/.zshrc` but since Ansible won't be initiating a login shell for every commands, we have to run this manually.

Secondly the use of `|| exit 0` when adding a plugin. This is because at time of writing, asdf will return a none zero error code if the plugin we add is already installed. Ansible will then interpret this as a failure and stop the play from running. We do not want this because the goal is to have a playbook we can run repeatedly to apply changes.

So the `|| exit 0` ensures that this line always returns a success exit code. The downside of this is that it masks genuine errors, but thankfully these are rare and will show up as a "plugin not installed" error when we later try and use the plugin. 

Once we have plugins installed, we then need to install versions and any default libraries, to take ruby as an example;

```
- name: "Install Default Ruby"
  shell: |
    source /Users/{{ lookup('env', 'USER') }}/.asdf/asdf.sh
    asdf install ruby 3.0.0
    asdf install ruby 2.7.2
    asdf global ruby 3.0.0
    gem install bundler -v 2.2.4
    gem install cocoapods
    gem install rubocop
    gem install solargraph
```

As before we `source` asdf before using its cli commands. We then install versions, in this case I have both ruby 3 and ruby 2 projects so I install a version of each. We then set the global version to `3.0.0` which means that when there is no `.tool-versions` file available specifying a particular ruby version, asdf will fallback to `3.0.0`. Finally we install a selection of gems (libraries) for the default ruby.

The final section of the playbook installs a selection of android SDK's using `sdkmanager`:

```
- name: Install Addroid SDKs etc
  shell: yes | sdkmanager "{{ item }}" --sdk_root=/Users/{{ lookup('env', 'USER') }}/Library/Android/sdk
  with_items:
    - "add-ons;addon-google_apis-google-21"        
    - "add-ons;addon-google_apis-google-22" 
    - "add-ons;addon-google_apis-google-23"
    ...
```

Which is only applicable if you will be using the machine for Android development.

Something not used in this playbook but also available is installing MacOS App Store apps directly with ansible via `mas` (which we installed with homebrew earlier):

```yaml
- name: Install apps from the Mac App Store using mas (Assumes you're logged in etc)
  shell: mas install {{ item }}
  with_items:
    - 409183694 # Keynote
    - 1295203466 # Microsoft remote desktop
    - 497799835 # xcode
    - 496437906 # shush microphone manager
    - 419330170 # Moom window manager
```

This comes with the important caveat that you must have installed the app before manually (e.g. on a different machine) for this to work. For more on how to use `mas` including how to find app identifiers see [the mas documentation](https://github.com/mas-cli/mas)

## Typical Workflow

After forking this playbook and cloning locally, before you can run it, you need to:

- Install XCode and Command Line Tools 
- Install Ansible
- Fetch community Asnible modules defined in `requirements.txt`

This can be done in one step using the script in `bin/bootstrap`:

```bash
#!/bin/sh
xcode-select --install
sudo xcodebuild -license
sudo easy_install pip
pip install --ignore-installed ansible
ansible-galaxy install -r requirements.yml

ansible-playbook -i "localhost," -c local ansible_osx.yml --ask-become-pass
```

This will complete the required prerequisite steps and then run the playbook (asking you for your sudo password when it does so).

Ideally whenever you need to add software to your MacOS install, rather than installing it manually, you update your Ansible playbook and re-run the Ansible command:

```bash
ansible-playbook -i "localhost," -c local ansible_osx.yml --ask-become-pass
```

If like me, Ansible commands just don't stick in your head, there's a shortcut for this in the form of `bin/apply`.

If you follow this iterative approach of updating the playbook as you install new software, when the time comes to provision a new machine from scratch, it will be a much easier ride.

{% endraw %}