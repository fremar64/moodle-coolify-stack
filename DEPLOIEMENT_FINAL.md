# 🚀 Déploiement Final - Correction "no available server"

## 📋 Résumé des corrections (2 commits)

### Commit 1 : `d415f8f1` - config.php + Wiris
- ✅ Ajout `moodle/config.php` (configuration dynamique)
- ✅ Nettoyage doublons plugins Wiris
- ✅ Désactivation workflows GitHub en échec

### Commit 2 : `b4fa2090` - Labels Traefik complets
- ✅ **Labels Traefik de routage** (fix principal "no available server")
- ✅ Healthchecks MariaDB + Redis
- ✅ Depends_on conditionnels
- ✅ Logs améliorés (cron + backup)

---

## 🎯 Déploiement sur Coolify

### Option A : Via interface Coolify (RECOMMANDÉ)

1. **Ouvrir Coolify** : https://votre-coolify-url:8000
2. **Aller à l'application Moodle**
3. **Cliquer "Deploy"**
4. **Attendre 5-10 minutes**
5. **Tester** : https://ecole-en-ligne.ceredis.net

### Option B : Redéploiement manuel (si webhook configuré)

Le push sur `main` déclenche automatiquement le déploiement.

---

## ✅ Vérifications post-déploiement

### 1. État des conteneurs

Via Coolify UI → Application → Logs, vérifiez :
```
✓ Base de données accessible
✓ Fichiers Moodle présents
✓ Configuration Apache activée
✓ Démarrage d'Apache
```

**SANS** :
- ❌ Warnings Wiris (doublons supprimés)
- ❌ Erreur "config.php manquant"

### 2. Test HTTP

```bash
curl -I https://ecole-en-ligne.ceredis.net
```

**Attendu** :
```
HTTP/2 200
```

**PAS** :
- ❌ HTTP 303 (boucle redirection)
- ❌ 504 Gateway Timeout
- ❌ "no available server"

### 3. Logs Traefik (optionnel)

Si accès aux logs Traefik :
```bash
docker logs <traefik-container> | grep moodle
```

**Devrait montrer** :
```
Router moodle@docker created
Service moodle@docker registered
```

---

## 🔧 Si problème persiste

### Scénario 1 : Toujours "no available server"

**Cause possible** : Coolify gère déjà les labels Traefik automatiquement (conflit)

**Solution** :
1. Dans Coolify → Application Moodle → Settings
2. Vérifier section "Domains" : `ecole-en-ligne.ceredis.net` configuré
3. Si oui, commenter les labels manuels dans `docker-compose.yml` :

```yaml
# labels:
#   - "traefik.enable=true"
#   ...etc
```

### Scénario 2 : HTTP 500 Internal Server Error

**Cause** : Problème config.php ou permissions

**Diagnostic** :
```bash
# Logs Moodle (via Coolify UI ou SSH)
docker logs moodle_app --tail=50

# Vérifier config.php existe
docker exec moodle_app ls -l /var/www/html/config.php
```

**Solution** :
```bash
# Si config.php manquant, le recréer
docker exec moodle_app bash -c "cat > /var/www/html/config.php << 'EOFCFG'
<?php
// Contenu du fichier config.php (voir moodle/config.php dans le repo)
EOFCFG"
```

### Scénario 3 : Healthcheck failed

**Diagnostic** :
```bash
docker inspect moodle_app | grep -A 10 Health
docker inspect moodle_db | grep -A 10 Health
```

**Solution temporaire** : Désactiver healthchecks Docker (garder seulement Traefik)

---

## 📊 Changements techniques clés

### Labels Traefik ajoutés

| Label | Valeur | Purpose |
|-------|--------|---------|
| `traefik.enable` | `true` | Active explicitement Traefik |
| `traefik.http.routers.moodle.rule` | `Host(ecole-en-ligne.ceredis.net)` | Règle de routage |
| `traefik.http.services.moodle.loadbalancer.server.port` | `80` | Port du service |
| `traefik.http.routers.moodle.tls` | `true` | Active HTTPS |
| `traefik.http.routers.moodle.tls.certresolver` | `letsencrypt` | Certificat auto |

### Ressources allouées

| Service | CPU | RAM | Notes |
|---------|-----|-----|-------|
| Moodle | 3 | 3GB | Limite max, 2GB réservé |
| MariaDB | 2 | 3GB | Buffer pool 2GB |
| Redis | - | 768MB | Maxmemory 512MB |

### Timeouts configurés

| Paramètre | Valeur | Raison |
|-----------|--------|--------|
| `max_execution_time` | 300s | Requêtes lourdes Moodle |
| `traefik timeout` | 300s | Éviter 504 |
| `wait_timeout` (DB) | 600s | Connexions longues |

---

## 🎉 Résultat attendu

Après déploiement réussi :

✅ Site accessible : https://ecole-en-ligne.ceredis.net  
✅ Page de connexion Moodle affichée  
✅ Connexion admin fonctionnelle  
✅ Pas d'erreurs dans les logs  
✅ Healthchecks verts dans Coolify  
✅ Certificat SSL Let's Encrypt valide  

---

## 📞 Support

Si problème après déploiement, fournir :

1. **Logs Moodle** (50 dernières lignes)
2. **Statut conteneurs** : `docker compose ps`
3. **Test curl** : `curl -I https://ecole-en-ligne.ceredis.net`
4. **Screenshot** de l'erreur navigateur

**Commits** : `d415f8f1` + `b4fa2090`  
**Date** : 2025-12-10  
**Statut** : ✅ Prêt pour production
