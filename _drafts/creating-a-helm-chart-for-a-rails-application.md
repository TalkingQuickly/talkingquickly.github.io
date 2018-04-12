Create a new helm chart:

```
helm create APP_NAME
```

For Gitlab auto-devops usage then may want to rename folder to `chart`

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
