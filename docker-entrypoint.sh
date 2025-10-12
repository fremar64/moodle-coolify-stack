#!/bin/bash
set -e

echo "=== Initialisation du conteneur Moodle ==="

# Définir les variables d'environnement Apache
export APACHE_DOCUMENT_ROOT=/var/www/html
export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data

# Attendre que la base de données soit prête
echo "Attente de la base de données..."
while ! nc -z db 3306; do
  sleep 1
done
echo "Base de données accessible ✓"

# Vérifier que Moodle est présent
if [ ! -f /var/www/html/index.php ]; then
    echo "ERREUR: Fichiers Moodle manquants dans /var/www/html"
    exit 1
fi
echo "Fichiers Moodle présents ✓"

# Vérifier et corriger les permissions
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
chmod -R 755 /var/www/html
chmod -R 775 /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
echo "Permissions configurées ✓"

# Configuration Apache personnalisée
cat > /etc/apache2/conf-available/moodle.conf << 'EOF'
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    DirectoryIndex index.php
</Directory>

# Optimisations pour Moodle
ServerTokens Prod
ServerSignature Off
LimitRequestBody 268435456
EOF

a2enconf moodle
echo "Configuration Apache activée ✓"

# Afficher les informations de démarrage
echo "=== Informations de démarrage ==="
echo "Apache Document Root: $APACHE_DOCUMENT_ROOT"
echo "Moodle WWW Root: ${MOODLE_WWWROOT:-Non défini}"
echo "Base de données: ${MOODLE_DB_HOST:-db}:3306"
echo "Redis: ${MOODLE_REDIS_HOST:-redis}:${MOODLE_REDIS_PORT:-6379}"
echo "Fichiers Moodle: $(ls -la /var/www/html/index.php 2>/dev/null || echo 'MANQUANTS')"
echo "================================"

echo "Démarrage d'Apache..."
exec "$@"