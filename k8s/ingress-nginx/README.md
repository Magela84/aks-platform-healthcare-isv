# NGINX Ingress Controller + TLS (cert-manager)

One shared ingress controller fronts all four apps. Each app's Helm
release creates an `Ingress` object; NGINX watches for them and wires
up routing automatically. cert-manager issues and renews the TLS certs.

> `helm` and `kubectl` run in **Azure Cloud Shell** (both are
> pre-installed there). Run these after `az aks get-credentials`.

## 1. Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.replicaCount=2
```

Get the public IP Azure assigns to the load balancer:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

Point your DNS `A` records (`patient-portal.pulsehealth...`, etc.) at
that IP, or for a demo map it in `/etc/hosts`.

## 2. Install cert-manager (automatic TLS)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
```

## 3. Create a ClusterIssuer

Apply `cluster-issuer.yaml` (below) once. The app charts reference it
via `ingress.tls.clusterIssuer: letsencrypt-prod`.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: magela8403@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

## Notes

- For a quick internal demo without public DNS, set
  `ingress.tls.enabled=false` in the app values and use plain HTTP,
  or use a self-signed issuer instead of Let's Encrypt.
- Let's Encrypt HTTP-01 validation needs the DNS name to resolve to
  the ingress IP **before** the cert can be issued.
