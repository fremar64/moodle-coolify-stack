# ⚡ Guide d'Optimisation des Performances - Moodle CEREDIS

## Vue d'ensemble

Ce guide présente les optimisations pour améliorer les performances de votre plateforme Moodle en production, avec un focus sur les environnements éducatifs multi-utilisateurs.

## Objectifs de performance

| Métrique | Objectif | Critique |
|----------|----------|----------|
| Temps de chargement page | < 2s | < 5s |
| Time to First Byte (TTFB) | < 500ms | < 1s |
| Utilisateurs concurrent  | 100+ | 50+ |
| Disponibilité | 99.9% | 99% |

---

## 1. Optimisation de la base de données

### 1.1 Configuration MariaDB

Modifiez `docker-compose.yml` pour ajuster les paramètres MariaDB :

```yaml
services:
  db:
    image: mariadb:11.4
    command: [
      "--character-set-server=utf8mb4",
      "--collation-server=utf8mb4_unicode_ci",
      "--skip-character-set-client-handshake",
      
      # Buffer pool (ajuster selon RAM disponible)
      "--innodb-buffer-pool-size=2G",        # 50-70% de la RAM dédiée à DB
      "--innodb-buffer-pool-instances=4",
      
      # Logs et performance
      "--innodb-log-file-size=512M",
      "--innodb-flush-log-at-trx-commit=2",  # Performance vs durabilité
      "--innodb-flush-method=O_DIRECT",
      
      # Connexions
      "--max-connections=200",
      "--max-allowed-packet=256M",
      
      # Query cache (désactivé par défaut dans MariaDB 10.5+)
      "--query-cache-type=0",
      
      # Optimisation tables
      "--table-open-cache=4000",
      "--table-definition-cache=2000",
      
      # Threads
      "--thread-cache-size=50",
      "--tmp-table-size=256M",
      "--max-heap-table-size=256M"
    ]
```

### 1.2 Indexation et maintenance

Créez `scripts/optimize-database.sh` :

```bash
#!/bin/bash
set -e

source .env

echo "🔧 Optimisation de la base de données Moodle"

docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" moodle <<'SQL'

-- Analyser les tables
ANALYZE TABLE mdl_user;
ANALYZE TABLE mdl_course;
ANALYZE TABLE mdl_course_modules;
ANALYZE TABLE mdl_grade_items;
ANALYZE TABLE mdl_quiz_attempts;

-- Optimiser les tables
OPTIMIZE TABLE mdl_logstore_standard_log;
OPTIMIZE TABLE mdl_sessions;
OPTIMIZE TABLE mdl_cache_flags;

-- Vérifier les index manquants (requêtes fréquentes)
SHOW INDEX FROM mdl_user;
SHOW INDEX FROM mdl_course_modules;

-- Afficher les statistiques
SHOW TABLE STATUS WHERE Name LIKE 'mdl_%';

SQL

echo "✅ Optimisation terminée"
echo "💡 Planifiez cette tâche mensuellement via cron"
```

Ajoutez à cron :

```bash
# Optimisation DB le 1er de chaque mois à 3h
0 3 1 * * /chemin/vers/scripts/optimize-database.sh >> /var/log/moodle-optimization.log 2>&1
```

### 1.3 Nettoyage des logs

```bash
#!/bin/bash
# scripts/cleanup-old-logs.sh

docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" moodle <<'SQL'

-- Supprimer les logs de plus de 90 jours
DELETE FROM mdl_logstore_standard_log 
WHERE timecreated < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 90 DAY));

-- Nettoyer les sessions expirées
DELETE FROM mdl_sessions 
WHERE timemodified < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY));

-- Vider les caches temporaires
TRUNCATE TABLE mdl_cache_flags;
TRUNCATE TABLE mdl_cache_text;

SQL
```

---

## 2. Cache et Redis

### 2.1 Configuration Redis optimale

Dans `.env` :

```bash
# Redis pour session + cache
REDIS_MAXMEMORY=512mb
REDIS_MAXMEMORY_POLICY=allkeys-lru
```

Modifiez `docker-compose.yml` :

```yaml
services:
  redis:
    image: redis:7-alpine
    command: >
      redis-server
      --appendonly yes
      --maxmemory 512mb
      --maxmemory-policy allkeys-lru
      --save 900 1
      --save 300 10
      --save 60 10000
      --tcp-backlog 511
      --timeout 300
      --tcp-keepalive 60
    sysctls:
      - net.core.somaxconn=1024
```

### 2.2 Configuration cache Moodle

Dans `moodle/config.php` :

```php
// Cache configuration (MUC - Moodle Universal Cache)
$CFG->cachedir = '/var/www/moodledata/cache';

// Redis comme cache principal
$CFG->session_handler_class = '\core\session\redis';
$CFG->session_redis_host = 'redis';
$CFG->session_redis_port = 6379;
$CFG->session_redis_database = 0;
$CFG->session_redis_prefix = 'moodle_sess_';
$CFG->session_redis_acquire_lock_timeout = 120;
$CFG->session_redis_lock_expire = 7200;

// Cache des strings (traductions)
$CFG->langstringcache = true;
$CFG->cachejs = true;

// Désactiver les thèmes designers (production)
$CFG->themedesignermode = false;
$CFG->cachejs = true;
$CFG->yuicomboloading = true;
```

### 2.3 Monitoring Redis

```bash
# Vérifier l'utilisation de Redis
docker compose exec redis redis-cli INFO stats
docker compose exec redis redis-cli INFO memory

# Surveiller en temps réel
docker compose exec redis redis-cli MONITOR

# Vider le cache si nécessaire
docker compose exec redis redis-cli FLUSHDB
```

---

## 3. Optimisation PHP

### 3.1 Configuration PHP-FPM

Créez `php-fpm-custom.conf` :

```ini
; Pool Configuration
[www]
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500

; Limites de mémoire
php_admin_value[memory_limit] = 512M
php_admin_value[upload_max_filesize] = 256M
php_admin_value[post_max_size] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300

; OPcache
php_admin_value[opcache.enable] = 1
php_admin_value[opcache.memory_consumption] = 512
php_admin_value[opcache.interned_strings_buffer] = 64
php_admin_value[opcache.max_accelerated_files] = 20000
php_admin_value[opcache.validate_timestamps] = 0
php_admin_value[opcache.revalidate_freq] = 0
php_admin_value[opcache.save_comments] = 1
php_admin_value[opcache.fast_shutdown] = 1

; Realpath cache
php_admin_value[realpath_cache_size] = 4096K
php_admin_value[realpath_cache_ttl] = 600

; Désactiver les fonctions dangereuses
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
```

Modifiez `Dockerfile` :

```dockerfile
# Copier la config PHP-FPM
COPY php-fpm-custom.conf /usr/local/etc/php-fpm.d/zz-custom.conf

# Activer OPcache
RUN docker-php-ext-enable opcache
```

### 3.2 Variables d'environnement PHP

Dans `.env` :

```bash
# Ajuster selon le nombre d'utilisateurs
PHP_MEMORY_LIMIT=512M
PHP_MAX_EXECUTION_TIME=300
UPLOAD_MAX_SIZE=256M

# OPcache
PHP_OPCACHE_MEMORY=512
PHP_OPCACHE_MAX_FILES=20000
```

---

## 4. Optimisation Apache

### 4.1 Configuration Apache

Créez `apache-performance.conf` :

```apache
# Compression GZIP
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
    AddOutputFilterByType DEFLATE application/xml application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript text/javascript
    AddOutputFilterByType DEFLATE image/svg+xml
</IfModule>

# Cache navigateur
<IfModule mod_expires.c>
    ExpiresActive On
    
    # Images
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType image/x-icon "access plus 1 year"
    
    # CSS et JavaScript
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType text/javascript "access plus 1 month"
    
    # Fonts
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    
    # Documents
    ExpiresByType application/pdf "access plus 1 month"
    
    # HTML par défaut
    ExpiresByType text/html "access plus 0 seconds"
</IfModule>

# Keepalive
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5

# MPM Prefork (ou worker selon config)
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      150
    MaxConnectionsPerChild   0
</IfModule>

# Désactiver le listage des répertoires
Options -Indexes

# Protection contre l'injection
<IfModule mod_headers.c>
    Header set X-Content-Type-Options "nosniff"
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-XSS-Protection "1; mode=block"
    Header set Referrer-Policy "strict-origin-when-cross-origin"
</IfModule>
```

### 4.2 Intégrer au Dockerfile

```dockerfile
# Activer modules Apache nécessaires
RUN a2enmod deflate expires headers rewrite

# Copier config performance
COPY apache-performance.conf /etc/apache2/conf-available/
RUN a2enconf apache-performance
```

---

## 5. Optimisations Moodle

### 5.1 Configuration Moodle

Dans `moodle/config.php` :

```php
// Performance
$CFG->debug = 0;  // Désactiver le debug en production
$CFG->debugdisplay = 0;
$CFG->perfdebug = 0;
$CFG->perfinfo = false;

// Thèmes et assets
$CFG->themedesignermode = false;
$CFG->cachejs = true;
$CFG->yuicomboloading = true;

// Sessions
$CFG->sessiontimeout = 7200;  // 2 heures

// Cron optimisé
$CFG->cronremotepassword = 'VotreSecretCron';
$CFG->cronclionly = true;

// Anti-virus (si ClamAV installé)
// $CFG->antiviruses = 'clamav';

// Limitation des requêtes
$CFG->extramemorylimit = '512M';
$CFG->maxtimelimit = 300;
```

### 5.2 Purge automatique des caches

Créez `scripts/purge-moodle-caches.sh` :

```bash
#!/bin/bash

echo "🧹 Purge des caches Moodle"

docker compose exec moodle php /var/www/html/admin/cli/purge_caches.php

echo "✅ Caches purgés"
```

Ajoutez à cron (quotidien) :

```bash
0 2 * * * /chemin/vers/scripts/purge-moodle-caches.sh
```

### 5.3 Désactiver les plugins inutilisés

Via l'interface admin Moodle :
1. **Administration** → **Plugins** → **Vue d'ensemble des plugins**
2. Désactivez les plugins non utilisés :
   - Blocs inutilisés
   - Formats de cours non utilisés
   - Méthodes d'authentification non nécessaires
   - Filtres de contenu non requis

---

## 6. Monitoring et alertes

### 6.1 Script de monitoring

Créez `scripts/performance-monitor.sh` :

```bash
#!/bin/bash

ALERT_EMAIL="admin@ceredis.net"
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85

# Métriques conteneurs
echo "=== Métriques Moodle ==="
docker stats --no-stream moodle_app moodle_db moodle_redis

# CPU
CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" moodle_app | sed 's/%//')
if (( $(echo "$CPU_USAGE > $THRESHOLD_CPU" | bc -l) )); then
    echo "⚠️  ALERTE: CPU élevé ($CPU_USAGE%)" | mail -s "Moodle CPU Alert" $ALERT_EMAIL
fi

# Mémoire
MEM_USAGE=$(docker stats --no-stream --format "{{.MemPerc}}" moodle_app | sed 's/%//')
if (( $(echo "$MEM_USAGE > $THRESHOLD_MEMORY" | bc -l) )); then
    echo "⚠️  ALERTE: Mémoire élevée ($MEM_USAGE%)" | mail -s "Moodle Memory Alert" $ALERT_EMAIL
fi

# Espace disque
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 85 ]; then
    echo "⚠️  ALERTE: Disque plein ($DISK_USAGE%)" | mail -s "Moodle Disk Alert" $ALERT_EMAIL
fi

# Connexions DB
DB_CONNECTIONS=$(docker compose exec -T db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
    -e "SHOW STATUS LIKE 'Threads_connected';" | awk 'NR==2 {print $2}')
echo "Connexions DB actives: $DB_CONNECTIONS"

# Taille du cache Redis
REDIS_SIZE=$(docker compose exec -T redis redis-cli INFO memory | grep used_memory_human | cut -d: -f2)
echo "Utilisation Redis: $REDIS_SIZE"
```

Ajoutez à cron (toutes les 15 minutes) :

```bash
*/15 * * * * /chemin/vers/scripts/performance-monitor.sh >> /var/log/moodle-perf.log
```

### 6.2 Métriques Moodle

Script pour extraire des métriques depuis Moodle :

```bash
#!/bin/bash
# scripts/moodle-metrics.sh

docker compose exec moodle php /var/www/html/admin/cli/adhoc_task.php --execute

echo "=== Statistiques Moodle ==="
docker compose exec -T db mysql -u moodle -p"${MOODLE_DB_PASSWORD}" moodle <<'SQL'

SELECT 'Utilisateurs actifs (7j)' AS Metric, COUNT(*) AS Value 
FROM mdl_user 
WHERE lastaccess > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 7 DAY));

SELECT 'Cours publiés' AS Metric, COUNT(*) AS Value 
FROM mdl_course 
WHERE visible = 1;

SELECT 'Activités totales' AS Metric, COUNT(*) AS Value 
FROM mdl_course_modules;

SELECT 'Taille DB (MB)' AS Metric, 
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS Value
FROM information_schema.TABLES 
WHERE table_schema = 'moodle';

SQL
```

---

## 7. CDN et Statiques

### 7.1 Utiliser un CDN pour assets

Dans `moodle/config.php` :

```php
// Si vous utilisez un CDN (Cloudflare, etc.)
$CFG->alternative_file_system_class = '\tool_objectfs\azure_file_system';
// ou
$CFG->alternative_file_system_class = '\tool_objectfs\s3_file_system';

// Ou servir les fichiers statiques via un autre domaine
$CFG->httpswwwroot = 'https://cdn.ceredis.net';
```

### 7.2 Compression des assets

Activez la compression côté Moodle :

```bash
# Minifier JS/CSS en production
docker compose exec moodle php /var/www/html/admin/cli/cfg.php \
    --name=yuicomboloading --set=1

docker compose exec moodle php /var/www/html/admin/cli/cfg.php \
    --name=cachejs --set=1
```

---

## 8. Tests de charge

### 8.1 Tester avec Apache Bench

```bash
# Test simple (100 requêtes, 10 concurrentes)
ab -n 100 -c 10 https://ecole-en-ligne.ceredis.net/

# Test avec authentification
ab -n 1000 -c 50 -C "MoodleSession=votrecookie" \
    https://ecole-en-ligne.ceredis.net/my/
```

### 8.2 Tester avec k6 (recommandé)

Installez k6 :

```bash
# Sur Ubuntu
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
    --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | \
    sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

Créez `tests/load-test.js` :

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Montée à 50 utilisateurs
    { duration: '5m', target: 50 },   // Maintien à 50 utilisateurs
    { duration: '2m', target: 100 },  // Montée à 100
    { duration: '5m', target: 100 },  // Maintien
    { duration: '2m', target: 0 },    // Descente
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% des requêtes < 2s
    http_req_failed: ['rate<0.01'],     // Moins de 1% d'erreurs
  },
};

export default function () {
  const res = http.get('https://ecole-en-ligne.ceredis.net/');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 2s': (r) => r.timings.duration < 2000,
  });
  
  sleep(1);
}
```

Exécutez :

```bash
k6 run tests/load-test.js
```

---

## 9. Checklist d'optimisation

### Avant mise en production

- [ ] Redis configuré et testé
- [ ] OPcache activé (validate_timestamps=0)
- [ ] Compression GZIP activée
- [ ] Cache navigateur configuré (Expires headers)
- [ ] Thème designer mode désactivé
- [ ] Debug Moodle désactivé
- [ ] Cron optimisé
- [ ] Plugins inutilisés désactivés
- [ ] Indexation DB vérifiée
- [ ] Test de charge réussi (>50 utilisateurs)

### Maintenance hebdomadaire

- [ ] Vérifier les métriques de performance
- [ ] Purger les caches si nécessaire
- [ ] Surveiller l'utilisation Redis

### Maintenance mensuelle

- [ ] Optimiser les tables DB
- [ ] Nettoyer les logs anciens
- [ ] Analyser les slow queries
- [ ] Test de charge

---

## 10. Ressources

- [Moodle Performance](https://docs.moodle.org/en/Performance)
- [Redis Best Practices](https://redis.io/topics/optimization)
- [Apache Performance](https://httpd.apache.org/docs/2.4/misc/perf-tuning.html)
- [k6 Load Testing](https://k6.io/docs/)

---

**Version** : 1.0  
**Maintenu par** : CEREDIS  
**Dernière mise à jour** : Décembre 2025
