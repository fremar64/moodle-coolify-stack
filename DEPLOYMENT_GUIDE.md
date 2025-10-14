# Guide de Déploiement Moodle sur Coolify

## 🎯 Stack Moodle complet pour Coolify

Ce repository contient une stack complète Docker Compose pour déployer Moodle 5.1 sur la plateforme Coolify avec une approche basée sur Git.

## 📦 Composants

- **Moodle 5.1 stable** : Code source officiel complet
- **MariaDB 11.4** : Base de données optimisée
- **Redis 7** : Cache et sessions
- **Apache/PHP 8.3** : Serveur web avec configuration optimisée

## 🚀 Déploiement sur Coolify

### 1. Création du projet dans Coolify

1. Connectez-vous à votre instance Coolify
2. Créez un nouveau projet
3. Sélectionnez "Git Repository" comme source
4. Entrez l'URL du repository : `https://github.com/fremar64/moodle-coolify-stack.git`
5. Sélectionnez la branche `main`

### 2. Configuration

Coolify détectera automatiquement le fichier `docker-compose.yml` et configurera :

- **Service Moodle** : Port 80 avec Apache/PHP
- **Service MariaDB** : Base de données avec volume persistant
- **Service Redis** : Cache pour les performances

### 3. Variables d'environnement

Coolify configurera automatiquement les variables d'environnement nécessaires :

```env
MYSQL_ROOT_PASSWORD=<généré_automatiquement>
MYSQL_DATABASE=moodle
MYSQL_USER=moodle
MYSQL_PASSWORD=<généré_automatiquement>
```

### 4. Volumes et persistance

- **Volume Moodle** : `/var/www/html` (code source)
- **Volume MariaDB** : `/var/lib/mysql` (base de données)
- **Volume Redis** : `/data` (cache)

## 🔧 Configuration post-déploiement

### 1. Premier accès

Une fois déployé, accédez à votre domaine Coolify. Moodle vous guidera dans l'installation :

1. **Langue** : Sélectionnez le français
2. **Chemins** : Coolify configure automatiquement les chemins
3. **Base de données** : 
   - Type : MariaDB
   - Host : `db`
   - Base : `moodle`
   - Utilisateur : `moodle`
   - Mot de passe : Celui configuré par Coolify

### 2. Configuration du cache

Le cache Redis est automatiquement disponible sur `redis:6379`.

### 3. Optimisations incluses

- **Composer** : Installation automatique des dépendances
- **Pack de langue française** : Installé automatiquement
- **Permissions** : Configurées correctement
- **Sécurité PHP** : Configuration optimisée

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Coolify     │    │     Moodle      │    │     MariaDB     │
│  Reverse Proxy  │───▶│   Apache/PHP    │───▶│   Database      │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │      Redis      │
                       │     Cache       │
                       └─────────────────┘
```

## 📁 Structure du projet

```
moodle-coolify-stack/
├── docker-compose.yml       # Orchestration des services
├── Dockerfile              # Image Moodle personnalisée
├── docker-entrypoint.sh    # Script d'initialisation
├── moodle/                 # Code source Moodle 5.1
│   ├── index.php
│   ├── config-dist.php
│   ├── composer.json
│   └── ...                # Tous les fichiers Moodle
└── DEPLOYMENT_GUIDE.md     # Ce guide
```

## 🔍 Résolution de problèmes

### Problèmes courants

1. **Erreur 403** : Vérifiez que les permissions sont correctes
2. **Erreur base de données** : Vérifiez les variables d'environnement
3. **Composants manquants** : Le code source est maintenant complet

### Logs

Consultez les logs dans Coolify :
- Service `moodle` : Logs Apache/PHP
- Service `db` : Logs MariaDB
- Service `redis` : Logs cache

## 📊 Avantages de cette approche

✅ **Code source complet** : Moodle 5.1 officiel intégral
✅ **Gestion Git** : Traçabilité et versioning
✅ **Déploiement automatisé** : Un clic dans Coolify
✅ **Performances optimisées** : Redis + MariaDB 11.4
✅ **Sécurisé** : Configuration PHP durcie
✅ **Évolutif** : Facilement customisable

## 🚀 Mise à jour

Pour mettre à jour Moodle :

1. Mettez à jour le code source dans le repository
2. Commitez et pushez
3. Coolify redéploiera automatiquement

## 📞 Support

En cas de problème :

1. Vérifiez les logs dans Coolify
2. Consultez la documentation Moodle officielle
3. Vérifiez la configuration Docker Compose

---

**Développé pour Coolify** | Moodle 5.1 | Docker Compose | Git-based deployment