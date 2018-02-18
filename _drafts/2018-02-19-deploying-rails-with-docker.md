# Deploying Rails with Docker Swarm

## Overview

At the end of this tutorial we will have:

* A `docker-compose` based development environment for your rails application
* A docker swarm cluster made up of one or more remote machines
* A private docker registry running on that swarm
* A rails application running on that swarm with automatic SSL (https)
* A very simple load balance that automatically exposes additional services we deploy on sub-domaind along with setting up SSL for them
* A password protected management interface for viewing the status of the load balancer

This will be accomplished using docker native tools and widely used community images. Once the swarm is created, it's easy to add additional nodes and multiple rails (or any other) applications can be deployed to it at once.

## Setting up the swarm

* Creating nodes
* Setting up firewall
* Creating a network

## Connecting to the swarm remotely

We'll need have Docker installed locally <https://docs.docker.com/install/>. We'll also need `docker-compose` installed, for OSX then this is included, for Linux, instructions are here; <https://docs.docker.com/compose/install/#install-compose>.

To connect to the remote swarm, we'll create an SSH tunnel to the remote server IP

```
ssh -fNT -L /tmp/remote-docker.sock:/var/run/docker.sock root@REMOTE_IP
export DOCKER_HOST=unix:///tmp/remote-docker.sock
```

You can verify you're correctly connected to the remote swarm with:

```
docker node ls
```

To revert to your local docker install you can simply `unset DOCKER_HOST`. I have the following aliases setup in my `.zshrc` to make these switches easier:

```
alias docker-book="rm -r /tmp/remote-docker.sock && ssh -fNT -L /tmp/remote-docker.sock:/var/run/docker.sock root@REMOTE_IP && export DOCKER_HOST=unix:///tmp/remote-docker.sock"
alias docker-local="unset DOCKER_HOST"
```

## Setting up DNS

One of the first things we'll set up is a front-end load balancer which will be responsible for exposing our application to the public Internet and obtaining a suitable SSL certificate via LetsEncrypt so that any service we expose is automatically available over HTTPS only. For this we will use [Traefik](https://traefik.io/) which is a powerful, easy to deploy HTTP reverse proxy and load balancer.

In order for our load balancer to route traffic correctly, we have to setup DNS routes for our traffic. For SSL to work, the hosts must be resolvable by LetsEncrypt on the public Internet rather than just amending our local hosts file.

To test without using a publicly accessible domain, local hosts file mappings can be used, but the certificate served will not be signed by a trust root and so we'll have to allow the certificates every time we visit a URL.

Setup an `A Record` for each of the sub-domains you wish to route, for example `www`. You should also setup a sub-domain for the load balancers management interface, e.g. `load-balancer.yourdomain.com`. Finally there should be a sub-domain for a private docker registry, e.g. `registry.yourdomain.com`

These A records should all point to the IP of one of the managers in the swarm.

I will often setup a single wildcard DNS entry for all sub-domains on a host so that additional services can be deployed dynamically without ever having to touch DNS. For example I'll setup a single `A Record` `*.dockertesting.talkingquickly.co.uk` pointing to one of the managers in the swarm. I can then deploy services with SSL to any sub-domain of that, without having to wait for DNS changes to propagate.

## Deploying the load balancer

To deploy the load balancer, create a new folder in the root of the project `deploy` and in this, add a file named `compose-load-balancer.yml` with the following content:

```
version: "3"
services:  
  traefik:
    image: traefik
    command:
      - traefik
      - --api
      - --debug=false
      - --logLevel=DEBUG
      - --defaultEntryPoints=https,http
      - --entryPoints=Name:http Address::80 Redirect.EntryPoint:https
      - --entryPoints=Name:https Address::443 TLS
      - --retry
      - --docker
      - --docker.swarmmode
      - --docker.endpoint=unix:///var/run/docker.sock
      - --docker.domain=YOUR_DOMAIN
      - --docker.watch
      - --docker.exposedbydefault=false
      - --acme
      - --acme.email=YOUR_EMAIL
      - --acme.storage=/certs/acme.json
      - --acme.entryPoint=https
      - --acme.onhostrule
      - --acme.httpchallenge
      - --acme.httpchallenge.entrypoint=http
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - certs:/certs
    networks:
      - internal-network
    ports:
      - "80:80"
      - "443:443"
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=internal-network"
        - "traefik.port=8080"
        - "traefik.frontend.rule=Host:URL_FOR_MANAGEMENT_INTERFACE"
        - "traefik.frontend.auth.basic=USERNAME:PASSWORD"
      placement:
        constraints:
          - node.role == manager

networks:
  internal-network:
    external: true

volumes:
  certs:
```

Replacing the following:

* `YOUR_EMAIL` with your email address
* `YOUR_DOMAIN` with the root domain you'll be using
* `URL_FOR_MANAGEMENT_INTERFACE` with the URL the management interface should be available on. This should be a URL which you've setup DNS for, e.g: `load-balancer.yourdomain.com`
* `USERNAME:PASSWORD_HASH` with your desired username and the hash of your password generated with `htpasswd -n USERNAME`. If you don't have `htpasswd` available you may need to install `apache2-utils` on Ubuntu. If the hash contains `$` signs you'll need to escape this by prefixing them with another `$`.

Then, ensuring you are connected to the remote swarm, execute the following in the root of the project:

```
docker stack deploy --compose-file deploy/compose-load-balancer.yml load-balancer
```

And wait for it to deploy. The first time may take a while images are pulled.

This will use the compose file we've created to deploy a stack to the swarm called `load-balancer`.

We can check on progress using the command:

```
docker stack services load-balancer
```

Which will output something like:

```
ID                  NAME                    MODE                REPLICAS            IMAGE               PORTS
mvnsb56pq3da        load-balancer_traefik   replicated          0/1                 traefik:latest      *:80->80/tcp,*:443->443/tcp
```

Once this returns `1/1` under replicas, then the stack is live. If this doesn't happen, you can use:

```
docker service ps load-balancer_traefik
```

To see more details. You can further drill in with:

```
docker service inspect load-balancer_traefik
```

and:

```
docker service logs load-balancer_traefik
```

To view logging output from the container.

Once replicas reads `1/1` you should be able to view the management interface by visiting the URL you chose e.g. `https://load-balancer.yourdomain.com`. You'll then be prompted for the credentials you generated with `htpasswd` and should see the management interface presented over HTTPS. Keep in mind that basic auth should only ever be used over `https` otherwise passwords are transmitted in plaintext.

The [documentation for traefik](https://docs.traefik.io/) is high quality and here we're barely scratching the service of what it's capable of.

## Deploying the registry

The final bit of setup needed before we can deploy the Rails application is a private registry to store the docker images containing our application code. We could use dockers own registry for this but for private images this incurs a cost and we may prefer to avoid the dependency on their infrastructure.

Add a file named `compose-load-balancer.yml` in the `deploy/` directory with the following content:

```
version: "3"
services:  
  registry:
    image: registry:2
    volumes:
      - registry:/var/lib/registry
    networks:
      - internal-network
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=internal-network"
        - "traefik.port=5000"
        - "traefik.frontend.rule=Host:URL_FOR_REGISTRY"
        - "traefik.frontend.auth.basic=USERNAME:PASSWORD_HASH"
      placement:
        constraints:
          - node.role == manager

networks:
  internal-network:
    external: true

volumes:
  registry:
```

As before replace:

* `URL_FOR_REGISTRY` with the URL the management interface should be available on. This should be a URL which you've setup DNS for, e.g: `load-balancer.yourdomain.com`
* `USERNAME:PASSWORD_HASH` with your desired username and the hash of your password generated with `htpasswd -n USERNAME`. If you don't have `htpasswd` available you may need to install `apache2-utils` on Ubuntu. If the hash contains `$` signs you'll need to escape this by prefixing them with another `$`.

We can then check on progress with:

```
docker stack services registry
```

Once the above shows `1/1` replicas we can login:

```
docker login URL_FOR_REGISTRY`
```

## Dockerising the Rails application

Follow the steps [in my other tutorial here](@TODO) to setup an existing or create a new Rails application with a Docker development environment.

## Building the Rails application for deployment

## Deploying the Rails application

## Running one off commands

## Updating the Rails application
