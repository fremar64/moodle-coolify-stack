#!/bin/bash
# Script de monitoring des ressources Moodle pour prévenir les erreurs 504
# À exécuter en cron toutes les 5 minutes

set -e

# Configuration
MOODLE_CONTAINER="moodle_app"
DB_CONTAINER="moodle_db"
REDIS_CONTAINER="moodle_redis"
LOG_FILE="/var/log/moodle-monitoring.log"
ALERT_EMAIL="${ALERT_EMAIL:-admin@ceredis.net}"
MEMORY_THRESHOLD=85    # Pourcentage
CPU_THRESHOLD=90       # Pourcentage
RESTART_THRESHOLD=95   # Redémarrage auto si dépassé

# Couleurs pour sortie console
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fonction d'alerte
send_alert() {
    local subject="$1"
    local message="$2"
    
    # Log l'alerte
    log "⚠ ALERT: $subject - $message"
    
    # Envoyer email (si mail configuré)
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
    fi
}

# Vérifier si un conteneur existe
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$1$"
}

# Récupérer les stats d'un conteneur
get_container_stats() {
    local container=$1
    
    if ! container_exists "$container"; then
        echo "0|0|0"
        return 1
    fi
    
    local stats=$(docker stats --no-stream --format "{{.MemPerc}}|{{.CPUPerc}}|{{.NetIO}}" "$container" 2>/dev/null)
    echo "$stats"
}

# Vérifier la santé d'un conteneur
check_container_health() {
    local container=$1
    local name=$2
    
    if ! container_exists "$container"; then
        send_alert "Container Missing: $name" "Le conteneur $container n'existe pas ou n'est pas démarré"
        return 1
    fi
    
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    
    if [ "$status" != "running" ]; then
        send_alert "Container Down: $name" "Le conteneur $container est dans l'état: $status"
        return 1
    fi
    
    # Vérifier le nombre de redémarrages
    local restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null)
    if [ "$restart_count" -gt 5 ]; then
        send_alert "Container Restarting: $name" "Le conteneur $container a redémarré $restart_count fois"
    fi
    
    return 0
}

# Vérifier les ressources d'un conteneur
check_resources() {
    local container=$1
    local name=$2
    
    local stats=$(get_container_stats "$container")
    IFS='|' read -r mem_perc cpu_perc net_io <<< "$stats"
    
    # Enlever le symbole %
    mem_perc=${mem_perc%\%}
    cpu_perc=${cpu_perc%\%}
    
    # Vérifier si les valeurs sont numériques
    if ! [[ "$mem_perc" =~ ^[0-9.]+$ ]]; then
        mem_perc=0
    fi
    if ! [[ "$cpu_perc" =~ ^[0-9.]+$ ]]; then
        cpu_perc=0
    fi
    
    log "📊 $name - CPU: ${cpu_perc}% | Memory: ${mem_perc}% | Network: $net_io"
    
    # Alertes mémoire
    if (( $(echo "$mem_perc >= $RESTART_THRESHOLD" | bc -l) )); then
        send_alert "CRITICAL: High Memory on $name" "Utilisation mémoire critique: ${mem_perc}% (seuil: ${RESTART_THRESHOLD}%)"
        log "🔄 Redémarrage automatique de $container..."
        docker restart "$container"
        sleep 10
    elif (( $(echo "$mem_perc >= $MEMORY_THRESHOLD" | bc -l) )); then
        send_alert "WARNING: High Memory on $name" "Utilisation mémoire élevée: ${mem_perc}% (seuil: ${MEMORY_THRESHOLD}%)"
    fi
    
    # Alertes CPU
    if (( $(echo "$cpu_perc >= $CPU_THRESHOLD" | bc -l) )); then
        send_alert "WARNING: High CPU on $name" "Utilisation CPU élevée: ${cpu_perc}% (seuil: ${CPU_THRESHOLD}%)"
    fi
}

# Vérifier la connectivité HTTP Moodle
check_http_availability() {
    local url="http://localhost/login/index.php"
    local response_code=$(docker exec "$MOODLE_CONTAINER" curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$response_code" != "200" ]; then
        send_alert "HTTP Check Failed: Moodle" "Moodle ne répond pas correctement (code: $response_code)"
        log "❌ HTTP check failed: $response_code"
        return 1
    else
        log "✅ HTTP check OK: $response_code"
        return 0
    fi
}

# Vérifier la connexion DB
check_db_connection() {
    local db_check=$(docker exec "$DB_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" 2>&1)
    
    if [[ "$db_check" == *"ERROR"* ]]; then
        send_alert "Database Connection Failed" "Impossible de se connecter à MariaDB"
        log "❌ DB connection failed"
        return 1
    else
        log "✅ DB connection OK"
        return 0
    fi
}

# Vérifier le nombre de connexions DB
check_db_connections() {
    local connections=$(docker exec "$DB_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -N -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | awk '{print $2}')
    
    if [ -z "$connections" ]; then
        connections=0
    fi
    
    log "🔌 Connexions DB actives: $connections"
    
    if [ "$connections" -gt 150 ]; then
        send_alert "High DB Connections" "Nombre de connexions DB élevé: $connections"
    fi
}

# Vérifier Redis
check_redis() {
    local redis_info=$(docker exec "$REDIS_CONTAINER" redis-cli INFO memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
    
    if [ -z "$redis_info" ]; then
        send_alert "Redis Check Failed" "Impossible de récupérer les stats Redis"
        log "❌ Redis check failed"
        return 1
    else
        log "✅ Redis memory: $redis_info"
        return 0
    fi
}

# Fonction principale
main() {
    log "═══════════════════════════════════════════════════════"
    log "🔍 Démarrage du monitoring Moodle"
    
    # Vérifier la santé des conteneurs
    echo -e "\n${YELLOW}Vérification des conteneurs...${NC}"
    check_container_health "$MOODLE_CONTAINER" "Moodle"
    check_container_health "$DB_CONTAINER" "MariaDB"
    check_container_health "$REDIS_CONTAINER" "Redis"
    
    # Vérifier les ressources
    echo -e "\n${YELLOW}Vérification des ressources...${NC}"
    check_resources "$MOODLE_CONTAINER" "Moodle"
    check_resources "$DB_CONTAINER" "MariaDB"
    check_resources "$REDIS_CONTAINER" "Redis"
    
    # Vérifications fonctionnelles
    echo -e "\n${YELLOW}Vérifications fonctionnelles...${NC}"
    check_http_availability
    check_db_connection
    check_db_connections
    check_redis
    
    log "✅ Monitoring terminé"
    log "═══════════════════════════════════════════════════════"
}

# Exécution
main

# Code de sortie
exit 0
