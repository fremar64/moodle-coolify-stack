#!/bin/bash
#########################################
# Script de correction erreur cache Moodle
# Erreur: tool_forcedcache_cache_factory not found
# Date: 2025-12-10
#########################################

set -e

echo "========================================="
echo "Fix Moodle Cache Error - tool_forcedcache"
echo "========================================="
echo ""

# Étape 1 : Nettoyer les caches
echo "[1/5] Nettoyage des caches Moodle..."
rm -rf /var/www/html/public/cache/classes/* 2>/dev/null || true
rm -rf /var/www/moodledata/cache/* 2>/dev/null || true
rm -rf /var/www/moodledata/localcache/* 2>/dev/null || true
rm -rf /var/www/moodledata/temp/* 2>/dev/null || true
echo "✓ Caches nettoyés"

# Étape 2 : Vérifier les permissions
echo "[2/5] Correction des permissions..."
chown -R www-data:www-data /var/www/moodledata
chown -R www-data:www-data /var/www/html/public/cache
echo "✓ Permissions corrigées"

# Étape 3 : Recréer les répertoires de cache
echo "[3/5] Recréation des répertoires de cache..."
mkdir -p /var/www/moodledata/cache
mkdir -p /var/www/moodledata/localcache
mkdir -p /var/www/moodledata/temp
mkdir -p /var/www/html/public/cache/classes
chown -R www-data:www-data /var/www/moodledata/cache
chown -R www-data:www-data /var/www/moodledata/localcache
chown -R www-data:www-data /var/www/moodledata/temp
chown -R www-data:www-data /var/www/html/public/cache
echo "✓ Répertoires recréés"

# Étape 4 : Vérifier config.php
echo "[4/5] Vérification config.php..."
if grep -q "^\$CFG->alternative_cache_factory_class" /var/www/html/config.php 2>/dev/null; then
    echo "⚠️  Configuration cache forcé détectée dans /var/www/html/config.php"
    echo "   Commentez cette ligne manuellement ou utilisez la config depuis /var/www/html/config.php"
fi

if grep -q "^\$CFG->alternative_cache_factory_class" /var/www/html/public/config.php 2>/dev/null; then
    echo "⚠️  Configuration cache forcé détectée dans /var/www/html/public/config.php"
    echo "   Commentez cette ligne manuellement"
fi

echo "✓ Vérification terminée"

# Étape 5 : Test de santé
echo "[5/5] Test de santé..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/login/index.php | grep -q "200"; then
    echo "✅ Moodle répond correctement (HTTP 200)"
else
    echo "⚠️  Moodle ne répond pas encore avec HTTP 200"
    echo "   Redémarrez Apache avec : apache2ctl graceful"
fi

echo ""
echo "========================================="
echo "✅ Correction terminée !"
echo "========================================="
echo ""
echo "Prochaines étapes :"
echo "1. Redémarrer le conteneur Moodle (Coolify UI)"
echo "2. Tester : https://ecole-en-ligne.ceredis.net"
echo "3. Vérifier les logs : docker logs moodle_app --tail 50"
echo ""
