FROM moodlehq/moodle-php-apache:8.3

# Installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    netcat-traditional \
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
RUN mkdir -p /var/www/moodledata && \
    chown -R www-data:www-data /var/www/moodledata && \
    chmod -R 775 /var/www/moodledata

WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]