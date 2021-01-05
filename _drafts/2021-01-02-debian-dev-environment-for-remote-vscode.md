---
layout : post
title: Automated Debian development environment for VSCode with Ansible
date: 2021-01-05 00:00
categories: devops ansible automation vscode
biofooter: true
bookfooter: false
docker_book_footer: false
---

One of the things VSCode has done extremely well is creating a seamless remote development experience. Using the remote extension pack, specifically the SSH development extension, it's possible to run VSCode locally, while performing all actions on a remote server completely seamlessly. This allows us to use a local VM for much faster docker development on macOS. This also means we are free to spin up powerful Cloud VM's with many cores and plenty of RAM when we're working on more intensive tasks.

With this setup I seamlessly switch between fully local development using a Virtualbox VM and a 16 core cloud VM with 64GB of RAM when I need more horsepower. This is accomplished using an Ansible playbook which automatically sets up Debian VM's with sensible defaults for development, including a beautiful default ZSH configuration (inc auto-completions) and easy language version management with asdf. This post starts with the practical steps required for this setup, and then goes on to explain what's being installed and how it works.

## Set up a Virtualbox VM

If you're using a cloud VM (e.g. GCP, AWS, Hetzner etc) then you can skip this section and go straight to "Cloud VM" below. 

Create a VM, select "Linux" as the type and "Debian (64 bit)" as the version. The amount of RAM to allocate to the VM varies depending on your workload but as a guide, I rarely allocate less than 4GB and often go for 8GB or 16GB. As a very rough rule of thumb, allocate half of your RAM and available threads to the development VM. Create a new virtual disk, if you're going to be working with Docker, allocate at least 100GB or so (Docker images add up quickly), choose VDI as the type of image and for optimal performance select "Fixed Size" when asked.

Before you start the Virtualbox VM, go to its settings page, then the "System->Processor" tab and increase the number of processors to half the number of threads available. So on an 8 core, 16 thread Intel Macbook Pro, you would choose 8. This step is important and often missed, remote development on a VM with only 1 core is going to be neither fast nor fun!

Next go to the "Network" tab, choose "Advanced", then "Port Forwarding" and click the green "add" icon. In host port put `2222` and in guest port put `22` (ssh). This means that port 22 of the guest will now be available on port 2222 of the host (e.g. our local machine).   

Download the latest Debian 10 installation ISO from the [Debian website](https://www.debian.org) and in "Settings / Storage" select the "Empty" slot under "Controller: IDE" and click the disc icon on the right, select "Choose a disc file" and then browse to the location of the downloaded Debian ISO and select it.

Now start the VM where you'll be greeted by the Debian installer (if the display is tiny, try adjusting the scale factor for the VM under its video settings). Select your language, location etc and when asked for a hostname, enter something descriptive, this will be displayed in the shell prompt so that you know when you're working in the VM and when you're working locally, when prompted for domain name, you can leave this blank. Make sure you remember - or better store in your password manager - the root and user account credentials you create.

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

On OSX if you don't have `ssh-copy-id` installed then you can install it with; `brew install ssh-copy-id` or `sudo port install openssh +ssh-copy-id`

## Cloud VM

You can skip this section if you're using a local Virtualbox VM.

If you're using a Cloud VM, choose the latest Debian 10 (Buster) image that's available. Ensure that you have key based SSH access to the newly created VM, this may be done as part of the creation process. If not (e.g. if you only have password access) then use `ssh-copy-id` to copy your public key to the remote machine:

```bash
ssh-copy-id USERNAME@SSH_HOST
```

On OSX if you don't have `ssh-copy-id` installed then you can install it with; `brew install ssh-copy-id` or `sudo port install openssh +ssh-copy-id`

## Provisioning the machine

## 

## What are we setting up

## Reading the Ansible playbook

## VSCode Remote Development

## Faster docker development on macOS