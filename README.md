# Argo CD

Este guia descreve o deployment do **Argo CD** em um cluster **Kubernetes** e a instalação de infraestrutura e aplicações via GitOps.

## Pré-requisitos

- `Kubernetes` instalado
- `kubectl` instalado

## Instalar o Argo CD

```bash
git clone https://github.com/diegofnunesbr/argocd.git
cd argocd
kubectl apply -n argocd -f argocd-install.yaml
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

## Configurar o Argo CD

```bash
cd argocd
kubectl apply -n argocd -f argocd-configure.yaml
```

## Configurar o acesso local do Argo CD no Windows

> **Importante:** execute o comando abaixo em um PowerShell aberto como Administrador.

```powershell
Add-Content C:\Windows\System32\drivers\etc\hosts "192.168.1.3 argocd.local"
```

Substitua `192.168.1.3` pelo IP do Ingress/LoadBalancer do Argo CD no seu ambiente.

## Acessar o Argo CD

https://argocd.local/

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

## Remover o Argo CD

```bash
cd argocd
kubectl delete -f argocd-install.yaml
```
