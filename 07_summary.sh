#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m   $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR]\e[0m  $*"; }
require_root() { if [[ $EUID -ne 0 ]]; then err "Lancez ce script avec sudo ou en root."; exit 1; fi; }
require_tools() { for b in zpool zfs grep awk sed pvesm; do command -v "$b" >/dev/null 2>&1 || { err "Binaire manquant: $b"; exit 1; }; done; }
ensure_pool() { local POOL="$1"; if ! zpool list -H -o name "$POOL" >/dev/null 2>&1; then err "Le zpool '$POOL' n'existe pas. Ex: rpool"; exit 1; fi; }

# 07_summary.sh — Récapitulatif de l'état ZFS/Storages
POOL="${1:-rpool}"
require_root
require_tools
ensure_pool "$POOL"
info "ÉTAT DU POOL"
zpool status "$POOL" || true
zpool get autotrim "$POOL" || true
echo
info "DATASETS"
zfs list -o name,used,avail,refer,quota,mountpoint || true
echo
info "VOLUMES"
zfs list -t volume || true
echo
info "STORAGES PROXMOX"
pvesm status || true
