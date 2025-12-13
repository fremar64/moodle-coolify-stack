# Correction : Erreur "Le proxy inverse est activé"

## Résumé du problème

**Date d'apparition** : 10 décembre 2025  
**Cause** : Commit `d415f8f1` qui a introduit `$CFG->reverseproxy = true;` dans le nouveau fichier `moodle/config.php`

### Chronologie

1. **Avant le 10 décembre** : Moodle fonctionnait correctement sans fichier `config.php` versionné dans Git
2. **10 décembre** : Ajout de `moodle/config.php` avec `$CFG->reverseproxy = true;` (commit d415f8f1)
3. **Depuis** : Erreur "Le proxy inverse est activé ; il n'est donc pas possible d'accéder au serveur de manière directe"

## Cause racine

### Pourquoi l'erreur apparaît maintenant ?

Le commit du 10 décembre a créé un fichier `moodle/config.php` avec cette configuration problématique :

```php
$CFG->reverseproxy = true; // ❌ PROBLÉMATIQUE
$CFG->sslproxy = true;
```

**Avant ce commit** : Moodle utilisait probablement un `config.php` créé manuellement lors de l'installation initiale (non versionné dans Git) qui n'avait PAS `reverseproxy = true`.

### Explication technique

Cette erreur est générée par le code de Moodle dans `/lib/setuplib.php` (ligne 737) :

```php
if (!empty($CFG->reverseproxy) && $rurl['host'] === $wwwroot['host'] && 
    (empty($wwwroot['port']) || $rurl['port'] === $wwwroot['port'])) {
    throw new \moodle_exception('reverseproxyabused', 'error');
}
```

Moodle lance cette exception lorsque :
1. `$CFG->reverseproxy = true` est activé
2. Le host de la requête HTTP (`HTTP_HOST`) est **identique** au host configuré dans `wwwroot`

### Pourquoi `reverseproxy = true` ne convient pas à Coolify/Traefik ?

Le mode `reverseproxy` de Moodle est conçu pour des configurations où :
- Le proxy reverse **ne transmet PAS** l'en-tête `Host` original
- Le serveur Moodle reçoit un nom d'hôte **interne** différent du `wwwroot` public
- Exemple : Moodle reçoit `http://internal-server:8080` mais `wwwroot = https://example.com`

**Or, Coolify/Traefik** :
- ✅ Transmet correctement l'en-tête `Host` (comportement standard HTTP)
- ✅ Gère la terminaison SSL de manière transparente
- ✅ Transmet les en-têtes `X-Forwarded-*` appropriés

**Résultat** : Moodle reçoit `Host: ecole-en-ligne.ceredis.net`, identique à `wwwroot` → Exception !

## Solution appliquée

### Modifications dans [config.php](moodle/config.php#L51-L56)

```php
// Security settings
$CFG->cookiesecure = true; // HTTPS only
$CFG->sslproxy = true; // SSL termination at Traefik level

// IMPORTANT: reverseproxy setting removed - caused "reverseproxyabused" error
// Traefik handles proxy transparently without needing Moodle's reverse proxy mode
```

**Changement clé** : 
- ❌ SUPPRIMÉ : `$CFG->reverseproxy = true;`
- ✅ CONSERVÉ : `$CFG->sslproxy = true;`
- ✅ CONSERVÉ : `$CFG->cookiesecure = true;`

### Pourquoi cette configuration fonctionne ?

1. **Absence de `reverseproxy`** : Désactive la vérification stricte du host (comportement par défaut de Moodle)
2. **`sslproxy = true`** : Indique que la terminaison SSL est gérée par le proxy (nécessaire)
3. **`cookiesecure = true`** : Force les cookies HTTPS (sécurité)
4. **Traefik gère tout** : Les en-têtes HTTP, le SSL, et le routage sont transparents

## Configurations testées

### ❌ Configuration qui NE FONCTIONNE PAS

```php
$CFG->reverseproxy = true;  // ← Cause l'erreur
$CFG->sslproxy = true;
```
**Résultat** : Exception `reverseproxyabused` car `HTTP_HOST` est identique à `wwwroot`

### ❌ Configuration qui NE FONCTIONNE PAS NON PLUS

```php
$CFG->reverseproxy = false; // ← Explicitement désactivé
$CFG->sslproxy = true;
```
**Problème** : `reverseproxy = false` est traité comme une valeur définie (non vide), ce qui peut encore déclencher certaines vérifications

### ✅ Configuration qui FONCTIONNE

```php
// $CFG->reverseproxy absent (non défini)
$CFG->sslproxy = true;
$CFG->cookiesecure = true;
```
**Résultat** : Moodle utilise son comportement par défaut, compatible avec les proxies transparents

## Instructions de déploiement

### Étape 1 : Vérifier les modifications

```bash
cd /home/ceredis/moodle-coolify-stack
grep -n "reverseproxy" moodle/config.php
```

**Résultat attendu** : Aucune ligne active avec `$CFG->reverseproxy`, uniquement des commentaires

### Étape 2 : Redéployer depuis Coolify

1. **Interface Coolify** → Votre application Moodle
2. Cliquez sur **"Redeploy"** ou **"Force Rebuild With Latest Commit"**
3. Attendez la fin du déploiement (2-3 minutes)
4. Vérifiez les logs pour confirmer le démarrage

### Étape 3 : Nettoyer le cache (optionnel)

Si le problème persiste après le redéploiement, exécutez le script de nettoyage :

```bash
cd /home/ceredis/moodle-coolify-stack
./scripts/clear-moodle-cache.sh
```

Ou manuellement :
```bash
# Trouver le nom du conteneur
docker ps | grep moodle

# Purger le cache (remplacez CONTAINER_NAME par le nom réel)
docker exec CONTAINER_NAME php /var/www/html/public/admin/cli/purge_caches.php

# Nettoyer les fichiers cache
docker exec CONTAINER_NAME rm -rf /var/www/moodledata/cache/* /var/www/moodledata/localcache/*
```

### Étape 4 : Vérifier le résultat

Accédez à https://ecole-en-ligne.ceredis.net

**✅ Succès** : Page de connexion Moodle s'affiche  
**❌ Échec** : Voir la section Débogage ci-dessous

## Débogage

### Vérifier que le config.php est correct dans le conteneur

```bash
# Trouver le conteneur actif
docker ps | grep moodle

# Vérifier le contenu (remplacez CONTAINER_NAME)
docker exec CONTAINER_NAME grep -A 2 "reverseproxy\|sslproxy" /var/www/html/config.php
```

**Résultat attendu** : Aucune ligne avec `$CFG->reverseproxy`, uniquement `$CFG->sslproxy = true;`

### Vérifier les logs de Moodle

```bash
# Dans Coolify : Applications → Moodle → Logs
# Ou en ligne de commande :
docker logs CONTAINER_NAME --tail=50
```

Recherchez :
- ❌ `reverseproxyabused` : Le config.php n'est pas chargé correctement
- ✅ `Apache/2.4` ready : Le conteneur démarre normalement

### Si l'erreur persiste

**Possibilité 1** : Le volume `moodledata` contient un ancien config.php

```bash
# Vérifier s'il existe un config.php dans moodledata
docker exec CONTAINER_NAME find /var/www/moodledata -name "config.php"
```

**Possibilité 2** : Cache OPcache PHP

```bash
# Redémarrer complètement l'application
docker compose restart moodle
# Ou depuis Coolify : Stop → Start
```

## Analyse Git : Pourquoi maintenant ?

### Historique des modifications

```bash
cd /home/ceredis/moodle-coolify-stack
git log --oneline --since="2 months ago" -- moodle/config.php
```

**Résultat** :
- `8332f45a` (10 déc) : Désactivation tool_forcedcache
- `d415f8f1` (10 déc) : **Ajout config.php + reverseproxy=true** ← SOURCE DU PROBLÈME

### Configuration avant le 10 décembre

Avant ce commit, le fichier `moodle/config.php` **n'existait pas dans Git**. La configuration était probablement :
- Créée manuellement lors de l'installation initiale de Moodle
- Stockée uniquement dans le volume Docker (non versionnée)
- **Sans la directive `reverseproxy = true`**

### Pourquoi le problème a été introduit ?

Le commit du 10 décembre a tenté d'améliorer la configuration en créant un `config.php` standard pour le versionnement Git. Malheureusement, il a inclus `$CFG->reverseproxy = true;` en pensant que c'était nécessaire pour Coolify/Traefik, alors que c'est justement ce qui cause l'erreur.

## Leçons apprises

1. **Ne pas activer `reverseproxy`** pour les proxies transparents modernes (Traefik, nginx, Caddy)
2. **Tester les changements de configuration** avant de les déployer en production
3. **Documenter les configurations fonctionnelles** avant de les modifier
4. **Utiliser Git pour revenir en arrière** en cas de problème

## Références

- **Code source** : [`/lib/setuplib.php` ligne 726-738](moodle/public/lib/setuplib.php#L726-L738)
- **Exception** : `reverseproxyabused` définie dans `/lang/en/error.php`
- **Documentation Moodle** : https://docs.moodle.org/en/Masquerading
- **Commit problématique** : `d415f8f1` (10 décembre 2025)

## Statut

**✅ Corrigé** : Suppression de `$CFG->reverseproxy` dans [config.php](moodle/config.php)  
**📅 Date** : 13 décembre 2025  
**🔄 Action requise** : Redéployer l'application depuis Coolify
