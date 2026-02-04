#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m   $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR]\e[0m  $*"; }
require_root() { if [[ $EUID -ne 0 ]]; then err "Lancez ce script avec sudo ou en root."; exit 1; fi; }
require_tools() { for b in zpool zfs grep awk sed pvesm; do command -v "$b" >/dev/null 2>&1 || { err "Binaire manquant: $b"; exit 1; }; done; }
ensure_pool() { local POOL="$1"; if ! zpool list -H -o name "$POOL" >/dev/null 2>&1; then err "Le zpool '$POOL' n'existe pas. Ex: rpool"; exit 1; fi; }

# 02_set_root_quota.sh — Fixe refquota=100G sur le dataset root de Proxmox
POOL="${1:-rpool}"
ROOT_QUOTA="${2:-100G}"
require_root
require_tools
ensure_pool "$POOL"
# Détection auto du dataset racine (ex: rpool/ROOT/pve-1)
ROOT_DS="$(zfs list -H -o name | awk -v p="$POOL/ROOT/" '$0 ~ "^"p {print; exit}')"
if [[ -z "$ROOT_DS" ]]; then err "Impossible de trouver le dataset racine sous ${POOL}/ROOT/* — passez-le en 2e param."; exit 1; fi
info "Dataset racine détecté: $ROOT_DS → refquota=$ROOT_QUOTA"
zfs set "refquota=$ROOT_QUOTA" "$ROOT_DS"
ok "refquota appliquée sur $ROOT_DS"
zfs list -o name,refer,used,avail,refquota "$ROOT_DS"
