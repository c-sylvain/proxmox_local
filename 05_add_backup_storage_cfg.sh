#!/usr/bin/env bash
set -euo pipefail
info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok()   { echo -e "\e[1;32m[OK]\e[0m   $*"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $*"; }
err()  { echo -e "\e[1;31m[ERR]\e[0m  $*"; }
require_root() { if [[ $EUID -ne 0 ]]; then err "Lancez ce script avec sudo ou en root."; exit 1; fi; }
require_tools() { for b in zpool zfs grep awk sed pvesm; do command -v "$b" >/dev/null 2>&1 || { err "Binaire manquant: $b"; exit 1; }; done; }
ensure_pool() { local POOL="$1"; if ! zpool list -H -o name "$POOL" >/dev/null 2>&1; then err "Le zpool '$POOL' n'existe pas. Ex: rpool"; exit 1; fi; }

# 05_add_backup_storage_cfg.sh — Ajoute le stockage 'backup-local' → /backup dans /etc/pve/storage.cfg
require_root
require_tools
CFG="/etc/pve/storage.cfg"
if ! grep -qE '^dir:\s+backup-local' "$CFG" 2>/dev/null; then
  info "Ajout du stockage 'backup-local' dans $CFG..."
  cat <<'EOF' >> "$CFG"
dir: backup-local
    path /backup
    content backup
    prune-backups keep-last=7,keep-weekly=4,keep-monthly=3
EOF
  ok "Stockage backup-local ajouté."
else
  info "'backup-local' existe déjà dans $CFG, rien à faire."
fi
pvesm status || true
