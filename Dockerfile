FROM moodlehq/moodle-php-apache:8.3

# Installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    netcat-traditional \
    git \
    && rm -rf /var/lib/apt/lists/*

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définir les variables d'environnement Apache
ENV APACHE_DOCUMENT_ROOT=/var/www/html
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data

# Configuration PHP pour la sécurité
RUN echo "zend.exception_ignore_args = On" > /usr/local/etc/php/conf.d/zend-security.ini

# Télécharger et installer Moodle 5.1
RUN cd /var/www && \
    rm -rf html && \
    git clone --depth 1 --branch MOODLE_501_STABLE https://github.com/moodle/moodle.git html && \
    cd html && \
    git checkout MOODLE_501_STABLE && \
    rm -rf .git

# Installer les dépendances Composer
RUN cd /var/www/html && \
    composer install --no-dev --classmap-authoritative --no-interaction

# Télécharger le pack de langue français directement
RUN curl -s -L -o /tmp/fr.zip "https://download.moodle.org/download.php/direct/langpack/5.1/fr.zip" && \
    if [ -s /tmp/fr.zip ] && unzip -t /tmp/fr.zip > /dev/null 2>&1; then \
        mkdir -p /var/www/html/lang && \
        unzip -q /tmp/fr.zip -d /var/www/html/lang/ && \
        echo "Pack de langue français préinstallé avec succès"; \
    else \
        echo "Impossible de télécharger le pack français, sera disponible via l'interface"; \
    fi && \
    rm -f /tmp/fr.zip

# Créer le script d'entrée personnalisé
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Préparer les répertoires et permissions
RUN mkdir -p /var/www/moodledata && \
    chown -R www-data:www-data /var/www/html /var/www/moodledata && \
    chmod -R 755 /var/www/html && \
    chmod -R 775 /var/www/moodledata

WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]