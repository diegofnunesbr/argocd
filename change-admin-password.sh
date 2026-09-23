#!/bin/bash
set -euo pipefail

CTX="${KUBE_CONTEXT:-k0s}"
K="kubectl --context=$CTX"
$K -n argocd get secret argocd-secret >/dev/null || { echo "Sem acesso ao ArgoCD pelo contexto '$CTX' (ver README, seção do kubeconfig)."; exit 1; }

read -rsp "Nova senha do admin do Argo CD: " PW; echo
read -rsp "Confirme a senha: " PW2; echo
[ -n "$PW" ] && [ "$PW" = "$PW2" ] || { echo "Senhas vazias ou diferentes."; exit 1; }

HASH=$(printf '%s' "$PW" | htpasswd -niBC 10 "" | tr -d ':\n' | sed 's/^\$2y/\$2a/')
MTIME=$(date -u +%FT%TZ)

printf '{"stringData":{"admin.password":"%s","admin.passwordMtime":"%s"}}' "$HASH" "$MTIME" \
  | $K -n argocd patch secret argocd-secret --type merge --patch-file /dev/stdin >/dev/null
$K -n argocd delete secret argocd-initial-admin-secret --ignore-not-found >/dev/null
echo "Pronto. Login: admin + senha nova em https://argocd.diegofnunesbr.com (sessões abertas são deslogadas)."
