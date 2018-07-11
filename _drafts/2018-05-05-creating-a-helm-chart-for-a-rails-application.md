---
layout : post
title: Deploying Rails to Kubernetes with Helm
date: 2018-04-29 15:40:00
categories: startups
biofooter: true
bookfooter: false
docker_book_footer: false
permalink: /deploying-rails-to-kubernetes-with-helm
---

Helm makes it easy to package up the services which make up a webapp, for example a Rails applications, a Postgres database and Redis, and then deploy them to a Kubernetes cluster. This tutorial covers how to create a Helm chart from scratch to do exactly this.

<!--more-->

The previous part of this tutorial explains [how to setup a Kubernetes cluster on any VPS or Bare Metal provider](/setting-up-kubernetes-with-kubeadm-on-vps-bare-metal).

In this section we'll create a helm chart which can be used to deploy a vanilla Rails application to this cluster. The sample code includes a `Dockerfile` which can be used for a simple Rails application but [this post has more details on how to Dockerise an existing Rails application](/2018/03/rails-development-environment-with-docker-compose/) as well as how to move the complete development workflow to Docker.

This tutorial assumes you have Docker installed and available locally as well as a working cluster from the previous tutorial. While this tutorial is primarily tested on the cluster configuration described their, it should work with minimal adaptations on any Kubernetes cluster with Helm / Tiller available.

## Adding a Dockerfile

## Running Locally Using a Dockerfile

## Setting up a remote registry

## Generating a new Chart with Helm

## Setting up dependencies

## Configuring Postgres

## Deploying

## Updating

## Debugging Tips













Create a new helm chart:

```
helm create APP_NAME
```

Update `values.yaml` to have correct `image/repository`

Add `requirements.yaml` with dependencies:

```
dependencies:
- name: postgresql
  version: 0.9.5
  repository: https://kubernetes-charts.storage.googleapis.com/
- name: redis
  version: 1.1.20
  repository: https://kubernetes-charts.storage.googleapis.com/
- name: memcached
  version: 2.0.4
  repository: https://kubernetes-charts.storage.googleapis.com/
```

Pull the required dependencies

```
helm dep list
helm dep update
```

Add a section to configure postgres:

```
postgresql:
  postgresUser: NCjbuaVVDvgEtxM
  postgresPassword: GDF7BbwKuTFgV8L
  postgresDatabase: DATABASE_NAME
```

Add the pull secret section to `templates/deployment.yaml` under the `spec` key:

```
imagePullSecrets:
  - name: {{ .Values.image.pullSecret }}
```

Update `containerPort` in `templates/deployment.yaml` to be `3000`

Add `env` vars under `container` key of `templates/deployment.yaml`:

```
env:
  - name: DATABASE_URL
    value: "mysql2://{{ .Values.mysql.mysqlUser }}:{{ .Values.mysql.mysqlPassword }}@{{ .Release.Name }}-mysql/{{ .Values.mysql.mysqlDatabase }}"
```

(May need to set `/admin/application_settings` registry token timeout to a higher value in gitlab)

## Configuration with Config Maps

https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
