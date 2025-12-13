# SOLUTION : Erreur "Le proxy inverse est activé"

## 🎯 Vous aviez raison !

Le problème vient effectivement des **modifications récentes** (10 décembre 2025) et non de la configuration initiale qui fonctionnait.

## 🔍 Ce qui s'est passé

### Avant le 10 décembre ✅
- Moodle fonctionnait correctement
- Le fichier `config.php` n'était PAS versionné dans Git
- Configuration créée manuellement lors de l'installation
- **Pas de `$CFG->reverseproxy` défini** → Comportement par défaut

### 10 décembre ❌ (Commit d415f8f1)
```php
// Ajout dans moodle/config.php
$CFG->reverseproxy = true; // ← Cause l'erreur !
$CFG->sslproxy = true;
```

**Intention** : Améliorer la configuration pour Coolify/Traefik  
**Résultat** : Erreur "Le proxy inverse est activé"

### Aujourd'hui ✅ (13 décembre)
```php
// moodle/config.php (corrigé)
$CFG->cookiesecure = true;
$CFG->sslproxy = true;
// $CFG->reverseproxy SUPPRIMÉ (non défini)
```

**Raison** : Traefik transmet l'en-tête `Host` correctement, ce qui est incompatible avec `reverseproxy=true`

## 🛠️ Actions à faire MAINTENANT

### 1. Redéployer depuis Coolify

```
Interface Coolify → Application Moodle → "Force Rebuild With Latest Commit"
```

Ou si vous avez déjà un webhook configuré :
```bash
# Le push Git vient de déclencher automatiquement le redéploiement
```

### 2. Attendre le déploiement (2-3 minutes)

Surveiller les logs dans Coolify :
- Applications → Moodle → Logs
- Recherchez : "Démarrage d'Apache..." ou "ready for connections"

### 3. Tester l'accès

Ouvrir : https://ecole-en-ligne.ceredis.net

**✅ Attendu** : Page de connexion Moodle  
**❌ Si erreur persiste** : Voir section "Débogage" ci-dessous

## 🔧 Débogage (si nécessaire)

### Option 1 : Nettoyer le cache

```bash
cd /home/ceredis/moodle-coolify-stack
./scripts/clear-moodle-cache.sh
```

### Option 2 : Vérifier le config.php dans le conteneur

```bash
# Trouver le conteneur
docker ps | grep moodle

# Vérifier la configuration (remplacez CONTAINER_NAME)
docker exec CONTAINER_NAME grep "reverseproxy\|sslproxy" /var/www/html/config.php
```

**Résultat attendu** :
```php
$CFG->sslproxy = true; // SSL termination at Traefik level
// Pas de ligne avec $CFG->reverseproxy
```

### Option 3 : Logs Coolify

Dans l'interface Coolify :
- Applications → Moodle → Logs
- Recherchez "reverseproxyabused" ou "500"

## 📊 Résumé des changements

| Élément | Avant (10 déc) | Après (13 déc) | Statut |
|---------|----------------|----------------|--------|
| `$CFG->reverseproxy` | `true` | Non défini | ✅ Corrigé |
| `$CFG->sslproxy` | `true` | `true` | ✅ Conservé |
| `$CFG->cookiesecure` | `true` | `true` | ✅ Conservé |
| Erreur proxy | ❌ Oui | ✅ Non | ✅ Résolu |

## 📚 Documentation

- **Analyse complète** : [FIX_REVERSEPROXY_ERROR.md](FIX_REVERSEPROXY_ERROR.md)
- **Script de cache** : [scripts/clear-moodle-cache.sh](scripts/clear-moodle-cache.sh)
- **Commit de correction** : `ac2261aa` (13 décembre 2025)
- **Commit problématique** : `d415f8f1` (10 décembre 2025)

## 🎓 Leçons apprises

1. ✅ **Toujours sauvegarder les configurations fonctionnelles** avant modification
2. ✅ **Tester en environnement de développement** avant production
3. ✅ **Utiliser Git pour revenir en arrière** rapidement
4. ✅ **Documenter les changements** avec leurs raisons

## ✅ Prochaines étapes

1. **Redéployer depuis Coolify** (maintenant)
2. **Tester l'accès** à https://ecole-en-ligne.ceredis.net
3. **Confirmer que tout fonctionne**
4. **Archiver cette documentation** pour référence future

---

**Date** : 13 décembre 2025  
**Commit** : ac2261aa  
**Statut** : ✅ Corrigé et prêt pour le redéploiement
