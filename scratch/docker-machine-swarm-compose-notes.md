docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery file://my_cluster \
    swarm-master

    docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery file://my_cluster \
    swarm-node-00

 swarm manage --tlsverify --tlscacert=<CACERT> --tlscert=<CERT> --tlskey=<KEY>

## This works

 docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery token://0e656eab9f653bdbfb6032e7e9f4cd2f \
    swarm-master

 docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery token://0e656eab9f653bdbfb6032e7e9f4cd2f \
    swarm-node-00

 docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery token://0e656eab9f653bdbfb6032e7e9f4cd2f \
    swarm-node-01

eval "$(docker-machine env --swarm swarm-master)"

docker info will then give three machines

env is now this:

export DOCKER_TLS_VERIFY=yes
export DOCKER_CERT_PATH=/Users/ben/.docker/machine/machines/swarm-master
export DOCKER_HOST=tcp://192.168.99.109:3376

Which implies that certificates are being handled separately

export DOCKER_TLS_VERIFY=yes
export DOCKER_CERT_PATH=/Users/ben/.docker/machine/certs/
export DOCKER_HOST=tcp://127.0.0.1:4001

THIS works with the above nodes:

swarm manage --tlsverify --tlscacert /Users/ben/.docker/machine/certs/ca.pem --tlskey /Users/ben/.docker/machine/certs/key.pem --tlscert /Users/ben/.docker/machine/certs/cert.pem -H tcp://0.0.0.0:4001 file://my_cluster

where my_cluster contains:

192.168.99.110:2376
192.168.99.111:2376

swarm manage -H tcp://0.0.0.0:4001 file://my_cluster

swarm manage --tlsverify --tlscacert /Users/ben/.docker/machine/machines/swarm-master/ca.pem --tlskey /Users/ben/.docker/machine/machines/swarm-master/key.pem --tlscert /Users/ben/.docker/machine/machines/swarm-master/cert.pem -H tcp://0.0.0.0:4001 file://my_cluster

THIS WORKS:

docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery file://my_cluster \
    swarm-node-00

docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-discovery file://my_cluster \
    swarm-node-01

docker-machine create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery nodes://192.168.99.110:2376,192.168.99.111:2376 \
    swarm-master

$(docker-machine env --swarm swarm-master) 

docker info

Filters etc are set by environment variables, e.g. -e, so should be able to do this from compose!!!!

compose swarm integration hasn't been released yet; https://github.com/docker/compose/blob/master/SWARM.md

-m is memory so potentially docker compose can do that

Looks like my mid june:
	- Swarm will support builds
	- Compose will support automatic restarting


./docker-machine_darwin-amd64 create \
    -d virtualbox \
    --swarm \
    --swarm-discovery file://my_cluster \
    swarm-node-03

./docker-machine_darwin-amd64 create \
    -d virtualbox \
    --swarm \
    --swarm-discovery file://my_cluster \
    swarm-node-04


./docker-machine_darwin-amd64 create \
    -d virtualbox \
    --swarm \
    --swarm-master \
    --swarm-discovery nodes://192.168.99.107:2376,192.168.99.110:2376 \
    swarm-master2

Boot2Docker SSH Creds (from: https://github.com/boot2docker/boot2docker):

user: docker
pass: tcuser

If using Boot2Docker then configure the Daemon in  /var/lib/boot2docker/profile

Don't use hypens in labels

Set a host label with the node

Port filters are applied automatically so can't accidentally schedule two things with the same port exposed

## Boot2Docker

Setup here: http://docs.docker.com/installation/mac/

	boot2docker init

	boot2docker start

	eval "$(boot2docker shellinit)"