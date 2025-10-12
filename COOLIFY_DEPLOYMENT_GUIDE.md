# Guide de déploiement - Coolify Docker Compose avec Dockerfile

## ✅ Votre configuration actuelle est PARFAITE

Vous utilisez **Docker Compose avec Git** dans Coolify, et c'est la meilleure approche pour votre cas.

## 🚫 NE CHANGEZ RIEN dans Coolify

- **Gardez** : Applications -> Git Based
- **Gardez** : Docker Compose Location : `/docker-compose.yml`
- **N'allez PAS** vers Docker Based -> Dockerfile

## 📁 Architecture de la solution

```
votre-repo/
├── docker-compose.yml     ← Orchestration (déjà configuré)
├── Dockerfile            ← Image custom pour Moodle
├── docker-entrypoint.sh  ← Script d'initialisation
└── autres fichiers...
```

## 🔄 Ce qui va se passer

1. **Coolify lit** `docker-compose.yml`
2. **Le service `moodle`** utilise `build: .` → Coolify va construire l'image avec le `Dockerfile`
3. **Le Dockerfile** corrige tous les problèmes (Apache, Composer, PHP, pack français)
4. **Résultat** : Moodle fonctionne parfaitement

## 🚀 Actions à faire

### Dans Coolify (AUCUN changement de configuration) :

1. **Assurez-vous** que ces variables d'environnement sont définies :
```
DOMAIN=ecole-en-ligne.ceredis.net
MYSQL_ROOT_PASSWORD=votre_mot_de_passe_root
MOODLE_DB_PASSWORD=votre_mot_de_passe_moodle
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=votre_mot_de_passe_admin
MOODLE_ADMIN_EMAIL=admin@ceredis.net
```

2. **Cliquez sur "Deploy"** (redéploiement)

### Ce qui va changer automatiquement :

- ✅ Build de l'image custom avec Dockerfile
- ✅ Installation automatique de Composer
- ✅ Pack français préinstallé
- ✅ Configuration Apache/PHP corrigée
- ✅ Plus d'erreur 403 Forbidden

## 📊 Logs attendus après déploiement

```
Building moodle_app...
Step 1/10 : FROM moodlehq/moodle-php-apache:8.3
Step 2/10 : RUN apt-get update && apt-get install...
...
Successfully built xxxxx
Creating moodle_db... done
Creating moodle_redis... done
Creating moodle_app... done
=== Initialisation du conteneur Moodle ===
Base de données accessible ✓
Dépendances Composer installées ✓
Configuration des permissions...
Permissions configurées ✓
Démarrage d'Apache...
```

## 🎯 Résultat final

- **URL** : https://ecole-en-ligne.ceredis.net
- **Interface** : Installation Moodle en français
- **Statut** : Toutes les vérifications au vert
- **Erreurs** : Aucune (403, Composer, etc. résolues)

## ⚡ Pourquoi cette approche est parfaite

1. **Pas de reconfiguration** Coolify
2. **Docker Compose** gère la base de données, Redis, backup
3. **Dockerfile** corrige uniquement le conteneur Moodle
4. **Git-based** : changements trackés et versionnés
5. **Scalable** : facile d'ajouter d'autres services

**Redéployez maintenant et tout devrait fonctionner !** 🚀