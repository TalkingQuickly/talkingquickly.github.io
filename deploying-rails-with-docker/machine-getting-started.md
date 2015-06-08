## Overview

Most of this comes from <http://docs.docker.com/machine/>

## Pre-reqs

* Head over to <http://docs.docker.com/machine/> and install both docker-machine and the docker client as per the instructions.
* Make sure that you have at least verison 4.3.26 of Virtualbox installed

## Steps

Make sure it works:

    docker-machine ls

should give:

    NAME   ACTIVE   DRIVER       STATE   URL   SWARM

If you get command not found, then `docker-machine` isn't in your path.

Create a new machine with:

    docker-machine create --driver virtualbox dev

This will create a new machine in Virtualbox using boot2docker.

Check that it's running:

    docker-machine ls

Should give:

    NAME   ACTIVE   DRIVER       STATE     URL                         SWARM
    dev    *        virtualbox   Running   tcp://192.168.99.100:2376 

Make this docker instance the current one. That is the one your local docker client will use with:

    $(docker-machine env dev)
