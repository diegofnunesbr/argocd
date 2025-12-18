# Argo CD

### Instalar o Argo CD:

- `git clone https://github.com/diegofnunesbr/argocd.git`
- `cd argocd`
- `kubectl apply -n argocd -f argocd-install.yaml`

### Instalar o MetalLB:

- `cd argocd/applications`
- `kubectl apply -f argocd-metallb-system.yaml`

### Instalar o ingress-nginx:

- `cd argocd/applications`
- `kubectl apply -f argocd-ingress-nginx.yaml`

### Instalar o cert-manager:

- `cd argocd/applications`
- `kubectl apply -f argocd-cert-manager.yaml`

### Configurar o Argo CD:

- `cd argocd`
- `kubectl apply -n argocd -f argocd-configure.yaml`

### Instalar o Pi-hole:

- `cd argocd/applications`
- `kubectl apply -f argocd-pihole.yaml`
