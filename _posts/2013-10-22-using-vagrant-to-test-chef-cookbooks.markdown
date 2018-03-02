---
layout : post
title: "Using Vagrant to test Chef Cookbooks"
date: 2013-10-22 19:03:00
categories: rails devops
biofooter: false
bookfooter: true
---

Vagrant makes it easy to manage and distribute virtual machines. Vagrant is an extremely powerful tool in itself with a particular strength of making it easy to distribute local testing environments to developers which (almost) perfectly mirror your production configuration.

<!--more-->

This section does not cover how to use Vagrant to create these re-usable environments. Instead it covers a very specific workflow I use for testing Chef Recipes.

This can be especially useful when you’re testing changes to recipes and want to see how it will interact with your existing production configuration.

For more on this workflow, read on, for a general introduction to the power of Vagrant, start here:

<http://docs.vagrantup.com/v2/getting-started/index.html>

## Getting Setup

Go to <http://downloads.vagrantup.com/> and download then install the most recent version of Vagrant (I used 1.3.5). You’ll also need VirtualBox installed as Vagrant in this scenario acts as a tool for managing VirtualBox instances.

Make sure Vagrant is available in terminal by typing `vagrant` and ensuring you get output similar to the following:

``` bash
➜ ~ vagrant
Usage: vagrant [-v] [-h] command []
-v, --version Print the version and exit.
-h, --help Print this help.
....
```

If you get a command not found error, it may be necessary to restart your terminal.

For help on any individual command run

``` bash
vagrant COMMAND -h
```

Create a new directory then:

``` bash
vagrant init precise64 http://files.vagrantup.com/precise64.box
```

This will generate a Vagrantfile

``` bash
vagrant up
```

Will then download the pre created image of Ubuntu 12.04 and boot a Virtual Machine using it, don’t worry about the initial note saying that precise64 doesn’t yet exist

You can then ssh into this virtual machine using:

``` bash
vagrant ssh
```

Which will log you in as the vagrant user. Passwordless sudo is enabled so you don’t have to worry about default passwords

## SSHing in directly

When testing chef cookbooks, roles and node definitions, I like to be able to apply a definition to my vagrant virtual machine in exactly the same way I will my production server. A pre-requisite for this is that I can interact with it without using any vagrant specific commands. Happily SSHing in the old fashioned way is very simple. Begin by running:

``` bash
vagrant ssh-config
```

This will give output something like the following:

```
HostName 127.0.0.1
User vagrant
Port 2222
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
PasswordAuthentication no
IdentityFile /Users/ben/.vagrant.d/insecure_private_key
IdentitiesOnly yes
LogLevel FATAL
```

Which shows the config which is being used by the `vagrant ssh` command.

From the above we can construct the following ssh command:

``` bash
ssh vagrant@127.0.0.1 -p 2222 -i /Users/ben/.vagrant.d/insecure_private_key
```

Which means establish a connection to 127.0.0.1 on port 2222 using the vagrant generated private key file to authorise the user `vagrant`.

## Why not just use Vagrants built in chef and chef-solo support?

Vagrant has excellant chef-solo support built in. Rather than using our existing node definition files, we can effectively include the data from a node definition file, in our vagrantfile. When `vagrant up` is run for the first time, the vagrant image will be automatically provisioned. This is very powerful when we’re using vagrant to make it easy for developers to provision environments which closely match production.

However when developing testing Chef cookbooks, role definitions and node definitions, I prefer the process of provisioning the Vagrant VM to be identical in as many ways as possible to the process of provisioning production and staging VM’s.

For me this means using exactly the same commands (knife solo prepare, knife solo cook etc). I strongly recommend reading http://docs.vagrantup.com/v2/provisioning/chef_solo.html to understand how chef provisioning can be built into a Vagrantfile if you do start using Vagrant for local development environments.

## Testing chef cookbooks

Now we have a vagrant virtual machine which we can ssh into as we would any VPS, we can test our chef configuration on it.

Open a terminal in your chef repository, so in my case

``` bash
cd ~/proj/devops/rails_server_template
```

then install chef on your Vagrant VM:

``` bash
knife solo prepare vagrant@127.0.0.1 -p 2222 -i /Users/ben/.vagrant.d/insecure_private_key
```

Where the port, ip and path to private key match the results of vagrant ssh-config before.

The output should be something like:

``` bash
Bootstrapping Chef...
 --2013-10-20 15:27:50-- https://www.opscode.com/chef/install.sh
 Resolving www.opscode.com (www.opscode.com)... 184.106.28.83
 Connecting to www.opscode.com (www.opscode.com)|184.106.28.83|:443... connected.
 HTTP request sent, awaiting response... 200 OK
 Length: 6790 (6.6K) [application/x-sh]
 Saving to: `install.sh'

100%[======================================>] 6,790 --.-K/s in 0s

2013-10-20 15:27:56 (799 MB/s) - `install.sh' saved [6790/6790]

Downloading Chef 11.6.2 for ubuntu...
 Installing Chef 11.6.2
 Selecting previously unselected package chef.
 (Reading database ... 51095 files and directories currently installed.)
 Unpacking chef (from .../chef_11.6.2_amd64.deb) ...
 Setting up chef (11.6.2-1.ubuntu.12.04) ...
 Thank you for installing Chef!
```

This will have created an empty node definition file in `nodes/127.0.0.1`. To use this auto generated node definition file (`nodes/ip_address.json`) simply populate it and then enter:

``` bash
knife solo cook vagrant@127.0.0.1 -p 2222 -i /Users/ben/.vagrant.d/insecure_private_key
```

Otherwise use

``` bash
knife solo cook vagrant@127.0.0.1 nodes/my_node_definition.json -p 2222 -i /Users/ben/.vagrant.d/insecure_private_key
```

Where `nodes/my_node_definition.json` is the path to an existing node definition.

The output from this will begin by installing the chef recipes from your Berksfile and then show the output from each individual recipe.

Once this process completes, the Vagrant VM should now be configured as per your chef definition.

## Users, Sudo and Root

By default Vagrant sets up the `vagrant` user with the password `vagrant`. This user has passwordless sudo enabled so you never have to worry about default passwords (however read to the end for a gotcha here).

When you run `cook` for the first time using the vagrant user, chef will automatically try and use `sudo` where root access is required. The first time this will work correctly because the vagrant user has passwordless sudo enabled. If however the configuration you’re applying with chef includes defining who can sudo and how (such as my example rails server chef template), the next time you try and run `cook` for example to test another change to your chef repository, you’re likely to see something like the following:

``` bash
Running Chef on 127.0.0.1...
 Checking Chef version...
 Enter the password for vagrant@127.0.0.1:
```

The default password for the `vagrant` user is `vagrant` however after entering, the process will still fail with the message:

``` bash
ERROR: RuntimeError: Couldn't find Chef >=0.10.4 on 127.0.0.1. Please run `knife solo prepare vagrant@127.0.0.1 -i /Users/ben/.vagrant.d/insecure_private_key -p 2222` to ensure Chef is installed and up to date.
```

This is because the `vagrant` user is no longer in the sudoers file and so chefs attempt to run commands with sudo fails. You can verify that this is the case by running `vagrant ssh` from with your original vagrant folder which starts a shell with the vagrant user and then running `sudo ls` which will give output like:

``` bash
vagrant@precise64:~$ sudo ls
 [sudo] password for vagrant:
 vagrant is not in the sudoers file. This incident will be reported.
```

Confirming that our vagrant user can no longer sudo.

There are various ways around this:

The first, and simplest, is to simply add the vagrant user to the sudoers group in your node defintion file. This has the added bonus that it allows commands like `vagrant halt` to continue working. This is generally the approach I use in day to day testing.

Some argue however that we should not modify the code we are testing in order to work with the tool we are testing it with. To avoid this we can modify our `cook` command going forward to execute using a user we know we have given sudo rights to, in the case of the rails_example_template this user would be deploy so going forward the command would be:

``` bash
knife solo cook deploy@127.0.0.1 nodes/my_node_definition.json -p 2222 -i /Users/ben/.vagrant.d/insecure_private_key
```

Personally I prefer a hybrid. I generally add the vagrant user to the sudoers list in the node defintiion so that the vagrant interface can continue to function as usual however I use the above format when I want to test that provisioning as the deploy user works as expected.

## Conclusion

If you use Chef Solo, this configuration allows you to use Vagrant to test cookbooks using local, disposable VM’s through a process that is almost identical to the production workflow. For more on Vagrant, such as how to forward ports, manage shared folders and package images for distribution, see the excellant Vagrant documentation at: <http://docs.vagrantup.com/v2/getting-started/>

{% include also-read-rails.html %}
