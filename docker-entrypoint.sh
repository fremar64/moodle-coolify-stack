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

# Installer les dépendances Composer si nécessaire
if [ -f /var/www/html/composer.json ] && [ ! -d /var/www/html/vendor ]; then
    echo "Installation des dépendances Composer..."
    cd /var/www/html
    composer install --no-dev --classmap-authoritative --no-interaction --quiet
    echo "Dépendances Composer installées ✓"
elif [ -f /var/www/html/composer.json ]; then
    echo "Dépendances Composer déjà présentes ✓"
else
    echo "Aucun composer.json trouvé, Moodle sera configuré lors de l'installation"
fi

# Vérifier et corriger les permissions
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
chmod -R 755 /var/www/html
echo "Permissions configurées ✓"

# Configuration Apache personnalisée
cat > /etc/apache2/conf-available/moodle.conf << 'EOF'
<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
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
echo "Base de données: ${MOODLE_DB_HOST:-db}:${MOODLE_DB_PORT:-3306}"
echo "Redis: ${MOODLE_REDIS_HOST:-redis}:${MOODLE_REDIS_PORT:-6379}"
echo "================================"

echo "Démarrage d'Apache..."
exec "$@"