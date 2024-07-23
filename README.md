# Argo CD

### Instalar o Argo CD no Kubernetes:

- `git clone git@github.com:diegofnunesbr/argocd.git`
- `cd argocd`
- `helm install --create-namespace argocd -n argocd .`

### Configurar o Argo CD no arquivo hosts do Windows:

- `sudo tee -a /mnt/c/Windows/System32/drivers/etc/hosts <<< "$(ifconfig eth0 | grep 'inet ' | awk '{print $2}') argocd.local"`

### Remover o Argo CD no Kubernetes:

- `helm uninstall argocd -n argocd`
