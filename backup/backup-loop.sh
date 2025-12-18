#!/bin/sh
set -eu

BACKUP_INTERVAL_SECONDS="${BACKUP_INTERVAL_SECONDS:-86400}"

if ! command -v backup-once.sh >/dev/null 2>&1; then
  echo "[BACKUP][WARN] backup-once.sh introuvable"
  exit 127
fi

while true; do
  backup-once.sh || true
  sleep "${BACKUP_INTERVAL_SECONDS}"
done
