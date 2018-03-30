## Setting up the cluster with Kubeadm

https://kubernetes.io/docs/setup/independent/install-kubeadm/

Docker

```
apt-get update
apt-get install -y docker.io
```

Kubeadm

```
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
```

https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

Setup the master

```
kubeadm init --pod-network-cidr=192.168.0.0/16
```

Make a note of the joining token:

```
kubeadm join 195.201.123.113:6443 --token breel6.r2l2v8pg8tp32lri --discovery-token-ca-cert-hash sha256:5dc7b3346c92a05a53b6d6ab4b098ff3eddc5a0e852988cb225e44ff309d0efb
```

Setup configuration for kubectl locally (optional)

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Setup a network

```
kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
```

Check everything is ready (takes a few minutes)

```
kubectl get nodes
```

Remove the master taint (optional)

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

Repeat on other nodes but instead of init, use the join command

If using UFW at a minimum need to open 6443

Get local access to the cluster:

(if have existing config make sure back it up, or use env vars for switching etc)

```
scp root@SERVER_IP:/etc/kubernetes/admin.conf ~/.kube/config-CLUSTER-NAME
```

Setup $KUBECONFIG

```
export KUBECONFIG=/home/ben/.kube/config-ONE:/home/ben/.kube/config-TWO
```

Then need to modify the configs to have descriptive names otherwise only the first one will show up; https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#merging-kubeconfig-files

then:

```
kubectl config view
kubectl config use-context CONTEXT-NAME
```

Can also do things like setting the namespace per context, e.g. one for `default`, one for `kube-system` etc

Setup helm and tiller:

```
kubectl create serviceaccount tiller --namespace kube-system
```

Setup persistence:
