#!/bin/sh
set -eu

log() {
  echo "[BACKUP] $*"
}

warn() {
  echo "[BACKUP][WARN] $*"
}

now_ts() {
  date +%Y%m%d_%H%M%S
}

touch_heartbeat() {
  date +%s > /tmp/backup_heartbeat
}

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "Binaire manquant: $1"
    return 1
  fi
  return 0
}

DB_HOST="${DB_HOST:-db}"
DB_NAME="${DB_NAME:-moodle}"
DB_USER="${DB_USER:-moodle}"
DB_PASS="${MOODLE_DB_PASSWORD:-${MYSQL_PASSWORD:-}}"

BACKUP_INTERVAL_SECONDS="${BACKUP_INTERVAL_SECONDS:-86400}"
DROPBOX_PATH_BASE="${DROPBOX_PATH_BASE:-dropbox:/moodle_backups}"

# Sanity checks (soft — on continue pour au moins écrire des logs)
require_bin rclone || true
require_bin mysqldump || true

if [ -z "${DB_PASS}" ]; then
  warn "Mot de passe DB manquant: définir MOODLE_DB_PASSWORD (ou MYSQL_PASSWORD)"
fi

if [ -z "${DROPBOX_TOKEN:-}" ]; then
  warn "DROPBOX_TOKEN absent: aucun upload Dropbox ne sera fait"
fi

# Boucle principale
while true; do
  touch_heartbeat
  log "Démarrage - $(date)"

  TS="$(now_ts)"
  SQL_FILE="/scripts/db_backup_${TS}.sql"
  ERR_FILE="/scripts/db_backup_${TS}.err"

  dump_rc=0

  if [ -n "${DB_PASS}" ] && command -v mysqldump >/dev/null 2>&1; then
    mysqldump \
      --single-transaction \
      --quick \
      --skip-lock-tables \
      -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" \
      > "${SQL_FILE}" 2> "${ERR_FILE}" || dump_rc=$?
  else
    dump_rc=127
    echo "mysqldump non disponible ou mot de passe DB manquant" > "${ERR_FILE}"
  fi

  if [ "${dump_rc}" -eq 0 ]; then
    log "Dump SQL réussi: ${SQL_FILE}"
  else
    warn "Dump SQL échoué (rc=${dump_rc}). Voir: ${ERR_FILE}"
  fi

  # Upload Dropbox (toujours tenter l'upload des fichiers Moodle, indépendamment du dump SQL)
  if [ -n "${DROPBOX_TOKEN:-}" ] && command -v rclone >/dev/null 2>&1; then
    # Petit test rapide (utile pour diagnostiquer un token invalide)
    if ! rclone lsf "dropbox:" >/dev/null 2>&1; then
      warn "Connexion Dropbox impossible (token invalide/expiré ?). Vérifier DROPBOX_TOKEN."
    else
      log "Upload fichiers Moodle → ${DROPBOX_PATH_BASE}/files"
      rclone copy /data/moodle "${DROPBOX_PATH_BASE}/files" --progress || warn "Upload fichiers Moodle échoué"

      if [ -f "${SQL_FILE}" ]; then
        log "Upload dump SQL → ${DROPBOX_PATH_BASE}/sql"
        rclone copy "${SQL_FILE}" "${DROPBOX_PATH_BASE}/sql" --progress || warn "Upload dump SQL échoué"
      fi

      if [ -f "${ERR_FILE}" ]; then
        log "Upload log erreur → ${DROPBOX_PATH_BASE}/sql"
        rclone copy "${ERR_FILE}" "${DROPBOX_PATH_BASE}/sql" --progress || true
      fi

      log "Terminé - $(date)"
    fi
  else
    warn "Upload ignoré (DROPBOX_TOKEN absent ou rclone indisponible)"
  fi

  touch_heartbeat
  sleep "${BACKUP_INTERVAL_SECONDS}"
done
