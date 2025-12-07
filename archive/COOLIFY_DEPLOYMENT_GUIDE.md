# Guide de déploiement — Coolify (Git + Docker Compose)

## ✅ Approche retenue

Vous utilisez **Docker Compose basé sur Git** dans Coolify. C’est l’approche recommandée : traçable, reproductible, et adaptée à Moodle.

## 🚫 Côté Coolify

- Type d’application : Git Based (Docker Compose)
- Chemin du fichier : `/docker-compose.yml`
- Pas besoin du mode "Docker Based → Dockerfile".

## 📁 Architecture de la solution

```
votre-repo/
├── docker-compose.yml        ← Orchestration (Coolify lit ce fichier)
├── Dockerfile                ← Image custom Moodle (DocRoot = /var/www/html/public)
├── docker-entrypoint.sh      ← Initialisation (PHP ini dynamique, proxy HTTPS)
└── moodle/                   ← Code source Moodle (racine complète + public/)
```

## 🔄 Ce qui se passe au déploiement

1. **Coolify lit** `docker-compose.yml`
2. **Le service `moodle`** utilise `build: .` → Coolify va construire l'image avec le `Dockerfile`
3. **Le Dockerfile** définit le DocumentRoot sur `/var/www/html/public` et sécurise PHP/Apache
4. **Le script d’entrée** applique la config PHP depuis les variables d’env, gère le proxy HTTPS et installe le pack FR
5. **Résultat** : Installer Moodle fonctionnel (HTTPS, mémoire suffisante, chemins corrects)

## 🚀 Actions à faire

### Dans Coolify (variables d’environnement) :

1. **Assurez-vous** que ces variables d'environnement sont définies :
```
DOMAIN=ecole-en-ligne.ceredis.net
MYSQL_ROOT_PASSWORD=<mot_de_passe_root>
MOODLE_DB_PASSWORD=<mot_de_passe_moodle>
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=<mot_de_passe_admin>
MOODLE_ADMIN_EMAIL=admin@ceredis.net

# Réglages PHP (défauts fournis)
PHP_MEMORY_LIMIT=512M
UPLOAD_MAX_SIZE=256M
MAX_EXECUTION_TIME=300

# Optionnel : redirection HTTP → HTTPS derrière Traefik
FORCE_HTTPS=1
```

2. **Cliquez sur "Deploy"** (redéploiement)

### Ce qui est appliqué automatiquement :

- ✅ Build de l'image custom
- ✅ DocumentRoot = `/var/www/html/public`
- ✅ Pack français préinstallé (fallback via interface si téléchargement indisponible)
- ✅ Configuration PHP dynamique depuis les variables d’env
- ✅ Détection HTTPS via `X-Forwarded-Proto`; redirection optionnelle (`FORCE_HTTPS`)

## 📊 Logs attendus après déploiement

```
Building moodle_app...
...
=== Initialisation du conteneur Moodle ===
Base de données accessible ✓
Fichiers Moodle présents ✓
Application des réglages PHP dynamiques...
Réglages PHP appliqués ✓
Configuration des permissions...
Permissions configurées ✓
Configuration Apache activée ✓
Démarrage d'Apache...
```

## 🎯 Résultat final

- **URL** : https://ecole-en-ligne.ceredis.net
- **Interface** : Installation Moodle en français
- **Statut** : Toutes les vérifications au vert
- **Erreurs** : Aucune (404/403/HTTPS/mémoire résolues)

## ⚡ Pourquoi cette approche

1. **Aucune reconfiguration** Coolify
2. **Docker Compose** gère DB, Redis, backup
3. **DocumentRoot public** avec accès aux libs système (lib/, components.json)
4. **Git-based** : traçabilité complète
5. **Scalable** : ajout d’autres services aisé

---

## 🔄 Checklist de redéploiement Coolify

1. Ouvrez l’application → Deploy
2. Attendez l’apparition dans les logs de :
	- `Base de données accessible ✓`
	- `Réglages PHP appliqués ✓`
	- `Configuration Apache activée ✓`
3. Ouvrez `https://${DOMAIN}` et vérifiez que l’installateur force bien l’URL en HTTPS
4. Si le champ reste en http, activez `FORCE_HTTPS=1` et redéployez

## 🔍 Dépannage rapide

- **URL http verrouillée** : `websecure` dans Traefik + `X-Forwarded-Proto=https` + `FORCE_HTTPS=1` si besoin
- **Mémoire épuisée** : augmentez `PHP_MEMORY_LIMIT` (ex: 768M) et redéployez
- **404 / components.json** : vérifier que `./moodle` est monté vers `/var/www/html` (racine complète) et que le DocumentRoot est `/var/www/html/public`

## 📁 Volumes et chemins

- Code Moodle : `./moodle` → `/var/www/html` (racine complète)
- Données Moodle : `moodle_data` → `/var/www/moodledata`
- MariaDB : `db_data` → `/var/lib/mysql`
- Redis : `redis_data` → `/data`

Moodle est servi depuis `/var/www/html/public`, mais a besoin des fichiers système à la racine (`/var/www/html/lib`, `composer.json`, etc.).

## 🛠️ Installation par CLI (optionnel)

Si vous préférez éviter l’installateur web, suivez `INSTALL_CLI_GUIDE.md`.

**Redéployez maintenant, puis lancez l’installation.** 🚀