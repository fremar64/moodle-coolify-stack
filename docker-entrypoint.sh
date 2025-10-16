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
if [ ! -f /var/www/html/index.php ]; then
    echo "ERREUR: Fichiers Moodle manquants dans /var/www/html"
    echo "Assurez-vous que le volume ./moodle:/var/www/html est correctement monté"
    exit 1
fi
echo "Fichiers Moodle présents ✓"

# Vérifier l'état de /var/www/html/config.php (config réel généré par l'installateur)
CONFIG_TOP="/var/www/html/config.php"
if [ -e "$CONFIG_TOP" ]; then
    # Si c'est un lien symbolique vers public/config.php, on le supprime pour éviter une récursion
    if [ -L "$CONFIG_TOP" ]; then
        TARGET=$(readlink -f "$CONFIG_TOP" || true)
        if echo "$TARGET" | grep -q "/var/www/html/public/config.php$"; then
            echo "Suppression du symlink /var/www/html/config.php -> public/config.php (évite récursion)"
            rm -f "$CONFIG_TOP" || true
        fi
    fi
    # Si le fichier top-level contient le loader (signature de public/config.php), on le met de côté
    if [ -f "$CONFIG_TOP" ] && grep -q "Moodle configuration loader" "$CONFIG_TOP" 2>/dev/null; then
        echo "Attention: /var/www/html/config.php semble être un loader. Sauvegarde et suppression pour éviter une récursion..."
        mv "$CONFIG_TOP" "/var/www/html/config.php.bak.$(date +%s)" || true
    fi
fi

# Plus de liens symboliques: on utilise /public comme DocumentRoot directement

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

# Génération dynamique des paramètres PHP à partir des variables d'environnement
echo "Application des réglages PHP dynamiques..."
cat > /usr/local/etc/php/conf.d/99-custom-settings.ini <<EOF
memory_limit = ${PHP_MEMORY_LIMIT:-512M}
upload_max_filesize = ${UPLOAD_MAX_SIZE:-256M}
post_max_size = ${UPLOAD_MAX_SIZE:-256M}
max_execution_time = ${MAX_EXECUTION_TIME:-300}
max_input_vars = ${MAX_INPUT_VARS:-5000}
max_input_time = ${MAX_INPUT_TIME:-300}
opcache.enable = 1
opcache.memory_consumption = ${OPCACHE_MEMORY_CONSUMPTION:-256}
opcache.max_accelerated_files = ${OPCACHE_MAX_FILES:-10000}
opcache.validate_timestamps = 1
opcache.revalidate_freq = 2
realpath_cache_size = 4096K
realpath_cache_ttl = 600
EOF
echo "Réglages PHP appliqués ✓"

# Vérifier et corriger les permissions
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/html || true
chown -R www-data:www-data /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
chmod -R 755 /var/www/html 2>/dev/null || true
chmod -R 775 /var/www/moodledata 2>/dev/null || echo "moodledata sera créé lors de l'installation"
echo "Permissions configurées ✓"

# Configuration Apache personnalisée
SERVER_NAME_VALUE=${MOODLE_WWWROOT:-}
# Extraire l'hôte depuis MOODLE_WWWROOT si un schéma/chemin est présent
if [ -n "$SERVER_NAME_VALUE" ]; then
    SERVER_NAME_VALUE=${SERVER_NAME_VALUE#*://}
    SERVER_NAME_VALUE=${SERVER_NAME_VALUE%%/*}
fi
if [ -z "$SERVER_NAME_VALUE" ]; then
    SERVER_NAME_VALUE=localhost
fi

cat > /etc/apache2/conf-available/moodle.conf << EOF
ServerName $SERVER_NAME_VALUE
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

# Confiance dans le proxy (Traefik) pour le schéma HTTPS
# Si la requête vient en HTTPS côté client, Traefik transmet X-Forwarded-Proto=https.
# Ces directives informent PHP/Apache que la requête est sécurisée.
SetEnvIfNoCase X-Forwarded-Proto "https" HTTPS=on
SetEnvIfNoCase X-Forwarded-Proto "https" REQUEST_SCHEME=https
SetEnvIfNoCase X-Forwarded-Proto "https" SERVER_PORT=443

# Optionnel: assurer la variable d'environnement au niveau rewrite
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{HTTP:X-Forwarded-Proto} =https
RewriteRule .* - [E=HTTPS:on]
</IfModule>
EOF

# Redirection HTTP -> HTTPS optionnelle derrière proxy
if [ "${FORCE_HTTPS:-0}" = "1" ]; then
    cat >> /etc/apache2/conf-available/moodle.conf << 'EOF'

# Redirection forcée HTTP -> HTTPS derrière proxy
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{HTTP:X-Forwarded-Proto} !=https
RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</IfModule>
EOF
fi

# Activer la configuration et les modules Apache requis
a2enconf moodle >/dev/null 2>&1 || true
a2enmod headers >/dev/null 2>&1 || true
a2enmod rewrite >/dev/null 2>&1 || true
a2enmod setenvif >/dev/null 2>&1 || true
echo "Configuration Apache activée ✓"

# Afficher les informations de démarrage
echo "=== Informations de démarrage ==="
echo "Apache Document Root: $APACHE_DOCUMENT_ROOT"
echo "Moodle WWW Root: ${MOODLE_WWWROOT:-Non défini}"
echo "Base de données: ${MOODLE_DB_HOST:-db}:3306"
echo "Redis: ${MOODLE_REDIS_HOST:-redis}:${MOODLE_REDIS_PORT:-6379}"
echo "Code source: Volume monté depuis ./moodle (DocumentRoot: /var/www/html/public)"
echo "Fichiers Moodle: $(ls -la /var/www/html/public/index.php 2>/dev/null || echo 'MANQUANTS')"
echo "================================"

echo "Démarrage d'Apache..."
exec "$@"