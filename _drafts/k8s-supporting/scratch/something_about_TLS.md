helm install stable/traefik --name traefik1 --namespace kube-system --set ssl.enabled=true --set acme.enabled=true --set acme.email=ben@hillsbede.co.uk  --set loadBalancerIP=195.201.92.196

 kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')


helm install stable/nginx-ingress --namespace kube-system --set controller.hostNetwork=true,controller.kind=DaemonSet --set rbac.create=true --set controller.extraArgs.v=5 --set controller.service.type=NodePort --name nginx-ingress-1

helm install --name cert-manager --namespace kube-system stable/cert-manager --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt-prod,--default-issuer-kind=ClusterIssuer}'

apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cluster-issuer
spec:
  acme:
    # The ACME production api URL
    server: https://acme-v01.api.letsencrypt.org/directory

    # Email address used for ACME registration
    email: certificates@example.com

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-cluster-key-pair

    # Enable the HTTP-01 challenge provider
    http01: {}

https://blog.n1analytics.com/free-automated-tls-certificates-on-k8s/

https://medium.com/utinity/deploying-nginx-ingress-with-lets-encrypt-on-kubernetes-using-helm-a2a3b76a2e3e

https://github.com/jetstack/cert-manager/tree/v0.2.3/docs/api-types/issuer

https://github.com/jetstack/cert-manager/blob/master/docs/user-guides/ingress-shim.md
