---
layout : post
title: Automated Debian development environment for VSCode with Ansible
date: 2021-01-08 00:00
categories: devops ansible automation vscode
biofooter: true
bookfooter: false
docker_book_footer: false
---

One of the things VSCode has done extremely well is creating a seamless remote development experience. Using the remote extension pack, specifically the SSH development extension, it's possible to run VSCode locally, while performing all actions on a remote server completely seamlessly. This allows us to use a local VM for much faster docker development on macOS. It also means we are free to spin up powerful Cloud VM's with many cores and plenty of RAM when we're working on more intensive tasks.

With this setup I seamlessly switch between fully local development using a Virtualbox VM and a 16 core cloud VM with 64GB of RAM when I need more horsepower. In both environments this provides the level of Docker performance I associate with developing directly on Linux machines.

This is streamlined using an Ansible playbook which automatically sets up Debian VM's with sensible defaults for development, including a beautiful default ZSH configuration (inc auto-completions) and easy language version management with asdf. This post starts with the practical steps required for this setup, and then goes on to explain what's being installed and how it works.

<!--more-->

## Set up a Virtualbox VM

If you're using a cloud VM (e.g. GCP, AWS, Hetzner etc) then you can skip this section and go straight to "Cloud VM" below. 

Create a VM, select "Linux" as the type and "Debian (64 bit)" as the version. The amount of RAM to allocate to the VM varies depending on your workload but as a guide, I rarely allocate less than 4GB and often go for 8GB or 16GB. As a very rough rule of thumb, allocate half of your RAM and available threads to the development VM. Create a new virtual disk, if you're going to be working with Docker, allocate at least 100GB or so (Docker images add up quickly), choose VDI as the type of image and for optimal performance select "Fixed Size" when asked.

Before you start the Virtualbox VM, go to its settings page, then the "System->Processor" tab and increase the number of processors to half the number of threads available. So on an 8 core, 16 thread Intel Macbook Pro, you would choose 8. This step is important and often missed, remote development on a VM with only 1 core is going to be neither fast nor fun!

Next go to the "Network" tab, choose "Advanced", then "Port Forwarding" and click the green "add" icon. In host port put `2222` and in guest port put `22` (ssh). This means that port 22 of the guest will now be available on port 2222 of the host (e.g. our local machine).   

Download the latest Debian 10 installation ISO from the [Debian website](https://www.debian.org) and in "Settings / Storage" select the "Empty" slot under "Controller: IDE" and click the disc icon on the right, select "Choose a disc file" and then browse to the location of the downloaded Debian ISO and select it.

Now start the VM where you'll be greeted by the Debian installer (if the display is tiny, try adjusting the scale factor for the VM under its video settings). Select your language, location etc and when asked for a hostname, enter something descriptive, this will be displayed in the shell prompt so that you know when you're working in the VM and when you're working locally. When prompted for domain name, you can leave this blank. Make sure you remember - or better store in your password manager - the root and user account credentials you create.

Select default options for disk partitioning and then "Yes" when asked if you want to write the changes to disk (don't worry, you're writing changes to the Virtualbox disk, not your boot drive!). Choose no when asked if you want scan another CD / DVD. Select the defaults when going through the steps to setup the package manager.

When you reach the Software Selection screen, **untick everything except for "SSH Server" which should be ticked**.

Select yes when asked if you want to install GRUB to the MBR and then in the next step choose `/dev/sda` instead of the manual option.

Complete the installation, don't worry about instructions for removing the CD, this will happen automatically. The machine will then boot to a login prompt. 

This step is optional but recommended; close the machine and when asked choose "Save the machine state". Then in the Virtualbox main screen, choose your VM, right click on it and choose "Headless Start". This has a couple of benefits, firstly it avoids extra windows cluttering up your desktop and secondly avoids a periodic issue with audio device conflicts.

You should now be able to ssh into the newly created VM with `ssh USERNAME@localhost -p 2222` replacing username with the user account your created above.

The final step is to enable SSH key based login with:

```
ssh-copy-id -p 2222 USERNAME@localhost
```

On MacOS if you don't have `ssh-copy-id` installed then you can install it with; `brew install ssh-copy-id` or `sudo port install openssh +ssh-copy-id`

## Cloud VM

You can skip this section if you're using a local Virtualbox VM.

If you're using a Cloud VM, choose the latest Debian 10 (Buster) image that's available. Ensure that you have key based SSH access to the newly created VM, this may be done as part of the creation process. If not (e.g. if you only have password access) then use `ssh-copy-id` to copy your public key to the remote machine:

```bash
ssh-copy-id USERNAME@SSH_HOST
```

On MacOS if you don't have `ssh-copy-id` installed then you can install it with; `brew install ssh-copy-id` or `sudo port install openssh +ssh-copy-id`

## Provisioning the machine

Now that you have a suitable VM, we can use Ansible to install the tools needed for development.

Begin by cloning <https://github.com/TalkingQuickly/debian_dev_env>.

We then need to [install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) this is typically as simple as:

```bash
pip3 install ansible
```

Then from within the repo we cloned above, we fetch some community roles from Ansible Galaxy:

```bash
ansible-galaxy install -r requirements.yml
```

We then need to create an "inventory" file. An inventory file is just Ansible terminology for a file that tells it about the hosts it is going to be setting up. Start by creating a copy of the example inventory file:

```bash
cp inventory.example inventory.dev.yml
```

Which will create an inventory file `inventory.dev.yml` containing the following:

```yaml
all:
  hosts:
    "SSH_HOST":
      ansible_user: SSH_USERNAME
      main_user: DESIRED_LOGIN_USER
      ansible_ssh_port: SSH_PORT
      initial_become_method: su # this should be `su` if the SSH user does not, by default, have sudo access, otherwise (for most cloud providers) this should be `sudo`
```

Replace `SSH_HOST` with the hostname or IP address of the VM. For local virtualbox, this will be "localhost". Replace `SSH_USERNAME` with the user you use to connect via SSH, for virtualbox that's the user you created in the installer, for cloud VM providers it varies, for AWS it's often `ec2-user`, for GCP this will be your account username and for hetzner VM's it's generally root.

Replace `DESIRED_LOGIN_USER` with the user who you'll actually work as for development. If this user doesn't exist, they will be created and SSH key based login using the public key at `~/.ssh/id_rsa.pub` enabled. In the local Virtualbox scenario, this will be the user you created in the Debian installer (so `SSH_USERNAME` and `DESIRED_LOGIN_USER` will be the same).

`initial_become_method` should be set to `su` if the SSH user does not initially have sudo access, and `sudo` otherwise. So for Virtualbox, this should be `su`, for GCP; `sudo`.

Finally replace `SSH_PORT` with the port for connecting to SSH, in most cases this will be 22, except for the local Virtualbox scenario where it will be `2222` (the host port we selected at the start).

We're now ready to use Ansible to provision the machine:

```bash
ansible-playbook -i inventory.dev.yml main.yml --ask-become-pass
```

This will prompt you for a "BECOME password", this is the password which will be used to get root access. If you set `initial_become_method` to `su` above, it should be the root password, otherwise it should be sudo password for `ansible_user`. In the case of Virtualbox, `initial_become_password` will be set to `su` so this should be the root password. For GCP this should be `sudo` and you can leave become pass blank, e.g. just press enter when prompted.

If you get this error:

```
"Timeout (12s) waiting for privilege escalation prompt: 
```

Double check that you've set `initial_become_method` correctly above.

## VSCode Remote Development

Now that the VM is provisioned, we're ready to use it for remote development. Let's begin by enabling SSH Forwarding. This means that rather than having to copy our SSH keys to the new VM to allow us to do things like clone git repositories, we can allow the VM to "forward" to our local machine and use those keys to access things, without the keys ever leaving our remote machine, there's more about how this works in my post on [making ssh forwarding play nicely with tmux](/2021/01/tmux-ssh-agent-forwarding-vs-code/).

Add the following to `~/.ssh/config`:

```
Host A_FRIENDLY_NAME_FOR_THE_HOST
  ForwardAgent yes
  HostName ADDRESS_OR_IP_ADDRESS
  User SSH_USERNAME
  Port THE_SSH_PORT
```

Replacing the placeholders with your own values. You can now SSH into the remote machine using `ssh A_FRIENDLY_NAME_FOR_THE_HOST`.

More importantly if you fire up VSCode, making sure you have the [Remote Development Extension Pack](https://code.visualstudio.com/docs/remote/remote-overview) installed, and navigate to the remote explorer tab, selecting "SSH targets" from the dropdown, you'll now see `A_FRIENDLY_NAME_FOR_THE_HOST` listed!

Right click on your host in this explorer and choose "Connect to host in current window" and you're ready to go! Opening the vscode built in terminal will seamlessly bring up a terminal on the remote machine. Using commands like `code FILENAME` to open a file will open files from the remote machine in the current vscode instance.

Because we've setup SSH forwarding, we can use `git clone REPOSITORY` in this terminal to clone private repositories, and the public key on our local machine will be automatically used.

Open folder allows folders on the remote machine to be opened in exactly the same way we usually open local folders and the file explorer will show the filesystem of the remote machine.

If, having opened a project, we then start a server which can be access on a port, e.g. for Rails generally `3000`, we can go back to the "Remote Explorer", select "Forward a Port" and then enter `3000` and port `3000` will be made securely available on our local machine. So we can then access that server in our local web browser by going to `localhost:3000`. Ports can also be forwarded without using the mouse by opening the command palette and searching for "Forward a port".

## Faster docker development on macOS

The Docker for Mac team have done an incredible job at creating a smooth developer experience for Mac users.

The area which is still most problematic is filesystem performance. This is less an issue with Docker and more an issue with shared folder performance with virtual machines generally being substantially slower than native filesystem access.

This problem is most notable when working with large projects, especially projects with many large files. [This post](https://www.jeffgeerling.com/blog/2020/revisiting-docker-macs-performance-nfs-volumes) provides an excellent summary of the key alternative approaches available for Docker for Mac and their performance characteristics. I tried all of these and Docker Sync (which is an amazing project in itself) yielded reasonable performance but with some admin complexity and reliability issues. It was mainly this quest for better docker performance on MacOS that led me to switch to the approach outlined in this post.

When using VSCode to develop remotely (either locally via Virtualbox or remotely on a cloud VM), we are operating directly on the filesystem of a Linux host, so there's no intermediate VM between our files and Docker. This means that there's no meaningful performance penalty, so commands run in Docker have almost identical performance characteristics to commands run locally.

For a large Rails project, this was the difference between a time to first render of 30 seconds with vanilla Docker for Mac, 10 seconds with docker sync and 3 seconds using a local VM.

## What are we setting up

For a detailed understand of what's being installed and configured, see the next section (reading the ansible playbook). The core components we are installing and configuring:

1. Hardening, enabling UFW to block all incoming connections except for SSH
1. ZSH and OhMyZSH along with shell completions for docker, compose and Kubernetes tools
1. ASDF as a version manager for all languages (including but not limited to Ruby, Python, Node, Elixir and Erlang)
1. Docker and docker compose
1. Common utilities (GCP and AWS clis, `htop`, `tmux`, `git` etc)
1. Utilities for interacting with Kubernetes clusters; `kubectl`, `helm`, `kubectx` & `kubens`

## Reading the Ansible playbook

One of the great things about Ansible is that it has a very shallow learning curve, you can get a lot done in it without having to learn that much. The goal of this section is to provide the bare minimum needed to understand what's happening and make simple tweaks. For a more comprehensive introduction, [start here](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html).

Our command for running ansible is:

```
ansible-playbook -i inventory.dev.yml main.yml --ask-become-pass
```

This means "take the Ansible playbook defined in `main.yml` and apply it to the hosts defined in the inventory file `inventory.dev.yml`".

If we look at `main.yml`, we see something like:

```yaml
# In a minimal Debian install, sudo won't be available, so we first
# install that and make sure the user ansible connects to has access
# to it
- hosts: all
  become: yes 
  become_method: su
  become_user: root

  pre_tasks:
    - include_role:
        name: sudo
  

# Some tasks will fail if run directly as root (e.g. with `su` so once)
# we have sudo installed above, we switch back to it before doing the
# actual work
- hosts: all
  become: yes
  become_method: sudo

  roles:
  - hardening
  - docker
  - general
  - dotfiles
  - asdf
  - phraseapp
  - kubernetes_tools
```

There are two distinct sections here. The first is purely responsible for ensuring that `sudo` is installed and available (which it isn't by default in a Debian install).

The second section is where most of the work is done.

`hosts: all` means that what's coming next should be run on all hosts in the inventory file, in our case there is only one.

The `become` lines define how privileges should be escalated so that the Ansible user - who may not be root - is able to do things like installing software.

`roles` accepts an array of role names. For each one (`$ROLE_NAME`), it then loads and executes the tasks defined in `roles/$ROLE_NAME/tasks/main.yml`. So for each of these roles, we now know to find out what it's doing we just need to look at the `main.yml` file in the relevant subdirectory.

If we take `hardening` as an example, we see something like:

```yaml
- name: Update apt cache
  apt:
    update_cache: yes

- name: Install packages
  package:
    name:
      - ufw

- name: Allow rate limited connections to SSH
  community.general.ufw:
    rule: limit
    port: ssh
    proto: tcp

- name: Deny everything else and enable UFW
  community.general.ufw:
    state: enabled
    policy: deny
```

Which should be fairly self explanatory. For more information about what each task is doing, the Ansible documentation is excellent. So for example Googling "Ansible apt" gives [this](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html) as it's first result which - as with all of their documentation - includes a large selection of easy to follow examples at the end.

In our original setup, we executed this command:

```
ansible-galaxy install -r requirements.yml
```

In `requirements.yml` we describe any third party Ansible modules that we want to use. In this case it's a very short list:

```yaml
---
collections:
- name: community.general
```

We can then see a module from `community.general` being used in the above hardening example:

```yaml
- name: Allow rate limited connections to SSH
  community.general.ufw:
    rule: limit
    port: ssh
    proto: tcp
```

Googling "community.general.ufw" gives us [this](https://docs.ansible.com/ansible/latest/collections/community/general/ufw_module.html) page of documentation which includes comprehensive examples.


## That's all folks

Being able to quickly provision standardised linux development environments both locally and remotely has been a big boost to productivity and finally provided the best of both worlds in the Mac v Linux journey I've been flipflopping between for many years.