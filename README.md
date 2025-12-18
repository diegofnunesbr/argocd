# Argo CD

### Instalar o Argo CD:

- `git clone https://github.com/diegofnunesbr/argocd.git`
- `cd argocd`
- `kubectl apply -n argocd -f argocd-install.yaml`

### Instalar MetalLB:

- `cd argocd/applications`
- `kubectl apply -f argocd-metallb-system.yaml`

### Instalar ingress-nginx:

- `cd argocd/applications`
- `kubectl apply -f argocd-ingress-nginx.yaml`

### Instalar cert-manager:

- `cd argocd/applications`
- `kubectl apply -f argocd-cert-manager.yaml`

### Configurar o Argo CD:

- `cd argocd`
- `kubectl apply -n argocd -f argocd-configure.yaml`

### Instalar Pi-hole:

- `cd argocd/applications`
- `kubectl apply -f argocd-pihole.yaml`
