# argocd

Instalação do ArgoCD e o padrão "app of apps" pra gerenciar o que ele
implanta - mesmo padrão usado na empresa (documentado pelo próprio
ArgoCD: https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/),
com os apps do seu homelab, não os produtos/clientes reais da empresa.

## Ordem de bring-up completo do homelab

Cada repositório abaixo documenta a si mesmo, mas nenhum documenta a
ordem entre eles - essa é a sequência completa, do hardware até o
Jenkins, pra subir tudo do zero:

1. **Proxmox instalado e hardened** - instalação (`https://192.168.0.3:8006/`),
   usuário `diegofnunesbr@pam` como Administrator com 2FA, `root@pam`
   desabilitado na UI/API, SSH só por chave (sem senha, sem root). Runbook
   nas suas anotações pessoais, não é um repositório git.
2. **`cloud-init`** - perfis de primeira execução das VMs. Não precisa
   nenhuma ação isolada aqui na primeira vez, o `terraform` consome
   direto pelo `vm.yaml.tftpl`.
3. **`terraform`** - cria as VMs no Proxmox (`vm-ubuntu`, `vm-test`, etc.),
   já nascendo com a chave SSH pessoal e a do Rundeck autorizadas via
   cloud-init. Pré-requisito: `keys/rundeck.pub` já deve existir (gerado
   no passo do Rundeck abaixo) ou deixe `rundeck_ssh_public_key` vazio e
   rode `terragrunt apply` de novo depois.
4. **k0s** - instalado dentro da VM que vai hospedar o cluster
   (`vm-ubuntu`), single-node (`curl -sSLf https://get.k0s.sh | sudo sh`
   e sequência do repositório `k0s`).
5. **`rundeck`** - `deploy.sh` direto no node do k0s, depois "Preparar
   hosts" (só pra VMs fora do fluxo `terraform`) e "Configuração"
   (projeto, node source, autenticação SSH, jobs). É o único repositório
   que **não** depende do ArgoCD.
6. **`argocd`** (este repositório) - `argocd-install.yaml` +
   `argocd-nodeport.yaml`, depois o bootstrap do app-of-apps
   (`helm template clusters/homelab | kubectl apply -n argocd -f -`),
   que já traz `sealed-secrets` e `ingress-nginx` junto via
   `core-config`. **Sealed Secrets sai daqui** - é pré-requisito de
   `grafana` e `jenkins` abaixo.
7. **`mimir`** - depende só do ArgoCD (passo 6).
8. **`grafana`** - depende do ArgoCD + Sealed Secrets (passo 6) e do
   Mimir (passo 7, pro datasource).
9. **`jenkins`** - depende do ArgoCD + Sealed Secrets (passo 6). Rodar
   `./build.sh` **antes** de aplicar a Application (o próprio README do
   repositório já avisa, mas é fácil esquecer nessa altura do processo).
10. **Onboardar as VMs** - job `onboard-vm` do Rundeck (passo 5) em cada
    VM criada no passo 3, a qualquer momento depois do Mimir (passo 7)
    estar de pé, pra as métricas já aparecerem no Grafana.

Lembrete que vale pra `mimir`/`grafana`/`jenkins`/este repositório: as
Applications do ArgoCD leem do GitHub, não do seu clone local - todo
`git push` esquecido é uma sincronização que não acontece.

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
