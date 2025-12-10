# 🔴 Diagnostic des erreurs 504 Gateway Timeout

## Analyse des causes probables

### Observation
- **Erreur** : `Gateway time-out Error code 504` avec message Cloudflare
- **Fréquence** : Intermittente (fonctionne parfois après quelques minutes)
- **Pattern** : Instabilité récurrente

---

## 🎯 Causes identifiées

### 1. **CAUSE PRINCIPALE : Conteneur Moodle qui redémarre/crash**

**Symptômes observés** :
- Message Cloudflare (proxy devant Coolify/Traefik)
- Erreur 504 = backend non réactif dans le délai imparti
- Retour à la normale après quelques minutes

**Diagnostic via Coolify** :
```
Application Status: "running:unknown"
```

**Ce statut indique** :
- Coolify ne peut pas vérifier la santé de l'application
- Le healthcheck Docker est désactivé (volontairement dans docker-compose.yml)
- Le conteneur peut redémarrer sans que Coolify le détecte clairement

### 2. **Raisons possibles des crashs/redémarrages**

#### A. Manque de ressources (OOM - Out of Memory)
- **PHP Memory Limit** : Actuellement 512M (peut-être insuffisant sous charge)
- **Conteneur sans limite mémoire** : Peut consommer toute la RAM serveur
- **Cron Moodle** : Tâches gourmandes qui saturent la mémoire

#### B. Timeout PHP/Apache
- **max_execution_time** : Probablement 60s (défaut)
- **FPM request_timeout** : Peut tuer les processus PHP
- Pages Moodle lourdes qui dépassent le timeout → crash

#### C. Base de données lente
- **Buffer pool** : Seulement 512M (peut être insuffisant)
- Queries lentes qui bloquent PHP
- Connexions DB qui s'accumulent

#### D. Traefik timeout
- **Timeout par défaut** : 90 secondes
- Si Moodle met >90s à répondre → 504

---

## 🔧 Solutions à implémenter

### Solution 1 : Augmenter les limites de ressources (PRIORITÉ 1)

**Fichier : docker-compose.yml**

```yaml
moodle:
  # Ajouter des limites de ressources
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        memory: 1G
  
  # Augmenter timeout PHP
  environment:
    - PHP_MEMORY_LIMIT=1024M  # Doubler
    - MAX_EXECUTION_TIME=300  # 5 minutes
    - UPLOAD_MAX_SIZE=512M
```

**Fichier : MariaDB**

```yaml
db:
  command: [
    "--character-set-server=utf8mb4",
    "--collation-server=utf8mb4_unicode_ci",
    "--skip-character-set-client-handshake",
    "--innodb-buffer-pool-size=2G",  # Augmenter de 512M à 2G
    "--max-connections=200",
    "--wait-timeout=600"
  ]
  deploy:
    resources:
      limits:
        memory: 3G
      reservations:
        memory: 2G
```

---

### Solution 2 : Ajouter un healthcheck tolérant (PRIORITÉ 1)

**Fichier : docker-compose.yml**

```yaml
moodle:
  labels:
    - "traefik.http.services.moodle.loadbalancer.healthcheck.path=/login/index.php"
    - "traefik.http.services.moodle.loadbalancer.healthcheck.interval=30s"
    - "traefik.http.services.moodle.loadbalancer.healthcheck.timeout=10s"
    
  # Healthcheck Docker léger
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost/login/index.php"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 120s  # 2 minutes de démarrage
```

---

### Solution 3 : Augmenter les timeouts Traefik (PRIORITÉ 2)

**Via labels Coolify dans docker-compose.yml** :

```yaml
moodle:
  labels:
    # Timeouts Traefik
    - "traefik.http.services.moodle.loadbalancer.server.timeout=300s"
    - "traefik.http.services.moodle.loadbalancer.passhostheader=true"
    - "traefik.http.services.moodle.loadbalancer.responseforwarding.flushinterval=100ms"
```

---

### Solution 4 : Optimiser PHP-FPM (PRIORITÉ 2)

**Fichier : Dockerfile (ou config PHP-FPM)**

```ini
; /usr/local/etc/php-fpm.d/www.conf
pm = dynamic
pm.max_children = 50        # Augmenter si besoin
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
pm.process_idle_timeout = 10s
request_terminate_timeout = 300s  # 5 minutes
```

---

### Solution 5 : Monitoring et alertes (PRIORITÉ 3)

**Script de monitoring des ressources** :

```bash
#!/bin/bash
# /scripts/monitor-resources.sh

# Surveiller conteneur Moodle
MOODLE_MEM=$(docker stats --no-stream --format "{{.MemPerc}}" moodle_app | sed 's/%//')

if (( $(echo "$MOODLE_MEM > 80" | bc -l) )); then
    echo "⚠ WARNING: Moodle memory usage at ${MOODLE_MEM}%"
    # Redémarrer si critique
    if (( $(echo "$MOODLE_MEM > 95" | bc -l) )); then
        docker restart moodle_app
        echo "🔄 Moodle restarted due to high memory"
    fi
fi
```

**Cron** :
```bash
*/5 * * * * /path/to/monitor-resources.sh >> /var/log/moodle-monitor.log 2>&1
```

---

## 📊 Actions immédiates recommandées

### Étape 1 : Vérifier l'état actuel sur le serveur

**Via Coolify UI** :
1. Aller dans l'application Moodle
2. Consulter les **Logs** (dernières 500 lignes)
3. Vérifier les **Resources** (CPU/Memory usage)
4. Regarder si `restart_count` augmente

### Étape 2 : Logs serveur (si accès SSH)

```bash
# Sur le serveur Coolify
ssh user@votre-serveur

# Voir les conteneurs Moodle
docker ps | grep moodle

# Voir les restarts
docker inspect moodle_app | grep -A 5 "RestartCount"

# Logs Moodle (erreurs)
docker logs moodle_app --tail=500 | grep -E "(error|fatal|segfault|oom)" -i

# Logs Traefik
docker logs $(docker ps | grep traefik | awk '{print $1}') --tail=500 | grep ecole-en-ligne
```

### Étape 3 : Implémenter les correctifs

1. **Modifier `docker-compose.yml`** (augmenter ressources + timeouts)
2. **Git commit/push**
3. **Redéployer via Coolify**
4. **Surveiller pendant 24h**

---

## 🔍 Validation du diagnostic

### Hypothèse à confirmer : OOM (Out Of Memory) Killer

**Commande serveur** :
```bash
# Vérifier si le conteneur a été tué pour OOM
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process" | grep moodle

# Vérifier les limites actuelles
docker inspect moodle_app | grep -A 10 "Memory"
```

**Si résultat positif** → Confirme que le conteneur crashe par manque de mémoire

---

## 📝 Plan d'action complet

### Phase 1 : Diagnostic approfondi (Aujourd'hui)
- [x] Créer script de diagnostic `diagnose-504.sh`
- [ ] Exécuter sur le serveur de production
- [ ] Analyser les logs Moodle + Traefik + système
- [ ] Identifier le pattern exact des 504

### Phase 2 : Correctifs immédiats (Aujourd'hui)
- [ ] Augmenter PHP_MEMORY_LIMIT à 1024M
- [ ] Augmenter MAX_EXECUTION_TIME à 300s
- [ ] Ajouter limites Docker au conteneur Moodle
- [ ] Augmenter innodb_buffer_pool_size à 2G
- [ ] Ajouter healthcheck Traefik avec timeout 300s

### Phase 3 : Monitoring (Demain)
- [ ] Créer script `monitor-resources.sh`
- [ ] Configurer cron de surveillance
- [ ] Mettre en place alertes email/slack

### Phase 4 : Optimisations (Cette semaine)
- [ ] Optimiser requêtes DB lentes
- [ ] Configurer PHP-FPM correctement
- [ ] Activer cache Moodle (Redis)
- [ ] Load testing pour valider

---

## 🚨 Actions d'urgence si 504 en ce moment

```bash
# 1. Redémarrer l'application via Coolify UI
# OU en CLI :
docker restart moodle_app
docker restart moodle_db

# 2. Purger les caches Moodle
docker exec moodle_app php /var/www/html/admin/cli/purge_caches.php

# 3. Vérifier l'état
docker ps | grep moodle
docker stats --no-stream moodle_app moodle_db
```

---

## 📌 Conclusion

**Cause probable** : Conteneur Moodle qui crash par **manque de mémoire (OOM)** ou **timeout PHP** lors de requêtes lourdes.

**Solution** : Augmenter les ressources (CPU/RAM), timeouts PHP/Traefik, et monitorer activement.

**Prochaine étape** : Implémenter les modifications dans `docker-compose.yml` et redéployer.
