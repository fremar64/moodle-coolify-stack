# 🎓 Moodle Coolify Stack

Stack complète **Moodle 5.1** prête pour le déploiement sur **Coolify** avec code source, haute disponibilité et sauvegardes automatiques.

[![Moodle](https://img.shields.io/badge/Moodle-5.1-orange)](https://moodle.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🚀 Démarrage rapide

```bash
# 1. Forkez ou clonez ce dépôt
git clone https://github.com/fremar64/moodle-coolify-stack.git

# 2. Créez une application dans Coolify
#    - Type: Docker Compose (Git Repository)
#    - URL: https://github.com/fremar64/moodle-coolify-stack
#    - Branch: main

# 3. Configurez les variables d'environnement (voir .env.example)

# 4. Déployez et accédez à votre domaine
```

🎯 **Installation complète** : Consultez [SETUP.md](SETUP.md) pour le guide détaillé pas-à-pas.

---

## ✨ Fonctionnalités

### 🎯 Stack complète
- ✅ **Moodle 5.1 Stable** - Code source complet et personnalisable
- ✅ **MariaDB 11.4** - Base de données optimisée avec healthchecks
- ✅ **Redis 7** - Cache haute performance pour sessions et données
- ✅ **Apache/PHP 8.3** - Serveur web configuré et sécurisé
- ✅ **Traefik** - Reverse proxy avec SSL Let's Encrypt automatique

### 🔧 Automatisations
- ✅ **Cron Moodle** - Tâches planifiées toutes les 5 minutes
- ✅ **Sauvegardes Dropbox** - Quotidiennes (DB + fichiers)
- ✅ **Healthchecks** - Surveillance automatique de tous les services
- ✅ **Variables PHP dynamiques** - Configuration via environnement

### 🛡️ Production-ready
- ✅ **SSL/TLS automatique** - Certificats Let's Encrypt
- ✅ **Volumes persistants** - Données sécurisées et durables
- ✅ **Logs centralisés** - Surveillance via Coolify
- ✅ **Isolation réseau** - Réseau Docker dédié

---

## 📦 Composition de la stack

```yaml
Services:
├── db          → MariaDB 11.4 (base de données)
├── redis       → Redis 7 (cache & sessions)
├── moodle      → Apache/PHP 8.3 + Moodle 5.1
├── cron        → Tâches planifiées Moodle
└── backup      → Sauvegardes automatiques Dropbox

Volumes:
├── db_data          → Données MariaDB persistantes
├── redis_data       → Cache Redis persistant
└── moodle_data      → Fichiers utilisateurs Moodle
```

---

## 🏗️ Architecture

```
Internet
   ↓
┌─────────────────────────────────┐
│  Coolify Traefik (Reverse Proxy)|
│  - SSL/TLS Let's Encrypt        │
│  - Port 443 → 80                │
└──────────────┬──────────────────┘
               ↓
┌──────────────────────────────────┐
│  Moodle Container                │
│  - Apache/PHP 8.3                │
│  - Code source monté             │
│  - Healthcheck: curl localhost/  │
└───┬──────────────────────────┬───┘
    ↓                          ↓
┌─────────────┐        ┌──────────────┐
│  MariaDB    │        │    Redis     │
│  - Port 3306│        │  - Port 6379 │
│  - Volume   │        │  - AOF       │
│  - Health ✓ │        │  - Health ✓  │
└─────────────┘        └──────────────┘
```

---

## 📋 Prérequis

### Serveur Coolify
- **OS** : Linux (Ubuntu 22.04+ recommandé)
- **CPU** : 2 cœurs minimum
- **RAM** : 4 GB minimum (8 GB recommandé)
- **Stockage** : 20 GB minimum (50+ GB recommandé)
- **Coolify** : Version 4.0+

### DNS et réseau
- Nom de domaine configuré
- Enregistrement A pointant vers le serveur Coolify
- Port 80/443 ouverts

---

## ⚙️ Configuration

### Variables d'environnement

Copiez `.env.example` vers `.env` et modifiez :

```env
# Obligatoires
DOMAIN=ecole-en-ligne.example.com
MYSQL_ROOT_PASSWORD=MotDePasseSecuriseRoot123!
MOODLE_DB_PASSWORD=MotDePasseMoodleSecurise456!
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=MotDePasseAdmin789!
MOODLE_ADMIN_EMAIL=admin@example.com

# Recommandées
PHP_MEMORY_LIMIT=512M
UPLOAD_MAX_SIZE=256M
TIMEZONE=Europe/Paris

# Optionnelles
DROPBOX_TOKEN=votre_token_dropbox_pour_backups
```

📖 **Référence complète** : Voir [.env.example](.env.example) pour toutes les options disponibles.

---

## 🚀 Déploiement

### Via Coolify (recommandé)

1. **Créer une application**
   - Projects → + New Resource
   - Type: Public Repository
   - URL: `https://github.com/fremar64/moodle-coolify-stack`

2. **Configurer**
   - Domain: votre-domaine.com
   - Build Pack: Docker Compose
   - Environment Variables: depuis .env.example

3. **Déployer**
   - Cliquez sur Deploy
   - Attendez 5-10 minutes
   - Accédez à votre domaine

📖 **Guide complet** : Consultez [SETUP.md](SETUP.md)

### En local (développement)

```bash
# Cloner le dépôt
git clone https://github.com/fremar64/moodle-coolify-stack.git
cd moodle-coolify-stack

# Configurer l'environnement
cp .env.example .env
nano .env  # Modifier les variables

# Démarrer
docker compose up -d

# Suivre les logs
docker compose logs -f

# Accéder à http://localhost
```

---

## 🎨 Personnalisation

### Ajouter des plugins

```bash
# Cloner le dépôt
git clone https://github.com/votre-username/moodle-coolify-stack
cd moodle-coolify-stack

# Ajouter un plugin
cd moodle/mod/  # ou local/, theme/, auth/, etc.
# Placez votre plugin ici

# Committer et pousser
git add .
git commit -m "Ajout plugin XYZ"
git push

# Redéployer depuis Coolify
```

### Personnaliser le thème

```bash
# Ajouter un thème personnalisé
cd moodle/theme/
git clone https://github.com/votre-theme montheme

# Activer dans Moodle
# Administration → Apparence → Thèmes → Sélecteur de thèmes
```

### Modifier la configuration PHP

Les paramètres PHP sont configurables via variables d'environnement :

```env
PHP_MEMORY_LIMIT=1024M          # Augmenter pour gros cours
UPLOAD_MAX_SIZE=512M            # Fichiers volumineux
MAX_EXECUTION_TIME=600          # Scripts longs
OPCACHE_MEMORY_CONSUMPTION=512  # Plus de cache
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[SETUP.md](SETUP.md)** | 🚀 Guide d'installation complet étape par étape |
| **[MAINTENANCE.md](MAINTENANCE.md)** | 🔧 Maintenance, mises à jour et sauvegardes |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | 🚨 Résolution des problèmes courants |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | 🏗️ Détails techniques de l'architecture |
| **[.env.example](.env.example)** | ⚙️ Référence des variables d'environnement |

---

## 🔧 Maintenance

### Sauvegardes automatiques

✅ **Quotidiennes** vers Dropbox (si configuré)
- Base de données MySQL
- Fichiers Moodle (`/var/www/moodledata`)

### Commandes utiles

```bash
# Voir les logs
docker compose logs -f moodle

# Redémarrer un service
docker compose restart moodle

# Accéder au shell
docker exec -it moodle_app bash

# Exécuter le cron manuellement
docker exec moodle_app php /var/www/html/public/admin/cli/cron.php

# Vider les caches
docker exec moodle_app php /var/www/html/public/admin/cli/purge_caches.php
```

📖 **Guide complet** : Consultez [MAINTENANCE.md](MAINTENANCE.md)

---

## 🐛 Dépannage

### Problèmes courants

**❌ Erreur 502/503**
```bash
# Vérifier les healthchecks
docker compose ps

# Voir les logs
docker compose logs moodle
```

**❌ Base de données inaccessible**
```bash
# Vérifier MariaDB
docker compose logs db

# Tester la connexion
docker exec moodle_db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"
```

**❌ SSL non généré**
- Vérifiez le DNS : `nslookup votre-domaine.com`
- Attendez 10-15 minutes pour la propagation
- Consultez les logs Traefik dans Coolify

📖 **Guide complet** : Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🤝 Contribution

Les contributions sont les bienvenues !

1. Forkez le projet
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Committez vos changements (`git commit -m 'Ajout fonctionnalité'`)
4. Poussez vers la branche (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

---

## 📄 Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus de détails.

Moodle est sous licence GPL. Voir [moodle.org](https://moodle.org) pour plus d'informations.

---

## 🙏 Remerciements

- **Moodle Community** - Pour la plateforme LMS open source
- **Coolify** - Pour la plateforme de déploiement simplifiée
- **MoodleHQ** - Pour les images Docker officielles

---

## 📞 Support

- 📖 **Documentation** : Voir le dossier `docs/`
- 🐛 **Issues** : [GitHub Issues](https://github.com/fremar64/moodle-coolify-stack/issues)
- 💬 **Discussions** : [Moodle Forums](https://moodle.org/forums)
- 📧 **Contact** : [Frédéric OUAMBA](https://github.com/fremar64)

---

**Fait avec ❤️ pour la communauté éducative**

[![Déployer sur Coolify](https://img.shields.io/badge/Déployer-Coolify-blue?style=for-the-badge)](https://coolify.io)
