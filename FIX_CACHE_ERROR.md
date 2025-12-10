# 🔴 CORRECTIF URGENT - Erreur Cache Moodle

**Date** : 2025-12-10  
**Erreur** : `PHP Fatal error: Class "tool_forcedcache_cache_factory" not found`  
**Statut** : ✅ CORRIGÉ

---

## 🎯 Problème identifié

Le fichier `moodle/config.php` contenait une référence à un plugin de cache forcé **non installé** :

```php
$CFG->alternative_cache_factory_class = 'tool_forcedcache_cache_factory';
```

Cette ligne causait une erreur fatale PHP empêchant Moodle de démarrer, résultant en :
- HTTP 500 sur toutes les requêtes
- Healthcheck échoué (conteneur "unhealthy")
- Déploiement Coolify en échec

---

## ✅ Correction appliquée

### Fichier modifié : `moodle/config.php`

**Ligne 50-52** (AVANT) :
```php
// Cache store with Redis
$CFG->alternative_cache_factory_class = 'tool_forcedcache_cache_factory';
```

**Ligne 50-52** (APRÈS) :
```php
// Cache store with Redis (désactivé - plugin manquant)
// $CFG->alternative_cache_factory_class = 'tool_forcedcache_cache_factory';
```

### Script de nettoyage créé : `scripts/fix-cache-error.sh`

Ce script automatise :
1. Nettoyage des caches corrompus
2. Correction des permissions
3. Recréation des répertoires de cache
4. Vérification de la configuration
5. Test de santé HTTP

---

## 🚀 Déploiement de la correction

### Option A : Via Git + Coolify (RECOMMANDÉ)

1. **Commit et push** :
   ```bash
   cd ~/moodle-coolify-stack
   git add moodle/config.php scripts/fix-cache-error.sh
   git commit -m "fix(critical): Désactivation tool_forcedcache manquant"
   git push origin main
   ```

2. **Redéployer dans Coolify** :
   - Coolify → Application Moodle → **Deploy**
   - Attendre 5 minutes

3. **Tester** :
   ```bash
   curl -I https://ecole-en-ligne.ceredis.net
   # Attendu : HTTP/2 200
   ```

### Option B : Correction manuelle immédiate (si urgent)

Si vous avez accès SSH au serveur Coolify :

```bash
# 1. Identifier le conteneur Moodle
docker ps | grep moodle

# 2. Exécuter le script de nettoyage
docker exec -it <moodle_container_id> bash -c "
rm -rf /var/www/html/public/cache/classes/*
rm -rf /var/www/moodledata/cache/*
rm -rf /var/www/moodledata/localcache/*
rm -rf /var/www/moodledata/temp/*
chown -R www-data:www-data /var/www/moodledata
"

# 3. Commenter la ligne problématique dans le conteneur
docker exec -it <moodle_container_id> bash -c "
sed -i.bak 's/^\$CFG->alternative_cache_factory_class/\/\/ \$CFG->alternative_cache_factory_class/' /var/www/html/config.php
"

# 4. Redémarrer Apache
docker exec -it <moodle_container_id> apache2ctl graceful

# 5. Tester
curl -I http://localhost/login/index.php
```

**Note** : Cette méthode corrige temporairement. Il faut ensuite pousser les changements Git pour que la correction persiste.

---

## 🔍 Vérifications post-déploiement

### 1. Logs Moodle (doivent être propres)

```bash
docker logs <moodle_container> --tail 50
```

**Attendu** :
```
Démarrage d'Apache...
[Note] Apache/2.4.65 configured -- resuming normal operations
```

**PAS de** :
```
PHP Fatal error: Class "tool_forcedcache_cache_factory" not found
```

### 2. Test HTTP

```bash
curl -I https://ecole-en-ligne.ceredis.net
```

**Attendu** :
```
HTTP/2 200
content-type: text/html; charset=utf-8
```

### 3. Healthcheck Coolify

Dans Coolify UI → Application → Services :
- **Statut attendu** : `Running (healthy)` ✅
- **PAS** : `Running (unhealthy)` ❌

---

## 📊 Analyse de la cause racine

### Pourquoi cette ligne était présente ?

Le fichier `moodle/config.php` a été créé dans le commit **d415f8f1** avec cette configuration Redis :

```php
// Cache store with Redis
$CFG->alternative_cache_factory_class = 'tool_forcedcache_cache_factory';
```

**Intention** : Forcer l'utilisation de Redis pour le cache Moodle  
**Problème** : Le plugin `tool_forcedcache` n'est **pas installé** dans cette instance Moodle

### Pourquoi l'erreur n'apparaissait pas avant ?

Le fichier `moodle/config.php` était **absent** avant le commit d415f8f1. Moodle utilisait donc une configuration par défaut ou une installation wizard.

Lorsque nous avons créé `config.php` pour résoudre le problème "no available server", nous avons introduit cette ligne problématique.

---

## 🛠️ Solution pérenne

### Cache Redis sans plugin forcé

Moodle peut utiliser Redis pour le cache **sans** `tool_forcedcache`. Configuration suffisante :

```php
// Sessions Redis (déjà présent ✓)
$CFG->session_handler_class = '\core\session\redis';
$CFG->session_redis_host = 'redis';

// Cache directories (déjà présent ✓)
$CFG->cachedir = '/var/www/moodledata/cache';
$CFG->localcachedir = '/var/www/moodledata/localcache';

// PAS BESOIN de alternative_cache_factory_class
```

Pour configurer Redis comme cache store (optionnel, via UI) :
1. Connectez-vous en admin
2. **Site administration → Plugins → Caching → Configuration**
3. Ajoutez un "Redis cache store" manuellement

---

## 📝 Commits liés

| Commit | Date | Description |
|--------|------|-------------|
| `d415f8f1` | 2025-12-10 | Ajout config.php (a introduit l'erreur) |
| `b4fa2090` | 2025-12-10 | Labels Traefik (sans effet - erreur cache bloquante) |
| **À venir** | 2025-12-10 | **Fix cache error (cette correction)** |

---

## 🎉 Résultat attendu

Après application de cette correction :

✅ Moodle démarre sans erreur  
✅ HTTP 200 sur `/login/index.php`  
✅ Healthcheck passe (conteneur "healthy")  
✅ Déploiement Coolify réussi  
✅ Site accessible : https://ecole-en-ligne.ceredis.net  

---

## 📞 Si le problème persiste

### Scénario 1 : Toujours HTTP 500

**Diagnostic** :
```bash
docker exec <moodle_container> cat /var/www/html/config.php | grep alternative_cache
```

**Si la ligne est toujours active** :
- La modification n'est pas montée dans le conteneur
- Vérifiez que `moodle/config.php` est bien dans le volume Docker
- Ou appliquez la correction manuelle (Option B)

### Scénario 2 : Nouvelle erreur dans les logs

**Collectez** :
```bash
docker logs <moodle_container> --tail 100 > moodle-logs-after-fix.txt
```

Et partagez `moodle-logs-after-fix.txt` pour diagnostic.

### Scénario 3 : "no available server" revient

Si HTTP 200 fonctionne **mais** "no available server" dans le navigateur :
- Le problème cache est résolu ✅
- Revenir au diagnostic Traefik (labels manquants)
- Vérifier que les labels du commit `b4fa2090` sont bien appliqués

---

## 🔗 Fichiers de référence

- **Config corrigé** : `moodle/config.php` (ligne 50 commentée)
- **Script nettoyage** : `scripts/fix-cache-error.sh`
- **Guide déploiement** : `DEPLOIEMENT_FINAL.md`
- **Historique problèmes** : `CORRECTIFS_DEC10.md`

---

**Auteur** : GitHub Copilot  
**Statut** : ✅ Prêt pour déploiement  
**Urgence** : 🔴 CRITIQUE - À déployer immédiatement
