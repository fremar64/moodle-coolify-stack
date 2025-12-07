# Scripts d'Administration Moodle

Ce dossier contient les scripts d'administration pour gérer votre installation Moodle.

## 📋 Scripts disponibles

### 🔄 `backup.sh` - Sauvegarde

Crée des sauvegardes de votre installation Moodle.

**Usage:**
```bash
./scripts/backup.sh [OPTIONS]
```

**Options:**
- `--type full|db|files|code` - Type de sauvegarde (défaut: full)
- `--output DIR` - Dossier de sortie (défaut: ./backups)
- `--cleanup` - Nettoyer les anciennes sauvegardes (>7 jours)
- `--help` - Afficher l'aide

**Exemples:**
```bash
# Sauvegarde complète
./scripts/backup.sh

# Sauvegarde base de données uniquement
./scripts/backup.sh --type db

# Sauvegarde avec nettoyage
./scripts/backup.sh --cleanup
```

---

### 🔁 `restore.sh` - Restauration

Restaure une installation Moodle depuis des sauvegardes.

**Usage:**
```bash
./scripts/restore.sh [OPTIONS]
```

**Options:**
- `--db FILE` - Restaurer la base de données
- `--files FILE` - Restaurer les fichiers
- `--code FILE` - Restaurer le code source
- `--yes` - Sauter la confirmation
- `--list` - Lister les sauvegardes disponibles
- `--help` - Afficher l'aide

**Exemples:**
```bash
# Lister les sauvegardes disponibles
./scripts/restore.sh --list

# Restauration complète
./scripts/restore.sh \
  --db backups/moodle_db_20241207.sql.gz \
  --files backups/moodle_files_20241207.tar.gz

# Restauration base de données uniquement
./scripts/restore.sh --db backups/moodle_db_20241207.sql.gz
```

---

### ⬆️ `update-moodle.sh` - Mise à jour

Met à jour Moodle vers une nouvelle version.

**Usage:**
```bash
./scripts/update-moodle.sh [OPTIONS]
```

**Options:**
- `--version VERSION` - Version cible (ex: MOODLE_502_STABLE)
- `--list` - Lister les versions disponibles
- `--auto` - Mode automatique (pas de confirmation)
- `--skip-backup` - Ignorer la sauvegarde automatique
- `--help` - Afficher l'aide

**Exemples:**
```bash
# Lister les versions disponibles
./scripts/update-moodle.sh --list

# Mettre à jour vers Moodle 5.0.2
./scripts/update-moodle.sh --version MOODLE_502_STABLE

# Mise à jour automatique (CI/CD)
./scripts/update-moodle.sh --version MOODLE_502_STABLE --auto
```

**Processus:**
1. Sauvegarde automatique
2. Activation mode maintenance
3. Mise à jour du code
4. Mise à jour base de données
5. Vidage des caches
6. Redémarrage des services
7. Vérification de santé

---

### 🏥 `health-check.sh` - Vérification

Vérifie la santé de votre installation Moodle.

**Usage:**
```bash
./scripts/health-check.sh [OPTIONS]
```

**Options:**
- `--detailed` - Afficher des informations détaillées
- `--json` - Sortie au format JSON (pour monitoring)
- `--help` - Afficher l'aide

**Exemples:**
```bash
# Vérification basique
./scripts/health-check.sh

# Vérification détaillée
./scripts/health-check.sh --detailed

# Sortie JSON (pour Prometheus, etc.)
./scripts/health-check.sh --json
```

**Vérifications effectuées:**
- ✅ Docker daemon et services
- ✅ Healthchecks Docker
- ✅ MariaDB (connexion, taille base)
- ✅ Redis (cache, mémoire)
- ✅ Moodle (HTTP, fichiers, permissions)
- ✅ Volumes Docker
- ✅ Espace disque
- ✅ Service cron

**Code de sortie:**
- `0` - Tous les checks sont OK
- `>0` - Des erreurs ont été détectées

---

## 🔒 Permissions

Tous les scripts sont exécutables (`chmod +x`). Si nécessaire:

```bash
chmod +x scripts/*.sh
```

---

## ⚙️ Configuration

Les scripts utilisent les variables d'environnement du fichier `.env` à la racine du projet.

**Variables importantes:**
- `MYSQL_ROOT_PASSWORD` - Mot de passe root MySQL
- `MOODLE_DB_PASSWORD` - Mot de passe base Moodle

---

## 📊 Automatisation

### Cron quotidien (sauvegarde)

```bash
# Ajouter dans crontab
0 2 * * * /path/to/moodle-coolify-stack/scripts/backup.sh --cleanup
```

### Monitoring (health-check)

```bash
# Vérification toutes les 5 minutes
*/5 * * * * /path/to/scripts/health-check.sh --json > /var/log/moodle-health.json
```

### CI/CD (GitHub Actions)

Les scripts sont utilisés par les workflows GitHub Actions dans `.github/workflows/`.

---

## 🆘 Dépannage

### Problème: Permission denied

```bash
chmod +x scripts/*.sh
```

### Problème: .env non trouvé

```bash
# Copiez .env.example vers .env
cp .env.example .env
# Éditez avec vos valeurs
nano .env
```

### Problème: Docker non accessible

```bash
# Vérifiez que Docker est démarré
systemctl status docker

# Ajoutez votre utilisateur au groupe docker
sudo usermod -aG docker $USER
# Puis déconnectez/reconnectez-vous
```

---

## 📚 Documentation

Pour plus d'informations:
- **MAINTENANCE.md** - Guide de maintenance complet
- **TROUBLESHOOTING.md** - Résolution de problèmes
- **SETUP.md** - Installation et configuration

---

**Créé par:** [fremar64](https://github.com/fremar64)  
**Projet:** [moodle-coolify-stack](https://github.com/fremar64/moodle-coolify-stack)
