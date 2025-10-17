# Moodle Coolify Stack

Déploiement complet de **Moodle** sur un serveur **Coolify** (auto-hébergé), incluant :
- Moodle officiel version 5.1 (`MOODLE_501_STABLE`)
- Image PHP/Apache optimisée (`moodlehq/moodle-php-apache:8.3`)
- MariaDB
- Redis (cache)
- Cron automatique
- Sauvegardes quotidiennes vers **Dropbox**
- Reverse proxy **Traefik** avec SSL Let's Encrypt

> **Note importante** : Cette approche utilise le code source Moodle directement monté dans le container, permettant une personnalisation complète (plugins, thèmes, modifications) contrairement aux images pré-packagées.

---

## 🚀 Déploiement

Pour déployer cette stack avec Coolify (Git-Based Docker Compose), consultez :

- 👉 **[COOLIFY_DEPLOYMENT_GUIDE.md](COOLIFY_DEPLOYMENT_GUIDE.md)** (recommandé)
- 👉 **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** (détails supplémentaires)

### Installation rapide

1. **Fork/Clone** ce dépôt
2. **Créer une application** Coolify avec Git-Based Repository
3. **Configurer** les variables d'environnement (DOMAIN, mots de passe, PHP_MEMORY_LIMIT, etc.)
4. **Déployer** et suivre l'assistant d'installation Moodle

---

## 🏗️ Architecture & volumes

- Montage du code : `./moodle` → `/var/www/html` (racine complète)
- DocumentRoot Apache : `/var/www/html/public`
- Données Moodle : `moodle_data` → `/var/www/moodledata`
- Cron : `/var/www/html/public/admin/cli/cron.php`

## � HTTPS derrière Traefik

- Le conteneur respecte `X-Forwarded-Proto` pour détecter HTTPS côté client.
- Optionnel : forcer la redirection HTTP → HTTPS via `FORCE_HTTPS=1` (variable d’environnement dans Coolify).

## ⚙️ Réglages PHP dynamiques

Au démarrage, un fichier `/usr/local/etc/php/conf.d/99-custom-settings.ini` est généré à partir des variables d'environnement :

- `PHP_MEMORY_LIMIT` (ex: 512M)
- `UPLOAD_MAX_SIZE` (ex: 256M)
- `MAX_EXECUTION_TIME` (ex: 300)
- Optimisations `opcache`/`realpath`

Modifiez les variables dans Coolify puis redéployez pour les appliquer.

---

## �🔄 Sauvegardes automatiques

* Sauvegarde quotidienne :
  * des fichiers Moodle (`/var/www/moodledata`)
  * et de la base MySQL (`mysqldump`).
* Les sauvegardes sont envoyées vers ton **compte Dropbox** (configuré via `DROPBOX_TOKEN`).

Pour générer ton token :

```bash
rclone config
# Choisir : n → dropbox → suivre les instructions → copier le token
```

---

## 📁 Volumes persistants

| Volume                | Contenu                                |
| --------------------- | -------------------------------------- |
| `./moodle`            | Code source Moodle (racine + public)   |
| `moodle_data`         | Fichiers Moodle (cours, plugins, etc.) |
| `db_data`             | Données MariaDB                        |
| `redis_data`          | Cache Redis                            |
| `traefik_letsencrypt` | Certificats SSL                        |

---

## 🧩 Personnalisation

Tu peux :

* **Ajouter des plugins** : Place-les dans `moodle/local/`, `moodle/mod/`, etc.
* **Installer des thèmes** : Ajoute-les dans `moodle/theme/`
* **Modifier le code** : Édite directement les fichiers PHP dans `./moodle/`
* **Configurer PHP** : Utilise les variables d’environnement (voir ci-dessus)
* **Étendre Traefik** : Ajoute d'autres services sur ton domaine

### Avantages de cette approche

✅ **Code source accessible** : Modification directe des fichiers Moodle  
✅ **Plugins personnalisés** : Installation facile de modules tiers  
✅ **Débogage facilité** : Accès direct aux logs et au code  
✅ **Sauvegardes complètes** : Le code source est inclus dans les backups  
✅ **Contrôle total** : Pas de limitations d'une image pré-construite

---

## ⚡ Redis dans config.php (post-install)

Exemple minimal pour activer Redis pour les sessions (et cache, optionnel) après l’installation. Édite `moodle/config.php` dans le volume monté.

```
// Sessions via Redis
$CFG->session_handler_class = '\\core\\session\\redis';
$CFG->session_redis_host = 'redis';
$CFG->session_redis_port = 6379;
$CFG->session_redis_database = 0; // par défaut
//$CFG->session_redis_password = ''; // si nécessaire
//$CFG->session_redis_prefix = 'moodle:';

// (Optionnel) Exemple de cache Redis global
// Vous pouvez aussi configurer les caches via l'interface d'admin, ce qui est recommandé.
$CFG->cachestore_redis_server = 'redis';
$CFG->cachestore_redis_prefix = 'moodle:';
```

Après modification, purgez les caches via l’interface d’administration.

## 📚 Documentation

- **[🚀 COOLIFY_DEPLOYMENT_GUIDE.md](COOLIFY_DEPLOYMENT_GUIDE.md)** - Déploiement Coolify (Git + Docker Compose)
- **[📦 DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Détails de déploiement & architecture
- **[✅ VALIDATION.md](VALIDATION.md)** - Checklist de validation
- **[� INSTALL_PLUGIN.md](INSTALL_PLUGIN.md)** - Installer des plugins via Git (recommandé)
- **[�🛠 INSTALL_CLI_GUIDE.md](INSTALL_CLI_GUIDE.md)** - Installation via CLI (optionnel)
- **[🚨 TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Guide de dépannage et résolution d'erreurs
- **[📝 JOURNAL_INSTALLATION.md](JOURNAL_INSTALLATION.md)** - Historique et détails de l'installation
- **[🔄 UPDATE_GUIDE.md](UPDATE_GUIDE.md)** - Guide complet de mise à jour Moodle
- **[📖 Documentation officielle Moodle](https://docs.moodle.org/)**

---

**Auteur :** [Frédéric OUAMBA](https://github.com/fremar64)
**Licence :** MIT