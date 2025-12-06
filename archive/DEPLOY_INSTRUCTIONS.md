# Instructions de déploiement Coolify - CORRECTION COMPLÈTE

## 🚨 Problèmes résolus
- ✅ Erreur 403 Apache (APACHE_DOCUMENT_ROOT manquante)
- ✅ Composer non trouvé (intégré dans Dockerfile)
- ✅ Pack français corrompu (préinstallé dans l'image)
- ✅ Configuration PHP sécurisée (zend.exception_ignore_args)

## 📋 Actions à faire dans Coolify

### 1. Configuration Build
- **Build Pack**: Dockerfile
- **Dockerfile Location**: `./Dockerfile`
- **Context**: `.` (racine du projet)

### 2. Variables d'environnement à vérifier
Assurez-vous que ces variables sont bien définies :
```
DOMAIN=ecole-en-ligne.ceredis.net
MYSQL_ROOT_PASSWORD=votre_mot_de_passe_root
MOODLE_DB_PASSWORD=votre_mot_de_passe_moodle
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=votre_mot_de_passe_admin
MOODLE_ADMIN_EMAIL=admin@ceredis.net
```

### 3. Redéployement
1. **Arrêtez** l'application actuelle
2. **Supprimez les volumes** (optionnel pour repartir propre)
3. **Redéployez** l'application

## 🔍 Logs attendus après déploiement
```
=== Initialisation du conteneur Moodle ===
Attente de la base de données...
Base de données accessible ✓
Installation des dépendances Composer...
Dépendances Composer installées ✓
Configuration des permissions...
Permissions configurées ✓
Configuration Apache activée ✓
=== Informations de démarrage ===
Apache Document Root: /var/www/html
Moodle WWW Root: https://ecole-en-ligne.ceredis.net
Base de données: db:3306
Redis: redis:6379
================================
Démarrage d'Apache...
```

## 🎯 Résultat attendu
- ✅ https://ecole-en-ligne.ceredis.net accessible
- ✅ Installation Moodle en français
- ✅ Pas d'erreur 403 Forbidden
- ✅ Toutes les vérifications au vert

## 🛠️ Dépannage
Si problème persiste :
1. Vérifiez les logs du conteneur
2. Assurez-vous que le build Dockerfile s'est bien déroulé
3. Vérifiez que toutes les variables d'environnement sont définies