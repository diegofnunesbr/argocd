# Argo CD

Este guia descreve o deployment do **Argo CD** em um cluster **Kubernetes** e a instalação de infraestrutura e aplicações via GitOps.

## Pré-requisitos

- `Kubernetes` instalado
- `kubectl` instalado

## Estrutura do repositório

```text
argocd/
├── argocd-install.yaml     # Instalação do Argo CD (bootstrap manual)
├── argocd-configure.yaml   # Configurações do Argo CD (Ingress, ajustes)
└── README.md
```

---

## Instalar o Argo CD

```bash
git clone https://github.com/diegofnunesbr/argocd.git
cd argocd
kubectl apply -f argocd-install.yaml
```

## Instalar a infraestrutura base

### MetalLB

```bash
git clone https://github.com/diegofnunesbr/metallb-system.git
cd metallb-system
kubectl apply -f applications/argocd-metallb-system.yaml
```

### Ingress NGINX

```bash
git clone https://github.com/diegofnunesbr/ingress-nginx.git
cd ingress-nginx
kubectl apply -f applications/argocd-ingress-nginx.yaml
```

### cert-manager

```bash
git clone https://github.com/diegofnunesbr/cert-manager.git
cd cert-manager
kubectl apply -f applications/argocd-cert-manager.yaml
```

### sealed-secrets-controller

```bash
git clone https://github.com/diegofnunesbr/sealed-secrets-controller.git
cd sealed-secrets-controller
kubectl apply -f applications/argocd-sealed-secrets-controller.yaml
```

## Configurar o Argo CD

```bash
cd argocd
kubectl apply -n argocd -f argocd-configure.yaml
```

## Acessar o Argo CD

https://argocd.diegofnunesbr.com/

## Remover a infraestrutura base

### Ingress NGINX

```bash
cd ingress-nginx
kubectl delete -f applications/argocd-ingress-nginx.yaml
kubectl delete namespace ingress-nginx --ignore-not-found
```

### MetalLB

```bash
cd metallb-system
kubectl delete -f applications/argocd-metallb-system.yaml
kubectl delete namespace metallb-system --ignore-not-found
kubectl get crds | grep metallb.io | awk '{print $1}' | xargs kubectl delete crd
```

### cert-manager

```bash
cd cert-manager
kubectl delete -f applications/argocd-cert-manager.yaml
kubectl delete namespace cert-manager --ignore-not-found
kubectl get crds | grep cert-manager.io | awk '{print $1}' | xargs kubectl delete crd
```

### sealed-secrets-controller

```bash
cd sealed-secrets-controller
kubectl delete -f applications/argocd-sealed-secrets-controller.yaml
kubectl delete namespace sealed-secrets-controller --ignore-not-found
kubectl get crds | grep sealedsecrets.bitnami.com | awk '{print $1}' | xargs kubectl delete crd
```

## Remover o Argo CD

```bash
cd argocd
kubectl delete -f argocd-install.yaml
```
