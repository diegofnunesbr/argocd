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

### metallb

```bash
git clone https://github.com/diegofnunesbr/metallb.git
cd metallb
kubectl apply -f applications/argocd.metallb.yaml
```

### ingress-nginx

```bash
git clone https://github.com/diegofnunesbr/ingress-nginx.git
cd ingress-nginx
kubectl apply -f applications/argocd.ingress-nginx.yaml
```

### cert-manager

```bash
git clone https://github.com/diegofnunesbr/cert-manager.git
cd cert-manager
kubectl apply -f applications/argocd.cert-manager.yaml
```

### sealed-secrets-controller

```bash
git clone https://github.com/diegofnunesbr/sealed-secrets-controller.git
cd sealed-secrets-controller
kubectl apply -f applications/argocd.sealed-secrets-controller.yaml
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

### metallb

```bash
cd metallb
kubectl delete -f applications/argocd.metallb.yaml
kubectl delete namespace metallb --ignore-not-found
kubectl get crds | grep metallb.io | awk '{print $1}' | xargs kubectl delete crd
```

### cert-manager

```bash
cd cert-manager
kubectl delete -f applications/argocd.cert-manager.yaml
kubectl delete namespace cert-manager --ignore-not-found
kubectl get crds | grep cert-manager.io | awk '{print $1}' | xargs kubectl delete crd
```

### sealed-secrets-controller

```bash
cd sealed-secrets-controller
kubectl delete -f applications/argocd.sealed-secrets-controller.yaml
kubectl delete namespace sealed-secrets-controller --ignore-not-found
kubectl get crds | grep sealedsecrets.bitnami.com | awk '{print $1}' | xargs kubectl delete crd
```

## Remover o argocd

```bash
cd argocd
kubectl delete -f argocd-install.yaml
```
