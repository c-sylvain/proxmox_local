#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m   $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR]\e[0m  $*"; }
require_root() { if [[ $EUID -ne 0 ]]; then err "Lancez ce script avec sudo ou en root."; exit 1; fi; }
require_tools() { for b in zpool zfs grep awk sed pvesm; do command -v "$b" >/dev/null 2>&1 || { err "Binaire manquant: $b"; exit 1; }; done; }
ensure_pool() { local POOL="$1"; if ! zpool list -H -o name "$POOL" >/dev/null 2>&1; then err "Le zpool '$POOL' n'existe pas. Ex: rpool"; exit 1; fi; }

# 03_tune_data_dataset.sh — Quota 1300G + compression=lz4 sur ${POOL}/data
POOL="${1:-rpool}"
DATA_QUOTA="${2:-1300G}"
require_root
require_tools
ensure_pool "$POOL"
DATA_DS="$POOL/data"
if ! zfs list "$DATA_DS" >/dev/null 2>&1; then
  warn "$DATA_DS n'existe pas, création..."
  zfs create "$DATA_DS"
fi
info "Mise en place du quota=${DATA_QUOTA} et compression=lz4 sur $DATA_DS"
zfs set "quota=$DATA_QUOTA" "$DATA_DS"
zfs set compression=lz4 "$DATA_DS"
ok "Quota/Compression OK pour $DATA_DS"
zfs list -o name,used,avail,quota,compression "$DATA_DS"
