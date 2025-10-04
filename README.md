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

### 1. Préparation

Clone le dépôt :

```bash
git clone https://github.com/fremar64/moodle-coolify-stack.git
cd moodle-coolify-stack
```

Clone le code source Moodle (version 5.0.1) :

```bash
git clone -b MOODLE_501_STABLE https://github.com/moodle/moodle.git ./moodle
```

Copie et adapte les variables d'environnement :

```bash
cp .env.example .env
nano .env
```

### 2. Déploiement via Coolify

Dans l'interface Coolify :

1. Clique sur **New Application → Docker Based → Docker Compose Empty**
2. Sélectionne ce dépôt GitHub
3. Laisse Coolify générer automatiquement le `docker-compose.yml`
4. Lance le déploiement

L'application sera accessible à :

> [https://ecole-en-ligne.ceredis.net](https://ecole-en-ligne.ceredis.net)

Le certificat SSL sera généré automatiquement via Let's Encrypt.

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

**Auteur :** [Frédéric OUAMBA](https://github.com/fremar64)
**Licence :** MIT