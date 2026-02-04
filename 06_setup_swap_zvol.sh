#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m   $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR]\e[0m  $*"; }
require_root() { if [[ $EUID -ne 0 ]]; then err "Lancez ce script avec sudo ou en root."; exit 1; fi; }
require_tools() { for b in zpool zfs grep awk sed pvesm; do command -v "$b" >/dev/null 2>&1 || { err "Binaire manquant: $b"; exit 1; }; done; }
ensure_pool() { local POOL="$1"; if ! zpool list -H -o name "$POOL" >/dev/null 2>&1; then err "Le zpool '$POOL' n'existe pas. Ex: rpool"; exit 1; fi; }

# 06_setup_swap_zvol.sh — Crée/ajuste un zvol de swap 16G et l'active
POOL="${1:-rpool}"
SWAP_SIZE="${2:-16G}"
require_root
require_tools
ensure_pool "$POOL"
ZVOL="$POOL/swap"
NEED_CREATE=1
if zfs list -t volume "$ZVOL" >/dev/null 2>&1; then
  CUR_SIZE="$(zfs get -H -o value volsize "$ZVOL" 2>/dev/null || echo "")"
  if [[ "$CUR_SIZE" == "$SWAP_SIZE" ]]; then
    info "zvol swap déjà présent avec la bonne taille ($SWAP_SIZE)."
    NEED_CREATE=0
  else
    warn "zvol swap présent mais volsize=$CUR_SIZE, attendu=$SWAP_SIZE → recréation."
  fi
fi
if (( NEED_CREATE )); then
  info "Création/Récréation du zvol de swap ($SWAP_SIZE)."
  swapoff -a || true
  zfs destroy -f "$ZVOL" 2>/dev/null || true
  zfs create -V "$SWAP_SIZE" -b 4K     -o compression=zle -o logbias=throughput -o sync=always     -o primarycache=metadata -o secondarycache=none     "$ZVOL"
  mkswap -f "/dev/zvol/$ZVOL"
  if grep -q '^/dev/zvol/' /etc/fstab 2>/dev/null; then
    sed -i 's#^/dev/zvol/.*swap.*#/dev/zvol/'"$ZVOL"' none swap defaults 0 0#' /etc/fstab
  else
    echo "/dev/zvol/$ZVOL none swap defaults 0 0" >> /etc/fstab
  fi
  swapon "/dev/zvol/$ZVOL"
  ok "Swap zvol actif: $SWAP_SIZE"
fi
swapon --show || true
