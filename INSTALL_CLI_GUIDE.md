# Installation Moodle par CLI (optionnel)

Lorsque l'installateur web n'est pas souhaité ou si le champ d'URL est verrouillé/incorrect, vous pouvez réaliser l'installation via la CLI de Moodle.

## Prérequis

- Conteneurs `db` et `moodle` démarrés
- Variables d'environnement prêtes (DOMAIN, MOODLE_DB_PASSWORD, etc.)

## Commande d'installation (à exécuter dans le conteneur moodle)

Exécutez une session shell dans le conteneur `moodle_app` puis lancez le script d'installation :

```
php /var/www/html/public/admin/cli/install.php \
  --chmod=2775 \
  --lang=fr \
  --wwwroot="https://${DOMAIN}" \
  --dataroot=/var/www/moodledata \
  --dbtype=mariadb \
  --dbhost=db \
  --dbname=moodle \
  --dbuser=moodle \
  --dbpass="${MOODLE_DB_PASSWORD}" \
  --fullname="${MOODLE_SITE_NAME:-École en Ligne CEREDIS}" \
  --shortname="${MOODLE_SHORTNAME:-EEL}" \
  --summary="${MOODLE_SUMMARY:-Plateforme Moodle}" \
  --adminuser="${MOODLE_ADMIN_USER}" \
  --adminpass="${MOODLE_ADMIN_PASS}" \
  --adminemail="${MOODLE_ADMIN_EMAIL}" \
  --non-interactive \
  --agree-license
```

Notes :
- Assurez-vous que `${DOMAIN}` commence par `https://`.
- Après l'installation, vous pouvez connecter Redis dans `config.php` (post-installation via interface ou édition manuelle documentée par Moodle).
- Si vous souhaitez forcer HTTPS, utilisez la variable d'environnement `FORCE_HTTPS=1` et redéployez avant l'installation.
