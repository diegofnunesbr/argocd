# argocd

Este guia descreve o deployment do **argocd** em um cluster **Kubernetes** e a instalação de infraestrutura e aplicações via GitOps.

## Pré-requisitos

- `Kubernetes` instalado
- `kubectl` instalado

## Estrutura do repositório

```text
argocd/
├── argocd-install.yaml       # Instalação do argocd
├── argocd-configure.yaml     # Configurações do argocd
└── README.md
```

---

## Instalar o argocd

```bash
git clone https://github.com/diegofnunesbr/argocd.git
cd argocd
kubectl apply -n argocd -f argocd-install.yaml
```

## Instalar a infraestrutura base

### metallb-system

```bash
git clone https://github.com/diegofnunesbr/metallb-system.git
cd metallb-system
kubectl apply -f applications/argocd.metallb-system.yaml
```

### ingress-nginx

```bash
git clone https://github.com/diegofnunesbr/ingress-nginx.git
cd ingress-nginx
kubectl apply -f applications/argocd.ingress-nginx.yaml
```

### sealed-secrets

```bash
git clone https://github.com/diegofnunesbr/sealed-secrets.git
cd sealed-secrets
kubectl apply -f applications/argocd.sealed-secrets.yaml
```

### cert-manager

```bash
git clone https://github.com/diegofnunesbr/cert-manager.git
cd cert-manager
kubectl apply -f applications/argocd.cert-manager.yaml
```

## Configurar o argocd

```bash
cd argocd
kubectl apply -n argocd -f argocd-configure.yaml
```

## Acessar o argocd

https://argocd.diegofnunesbr.com/

## Remover a infraestrutura base

### ingress-nginx

```bash
cd ingress-nginx
kubectl delete -f applications/argocd.ingress-nginx.yaml
kubectl delete namespace ingress-nginx --ignore-not-found
```

### metallb-system

```bash
cd metallb-system
kubectl delete -f applications/argocd.metallb-system.yaml
kubectl delete namespace metallb-system --ignore-not-found
kubectl get crds | grep metallb-system.io | awk '{print $1}' | xargs kubectl delete crd
```

### cert-manager

```bash
cd cert-manager
kubectl delete -f applications/argocd.cert-manager.yaml
kubectl delete namespace cert-manager --ignore-not-found
kubectl get crds | grep cert-manager.io | awk '{print $1}' | xargs kubectl delete crd
```

### sealed-secrets

```bash
cd sealed-secrets
kubectl delete -f applications/argocd.sealed-secrets.yaml
kubectl delete namespace sealed-secrets --ignore-not-found
kubectl get crds | grep sealedsecrets.bitnami.com | awk '{print $1}' | xargs kubectl delete crd
```

## Remover o argocd

```bash
cd argocd
kubectl delete -f argocd-install.yaml
```
