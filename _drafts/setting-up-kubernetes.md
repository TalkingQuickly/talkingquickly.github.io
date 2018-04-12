---
layout : post
title: Setting up a Kubernetes Cluster with Kubeadm
date: 2018-04-08 08:45:00
categories: docker kubernetes
biofooter: true
bookfooter: false
docker_book_footer: true
---

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

Repeat on other nodes but instead of init, use the join command. If using ufw, allow all traffic between nodes.

If using UFW at a minimum need to open 6443 on the master. Remember that `ufw deny` and not having a ufw rule are different because there's a chain.

Get local access to the cluster:

(if have existing config make sure back it up, or use env vars for switching etc)

```
scp root@SERVER_IP:/etc/kubernetes/admin.conf ~/.kube/config-CLUSTER-NAME
```

Setup $KUBECONFIG

https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

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

https://github.com/kubernetes/helm/blob/master/docs/rbac.md

```
kubectl create serviceaccount tiller --namespace kube-system
```

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

```
helm initi --service-account tiller
```

Install the dashboard:

https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

```
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

And give it admin privileges:

https://github.com/kubernetes/dashboard/wiki/Access-control

```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
```

Then proxy and access using (https://dzone.com/articles/deploying-kubernetes-dashboard-to-a-kubeadm-create) :

http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

You can skip the login stage because we've given the dashboard full access

Setup persistence:

Deploy the rook operator (https://rook.github.io/docs/rook/master/helm-operator.html):

```
helm repo add rook-alpha https://charts.rook.io/alpha
helm install --namespace rook-system rook-alpha/rook
```

Then create a rook cluster (https://rook.github.io/docs/rook/master/quickstart.html#create-a-rook-cluster):

```
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

Execute:

```
kubectl create -f rook-cluster.yaml
```

Create some block storage (https://rook.github.io/docs/rook/master/block.html :

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
  provisioner: rook.io/block
  parameters:
    pool: replicapool
```

Set the newly created storageclass to the default (https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/):

```
 kubectl patch storageclass rook-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
 ```

 Now try deploying MySQL as an example:

```
helm install --name mysqltest2 stable/mysql
```

You can now see volume claims and volumes created:

```
kubectl get pvc
kubectl get pv
```

and that the mysql pod is running:

```
kubectl get pods
```

## Setting up ingress and SSL

Setup a wildcard DNS entry, make sure port 80 & 443 is open on whichever node you want to be internet facing.

```
helm install stable/nginx-ingress --namespace kube-system --set controller.hostNetwork=true,controller.kind=DaemonSet --set rbac.create=true --set controller.extraArgs.v=5 --set controller.service.type=NodePort --name nginx-ingress-1
```

```
helm install --name cert-manager --namespace kube-system stable/cert-manager --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt-cluster-issuer,--default-issuer-kind=ClusterIssuer}'
```

```
kubectl create -f cluster_issuer.yaml
```

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


## Accessing services

Forwarding ports: https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/

```
kubectl port-forward redis-master-765d459796-258hz 6379:6379
```
