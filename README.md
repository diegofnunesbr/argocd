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
├── argocd-configure.yaml          # Ingress+TLS (precisa cert-manager/ingress-nginx)
├── argocd-nodeport.yaml           # expõe a UI via NodePort fixo (30843), sem dependências
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
kubectl apply -n argocd -f argocd-nodeport.yaml
```

`argocd-nodeport.yaml` expõe a UI direto num NodePort fixo (`30843`),
mesmo padrão de Mimir/Grafana/Rundeck nesse homelab - sem dependências,
funciona assim que o ArgoCD sobe. É o caminho recomendado por padrão.

Se preferir expor via Ingress+TLS com domínio próprio (`argocd.diegofnunesbr.com`)
em vez de NodePort, use `argocd-configure.yaml` no lugar - mas ele exige
`cert-manager`/`ingress-nginx` já instalados nesse cluster (`Certificate`
CRD e o webhook do ingress-nginx), senão o apply falha:

```bash
kubectl apply -n argocd -f argocd-configure.yaml
```

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

Com `argocd-nodeport.yaml` aplicado:

```text
http://<ip-do-node-k0s>:30843
```

Repare que é **http**, não https: o `argocd-install.yaml` sobe o
`argocd-server` com `server.insecure: true` (ambas as portas do Service
apontam pro mesmo `targetPort: 8080`, que só fala HTTP puro - TLS fica
por conta de um Ingress na frente, que não temos aqui). Login `admin` +
senha inicial autogerada:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Recomendado trocar essa senha no primeiro login (`argocd account update-password`
via CLI, ou pela própria UI em User Info).
