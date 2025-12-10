# 🚀 Guide de déploiement des corrections 504

## Modifications effectuées

### 1. **docker-compose.yml** - Augmentation des ressources et timeouts

#### MariaDB
- ✅ `innodb_buffer_pool_size` : 512M → **2G**
- ✅ `max_connections` : Ajouté (200)
- ✅ `wait_timeout` : Ajouté (600s)
- ✅ Limites Docker : **3G RAM, 2 CPUs**

#### Redis
- ✅ `maxmemory` : Ajouté (**512MB**)
- ✅ `maxmemory-policy` : **allkeys-lru**
- ✅ Limites Docker : **768M RAM**

#### Moodle
- ✅ `PHP_MEMORY_LIMIT` : 512M → **1024M**
- ✅ `UPLOAD_MAX_SIZE` : 256M → **512M**
- ✅ `POST_MAX_SIZE` : Ajouté (**512M**)
- ✅ `MAX_EXECUTION_TIME` : **300s** (5 minutes)
- ✅ Limites Docker : **3G RAM, 3 CPUs**

#### Healthcheck
- ✅ Healthcheck Docker ajouté (`/login/index.php`)
- ✅ Labels Traefik pour healthcheck distant
- ✅ **start_period** : 120s (temps de démarrage)

#### Timeouts Traefik
- ✅ `loadbalancer.server.timeout` : **300s**
- ✅ `healthcheck.interval` : **30s**
- ✅ `healthcheck.timeout` : **10s**

### 2. **Scripts créés**

- ✅ `scripts/diagnose-504.sh` - Diagnostic complet des erreurs 504
- ✅ `scripts/monitor-resources.sh` - Monitoring automatique avec alertes
- ✅ `DIAGNOSTIC_504.md` - Documentation du diagnostic

---

## 📋 Procédure de déploiement

### Étape 1 : Commit et push des modifications

```bash
cd /home/ceredis/moodle-coolify-stack

# Vérifier les modifications
git status
git diff docker-compose.yml

# Commiter
git add docker-compose.yml scripts/ DIAGNOSTIC_504.md
git commit -m "fix: Résolution erreurs 504 - Augmentation ressources et timeouts"

# Pousser vers GitHub
git push origin main
```

### Étape 2 : Déployer via Coolify

**Option A : Via l'interface Coolify (recommandé)**
1. Allez sur https://votre-coolify-url
2. Cliquez sur votre application Moodle
3. Cliquez sur **"Deploy"**
4. Attendez la fin du déploiement (~5-10 min)

**Option B : Auto-déploiement (si webhook configuré)**
- Le push sur `main` déclenche automatiquement le déploiement

### Étape 3 : Vérification post-déploiement

```bash
# 1. Vérifier que les conteneurs sont UP
# Via Coolify UI → Application → Logs

# OU en SSH sur le serveur :
ssh user@votre-serveur

# Voir les conteneurs
docker ps | grep moodle

# Vérifier la mémoire allouée
docker inspect moodle_app | grep -A 10 "Memory"

# Vérifier les limites CPU
docker inspect moodle_app | grep -A 5 "CpuShares"

# Tester le healthcheck
docker inspect moodle_app | grep -A 10 "Health"
```

### Étape 4 : Tests fonctionnels

```bash
# Test 1 : Accès HTTP
curl -I https://ecole-en-ligne.ceredis.net

# Test 2 : Page de login
curl -L https://ecole-en-ligne.ceredis.net/login/index.php | grep -i "moodle"

# Test 3 : Vérifier les timeouts Traefik
docker logs $(docker ps | grep traefik | awk '{print $1}') --tail=50 | grep moodle
```

### Étape 5 : Monitoring actif (premières 24h)

```bash
# Sur le serveur, lancer le monitoring manuel
cd /data/coolify/applications/*/moodle-coolify-stack
./scripts/monitor-resources.sh

# Ou configurer en cron (recommandé)
crontab -e

# Ajouter :
*/5 * * * * /data/coolify/applications/*/moodle-coolify-stack/scripts/monitor-resources.sh >> /var/log/moodle-monitor.log 2>&1
```

---

## 🔍 Vérifications critiques

### Vérifier que les limites sont appliquées

```bash
# Sur le serveur
docker stats --no-stream moodle_app moodle_db moodle_redis
```

**Attendu** :
- `moodle_app` : MEM USAGE proche de 2-3G max
- `moodle_db` : MEM USAGE proche de 2-3G max
- `moodle_redis` : MEM USAGE < 512M

### Vérifier les timeouts Traefik

```bash
# Inspecter les labels Traefik appliqués
docker inspect moodle_app | grep -A 20 "Labels"
```

**Rechercher** :
- `traefik.http.services.moodle.loadbalancer.server.timeout=300s`
- `traefik.http.services.moodle.loadbalancer.healthcheck.path=/login/index.php`

### Vérifier MariaDB buffer pool

```bash
docker exec moodle_db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
```

**Attendu** : `2147483648` (2G en bytes)

---

## 🚨 En cas de problème après déploiement

### Problème : Conteneur Moodle ne démarre pas

```bash
# Consulter les logs
docker logs moodle_app --tail=100

# Vérifier si OOM (Out of Memory)
dmesg | grep -i "out of memory" | grep moodle

# Si OOM : Réduire les limites dans docker-compose.yml
# limits.memory: 3G → 2G (par exemple)
```

### Problème : Erreur 502 au lieu de 504

```bash
# 502 = conteneur down ou healthcheck qui échoue
# Vérifier le healthcheck
docker exec moodle_app curl -f http://localhost/login/index.php

# Si échoue, désactiver temporairement le healthcheck
# (commenter les lignes healthcheck dans docker-compose.yml)
```

### Problème : Toujours 504 après déploiement

```bash
# 1. Vérifier que les nouveaux timeouts sont appliqués
docker inspect moodle_app | grep timeout

# 2. Vérifier les logs Traefik
docker logs $(docker ps | grep traefik | awk '{print $1}') --tail=200 | grep ecole-en-ligne

# 3. Purger les caches Moodle
docker exec moodle_app php /var/www/html/admin/cli/purge_caches.php

# 4. Redémarrer l'ensemble de la stack
docker compose restart
```

---

## 📊 Métriques à surveiller (24-48h)

### Indicateurs de succès

- ✅ **Pas d'erreur 504** pendant 24h
- ✅ **Utilisation mémoire Moodle < 80%**
- ✅ **Utilisation CPU < 70%**
- ✅ **Temps de réponse < 2s**
- ✅ **Aucun redémarrage intempestif**

### Dashboard de monitoring

```bash
# Créer un dashboard simple
watch -n 10 'docker stats --no-stream moodle_app moodle_db moodle_redis'
```

---

## 🔄 Rollback en cas d'urgence

Si les modifications causent plus de problèmes :

```bash
# 1. Via Coolify UI
# → Application → Deployments → Cliquez sur le déploiement précédent → Redeploy

# 2. Via Git
git revert HEAD
git push origin main
# → Déclenche un redéploiement automatique

# 3. Manuellement sur le serveur
cd /data/coolify/applications/*/moodle-coolify-stack
git checkout <commit-precedent>
docker compose up -d --force-recreate
```

---

## 📞 Support

En cas de problème persistant :

1. **Logs à collecter** :
   - `docker logs moodle_app > moodle.log`
   - `docker logs moodle_db > db.log`
   - `docker logs $(docker ps | grep traefik | awk '{print $1}') > traefik.log`
   - `docker stats --no-stream > stats.log`

2. **Script de diagnostic complet** :
   ```bash
   ./scripts/diagnose-504.sh > diagnostic-report.txt
   ```

3. **Contacter** :
   - Email : admin@ceredis.net
   - GitHub Issues : https://github.com/fremar64/moodle-coolify-stack/issues

---

## ✅ Checklist finale

Avant de considérer le problème résolu :

- [ ] Déploiement réussi sans erreurs
- [ ] Tous les conteneurs en état `running`
- [ ] Healthchecks passent (vert dans Coolify)
- [ ] Site accessible sans 504 pendant 1h
- [ ] Monitoring en place (cron ou manuel)
- [ ] Logs ne montrent pas d'erreurs critiques
- [ ] Performance acceptable (< 2s temps de chargement)
- [ ] Test sous charge (10+ utilisateurs simultanés)

---

**Version** : 2025-12-10  
**Status** : Correctifs implémentés, en attente de déploiement
