FROM moodlehq/moodle-php-apache:8.3

# Installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définir les variables d'environnement Apache
ENV APACHE_DOCUMENT_ROOT=/var/www/html
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data

# Configuration PHP pour la sécurité
RUN echo "zend.exception_ignore_args = On" > /usr/local/etc/php/conf.d/zend-security.ini

# Créer le script d'entrée personnalisé
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Préparer les répertoires
RUN mkdir -p /var/www/html/lang && \
    chown -R www-data:www-data /var/www/html

# Télécharger le pack de langue français directement
RUN curl -s -L -o /tmp/fr.zip "https://download.moodle.org/download.php/direct/langpack/5.1/fr.zip" && \
    if [ -s /tmp/fr.zip ] && unzip -t /tmp/fr.zip > /dev/null 2>&1; then \
        unzip -q /tmp/fr.zip -d /var/www/html/lang/ && \
        echo "Pack de langue français préinstallé avec succès"; \
    else \
        echo "Impossible de télécharger le pack français, sera disponible via l'interface"; \
    fi && \
    rm -f /tmp/fr.zip

WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]