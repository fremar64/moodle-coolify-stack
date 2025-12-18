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

DB_HOST="${DB_HOST:-db}"
DB_NAME="${DB_NAME:-moodle}"
DB_USER="${DB_USER:-moodle}"
DB_PASS="${MOODLE_DB_PASSWORD:-${MYSQL_PASSWORD:-}}"

DROPBOX_PATH_BASE="${DROPBOX_PATH_BASE:-dropbox:/moodle_backups}"

# Rétention
LOCAL_SQL_RETENTION_DAYS="${LOCAL_SQL_RETENTION_DAYS:-14}"
SQL_REMOTE_RETENTION_DAYS="${SQL_REMOTE_RETENTION_DAYS:-30}"

# Sanity checks
if [ -z "${DB_PASS}" ]; then
  warn "Mot de passe DB manquant: définir MOODLE_DB_PASSWORD (ou MYSQL_PASSWORD)"
fi

if [ -z "${DROPBOX_TOKEN:-}" ]; then
  warn "DROPBOX_TOKEN absent: aucun upload Dropbox ne sera fait"
fi

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

# Upload Dropbox
if [ -n "${DROPBOX_TOKEN:-}" ] && command -v rclone >/dev/null 2>&1; then
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

    # Rétention distante des dumps SQL
    if [ -n "${SQL_REMOTE_RETENTION_DAYS}" ]; then
      log "Rétention distante SQL: suppression > ${SQL_REMOTE_RETENTION_DAYS} jours"
      rclone delete "${DROPBOX_PATH_BASE}/sql" \
        --min-age "${SQL_REMOTE_RETENTION_DAYS}d" \
        --include "db_backup_*.sql" \
        --include "db_backup_*.err" \
        --rmdirs || true
    fi

    log "Terminé - $(date)"
  fi
else
  warn "Upload ignoré (DROPBOX_TOKEN absent ou rclone indisponible)"
fi

# Rétention locale des dumps SQL
if [ -n "${LOCAL_SQL_RETENTION_DAYS}" ]; then
  find /scripts -maxdepth 1 -type f \
    \( -name 'db_backup_*.sql' -o -name 'db_backup_*.err' \) \
    -mtime "+${LOCAL_SQL_RETENTION_DAYS}" \
    -print -delete 2>/dev/null || true
fi

touch_heartbeat
