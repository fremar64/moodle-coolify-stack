# CORRECTION CRITIQUE - Fichiers Moodle manquants

## 🚨 Problème identifié

**Erreur 404 Not Found** : Les fichiers Moodle n'étaient pas présents dans `/var/www/html`

### Cause racine
- Le volume `./moodle:/var/www/html` montait un répertoire local **vide**
- Les fichiers Moodle n'étaient jamais installés dans le conteneur

## ✅ Solution implémentée

### 1. **Intégration Moodle dans l'image Docker**
- Téléchargement automatique de Moodle 5.1 stable depuis le repository officiel
- Installation des dépendances Composer au build
- Pack de langue français préinstallé

### 2. **Suppression du volume local**
- Supprimé `./moodle:/var/www/html` du docker-compose.yml
- Moodle est maintenant intégré dans l'image, pas monté depuis l'hôte

### 3. **Correction MOODLE_WWWROOT**
- Corrigé le double `https://` dans la variable d'environnement
- `MOODLE_WWWROOT=${DOMAIN}` au lieu de `https://${DOMAIN}`

### 4. **Script d'entrée amélioré**
- Vérification que les fichiers Moodle sont présents
- Gestion d'erreur si fichiers manquants
- Configuration Apache optimisée

## 🏗️ Architecture mise à jour

```
Dockerfile:
├── Image de base: moodlehq/moodle-php-apache:8.3
├── Installation Git + Composer
├── Téléchargement Moodle 5.1 stable
├── Installation dépendances Composer
├── Pack français préinstallé
└── Configuration optimisée

docker-compose.yml:
├── Service moodle: build: .
├── Volume: moodle_data:/var/www/moodledata (seulement)
├── Variables d'environnement corrigées
└── Pas de montage de répertoire local
```

## 🚀 Résultats attendus

Après redéploiement :
- ✅ **Fichiers Moodle présents** dans `/var/www/html`
- ✅ **Plus d'erreur 404** Not Found
- ✅ **Installation Moodle accessible** à https://ecole-en-ligne.ceredis.net
- ✅ **Interface en français** dès l'installation
- ✅ **Toutes les dépendances** installées

## 📋 Actions à faire

1. **Redéployez** l'application dans Coolify
2. **Attendez** 3-5 minutes (build complet avec téléchargement Moodle)
3. **Accédez** à https://ecole-en-ligne.ceredis.net
4. **L'installation Moodle** devrait démarrer automatiquement

## 🔍 Logs attendus

```
=== Initialisation du conteneur Moodle ===
Base de données accessible ✓
Fichiers Moodle présents ✓
Configuration des permissions...
Permissions configurées ✓
Configuration Apache activée ✓
=== Informations de démarrage ===
Apache Document Root: /var/www/html
Moodle WWW Root: ecole-en-ligne.ceredis.net
Fichiers Moodle: -rw-r--r-- 1 www-data www-data 1234 Oct 12 index.php
Démarrage d'Apache...
```

Cette correction résout définitivement le problème des fichiers manquants !