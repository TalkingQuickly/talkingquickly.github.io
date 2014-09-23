---
layout : post
title: "Automatically Generate Vagrant Machines from Chef Node Definitions""
date: 2014-08-09 08:00:00
categories: devops
biofooter: false
bookfooter: true
docker_book_footer: false
---

If you use chef-solo to provision your production servers, Vagrant makes it easy to set up a production like environment on a local VM for testing purposes. It can however seem like wasted time to have to manually replicate the contents of your node definition in your `Vagrantfile` and more importantly it's easy to make a change to either the `Vagrantfile` or the node definition and forget to update the other to match. In this post I'll look at a simple method of automatically generating Vagrant machines based on node definitions.

This post will use as an example the sample configuration from the book [Reliably Deploying Rails applications](https://leanpub.com/deploying_rails_applications) but it should be applicable to any project which uses a standard Chef Solo configuration.

The high level approach is simple, for any node we want a Vagrant machine for, we add a `vagrant` section to the definition json which defines some vagrant specific options, in particular the IP if we want to use private networking and the name to use. In our `Vagrantfile` we then look for any `.json` files in the `nodes` directory, parse the JSON and if it contains a `vagrant` key, generate a Vagrant configuration on the fly.

The Vagrant section of our node definition looks like this:

``` ruby
...
"vagrant": {
  "ip":"192.168.1.50"
  "name": "rails-pg-test-1", //a-z,0-9,- and . only 
},
...
```

For a complete example node definition see: <https://github.com/TalkingQuickly/rails-server-template/blob/master/nodes/rails_postgres_redis.json.example>

And our Vagrantfile looks like this:

```ruby
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Setup resource requirements
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  config.vm.box = "ubuntu/trusty64"

  # This should match the version specified in your
  # Gemfile. You must have the omnibus vagrant plugin
  # installed for this to work.
  config.omnibus.chef_version = "11.16.0"

  # Enable if you want to use the Vagrant Berkshelf plugin to manage
  # Cookbooks.
  config.berkshelf.enabled = false

  # Assumes that the Vagrantfile is in the root of our
  # Chef repository.
  root_dir = File.dirname(File.expand_path(__FILE__))

  # Assumes that the node definitions are in the nodes
  # subfolder
  nodes = Dir[File.join(root_dir,'nodes','*.json')]

  # Iterate over each of the JSON files
  nodes.each do |file|
    node_json = JSON.parse(File.read(file))

    # Only process the node if it has a vagrant section
    if(node_json["vagrant"])
      vagrant_name = node_json["vagrant"]["name"]
      vagrant_ip = node_json["vagrant"]["ip"]

      # Allow us to remove certain items from the run_list if we're
      # using vagrant. Useful for things like networking configuration
      # which may not apply/ may break in the vagrant environment
      if exclusions = node_json["vagrant"]["exclusions"]
        exclusions.each do |exclusion|
          if node_json["run_list"].delete(exclusion)
            puts "removed #{exclusion} from the run list"
          end
        end
      end

      config.vm.define vagrant_name do |vagrant|
        vagrant.vm.hostname = vagrant_name

        # Only use private networking if we specified an
        # IP. Otherwise fallback to DHCP
        if vagrant_ip
          vagrant.vm.network :private_network, ip: vagrant_ip
        end

        vagrant.vm.provision "chef_solo" do |chef|

          # Use berks-cookbooks not cookbooks and remember
          # to explicitly vendor berkshelf cookbooks with
          # berks vendor if not using the berkshelf vagrant plugin
          chef.cookbooks_path = ["berks-cookbooks", "site-cookbooks"]
          chef.data_bags_path = "data_bags"
          chef.roles_path = "roles"

          # Instead of using add_recipe and add_role, just
          # assign the node definition json, this will take
          # care of populating the run_list.
          chef.json = node_json
        end
      end
    end
  end
end
```

For a complete example `Vagrantfile` see <https://github.com/TalkingQuickly/rails-server-template/blob/master/Vagrantfile>

## Using with Berkshelf

If you're using Berkshelf, it may be tempting to simply use the `cookbooks` directory as `chef.cookbooks_path`. The problem with this however is that the `cookbooks` directory is only populated when we run `knife solo cook` so there's no guarentee that `cookbooks` always contains the correct versions, just the correct versions from when we last ran a cook.

If we take the following workflow:

* Run a cook
* Update or add a dependency in our `Berksfile`
* Run `berks install` or `berks update`

At the end of this process, `cookbooks` will not contain the new or updated cookbook, it will still contain the previous version.

It is therefore safer to have Vagrant use the `berks-cookbooks` directory and then delete this directory and run `berks vendor` whenever we want to work with Vagrant. This is generally my preferred approach.

The other option is to use the `vagrant-berkshelf` plugin to automate inclusion of Berkshelf provided cookbooks in the `cookbooks_path`. To do this, first install the plugin:

```bash
vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1
```

Then add:

```ruby
config.berkshelf.enabled = true
```

To your Vagrantfile. The key limitation is that it states on the projects web page that it doesn't currently support multi machine vagrant files which is usually what we'll be generating with this approach.

## Directory Structure

This assumes that the `Vagrantfile` is in the root of a chef-solo repository. In some situations the chef repository will actually be in a subfolder, for a example if your chef repository is a subfolder (`chef`) in a Rails application and the Vagrantfile sits in the root of the Rails project.

If this is the case, simply modify the line which loads the nodes from:

```ruby
nodes = Dir[File.join(root_dir,'nodes','*.json')]
```

to:

```ruby
nodes = Dir[File.join(root_dir.'chef','nodes','*.json')]
```

and update the `chef.*_path` entries to be prefixed with `chef/`.

## Exclusions

While the purpose of using Vagrant and Chef is often to allow us to create testing environments which closely match our production environment, there are sometimes scenario where we need to subtly vary the configuration between our produciton VM's and our vagrant configurations.

A good example of this might be networking. When working with Linode I use a custom cookbook and role which sets up a private IP address for the node. If this cookbook is applied to a Vagrant machine, it will tend to break networking completely. I don't however want to modify my node definition for use with Vagrant because this defeats the prupose of auto generating it to begin with.

In the example Vagrantfile this is handled by an additional attribute in the node definitions `vagrant` section called `exclusions`. This accepts an array of strings which should be removed from the `run_list` attribute before assigning the JSON to `chef.json`.

This is handled by the following section of the `Vagrantfile`:

``` ruby
# Allow us to remove certain items from the run_list if we're
# using vagrant. Useful for things like networking configuration
# which may not apply.
if exclusions = node_json["vagrant"]["exclusions"]
  exclusions.each do |exclusion|
    if node_json["run_list"].delete(exclusion)
      puts "removed #{exclusion} from the run list"
    end
  end
end
```

So if we were to take a node with the following run list:

```ruby
"run_list":
[
  "role[ruby-box]",
  "role[nginx-server]",
  "role[linode-with-private-networking]",
  "role[mongo-server]"
]
```

And the following `vagrant` section:

```json
"vagrant" : {
  "exclusions" : ["role[linode-with-private-networking]"],
  ...
},
```

This would result in the Vagrant provisioner seeing the following run list:

```ruby
"run_list":
[
  "role[ruby-box]",
  "role[nginx-server]",
  "role[mongo-server]"
]
```

Both roles and recipes can be removed in this mannger.

## Starting the Vagrant Box(es)

* Make sure you have the vagrant omnibus plugin (<https://github.com/schisamo/vagrant-omnibus>) installed which allows you to specify the chef version which is used. To install it simply enter `vagrant plugin install vagrant-omnibus`.
* Make sure you've got at least one node definition with the `vagrant` section specified above
* If you're not using the `vagrant-berkshelf` plugin then run`bundle exec berks vendor`. If you've run this before you'll need to remove the `berks-cookbooks` directory first
* Run `vagrant up` to start and provision all nodes which have the vagrant section, or `vagrant up NAME` where NAME is the name from the vagrant section of the node defintion to start a single node

This will setup the VM and automatically run chef solo to provision it as per the node definition. Once this completes, you can then access the node as you would any other remote machine using the IP address specified in the `vagrant` section of the node definition.

## Users and SSH

A common issue when working with chef and vagrant is that it's normal for chef scripts to modify both users and who has access to sudo. If this means that the vagrant user is removed or removed from the sudoers group, this can mean that commands such as `vagrant ssh`, `vagrant halt` etc will stop working. More importantly if the vagrant user doesn't behave as expected, shared folders will generally not work correctly.

One solution to this is to ensure that if you are explicitly setting who has access to sudo, the vagrant user is included. So for example in the Rails server template, this section:

```json
"authorization": {
  "sudo": {
    "users": ["deploy"]
  }
},
```

would be replaced with:


```json
"authorization": {
  "sudo": {
    "users": ["deploy", "vagrant"]
  }
},
```

The vagrant user also by default has passwordless sudo enabled, behaviour seems to be unpredictable if this is disabled but sometimes it will simply prompt you for the vagrant users password which is `vagrant`.

## Tips

* Node names must be made up of the characters a-z, 0-9, hypens and dots only. This allows the hostname to be set to the node name
* You can force provisioning to run again by stopping the VM (`vagrant halt` or `vagrant halt NAME`) and then running `vagrant up` or `vagrant up NAME` with the `--provision` option
