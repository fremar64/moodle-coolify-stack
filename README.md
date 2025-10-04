# Moodle Coolify Stack

Déploiement complet de **Moodle** sur un serveur **Coolify** (auto-hébergé), incluant :
- Moodle officiel (`moodlehq/moodle-php-apache`)
- MariaDB
- Redis (cache)
- Cron automatique
- Sauvegardes quotidiennes vers **Dropbox**
- Reverse proxy **Traefik** avec SSL Let's Encrypt

---

## 🚀 Déploiement

### 1. Préparation

Clone le dépôt :

```bash
git clone https://github.com/fremar64/moodle-coolify-stack.git
cd moodle-coolify-stack
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
| `moodle_data`         | Fichiers Moodle (cours, plugins, etc.) |
| `moodle_html`         | Code source PHP de Moodle              |
| `db_data`             | Données MariaDB                        |
| `redis_data`          | Cache Redis                            |
| `traefik_letsencrypt` | Certificats SSL                        |

---

## 🧩 Personnalisation

Tu peux :

* Ajouter des plugins Moodle dans `moodle_html/local/`
* Modifier la config PHP via un fichier `php.ini` monté dans le container
* Étendre Traefik pour héberger plusieurs services sur ton domaine

---

**Auteur :** [Frédéric OUAMBA](https://github.com/fremar64)
**Licence :** MIT