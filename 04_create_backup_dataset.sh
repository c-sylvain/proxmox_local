#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m   $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR]\e[0m  $*"; }
require_root() { if [[ $EUID -ne 0 ]]; then err "Lancez ce script avec sudo ou en root."; exit 1; fi; }
require_tools() { for b in zpool zfs grep awk sed pvesm; do command -v "$b" >/dev/null 2>&1 || { err "Binaire manquant: $b"; exit 1; }; done; }
ensure_pool() { local POOL="$1"; if ! zpool list -H -o name "$POOL" >/dev/null 2>&1; then err "Le zpool '$POOL' n'existe pas. Ex: rpool"; exit 1; fi; }

# 04_create_backup_dataset.sh — Crée rpool/backup (mountpoint=/backup), quota=400G, tuning fichiers volumineux
POOL="${1:-rpool}"
BACKUP_QUOTA="${2:-400G}"
require_root
require_tools
ensure_pool "$POOL"
BACKUP_DS="$POOL/backup"
if ! zfs list "$BACKUP_DS" >/dev/null 2>&1; then
  info "Création du dataset de sauvegarde $BACKUP_DS (mountpoint=/backup)..."
  zfs create -o mountpoint=/backup "$BACKUP_DS"
else
  info "Dataset $BACKUP_DS déjà présent, on ajuste ses propriétés..."
  zfs set mountpoint=/backup "$BACKUP_DS"
fi
info "Réglages sauvegarde: quota=$BACKUP_QUOTA, compression=lz4, atime=off, recordsize=1M"
zfs set "quota=$BACKUP_QUOTA" "$BACKUP_DS"
zfs set compression=lz4 "$BACKUP_DS"
zfs set atime=off "$BACKUP_DS"
zfs set recordsize=1M "$BACKUP_DS"
ok "Dataset backup configuré."
zfs list -o name,used,avail,quota,mountpoint,recordsize,compression "$BACKUP_DS"
