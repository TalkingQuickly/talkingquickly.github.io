## Steps

Make sure you've followed the machine getting started steps

## Install Swam

Taken from: <https://github.com/docker/swarm>

Assumes you have a working Go environment. on OSX basically:

    brew install go
    export GOPATH=~/go
    export PATH=$PATH:~/go/bin
    go get github.com/tools/godep

    $ mkdir -p $GOPATH/src/github.com/docker/
    $ cd $GOPATH/src/github.com/docker/
    $ git clone https://github.com/docker/swarm
    $ cd swarm
    $ godep go install .

Should then be able to do

    swarm

and get output.
