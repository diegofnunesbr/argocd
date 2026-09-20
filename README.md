# argocd

Instalação do ArgoCD e o padrão "app of apps" pra gerenciar o que ele
implanta - mesmo padrão usado na empresa (documentado pelo próprio
ArgoCD: https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/),
com os apps do seu homelab, não os produtos/clientes reais da empresa.

## Pré-requisitos

- `Kubernetes` instalado
- `kubectl` e `helm` instalados

## Estrutura do repositório

```text
argocd/
├── argocd-install.yaml            # instalação do ArgoCD em si
├── argocd-configure.yaml          # configurações do argocd
├── clusters/
│   └── homelab/                    # chart raiz: bootstrapa tudo nesse cluster
│       ├── Chart.yaml
│       ├── values.yaml              # repoURL/targetRevision deste repositório
│       └── templates/
│           ├── appProject.yaml
│           └── core-config.yaml     # Application apontando pro chart core-config/
└── core-config/                     # apps de infraestrutura do cluster
    ├── Chart.yaml
    ├── values.yaml
    ├── applications/                 # um arquivo por app real
    │   ├── sealed-secrets.yaml
    │   └── ingress-nginx.yaml
    └── templates/
        ├── application.yaml          # gera uma Application por arquivo em applications/
        └── appProject.yaml
```

## Instalar o ArgoCD

```bash
git clone https://github.com/diegofnunesbr/argocd.git
cd argocd
kubectl create namespace argocd
kubectl apply -n argocd -f argocd-install.yaml
kubectl -n argocd wait --for=condition=Ready pod --all --timeout=120s
kubectl apply -n argocd -f argocd-configure.yaml
```

`argocd-configure.yaml` só serve pra expor a UI via Ingress com TLS - ele
falha se `cert-manager`/`ingress-nginx` ainda não estiverem instalados
nesse cluster (`Certificate` CRD ausente / webhook do ingress-nginx
inexistente). Pra só usar o ArgoCD como controlador (sincronizar
Applications, sem UI exposta), pule esse `apply` e siga direto pro
bootstrap abaixo - instale `cert-manager`/`ingress-nginx` depois, quando
quiser a UI.

## Bootstrapar o cluster (app of apps)

```bash
helm template clusters/homelab | kubectl apply -n argocd -f -
```

Isso cria a `Application core-config`, que o próprio ArgoCD sincroniza e
expande nas Applications reais (`sealed-secrets`, `ingress-nginx`, etc.).

## Adicionar um app novo de infraestrutura

1. Crie um arquivo em `core-config/applications/<nome>.yaml` com
   `name`, `repoURL`, `chart`, `targetRevision` e `namespace`.
2. Dê push - o ArgoCD sincroniza sozinho (`automated: prune, selfHeal`).

## Adicionar um grupo novo (tipo `core-config`)

1. Crie uma pasta irmã de `core-config/` (ex.: `observability/`), com a
   mesma estrutura (`Chart.yaml`, `values.yaml`, `applications/`,
   `templates/application.yaml`, `templates/appProject.yaml`).
2. Adicione um `templates/<nome-do-grupo>.yaml` em `clusters/homelab/`
   apontando pra essa pasta nova, igual `core-config.yaml`.

## Acessar o argocd

Configurável depois de expor o serviço (`kubectl port-forward` ou um
Ingress, dependendo do que já estiver rodando no cluster).
