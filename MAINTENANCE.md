# 🔧 Guide de Maintenance - Moodle Coolify Stack

Ce guide couvre la maintenance quotidienne, les mises à jour et les sauvegardes de votre installation Moodle.

---

## 📅 Tâches de maintenance régulières

### Quotidien (automatique)

✅ **Cron Moodle** - Toutes les 5 minutes
- Nettoyage du cache
- Envoi des emails en attente
- Traitement des files d'attente
- Exécution des tâches planifiées

✅ **Sauvegardes Dropbox** - Tous les jours à minuit
- Fichiers Moodle (`/var/www/moodledata`)
- Base de données MySQL (dump SQL)

### Hebdomadaire (recommandé)

- [ ] Vérifier les logs d'erreurs
- [ ] Consulter les rapports Moodle
- [ ] Vérifier l'espace disque disponible
- [ ] Tester les sauvegardes

### Mensuel (recommandé)

- [ ] Vérifier les mises à jour de sécurité
- [ ] Nettoyer les fichiers temporaires
- [ ] Optimiser la base de données
- [ ] Réviser les utilisateurs inactifs

---

## 🔄 Mises à jour Moodle

### Avant toute mise à jour

⚠️ **IMPORTANT** : Faites toujours une sauvegarde complète avant mise à jour !

### Stratégie de mise à jour

Moodle suit un cycle de versions :
- **Versions mineures** (5.1.1 → 5.1.2) : Correctifs de sécurité, safe
- **Versions majeures** (5.1 → 5.2) : Nouvelles fonctionnalités, tester d'abord

### Processus de mise à jour

#### Étape 1 : Sauvegarde complète

```bash
# Connexion au serveur
ssh user@votre-serveur

# Naviguer vers le projet
cd /chemin/vers/moodle-coolify-stack

# Sauvegarde base de données
docker exec moodle_db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} moodle > backup-moodle-$(date +%F).sql

# Sauvegarde volume moodledata
docker run --rm \
  -v moodle-coolify-stack_moodle_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup-moodledata-$(date +%F).tar.gz -C /data .

# Sauvegarde du code source
tar czf backup-moodle-code-$(date +%F).tar.gz moodle/

# Sauvegarder dans un lieu sûr
# Exemple : copier vers un serveur distant, Dropbox, etc.
```

#### Étape 2 : Identifier la version cible

Consultez les versions disponibles :
- **Page officielle** : https://github.com/moodle/moodle/branches
- **Versions stables** : `MOODLE_501_STABLE`, `MOODLE_502_STABLE`, etc.

#### Étape 3 : Mettre à jour le code source

```bash
# Naviguer vers le dossier Moodle
cd moodle

# Récupérer toutes les branches
git fetch --all

# Voir la branche actuelle
git branch

# Passer à la nouvelle version (exemple : 5.1.2)
git checkout MOODLE_512_STABLE

# Ou mettre à jour la branche actuelle
git pull origin MOODLE_501_STABLE

# Retour à la racine
cd ..
```

#### Étape 4 : Activer le mode maintenance

```bash
# Via ligne de commande
docker exec moodle_app php /var/www/html/public/admin/cli/maintenance.php --enable

# Ou via l'interface web
# Administration → Serveur → Mode maintenance
```

#### Étape 5 : Appliquer la mise à jour

```bash
# Redémarrer les services
docker compose restart moodle cron

# Suivre les logs
docker compose logs -f moodle
```

#### Étape 6 : Finaliser via l'interface web

1. Accédez à `https://votre-domaine.com`
2. Moodle détectera automatiquement la mise à jour
3. Suivez l'assistant de mise à jour
4. Attendez la fin du processus (peut prendre 5-15 minutes)

#### Étape 7 : Désactiver le mode maintenance

```bash
docker exec moodle_app php /var/www/html/public/admin/cli/maintenance.php --disable
```

#### Étape 8 : Vérifications post-mise à jour

- [ ] Site accessible et fonctionnel
- [ ] Connexion administrateur OK
- [ ] Cours accessibles
- [ ] Plugins compatibles
- [ ] Pas d'erreurs dans les logs
- [ ] Cache Redis fonctionnel

### En cas de problème : Rollback

```bash
# Réactiver le mode maintenance
docker exec moodle_app php /var/www/html/public/admin/cli/maintenance.php --enable

# Restaurer le code source
rm -rf moodle/
tar xzf backup-moodle-code-$(date +%F).tar.gz

# Restaurer la base de données
docker exec -i moodle_db mysql -u root -p${MYSQL_ROOT_PASSWORD} moodle < backup-moodle-$(date +%F).sql

# Redémarrer
docker compose restart

# Désactiver le mode maintenance
docker exec moodle_app php /var/www/html/public/admin/cli/maintenance.php --disable
```

---

## 💾 Gestion des sauvegardes

### Sauvegardes automatiques (Dropbox)

Le service `backup` sauvegarde automatiquement tous les jours :

**Vérifier le statut**
```bash
docker logs moodle_backup
```

**Logs attendus**
```
Backup started at Thu Dec  7 00:00:01 UTC 2025
Transferred: 125.5 MiB / 125.5 MiB, 100%, 2.5 MiB/s
Backup done at Thu Dec  7 00:05:23 UTC 2025
```

### Sauvegardes manuelles on-demand

```bash
# Sauvegarde manuelle immédiate
docker exec moodle_backup sh -c "
  echo 'Manual backup started';
  mysqldump -h db -u moodle -p\${MYSQL_PASSWORD} moodle > /scripts/db_backup_manual.sql;
  rclone copy /data/moodle dropbox:/moodle_backups/manual/files --progress;
  rclone copy /scripts/db_backup_manual.sql dropbox:/moodle_backups/manual/sql --progress;
  echo 'Manual backup done';
"
```

### Restauration depuis une sauvegarde

#### Restaurer la base de données

```bash
# Depuis Dropbox
rclone copy dropbox:/moodle_backups/sql/db_backup.sql ./

# Restaurer
docker exec -i moodle_db mysql -u root -p${MYSQL_ROOT_PASSWORD} moodle < db_backup.sql
```

#### Restaurer les fichiers

```bash
# Depuis Dropbox vers le volume
docker run --rm \
  -v moodle-coolify-stack_moodle_data:/data \
  -e RCLONE_CONFIG_DROPBOX_TYPE=dropbox \
  -e RCLONE_CONFIG_DROPBOX_TOKEN=${DROPBOX_TOKEN} \
  rclone/rclone \
  copy dropbox:/moodle_backups/files /data --progress
```

### Configurer Dropbox (première fois)

```bash
# Installer rclone localement
curl https://rclone.org/install.sh | sudo bash

# Configuration interactive
rclone config

# Choisir :
# n → new remote
# name : dropbox
# storage : dropbox
# Suivre le processus d'authentification

# Récupérer le token
cat ~/.config/rclone/rclone.conf

# Copier la valeur "token" dans DROPBOX_TOKEN
```

---

## 🗄️ Maintenance de la base de données

### Optimiser les tables

```bash
# Via ligne de commande
docker exec moodle_db mysqlcheck -u root -p${MYSQL_ROOT_PASSWORD} --optimize moodle

# Ou via Moodle CLI
docker exec moodle_app php /var/www/html/public/admin/cli/mysql_compressed_rows.php -f
```

### Vérifier l'intégrité

```bash
docker exec moodle_db mysqlcheck -u root -p${MYSQL_ROOT_PASSWORD} --check moodle
```

### Nettoyer les sessions expirées

```bash
docker exec moodle_app php /var/www/html/public/admin/cli/purge_caches.php
```

---

## 📦 Gestion de l'espace disque

### Vérifier l'utilisation

```bash
# Espace total utilisé par Docker
docker system df

# Espace par volume
docker system df -v

# Taille des volumes Moodle
docker run --rm -v moodle-coolify-stack_moodle_data:/data alpine du -sh /data
docker run --rm -v moodle-coolify-stack_db_data:/data alpine du -sh /data
```

### Nettoyer les fichiers temporaires

```bash
# Dans Moodle : Administration → Serveur → Nettoyage
# Ou via CLI
docker exec moodle_app php /var/www/html/public/admin/cli/purge_caches.php --all
```

### Nettoyer Docker

```bash
# Supprimer les images non utilisées
docker image prune -a

# Supprimer les containers arrêtés
docker container prune

# Nettoyage complet (ATTENTION : supprime tout ce qui n'est pas utilisé)
docker system prune -a --volumes
```

---

## 🔍 Surveillance et logs

### Consulter les logs

```bash
# Logs Moodle en temps réel
docker compose logs -f moodle

# Logs de tous les services
docker compose logs -f

# Logs d'un service spécifique
docker compose logs -f db
docker compose logs -f redis
docker compose logs -f cron
docker compose logs -f backup

# Dernières 100 lignes
docker compose logs --tail=100 moodle
```

### Logs Moodle (via interface web)

**Administration → Rapports → Journaux**
- Filtrer par activité, utilisateur, date

### Vérifier la santé des services

```bash
# Statut des containers
docker compose ps

# Healthchecks
docker inspect moodle_db | grep -A 10 Health
docker inspect moodle_redis | grep -A 10 Health
docker inspect moodle_app | grep -A 10 Health
```

### Métriques de performance

```bash
# Utilisation CPU/RAM en temps réel
docker stats

# Performances base de données
docker exec moodle_db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW GLOBAL STATUS LIKE 'Threads%';"
```

---

## 🛡️ Sécurité

### Mises à jour de sécurité

**Abonnez-vous aux alertes Moodle**
- https://moodle.org/security/

### Vérifier les versions

```bash
# Version Moodle actuelle
docker exec moodle_app php /var/www/html/public/admin/cli/version.php

# Versions des images Docker
docker compose images
```

### Hardening recommandé

1. **Changer les mots de passe régulièrement**
2. **Activer l'authentification à deux facteurs** (Moodle)
3. **Limiter les tentatives de connexion**
4. **Surveiller les connexions administrateur**
5. **Désactiver les comptes inactifs**

---

## 🔄 Mises à jour des containers Docker

### Images de base

```bash
# Mettre à jour les images
docker compose pull

# Redémarrer avec les nouvelles images
docker compose up -d

# Vérifier
docker compose ps
```

### Rebuild complet

```bash
# Rebuild de l'image Moodle personnalisée
docker compose build --no-cache moodle

# Redéployer
docker compose up -d
```

---

## 📞 Support et ressources

### En cas de problème

1. **Consultez** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. **Vérifiez les logs** `docker compose logs`
3. **Recherchez** sur [moodle.org/forums](https://moodle.org/forums)
4. **Créez une issue** sur GitHub si bug confirmé

### Documentation officielle

- **Moodle** : https://docs.moodle.org/
- **Docker** : https://docs.docker.com/
- **Coolify** : https://coolify.io/docs

---

✅ **Maintenance régulière = Moodle performant et sécurisé !**
