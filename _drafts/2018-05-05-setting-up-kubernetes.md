---
layout : post
title: Setting up a Kubernetes Cluster on a VPS with Kubeadm
date: 2018-04-29 08:45:00
categories: docker kubernetes
biofooter: true
bookfooter: false
docker_book_footer: true
permalink: '/setting-up-kubernetes-with-kubeadm-on-vps-bare-metal'
---

Kubernetes makes it easy to deploy containerised applications to a cluster of servers. At the end of this tutorial we'll have a cluster setup over multiple nodes on any standard VPS provider (e.g. Digital Ocean, Linode, Hetzner Cloud etc) or bare metal servers. This means we can leverage the power of Kubernetes without the additional cost of high value add services such as AWS or Google Cloud.

The final system will have dynamic persistence management and automatic SSL certificates without relying on any provider specific functionality. Finally we'll have a visual dashboard where we can monitor the health of the cluster along with Helm/ Tiller installed for managing our deployed applications.

<!--more-->

## Setting up the cluster with Kubeadm

Begin by setting up one or more servers to use as Kubernetes nodes. Typically we would start with at least three but for staging or testing purposes, this tutorial will also work with just one. This tutorial has been tested on Hetzner Cloud and Digital Ocean.

Before continuing all nodes should be provisioned with Ubuntu 18.04 and at least 2GB of RAM, this tutorial has been tested primarily with 4GB+ of RAM. Swap should be disabled.

The Kubernetes project provides the [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) tool to make bootstrapping a reasonably secure, best practice Kubernetes cluster. The instructions in this section are primarily from the [kubeadm installation guide](https://kubernetes.io/docs/setup/independent/install-kubeadm/) and the [Using kubeadm to create a cluster guide](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/).

SSH into each of the nodes and execute the following commands as root:

```bash
# Setup Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80
ufw allow 443
ufw --force enable

# Disable Swap
swapoff -a
sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Docker
apt-get update
apt-get install -y docker.io

# Install Kubeadm
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
```

If working from the [sample code](@TODO Provide Link) then we can also simply execute:

```bash
ssh root@SERVER_IP < scripts/001-setup.sh
```

Once for each of the nodes.

Next, SSH into the node which is to be used as the master (this can be any node) and enter:

```
kubeadm init --pod-network-cidr=192.168.0.0/16
```

To setup the base Kubernetes install, this will take several minutes and at the end we'll see something like this:

```
Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 195.201.142.241:6443 --token 3n9uhr.pygh6vo2gexhqvwg --discovery-token-ca-cert-hash sha256:009658b59fae8e8c32ccdc71af7ad4609383872e05c8630c4a374bc233866b2f
```

It's important to make a note of the last line of this:

```
  kubeadm join 195.201.142.241:6443 --token 3n9uhr.pygh6vo2gexhqvwg --discovery-token-ca-cert-hash sha256:009658b59fae8e8c32ccdc71af7ad4609383872e05c8630c4a374bc233866b2f
```

To setup remote access, we'll also need to open port `6443` which is the port the Kubernetes API is available on. We'll then need to copy the Kubernetes configuration file for our cluster from the master, to our local machine.

Open port `6443` with:

```bash
ufw allow 6443
```

And then exit the SSH session.

## Local access with kubectl

When we ran `kubeadm init`, a file on our master `/etc/kubernetes/admin.conf` was generated which contains the keys and certificates needed to access our cluster. These certificates use the CA found in `/etc/kubernetes/pki/ca.crt` which may be required when integrating other services, such as Gitlab, with the cluster.

We begin by copying this file from the master node to our local machine. If you already have a kubernets configuration file at `$HOME/.kube/config` of your local machine then the below commands can be used to back it up. In practice there are much more elegant ways of managing multiple Kubernetes configuration files [as documented here](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) but this is beyond the scope of this tutorial.

The following should be executed from a local console on our development machine.

```
# Make sure kube config directory exists
mkdir -p ~/.kube

# Backup any old configuration if it exusts
[ -f ~/.kube/config ] && cp ~/.kube/config ~/.kube/config.backup

# Copy the config from our newly setup master node
scp root@<PUBLIC_IP_KUBE1>:/etc/kubernetes/admin.conf ~/.kube/config

# Use IP of our newly setup master
kubectl config set-cluster kubernetes --server=https://MASTER_IP:6443
```

To make use of the configuration file, we'll first need to [install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) which is the command line utility for interacting with a Kubernetes cluster.

Once this is installed we should be able to connect to the cluster, the command:

```
kubectl get nodes
```

And see something like the following:

```bash
NAME          STATUS     ROLES     AGE       VERSION
blog-test-1   NotReady   master    6m        v1.10.2
```

## Networking

The `NotReady` is because we haven't yet installed a network provider. There are many potential network providers which work out of the box with Kubernetes, in this case we'll be using Weave which requires almost no configuration out of the box and has built-in support for encrypting network traffic between nodes.

Once Weave is installed, a virtual network will be created which seamlessly spans all nodes in the system and allows workloads running on the cluster to access other workloads by hostname or IP, without any awareness of which node in the cluster they're running on. Services will be able to retain their IP's as they are moved between nodes, removing any need to think about the specifics of what is running where as we deploy applications to our cluster.

We can install Weave with just one command. Not that all `kubectl` commands should be executed locally:

```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

Which will give output such as the following:

```bash
serviceaccount "weave-net" created
clusterrole "weave-net" created
clusterrolebinding "weave-net" created
role "weave-net" created
rolebinding "weave-net" created
daemonset "weave-net" created
```

If we then check the list of nodes:

```
kubectl get nodes
```

We should see that the master node is now ready:

```bash
NAME          STATUS    ROLES     AGE       VERSION
blog-test-1   Ready     master    18m       v1.10.2
```

## Setting up a single node cluster

If you're just setting up a test cluster on a single node, then you'll need to remove the "master taint" to allow workloads to be schedule on the master node, you can do this with:

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

If you're adding multiple nodes and want the master to remain unable to run workloads directly, you can skip this step.

## Adding additional nodes

To add an additional node to the cluster, SSH into the node to be added and execute the joining command outputted by the `kubeadm init` process on the master, for example:

```bash
kubeadm join 195.201.142.241:6443 --token m2z792.hpy19zjskp0uwips --discovery-token-ca-cert-hash sha256:f2c01ee02cc227e88e4bad7bc5b78ef08f03489fd882296701df9bcad5ae0029
```

Once this has been completed for each worker node being added, the final step is to configure UFW to allow traffic between both the workers themselves and with the master node. The simplest approach is to simply allow all traffic on all ports between our nodes, to do this we would simply SSH into each node and enter:

```bash
# On node 1
ufw allow from NODE_2_IP
ufw allow from NODE_3_IP  

# On node 2
ufw allow from NODE_1_IP
ufw allow from NODE_3_IP  
...etc
```

However as well as being error prone, this gets exponentially harder as we add more nodes. In a large scale production deployment we'd manage these firewall rules with a configuration management system such as Ansible, Chef or Puppet, but to keep things lightweight, there's a simple bash script in the example code in `scripts/004-setup-firewall.sh` which will automate the process of opening just the ports we need between an arbitrary number of nodes:

```bash
#!/usr/bin/env bash

declare -a all_nodes=(
                      "IP1"
                      "IP2"
                      "IP3"
                     )

for target_node in "${all_nodes[@]}"
do
  for source_node in "${all_nodes[@]}"
  do
    echo ""
    for port in "10250" "20251" "10252" "10255" "6783" "6784"; do
      echo "ssh root@$target_node ufw allow from $source_node to any port $port"
      ssh root@$target_node ufw allow from $source_node to any port $port
    done
  done
done
```

To use this script simply replace `"IP1"` etc with the IP's of all nodes, including the master, in the cluster and then execute it with:

```
./scripts/004-setup-firewall.sh
```

The overlay network we're using - Weave - is a hugely powerful piece of software in itself, in particular there's more about [enabling encryption between nodes here](https://github.com/weaveworks-experiments/weave-kube/issues/38#issuecomment-253855874) and [troubleshooting here](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/).

Depending on the network being used, it's also possible to setup a VPN between the nodes themselves to further secure communications, using something like [WireGuard](https://www.wireguard.com/).

## Setting up the dashboard

Kubernetes includes a comprehensive web based dashboard which allows not only viewing the status of the cluster and applications deployed to it, but deploying new ones, managing logs and even executing a shell within a running application.

The dashboard is not deployed by default but we can deploy with a single command: as [described here](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/).

```bash
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

To access it we'll need to create a user (service account) and associate it with the automatically created admin role so that when logging into the dashboard, we'll have permissions to view and edit deployments.

To create the service account and role binding, we'll follow the [instructions from the dashboard wiki](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user).

The service account definition is defined in `kubernetes-definitions/dashboard/service-account.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
```

and the role binding in: `kubernetes-definitions/dashboard/cluster-role-binding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```

These can be create from a local console in the root of the example code with:

```
kubectl create -f kubernetes-definitions/dashboard/service-account.yaml
kubectl create -f kubernetes-definitions/dashboard/cluster-role-binding.yaml
```

We can then use this command to get the token for this newly created use:

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

By default the dashboard isn't publicly exposed anywhere, so to access it we start the kubectl proxy with:

```
kubectl proxy
```

Which will make the dashboard available on: <http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy>

When prompted enter the token we found above and the dashboard should then be available.

## Setup helm and tiller

The approach we've seen above, of using `yaml` files combined with `kubectl -f` is one of the primary ways of interacting with Kubernetes, through this approach we can create any combination of Kubernetes primitives and so deploy complex applications, it's a good idea to [get familiar with these concepts and primatives here](https://kubernetes.io/docs/concepts/).

While this approach is powerful, if our goal is simply to be able to deploy web applications to the cluster quickly, Helm and Tiller may offer a more suitable abstraction for day to day use. [Helm](https://github.com/kubernetes/helm) is part of the core Kubernetes offering and is best explained by it's own strapline:

> Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

By creating Helm charts, we can easily define exactly how to deploy an application, including any dependencies. What's more there's a large library of actively maintained charts for common pieces of software which we can make use of. So, for example, rather than trying to work out how to install PostgreSQL on Kubernetes from scratch, we can re-use the community chart to install and configure it with one command.

Building on that we can create charts for our own web applications and package up in there any dependencies, so our custom chart might explain how to deploy a Rails or Phoenix application, along with how to run background workers and how to configure the community PostgreSQL and Redis charts. This allows us to deploy complex applications with minimal effort.

Behind the scenes Helm is primarily a lightweight abstraction which makes generating and applying the Yaml definitions we've already seen less repetitive and more structured. As a result documentation which refers to using `kubectl create -f` is generally immediately applicable when we are developing custom helm charts.

Helm is made up of two components, the CLI (helm) and the server component Tiller which runs on the cluster and takes care of ensuring that the infrastructure state we define with our charts and apply using Helm is maintained on the server.

To begin with we need to [install the Helm client as per the instructions here] on our local development machine. Note that we do not need to follow the part of the linked guide relating to installing Tiller.

Once helm is installed then executing `helm` in a console our local machine should give a typical usage guide output.

As with the dashboard, we first need to create a `ServiceAccount` and a `ClusterRoleBinding` which links this service account to the `cluster-admin` role, thus giving it permissions to add and change anything about the cluster. This is required to allow it to fully manage the lifecycle of workloads we deploy.

First we create the `ServiceAccount`:

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
```

With:

```
kubectl create -f kubernetes-definitions/tiller/service-account.yaml
```

And then the `ClusterRoleBinding`:

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
```

With:

```
kubectl create -f kubernetes-definitions/tiller/cluster-role-binding.yaml
```

Finally we tell helm to setup `tiller` on our cluster using the new `ServiceAccount` we've just created.

```
helm init --service-account tiller
```

Note that Helm will use whichever is our currently active `kubeconfig` file to determine which Cluster to interact with so if `kubectl get nodes` outputs the nodes for the correct cluster then we can be confident that helm will connect to the correct cluster.

This process should only take a few seconds and will then display a confirmation that tiller is installed on the server. You can verify this by entering:

```bash
helm version
```

Which will show something like:

```bash
Client: &version.Version{SemVer:"v2.8.2", GitCommit:"a80231648a1473929271764b920a8e346f6de844", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.8.2", GitCommit:"a80231648a1473929271764b920a8e346f6de844", GitTreeState:"clean"}
```

Tip: if there's a problem installing Tiller such that `helm init` now gives an error that tiller is already installed by `helm list` outputs `Error: could not find tiller` there are two things we can try. Firstly we can use `helm reset --force`, if this fails then we can delete the deployment manually with `kubectl delete deployment tiller-deploy -n kube-system`, rectify the original mistake and then retry the installation.

## Setup persistence

Persistence is one of the harder problems when creating a Kubernetes cluster, a workload scheduled on one worker node could be moved to another worker node at any time and we need to ensure that any files persisted by the workload, for example the data directory of a database instance, will be available to it on the new node.

There are many possible solutions emerging, ranging from battle test but more complicated to configure options such as [Gluster](https://www.gluster.org/) to newer, Kubernetes native projects such as [Rook.io](https://rook.io/). Here we'll be using Rook for it's ease of configuration and first class integration with Kubernetes.

Rook is built on top of [Ceph](https://ceph.com/ceph-storage/file-system/), a battle-tested object storage system and takes care of allocating space to workloads when they request it (via persistent volume claims) and ensuring the data is replicated across multiple nodes to provide fault tolerance.

Now that we have Helm configured we can use it to install Rook, the below commands are taken from the [Rook installation instructions](https://rook.github.io/docs/rook/master/helm-operator.html):

```bash
helm repo add rook-alpha https://charts.rook.io/alpha
helm install --namespace rook-system rook-alpha/rook
```

Once this is completed, helm will provide a detail summary of the installation and what has been created as well as command we can use to check the status of Rook. This pattern of providing either a status command or, for a deployed application, a URL we can access it at, is common for helm charts.

Rook is now installed, but before it can be used, we need to configure it. Firstly we [create the cluster](https://rook.github.io/docs/rook/master/quickstart.html#create-a-rook-cluster):

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: rook
---
apiVersion: rook.io/v1alpha1
kind: Cluster
metadata:
  name: rook
  namespace: rook
spec:
  dataDirHostPath: /var/lib/rook
  storage:
    useAllNodes: true
    useAllDevices: false
    storeConfig:
      storeType: bluestore
      databaseSizeMB: 1024
      journalSizeMB: 1024
```

With the command:

```bash
kubectl create -f kubernetes-definitions/rook/cluster.yaml
```

Note that we are setting Rook to persist data to `/var/lib/rook` on each of our worker nodes. Alternatively if our nodes have dedicated block devices mounted for the purposes of persisting data, we could set `dataDirHostPath` to this path.


Then we [create some block storage](https://rook.github.io/docs/rook/master/block.html) on top of this Cluster:

```
apiVersion: rook.io/v1alpha1
kind: Pool
metadata:
  name: replicapool
  namespace: rook
spec:
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-block
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rook.io/block
parameters:
  pool: replicapool
```

With:

```bash
kubectl create -f kubernetes-definitions/rook/block-storage.yaml
```

We can now test our cluster with an installation of [PostgresSQL](helm install --name my-release stable/postgresql) as follows:

```
helm install --name pg-test-1 stable/postgresql
```

Once the command completes, it's worth taking note of the `notes` section of helms output:

```
NOTES:
PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:
pg-test-1-postgresql.default.svc.cluster.local

To get your user password run:

    PGPASSWORD=$(kubectl get secret --namespace default pg-test-1-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode; echo)

To connect to your database run the following command (using the env variable from above):

   kubectl run --namespace default pg-test-1-postgresql-client --restart=Never --rm --tty -i --image postgres \
   --env "PGPASSWORD=$PGPASSWORD" \
   --command -- psql -U postgres \
   -h pg-test-1-postgresql postgres

To connect to your database directly from outside the K8s cluster:
     PGHOST=127.0.0.1
     PGPORT=5432

     # Execute the following commands to route the connection:
     export POD_NAME=$(kubectl get pods --namespace default -l "app=postgresql,release=pg-test-1" -o jsonpath="{.items[0].metadata.name}")
     kubectl port-forward --namespace default $POD_NAME 5432:5432
```

This provides all the details needed to access the PostgreSQL instance we've created both from within the cluster and remotely.

We can confirm that rook is functioning as expected with the following:

```bash
kubectl get pvc
```

Which will output something like:

```bash
NAME                   STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pg-test-1-postgresql   Bound     pvc-ff4235c6-51fa-11e8-ab88-9600000a4339   8Gi        RWO            rook-block     6m
```

And:

```bash
kubectl get pv
```

Which will output something like:

```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                          STORAGECLASS   REASON    AGE
pvc-ff4235c6-51fa-11e8-ab88-9600000a4339   8Gi        RWO            Delete           Bound     default/pg-test-1-postgresql   rook-block               7m
```

Indicating that when our PostgreSQL install requested a persistent volume, Rook took care of provisioning and providing one.

We can now delete our test PostgreSQL installation:

```bash
helm delete --purge pg-test-1
```

## Setting up ingress and SSL

The final step in setting up our cluster is to enable Ingress. For our purposes Ingress takes care of exposing web applications to the outside world. This will allow us to include details about the domain which a web application we deploy with Helm should be available on and have routing and SSL taken care of automatically.

@TODO does this need to be a specific node? Setup a wildcard DNS entry, make sure port 80 & 443 is open on whichever node you want to be internet facing.

First we install the Nginx Ingree provider with:

```
helm install stable/nginx-ingress --namespace kube-system --set controller.hostNetwork=true,controller.kind=DaemonSet --set rbac.create=true --set controller.extraArgs.v=5 --set controller.service.type=NodePort --name nginx-ingress-1
```

Followed by Cert Manager which is responsible for automatically requesting certificates for new domains:

```
helm install --name cert-manager --namespace kube-system stable/cert-manager --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt-cluster-issuer,--default-issuer-kind=ClusterIssuer}'
```

Finally update the email address in `kubernetes-definitions/ingress/cluster-issuer.yaml` giving something like the following:

```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cluster-issuer
spec:
  acme:
    # The ACME production api URL
    server: https://acme-v01.api.letsencrypt.org/directory

    # Email address used for ACME registration
    email: EMAIL@EXAMPLE.ORG

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-cluster-key-pair

    # Enable the HTTP-01 challenge provider
    http01: {}
```

And then create the `ClusterIssuer`:

```bash
kubectl create -f kubernetes-definitions/ingress/cluster-issuer.yaml
```
We can confirm Ingress is working as expected by visiting http://WORKER_IP from a browser where we should see:

```
default backend - 404
```

Indicating the request was processed by the Nginx Ingress but there were no rules specified for where the request should be routed.

When setting up DNS to point one or more domains at the cluster, any of the worker IP's can be used.

## Deploying applications

Our Kubernetes cluster is now ready to use, [Part 2 of this tutorial covers how to deploy a Rails application to this cluster using Helm](@TODO LINK).









Add an ingress section:

```
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    certmanager.k8s.io/cluster-issuer: letsencrypt-cluster-issuer
  path: /
  hosts:
    - DOMAIN
  tls:
   - secretName: APP_NAME-tls
     hosts:
       - DOMAIN

```

## Private Registry

kubectl create secret docker-registry regcred --docker-server=SERVER_URL:PORT --docker-username='USERNAME' --docker-password='PERSONAL ACCESS TOKEN' --docker-email='EMAIL'

Remember this is namespaced, e.g. need one for every namespace

## Setting up Gitlab

The ca.crt is in /etc/kubernetes/pki/ca.crt on the root of the node, this is the PEM you have to give to gitlab see https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/

## Accessing services

Forwarding ports: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/

```
kubectl port-forward redis-master-765d459796-258hz 6379:6379
```

## Probably don't need this for Rook anymore

Set the newly created storageclass to the default (https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/):

```
 kubectl patch storageclass rook-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
 ```
