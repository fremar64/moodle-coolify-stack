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

Coolify détecte automatiquement le fichier `docker-compose.yml` et configure :

- **Service Moodle** : Port 80 avec Apache/PHP (DocumentRoot = `/var/www/html/public`)
- **Service MariaDB** : Base de données avec volume persistant
- **Service Redis** : Cache pour les performances

### 3. Variables d'environnement

À définir dans Coolify (onglet Variables) :

```env
DOMAIN=ecole-en-ligne.ceredis.net
MYSQL_ROOT_PASSWORD=<mot_de_passe_root>
MOODLE_DB_PASSWORD=<mot_de_passe_moodle>
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=<mot_de_passe_admin>
MOODLE_ADMIN_EMAIL=admin@ceredis.net

# Réglages PHP (valeurs par défaut déjà présentes)
PHP_MEMORY_LIMIT=512M
UPLOAD_MAX_SIZE=256M
MAX_EXECUTION_TIME=300

# Optionnel : forcer la redirection HTTPS derrière Traefik
FORCE_HTTPS=1
```

### 4. Volumes et persistance

- **Code Moodle** : `./moodle` → `/var/www/html` (montage de la racine complète)
- **Données Moodle** : `moodle_data` → `/var/www/moodledata`
- **MariaDB** : `db_data` → `/var/lib/mysql`
- **Redis** : `redis_data` → `/data`

## 🔧 Corrections apportées

### Problème résolu : 404 Not Found / composants manquants

**Cause** : Moodle 5.1 sépare le code web public (`public/`) du code système (`lib/`, `composer.json`). Monter uniquement `public/` masque des fichiers critiques.

**Solution** :

- Monter la racine complète `./moodle` vers `/var/www/html`
- Configurer Apache avec `DocumentRoot=/var/www/html/public`

### Files essentiels vérifiés ✅
- `install.php` : Présent dans `moodle/public/install.php`
- `index.php` : Présent dans `moodle/public/index.php`
- Toutes les bibliothèques Moodle incluses dans `moodle/public/lib/`

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

- **PHP dynamique** : `99-custom-settings.ini` généré depuis les variables d'env
- **Pack de langue FR** : Téléchargé automatiquement (fallback via interface si échec)
- **Permissions** : Durcies pour `www-data`
- **Sécurité PHP** : `zend.exception_ignore_args = On`
- **Proxy-aware** : Détection HTTPS via `X-Forwarded-Proto`; redirection optionnelle via `FORCE_HTTPS=1`

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
├── Dockerfile               # Image Moodle personnalisée
├── docker-entrypoint.sh     # Script d'initialisation
├── moodle/                  # Code source Moodle 5.1 (racine complète)
│   ├── lib/                 # Système
│   ├── public/              # DocumentRoot web
│   ├── config-dist.php
│   ├── composer.json
│   └── ...
└── DEPLOYMENT_GUIDE.md      # Ce guide
```

## 🔍 Résolution de problèmes

### Problèmes courants

1. **URL HTTP verrouillée pendant l'installation** :
  - Vérifiez que le routeur Traefik utilise l'entrypoint `websecure`
  - Assurez `X-Forwarded-Proto: https` dans les requêtes
  - Si besoin, définissez `FORCE_HTTPS=1`
2. **Erreur mémoire pendant l'installation** :
  - Augmentez `PHP_MEMORY_LIMIT` (ex: 768M)
  - Vérifiez via `php -i | grep memory_limit` dans le conteneur
3. **Erreur base de données** : Vérifiez les variables d'environnement et l'accessibilité `db:3306`

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

---

## 🔄 Redéploiement via Coolify (checklist)

1. Ouvrez l'application dans Coolify → Deploy
2. Attendez le build et le lancement des services
3. Dans les logs du service `moodle`, repérez :
   - `Base de données accessible ✓`
   - `Réglages PHP appliqués ✓`
   - `Configuration Apache activée ✓`
4. Visitez `https://${DOMAIN}` et vérifiez que l'URL affichée dans l'installateur est en HTTPS
5. Si non, ajoutez `FORCE_HTTPS=1` et redéployez

## ✅ Vérifications rapides

- PHP memory_limit appliqué :
  - Dans le conteneur `moodle_app` : `php -i | grep memory_limit`
- Accès cron : `php /var/www/html/public/admin/cli/cron.php`
- Fichier `lib/components.json` présent : `/var/www/html/lib/components.json`