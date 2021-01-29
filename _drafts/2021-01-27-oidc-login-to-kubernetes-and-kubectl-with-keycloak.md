---
layout : post
title: OIDC Login to Kubernetes and Kubectl with Keycloak
date: 2021-01-27 15:40:00
categories: devops
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: '/setting-up-oidc-login-kubernetes-kubectl-with-keycloak'
---

A commonly cited pain point for teams working with Kubernetes clusters is managing the configuration to connect to the cluster. All to often this ends up being either distributing Kubeconfig files with hardcoded credentials (insecure) or custom shell scripts over the AWS or GCP cli's.

In this post we'll integrate Kubernetes with Keycloak so that when we execute a `kubectl` or `helm` command, if the user is not already authenticated, they'll be presented with a keycloak browser login where they can enter their credentials.

We'll also configure group based access control, so we can, for example create a "KubernetesAdminstrators" group, and have all users in that group given `cluster-admin` access.

When we remove a user from Keycloak (or remove them from the relevant groups within Keycloak) they will then lose access to the cluster (subject to token expiry).

For this we'll be using OpenID Connect, more [here](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens) on how this works.

By default, configuring Kubernetes to support OIDC auth requires passing flags to the kubernetes API server. The challenge with this approach is that only one such provider can be configured and managed Kubernetes offerings - e.g. GCP or AWS - use this for their proprietary IAM systems.

To address this we will use [kube-oidc-proxy](https://github.com/jetstack/kube-oidc-proxy), a tool from Jetstack which allows us to connect to a proxy server which will manage OIDC authentication and use impersonation to give the authenticating user the required permissions. This approach has the benefit of being universal across clusters, so we don't have to follow different approaches for our managed vs unmanaged clusters.

This post is part of a series on single sign on for Kubernetes.

<!--more-->

{% include kubernetes-sso/contents.html active="kubernetesoidc" %}

{% include kubernetes-sso/pre-reqs.html %}

This also assumes you've already followed the Installing Keycloak section and have a functioning Keycloak instance you can login to with administrator rights.

## Setting up Keycloak

First we'll create a new client in Keycloak with Client ID: `kube-oidc-proxy` and client protocol: `openid-connect`. We'll then configure the following parameters for this client:

- **Access Type**: `confidential`, this is required for a client secret to be generated
- **Valid Redirect URLs**: `http://localhost:8000` and `http://localhost:18000`. This is used by [kubelogin](https://github.com/int128/kubelogin) as a callback when we login to kubectl and a browser window can be opened for us to authenticate with keycloak.

We can then save this new client and a new "Credentials" tab will appear. We'll need the generated client secret along with our client id (`kube-oidc-proxy`) for later steps.

## Setting up Kube OIDC Proxy

Having created the client, we can now create our configuration for `kube-oidc-proxy`. A base configuration can be found in `kube-oidc-proxy/values-kube-oidc.yml` and looks something like this:

```yaml
oidc:
  clientId: kube-oidc-proxy
  issuerUrl: https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master
  usernameClaim: sub

extraArgs:
  v: 10

ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
  hosts:
    - host: kube.ssotest.staging.talkingquickly.co.uk
      paths:
        - /
  tls:
    - secretName: oidc-proxy-tls
      hosts:
        - kube.ssotest.staging.talkingquickly.co.uk
```

The important things to customise here are:

- The `issuerUrl`, this is the URL of our keycloak instance, including the realm (in our case we're using the default master realm)
- The hostnames within the ingress definition. This URL will be a second Kubernetes API URL, so once our SSO login is setup, our kubeconfig files will point at this URL instead of the default cluster endpoint

The `extraArgs` `v: 10` sets `kube-oidc-proxy` to output verbose logging methods which is useful for debugging issues. In production this line can be removed.

We can then install `kube-oidc-proxy` with:

```
helm upgrade --install kube-oidc-proxy ./charts/kube-oidc-proxy --values kube-oidc-proxy/values-kube-oidc.yml
```

With `kube-oidc-proxy` up and running, we can now configure `kubectl` to use it. The simplest way to do this is with a `kubectl` plugin called [kubelogin](https://github.com/int128/kubelogin). With this plugin installed, when you execute a `kubectl` command, it will open a browser window for the user to login via Keycloak. It will then handle refreshing tokens and subsequently re-authorising if the session expires.

Installation instructions for `kubelogin` are [here](https://github.com/int128/kubelogin), if you use homebrew, it's as simple as `brew install int128/kubelogin/kubelogin`, otherwise I recommend [installing krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) to manage `kubectl` plugins which will then allow you to install the plugin with `kubectl krew install oidc-login`.

We'll then want to create a `kubeconfig.yml` file with the following contents (there's an example in `kubelogin/kuebconfig.yml`):

```yaml
apiVersion: v1
clusters:
- cluster:
    server: https://kube.ssotest.staging.talkingquickly.co.uk
  name: default
contexts:
- context:
    cluster: default
    namespace: identity
    user: oidc
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: oidc
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - oidc-login
      - get-token
      # - -v1
      - --oidc-issuer-url=https://sso.ssotest.staging.talkingquickly.co.uk/auth/realms/master
      - --oidc-client-id=kube-oidc-proxy
      - --oidc-client-secret=a32807bc-4b5d-40b7-8391-91bb2b80fd30
      - --oidc-extra-scope=email
      - --grant-type=authcode
      command: kubectl
      env: null
      provideClusterInfo: false
```

Replacing:

- The `server` url the ingress url we chose for `kube-oidc-proxy`
- The `oidc-issuer-url` with the same keycloak url we used in the `kube-oidc-proxy` configuration
- The value of `oidc-client-secret` with the secret key we extracted from the credentials tab of the client in Keycloak
- Optionally uncommenting the `-v1` line if you want to see verbose logging output

We can then execute 

```
export KUBECONFIG=./kubelogin/kubeconfig.yml
kubectl get pods  
```

Managing your kubeconfig files is beyond the scope of this tutorial but if you aren't already I strongly recommend some combination of [direnv](https://direnv.net) and [kubectx](https://github.com/ahmetb/kubectx). Both my Debian Remote Dev Env Environement (@todo link) and OSX Setup (@todo link) provide these tools out of the box.

It's important to note that the `export KUBECONFIG=./kubelogin/kubeconfig.yml` is local to an individual terminal session, so if you switch to a new terminal tab or close and re-open your terminal, it will be gone and you'll fallback to using whichever `KUBECONFIG` envrironment variable your shell is set to use by default.

When we execute the above we'll be sent out to a browser to login via Keycloak and once completed we'll be logged in.

We will however see an error along the lines of:

```
Error from server (Forbidden): pods is forbidden: User "oidcuser:7d7c2183-3d96-496a-9516-dda7538854c9" cannot list resource "pods" in API group "" in the namespace "identity"
```

Although our user is authenticated, e.g. Kubernetes knows that the current user is `oidcuser:7d7c2183-3d96-496a-9516-dda7538854c9`, this user is currently not authorised to do anything.

We can fix this by creating a cluster role binding which binds our user to the `cluster-admin` role which is the "superuser" role on Kubernetes.

We'll need to execute this in a separate temrinal, e.g. one in which we have not run `export KUBECONFIG=./kubelogin/kubeconfig.yml` and so `KUBECONFIG` is still pointing at a kubeconfig file which gives us admin access to the cluster.

```
kubectl create clusterrolebinding oidc-cluster-admin --clusterrole=cluster-admin --user='oidcuser:OUR_USER_ID'
```

Replacing OUR_USER_ID with our login users id from Keycloak (or from the error message above).

Note the `oidcuser:` prefix which is added due to the `usernamePrefix: "oidcuser:"` prefix configuration line in our Kube OIDC Proxy values file. This prevents users defined in Keycloak from conflicting with any kubernetes internal users.

## Keycloak login to kubernetes with groups

The above setup allows us to use `kubectl` while authenticating with our keycloak user. However for each user we have to create an individual cluster role binding assigning them permissions. This is manual and becomes painful for anything beyond a small handful of users.

The solution to this lies in groups, we'll configure our kubernetes oidc implementation to be aware of Keycloak groups. We can then create a `kubernetes-admins` group and have all users in this group given `cluster-admin` permissions automatically using a single ClusterRoleBinding.

Begin by creating a `KubernetesAdmins` group in Keycloak and then creating a new user and adding them to this group. 

We then need to update our Keycloak client to include the groups the user is a member of as part of the JWT.

We do this by going back to our `kube-oidc-client` entry under Keycloak clients and choosing the mappers tab then "Create".

We then enter the following:

- **Name**: `Groups`
- **Mapper Type**: `Group Membership`
- **Full Group Path**: `Off`

And then choosing save.

If we uncomment the `# - -v1` line in our `kubelogin/kubeconfig.yml` file, remove the contents of `~/.kube/cache/oidc-login/` and then execute a `kubectl` command e.g. `kubectl get pods` then we'll be asked to login and again and then we'll see that the decoded JWT now contains our groups, e.g:

```json
{
  ...                                         
  "groups": [                                                       
    "DockerRegistry",                                             
    "Administrators",
    "KubernetesAdmins"
  ],             
  ...
}
```

We can then create cluster role binding to give anyone with the `KubernetesAdmin` group, `cluster-admin` access. Our cluster role binding looks like this:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc-admin-group
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: oidcgroup:KubernetesAdmins
```

Note that `oidcgroup` which is added due to the `groupsPrefix: "oidcgroup:"` in our Kube OIDC Proxy values configuration. This prevents keycloak groups from colliding with in-built kubernetes groups.

We can apply the above with:

```
kubectl apply -f ./group-auth/cluster-role-binding.yml
```

And then delete our user specific cluster role binding with:

```
kubectl delete clusterrolebinding oidc-cluster-admin
```

We can confirm that our groups login works with a simple `kubectl get pods`.

We can take this further by creating more restrictive cluster roles (or using more of the in-built ones) to do things like creating users that only have access to certain namespaces within our cluster.

{% include kubernetes-sso/contents.html active="kubernetesoidc" %}