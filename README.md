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
5. **`argocd`** (este repositório) - `argocd-install.yaml`, depois o
   bootstrap do app-of-apps (`helm template clusters/homelab | kubectl
   apply -n argocd -f -`), que traz o `sealed-secrets` via `core-config`.
   **Sealed Secrets sai daqui** - é pré-requisito de tudo que vem depois.
6. **`ingress-nginx`** - Application própria (chart oficial +
   `values.yaml`), com `hostNetwork: true`, escutando `80`/`443` direto
   no node.
7. **`dns`** - registros DNS no Cloudflare via Terragrunt, incluindo o
   de cada serviço que vai ganhar Ingress (`argocd`, `ia`, `mimir`,
   `grafana`, `jenkins`, `rundeck`, tudo apontando pro IP da `vm-ubuntu`).
8. **`cert-manager`** - depende do Sealed Secrets (passo 5, pro
   `cert-manager-secret` com o token do Cloudflare) e indiretamente do
   `dns` (passo 7, o `ClusterIssuer` só emite certificado depois que o
   registro DNS do domínio já existir). Depois de saudável, aplique
   `argocd-ingress.yaml` **deste** repositório pra trocar o acesso ao
   próprio ArgoCD de port-forward pra `https://argocd.diegofnunesbr.com`.
9. **`rundeck`** - `deploy.sh` direto no node do k0s (imagem local,
   chave SSH e a Application), depois "Preparar hosts" (só pra VMs fora
   do fluxo `terraform`) e "Configuração" (projeto, node source,
   autenticação SSH, jobs).
10. **`mimir`** - depende do ArgoCD, `cert-manager` e `ingress-nginx`
    (passos 5/6/8) e do registro DNS `mimir.diegofnunesbr.com` (passo 7).
11. **`grafana`** - mesmas dependências do Mimir (passo 10), mais o
    próprio Mimir (pro datasource).
12. **`jenkins`** - mesmas dependências do Mimir (passo 10). Rodar
    `./build.sh` **antes** de aplicar a Application (o próprio README do
    repositório já avisa, mas é fácil esquecer nessa altura do processo).
13. **`samba`** - depende do Sealed Secrets (passo 5) e do pool ZFS na
    `vm-ubuntu` (passos 0/1 do README dele).
14. **`ia`** - mesmas dependências do Mimir (passo 10). Build/import das
    imagens antes de aplicar a Application.
15. **Onboardar as VMs** - job `onboard-vm` do Rundeck (passo 9) em cada
    VM criada no passo 3, a qualquer momento depois do Mimir (passo 10)
    estar de pé - o Alloy já sai configurado apontando pra
    `https://mimir.diegofnunesbr.com`, sem passo manual.

Lembrete que vale pra todos os repositórios com Application: elas leem
do GitHub, não do seu clone local - todo `git push` esquecido é uma
sincronização que não acontece.

**Todos os serviços com Ingress usam o mesmo par de mudanças**: Service
`ClusterIP` (nunca `NodePort`) + bloco `ingress` (ou um `Ingress` à mão,
pros repositórios sem chart Helm) com a anotação
`cert-manager.io/cluster-issuer: letsencrypt-clusterissuer` - o resto
(emissão do certificado, renovação) é automático.

## Pré-requisitos

- `Kubernetes` instalado
- `kubectl` e `helm` instalados

## Estrutura do repositório

```text
argocd/
├── argocd-install.yaml            # instalação do ArgoCD em si
├── argocd-ingress.yaml            # Service ClusterIP + Ingress com TLS via cert-manager
├── change-admin-password.sh       # troca a senha do admin
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
    │   └── sealed-secrets.yaml
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
```

Nesse ponto ainda não tem `Ingress` (depende do `ingress-nginx`,
repositório separado) nem TLS (depende do `cert-manager`, repositório
separado, instalado depois). Pra acompanhar o bootstrap visualmente
enquanto isso, use port-forward:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Acesse `http://localhost:8080`, login `admin` + senha inicial:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Bootstrapar o cluster (app of apps)

```bash
helm template clusters/homelab | kubectl apply -n argocd -f -
```

Isso cria a `Application core-config`, que o próprio ArgoCD sincroniza e
expande nas Applications reais (hoje só `sealed-secrets`).

## Expor o ArgoCD via Ingress (depois do cert-manager instalado)

Só depois que `cert-manager` e `ingress-nginx` (repositórios separados)
estiverem saudáveis:

```bash
kubectl apply -f argocd-ingress.yaml
```

Isso troca o Service pra `ClusterIP` e cria um `Ingress` com TLS
automático - o próprio port-forward acima para de ser necessário depois
disso.

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

Com `argocd-ingress.yaml` aplicado:

```text
https://argocd.diegofnunesbr.com
```

Certificado real (Let's Encrypt, renovado automaticamente pelo
cert-manager). O `argocd-server` roda com `server.insecure: true`
internamente (fala HTTP puro na porta `8080`) - o TLS é terminado no
`Ingress`/`ingress-nginx`, não no próprio ArgoCD, então isso é
transparente pra quem acessa.

Login `admin` + senha definida em "Trocar a senha do admin" abaixo (ou,
numa instalação nova antes de trocar, a inicial autogerada:
`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`).

## Trocar a senha do admin

Rode daqui do seu clone (precisa de `htpasswd` e `ssh` pra `vm-ubuntu`):

```bash
./change-admin-password.sh
```

Pede a senha sem ecoar, gera o hash bcrypt e grava em `argocd-secret`
(`admin.password`), que é onde o próprio ArgoCD guarda - e apaga o
`argocd-initial-admin-secret`, que deixa de valer. Diferente dos outros
repositórios, isso **não** vai pro git: o `argocd-secret` também guarda
chaves que o ArgoCD gera e escreve sozinho, então selar ele inteiro faria
o Sealed Secrets sobrescrever essas chaves. Numa reinstalação do zero,
basta rodar o script de novo.
