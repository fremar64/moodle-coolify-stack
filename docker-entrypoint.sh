#!/bin/bash
set -e

echo "=== Initialisation du conteneur Moodle ==="

# Définir les variables d'environnement Apache
export APACHE_DOCUMENT_ROOT=/var/www/html/public
export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data

# Attendre que la base de données soit prête
echo "Attente de la base de données..."
while ! nc -z db 3306; do
  sleep 1
done
echo "Base de données accessible ✓"

# Vérifier que Moodle est présent (monté via volume)
if [ ! -f /var/www/html/public/index.php ]; then
    echo "ERREUR: Fichiers Moodle manquants dans /var/www/html/public"
    echo "Assurez-vous que le volume ./moodle:/var/www/html est correctement monté"
    exit 1
fi
echo "Fichiers Moodle présents ✓"

# Les dépendances Moodle sont intégrées dans lib/
# Composer n'est pas nécessaire pour une installation standard
echo "Dépendances Moodle intégrées ✓"

# Télécharger le pack de langue français si absent
if [ ! -d /var/www/html/public/lang/fr ]; then
    echo "Téléchargement du pack de langue français..."
    mkdir -p /var/www/html/public/lang
    curl -s -L -o /tmp/fr.zip "https://download.moodle.org/download.php/direct/langpack/5.1/fr.zip" && \
    if [ -s /tmp/fr.zip ] && unzip -t /tmp/fr.zip > /dev/null 2>&1; then \
        unzip -q /tmp/fr.zip -d /var/www/html/public/lang/ && \
        echo "Pack de langue français installé ✓"; \
    else \
        echo "Impossible de télécharger le pack français, sera disponible via l'interface"; \
    fi && \
    rm -f /tmp/fr.zip
else
    echo "Pack de langue français déjà présent ✓"
fi

# Vérifier et corriger les permissions
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/html
chown -R www-data:www-data /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
chmod -R 755 /var/www/html
chmod -R 775 /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
echo "Permissions configurées ✓"

# Configuration Apache personnalisée
cat > /etc/apache2/conf-available/moodle.conf << 'EOF'
<Directory /var/www/html/public>
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
echo "Code source: Volume monté depuis ./moodle (DocumentRoot: /public)"
echo "Fichiers Moodle: $(ls -la /var/www/html/public/index.php 2>/dev/null || echo 'MANQUANTS')"
echo "================================"

echo "Démarrage d'Apache..."
exec "$@"