#!/bin/bash
# Script de nettoyage du cache Moodle pour forcer le rechargement de config.php

set -e

resolve_moodle_container() {
	# 1) Override explicite.
	if [ -n "${MOODLE_CONTAINER:-}" ]; then
		echo "$MOODLE_CONTAINER"
		return 0
	fi

	# 2) Projet docker-compose local (service moodle).
	if command -v docker >/dev/null 2>&1 && docker compose ps -q moodle >/dev/null 2>&1; then
		local cid
		cid="$(docker compose ps -q moodle | head -n 1)"
		if [ -n "$cid" ]; then
			echo "$cid"
			return 0
		fi
	fi

	# 3) Nom historique (stack locale) ou conteneur Coolify (moodle-<id>-<hash>).
	local name
	name="$(docker ps --format '{{.Names}}' | grep -E '^(moodle_app|moodle-)' | head -n 1 || true)"
	if [ -n "$name" ]; then
		echo "$name"
		return 0
	fi

	return 1
}

run_purge_caches() {
	local container="$1"

	# Moodle standard (dirroot): /var/www/html/admin/cli/...
	if docker exec "$container" test -f /var/www/html/admin/cli/purge_caches.php 2>/dev/null; then
		docker exec "$container" php /var/www/html/admin/cli/purge_caches.php
		return 0
	fi

	# Fallback ancien chemin (certaines variantes).
	if docker exec "$container" test -f /var/www/html/public/admin/cli/purge_caches.php 2>/dev/null; then
		docker exec "$container" php /var/www/html/public/admin/cli/purge_caches.php
		return 0
	fi

	echo "[ERREUR] purge_caches.php introuvable dans le conteneur ($container)." >&2
	echo "Astuce: docker exec $container find /var/www -maxdepth 5 -name purge_caches.php" >&2
	return 1
}

echo "=== Nettoyage du cache Moodle ==="

CONTAINER="$(resolve_moodle_container)" || {
	echo "[ERREUR] Impossible de déterminer le conteneur Moodle." >&2
	echo "Définissez MOODLE_CONTAINER=<nom_ou_id> puis relancez." >&2
	exit 1
}

echo "Conteneur Moodle: $CONTAINER"

# 1. Purger le cache Moodle via CLI
echo "1. Purge du cache Moodle..."
run_purge_caches "$CONTAINER" || echo "Note: Purge peut échouer si Moodle n'est pas accessible"

# 2. Supprimer les fichiers de cache manuelle ment
echo "2. Suppression manuelle des fichiers cache..."
docker exec "$CONTAINER" bash -c "rm -rf /var/www/moodledata/cache/* /var/www/moodledata/localcache/* /var/www/moodledata/temp/*" || echo "Note: Certains fichiers peuvent ne pas exister"

# 3. Redémarrer le conteneur pour recharger config.php
echo "3. Redémarrage du conteneur Moodle..."
cd /home/ceredis/moodle-coolify-stack
if docker compose ps -q moodle >/dev/null 2>&1; then
	docker compose restart moodle
else
	docker restart "$CONTAINER"
fi

echo ""
echo "✓ Cache nettoyé et conteneur redémarré"
echo "Attendez 30 secondes puis testez : https://ecole-en-ligne.ceredis.net"
