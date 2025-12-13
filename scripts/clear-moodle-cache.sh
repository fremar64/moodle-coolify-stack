#!/bin/bash
# Script de nettoyage du cache Moodle pour forcer le rechargement de config.php

set -e

echo "=== Nettoyage du cache Moodle ==="

# 1. Purger le cache Moodle via CLI
echo "1. Purge du cache Moodle..."
docker exec moodle_app php /var/www/html/public/admin/cli/purge_caches.php || echo "Note: Purge peut échouer si Moodle n'est pas accessible"

# 2. Supprimer les fichiers de cache manuelle ment
echo "2. Suppression manuelle des fichiers cache..."
docker exec moodle_app bash -c "rm -rf /var/www/moodledata/cache/* /var/www/moodledata/localcache/* /var/www/moodledata/temp/*" || echo "Note: Certains fichiers peuvent ne pas exister"

# 3. Redémarrer le conteneur pour recharger config.php
echo "3. Redémarrage du conteneur Moodle..."
cd /home/ceredis/moodle-coolify-stack
docker compose restart moodle

echo ""
echo "✓ Cache nettoyé et conteneur redémarré"
echo "Attendez 30 secondes puis testez : https://ecole-en-ligne.ceredis.net"
