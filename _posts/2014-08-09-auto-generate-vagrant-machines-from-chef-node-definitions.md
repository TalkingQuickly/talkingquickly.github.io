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

The high level approach is simple, for any node we want a Vagrant machine for, we add a `vagrant` section to the definition json which defines some vagrant specific options, in particular the IP if we want to use private networking and the IP to use. In our `Vagrantfile` we then look for any `.json` files in the `nodes` directory, parse the JSON and if it contains a `vagrant` key, generate a Vagrant configuration on the fly.

The Vagrant section of our node definition looks like this:

``` ruby
...
"vagrant": {
  "name": "rails-pg-test-1", //a-z,0-9,- and . only 
  "ip":"192.168.1.50"
},
...
```

And our Vagrantfile looks likes this:

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
  # Gemfile
  config.omnibus.chef_version = "11.16.0"

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

      config.vm.define vagrant_name do |vagrant|
        vagrant.vm.hostname = vagrant_name

        # Only use private networking if we specified an
        # IP. Otherwise fallback to DHCP
        if vagrant_ip
          vagrant.vm.network :private_network, ip: vagrant_ip
        end

        vagrant.vm.provision "chef_solo" do |chef|

          # Use berks-cookbooks not cookbooks and remember
          # to explicitly vendor berkshelf cookbooks
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

## Using with Berkshelf

If you're using Berkshelf, it may be tempting to simply use the `cookbooks` directory as `chef.cookbooks_path`. The problem with this however is that the `cookbooks` directory is only populated when we run `knife solo cook` so there's no guarentee that `cookbooks` always contains the correct versions, just the correct versions from when we last ran a cook.

If we take the following workflow:

* Run a cook
* Update or add a dependency in our `Berksfile`
* Run `berks install` or `berks update`

At the end of this process, `cookbooks` will not contain the new or updated cookbook, it will still contain the previous version.

It is therefore safer to have Vagrant use the `berks-cookbooks` directory and then delete this directory and run `berks vendor` whenever we want to work with Vagrant.

There is a Vagrant plugin for directly integrating Vagrants chef provision with Berkshelf however its status is unclear (<see https://sethvargo.com/the-future-of-vagrant-berkshelf/>).

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

## Starting the Vagrant Box(es)
