# 🚀 Guide d'Installation et Configuration - Moodle Coolify Stack

Ce guide complet vous accompagne étape par étape pour déployer Moodle sur Coolify.

---

## 📋 Prérequis

### Serveur
- **Serveur Coolify** fonctionnel et accessible
- **Accès SSH** au serveur (optionnel, pour dépannage)
- **Docker** et **Docker Compose** installés (géré par Coolify)

### Ressources minimales recommandées
- **CPU** : 2 cœurs minimum
- **RAM** : 4 GB minimum (8 GB recommandé)
- **Stockage** : 20 GB minimum (50+ GB recommandé)

### DNS
- **Nom de domaine** configuré (ex: `ecole-en-ligne.ceredis.net`)
- **Enregistrement A** pointant vers l'IP de votre serveur Coolify
- **Propagation DNS** complétée (vérifiez avec `nslookup`)

---

## 🎯 Étape 1 : Préparer le dépôt

### Option A : Utiliser le dépôt existant

```bash
# Le dépôt est déjà disponible sur GitHub
https://github.com/fremar64/moodle-coolify-stack
```

### Option B : Forker pour personnalisation

1. Allez sur https://github.com/fremar64/moodle-coolify-stack
2. Cliquez sur **Fork** en haut à droite
3. Clonez votre fork en local pour modifications
4. Utilisez votre fork dans Coolify

---

## 🔧 Étape 2 : Créer l'application dans Coolify

### 2.1 Créer un nouveau projet

1. Connectez-vous à votre instance **Coolify**
2. Dans le menu : **Projects** → **+ New Project**
3. Donnez un nom : `Moodle Production`
4. Cliquez sur **Save**

### 2.2 Ajouter l'application

1. Dans votre projet : **+ New Resource**
2. Sélectionnez **Public Repository**
3. Configurez :
   - **Repository URL** : `https://github.com/fremar64/moodle-coolify-stack`
   - **Branch** : `main`
   - **Build Pack** : `Docker Compose`
   - **Base Directory** : `/` (racine)

### 2.3 Configuration réseau

1. **Domain** : `ecole-en-ligne.ceredis.net`
2. **HTTPS** : ✅ Activé (Let's Encrypt automatique)
3. **Port** : 80 (configuré automatiquement)

---

## ⚙️ Étape 3 : Configurer les variables d'environnement

Dans Coolify, allez dans **Environment Variables** et ajoutez :

### Variables obligatoires

```env
# Domaine
DOMAIN=ecole-en-ligne.ceredis.net

# Base de données (générez des mots de passe forts !)
MYSQL_ROOT_PASSWORD=VotreMotDePasseSecuriseRoot123!
MOODLE_DB_PASSWORD=VotreMotDePasseMoodleSecurise456!

# Administrateur Moodle
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=VotreMotDePasseAdmin789!
MOODLE_ADMIN_EMAIL=admin@votre-domaine.com

# Nom du site
MOODLE_SITE_NAME=École en Ligne CEREDIS
```

### Variables optionnelles (recommandées)

```env
# Configuration PHP
PHP_MEMORY_LIMIT=512M
UPLOAD_MAX_SIZE=256M
MAX_EXECUTION_TIME=300

# Fuseau horaire
TIMEZONE=Europe/Paris
```

### Variables optionnelles (avancées)

```env
# Sauvegardes Dropbox (si utilisé)
DROPBOX_TOKEN=votre_token_dropbox

# Intégrations LRS/xAPI (si utilisé)
LRS_ENDPOINT=https://votre-lrs.com
LRS_USERNAME=votre_user
LRS_PASSWORD=votre_pass
```

💡 **Astuce** : Utilisez le fichier `.env.example` comme référence complète.

---

## 🚀 Étape 4 : Déployer l'application

1. Dans Coolify, cliquez sur **Deploy**
2. Suivez les logs en temps réel
3. Attendez la fin du build (5-10 minutes la première fois)

### Logs attendus (succès)

```
✓ Building Docker image
✓ Starting services: db, redis, moodle, cron, backup
✓ Database healthcheck passed
✓ Redis healthcheck passed
✓ Moodle healthcheck passed
✓ SSL Certificate issued
✓ Application ready
```

---

## 🎓 Étape 5 : Installation initiale de Moodle

### 5.1 Accéder à l'interface web

1. Ouvrez votre navigateur
2. Allez sur : `https://ecole-en-ligne.ceredis.net`
3. Vous serez redirigé vers l'assistant d'installation

### 5.2 Suivre l'assistant

**Langue**
- Sélectionnez : **Français (fr)**
- Cliquez sur **Suivant**

**Configuration des chemins**
- Les chemins sont pré-configurés ✓
- Cliquez sur **Suivant**

**Pilote de base de données**
- Sélectionnez : **MariaDB (natif/mariadb)**
- Cliquez sur **Suivant**

**Paramètres de base de données**
```
Hôte : db
Base de données : moodle
Utilisateur : moodle
Mot de passe : [MOODLE_DB_PASSWORD configuré]
Préfixe : mdl_
Port : 3306
Socket Unix : [vide]
```

**Licence**
- Acceptez les termes de la licence GPL
- Cliquez sur **Continuer**

**Vérification du serveur**
- Moodle vérifie les prérequis ✓
- Corrigez les avertissements si nécessaire
- Cliquez sur **Continuer**

**Installation**
- L'installation des tables se lance automatiquement
- Attendez la fin (2-5 minutes)

**Configuration du compte administrateur**
```
Nom d'utilisateur : [MOODLE_ADMIN_USER configuré]
Mot de passe : [MOODLE_ADMIN_PASS configuré]
Email : [MOODLE_ADMIN_EMAIL configuré]
```

**Paramètres de première page**
- Configurez les informations de votre établissement
- Cliquez sur **Enregistrer les modifications**

### 5.3 Finalisation

🎉 **Félicitations !** Votre Moodle est opérationnel.

---

## ✅ Étape 6 : Vérifications post-installation

### 6.1 Tester les fonctionnalités principales

- [ ] Connexion administrateur fonctionnelle
- [ ] Création d'un cours de test
- [ ] Upload d'un fichier
- [ ] Accès à l'administration du site
- [ ] Cache Redis actif (Admin → Plugins → Caching)

### 6.2 Vérifier les services

Dans Coolify, vérifiez que tous les containers sont **healthy** :
- ✅ `moodle_db` (MariaDB)
- ✅ `moodle_redis` (Cache)
- ✅ `moodle_app` (Application)
- ✅ `moodle_cron` (Tâches planifiées)
- ✅ `moodle_backup` (Sauvegardes)

### 6.3 Tester le SSL

```bash
# Vérifier le certificat SSL
curl -I https://ecole-en-ligne.ceredis.net

# Devrait retourner : HTTP/2 200
```

---

## 🔒 Étape 7 : Sécuriser l'installation

### 7.1 Changer les mots de passe par défaut

Si vous avez utilisé des mots de passe temporaires, changez-les maintenant.

### 7.2 Configurer les sauvegardes

1. Vérifiez que le service `backup` fonctionne
2. Si vous utilisez Dropbox, vérifiez les logs :
```bash
docker logs moodle_backup
```

### 7.3 Activer la maintenance planifiée

Dans Moodle : **Administration → Serveur → Maintenance planifiée**
- Configurez une fenêtre de maintenance hebdomadaire

---

## 🎨 Étape 8 : Personnalisation (optionnel)

### 8.1 Installer des plugins

```bash
# Clonez le dépôt en local
git clone https://github.com/votre-username/moodle-coolify-stack
cd moodle-coolify-stack

# Ajoutez un plugin dans le dossier approprié
cd moodle/mod/  # ou local/, theme/, etc.
# Ajoutez votre plugin

# Committez et poussez
git add .
git commit -m "Ajout plugin XYZ"
git push

# Redéployez depuis Coolify
```

### 8.2 Personnaliser le thème

1. Ajoutez votre thème dans `moodle/theme/`
2. Committez et redéployez
3. Dans Moodle : **Apparence → Sélecteur de thèmes**

---

## 📊 Surveillance et monitoring

### Logs des containers

Dans Coolify :
- **Applications** → Votre application → **Logs**
- Sélectionnez le service à surveiller

### Commandes utiles (SSH)

```bash
# Statut des containers
docker compose ps

# Logs d'un service spécifique
docker compose logs -f moodle

# Accès au shell Moodle
docker exec -it moodle_app bash

# Vérifier l'utilisation des ressources
docker stats
```

---

## 🆘 Dépannage

Pour résoudre les problèmes courants, consultez :
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Guide de dépannage complet

### Problèmes fréquents

**Erreur 502/503**
- Attendez 2-3 minutes (démarrage des services)
- Vérifiez les healthchecks dans Coolify

**Base de données inaccessible**
- Vérifiez les variables d'environnement
- Consultez les logs du container `db`

**Certificat SSL non généré**
- Vérifiez la configuration DNS
- Attendez 10-15 minutes pour la propagation

---

## 📚 Ressources supplémentaires

- **[README.md](README.md)** - Vue d'ensemble du projet
- **[MAINTENANCE.md](MAINTENANCE.md)** - Guide de maintenance et mises à jour
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Résolution de problèmes
- **[Documentation Moodle officielle](https://docs.moodle.org/)**
- **[Documentation Coolify](https://coolify.io/docs)**

---

✅ **Installation terminée !** Votre plateforme Moodle est prête à accueillir vos apprenants.
