# proxmox_local
Installation de proxmox sur un pc

Ces scripts découpent la configuration ZFS (Profil B) en étapes.
Ordre recommandé (sur Proxmox 8.4, mono-disque SSD, pool par défaut 'rpool') :

  00_check.sh [POOL]
  01_enable_autotrim.sh [POOL]
  02_set_root_quota.sh [POOL] [100G]
  03_tune_data_dataset.sh [POOL] [1300G]
  04_create_backup_dataset.sh [POOL] [400G]
  05_add_backup_storage_cfg.sh
  06_setup_swap_zvol.sh [POOL] [16G]
  07_summary.sh [POOL]

Exemples :
  sudo ./00_check.sh
  sudo ./01_enable_autotrim.sh
  sudo ./02_set_root_quota.sh rpool 100G
  sudo ./03_tune_data_dataset.sh rpool 1300G
  sudo ./04_create_backup_dataset.sh rpool 400G
  sudo ./05_add_backup_storage_cfg.sh
  sudo ./06_setup_swap_zvol.sh rpool 16G
  sudo ./07_summary.sh

Chaque script est idempotent autant que possible (sécurités, détections)
et accepte un premier argument facultatif pour le nom du pool (défaut: rpool).
