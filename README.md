# Moodle Coolify Stack

Déploiement complet de **Moodle** sur un serveur **Coolify** (auto-hébergé), incluant :
- Moodle officiel version 5.0.1 (`MOODLE_501_STABLE`)
- Image PHP/Apache optimisée (`moodlehq/moodle-php-apache:8.3`)
- MariaDB
- Redis (cache)
- Cron automatique
- Sauvegardes quotidiennes vers **Dropbox**
- Reverse proxy **Traefik** avec SSL Let's Encrypt

> **Note importante** : Cette approche utilise le code source Moodle directement monté dans le container, permettant une personnalisation complète (plugins, thèmes, modifications) contrairement aux images pré-packagées.

---

## 🚀 Déploiement

Pour déployer cette stack avec Coolify, consultez le guide complet :  
👉 **[README_DEPLOY.md](README_DEPLOY.md)**

Ce guide couvre l'approche **Git-Based** recommandée pour Coolify.

### Installation rapide

1. **Fork/Clone** ce dépôt
2. **Créer une application** Coolify avec Git-Based Repository
3. **Configurer** les variables d'environnement (voir `.env.example`)
4. **Déployer** et suivre l'assistant d'installation Moodle

---

## 🔄 Sauvegardes automatiques

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
| `./moodle`            | Code source Moodle (monté en local)   |
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
* **Configurer PHP** : Monte un fichier `php.ini` personnalisé dans le container
* **Étendre Traefik** : Ajoute d'autres services sur ton domaine

### Avantages de cette approche

✅ **Code source accessible** : Modification directe des fichiers Moodle  
✅ **Plugins personnalisés** : Installation facile de modules tiers  
✅ **Débogage facilité** : Accès direct aux logs et au code  
✅ **Sauvegardes complètes** : Le code source est inclus dans les backups  
✅ **Contrôle total** : Pas de limitations d'une image pré-construite

---

## 📚 Documentation

- **[🚀 README_DEPLOY.md](README_DEPLOY.md)** - Guide de déploiement Coolify Git-Based
- **[🚨 TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Guide de dépannage et résolution d'erreurs
- **[📝 JOURNAL_INSTALLATION.md](JOURNAL_INSTALLATION.md)** - Historique et détails de l'installation
- **[🔄 UPDATE_GUIDE.md](UPDATE_GUIDE.md)** - Guide complet de mise à jour Moodle
- **[📖 Documentation officielle Moodle](https://docs.moodle.org/)**

---

**Auteur :** [Frédéric OUAMBA](https://github.com/fremar64)
**Licence :** MIT