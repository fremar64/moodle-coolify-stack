#!/bin/bash
#
# Script de vérification de santé Moodle
# Usage: ./scripts/health-check.sh [--detailed] [--json]
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
DETAILED=false
JSON_OUTPUT=false
ERRORS=0
WARNINGS=0

# Fonctions d'affichage
log_ok() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${GREEN}✅${NC} $1"
    fi
}

log_warn() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${YELLOW}⚠️${NC}  $1"
    fi
    ((WARNINGS++))
}

log_error() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${RED}❌${NC} $1"
    fi
    ((ERRORS++))
}

log_info() {
    if [ "$JSON_OUTPUT" = false ] && [ "$DETAILED" = true ]; then
        echo -e "${BLUE}ℹ️${NC}  $1"
    fi
}

# Banner
if [ "$JSON_OUTPUT" = false ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏥 Moodle Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# Résultats JSON
declare -A RESULTS

# Vérifier Docker
check_docker() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "🐳 Docker Services"
        echo "─────────────────"
    fi
    
    # Docker daemon
    if docker info >/dev/null 2>&1; then
        log_ok "Docker daemon actif"
        RESULTS[docker_daemon]="healthy"
    else
        log_error "Docker daemon non accessible"
        RESULTS[docker_daemon]="unhealthy"
        return 1
    fi
    
    # Services en cours d'exécution
    cd "$PROJECT_DIR"
    
    local services=("db" "redis" "moodle" "cron")
    for service in "${services[@]}"; do
        if docker compose ps "$service" 2>/dev/null | grep -q "Up"; then
            log_ok "Service $service: Running"
            RESULTS["service_${service}"]="running"
        else
            log_error "Service $service: Stopped"
            RESULTS["service_${service}"]="stopped"
        fi
    done
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier les healthchecks Docker
check_healthchecks() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "💚 Docker Healthchecks"
        echo "─────────────────────"
    fi
    
    cd "$PROJECT_DIR"
    
    local services=("db" "redis" "moodle")
    for service in "${services[@]}"; do
        local health=$(docker inspect --format='{{.State.Health.Status}}' "moodle_${service}" 2>/dev/null || echo "none")
        
        case $health in
            healthy)
                log_ok "$service: Healthy"
                RESULTS["health_${service}"]="healthy"
                ;;
            unhealthy)
                log_error "$service: Unhealthy"
                RESULTS["health_${service}"]="unhealthy"
                ;;
            starting)
                log_warn "$service: Starting"
                RESULTS["health_${service}"]="starting"
                ;;
            none)
                log_info "$service: No healthcheck configured"
                RESULTS["health_${service}"]="none"
                ;;
        esac
    done
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier MariaDB
check_database() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "🗄️  Database (MariaDB)"
        echo "─────────────────────"
    fi
    
    cd "$PROJECT_DIR"
    
    # Connexion
    if docker compose exec -T db mysqladmin ping -h localhost --silent 2>/dev/null; then
        log_ok "MariaDB répond"
        RESULTS[db_ping]="ok"
    else
        log_error "MariaDB ne répond pas"
        RESULTS[db_ping]="failed"
        return 1
    fi
    
    # Connexion base Moodle
    if [ -f .env ]; then
        source .env
        if docker compose exec -T db mysql -u moodle -p"${MOODLE_DB_PASSWORD}" -e "USE moodle; SELECT 1;" >/dev/null 2>&1; then
            log_ok "Connexion base Moodle OK"
            RESULTS[db_connection]="ok"
        else
            log_error "Impossible de se connecter à la base Moodle"
            RESULTS[db_connection]="failed"
        fi
    fi
    
    # Taille de la base
    if [ "$DETAILED" = true ]; then
        local db_size=$(docker compose exec -T db mysql -u moodle -p"${MOODLE_DB_PASSWORD}" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as size_mb FROM information_schema.TABLES WHERE table_schema = 'moodle';" 2>/dev/null | tail -1)
        log_info "Taille base de données: ${db_size} MB"
        RESULTS[db_size_mb]="$db_size"
    fi
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier Redis
check_redis() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "📦 Redis Cache"
        echo "──────────────"
    fi
    
    cd "$PROJECT_DIR"
    
    if docker compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        log_ok "Redis répond"
        RESULTS[redis_ping]="ok"
    else
        log_error "Redis ne répond pas"
        RESULTS[redis_ping]="failed"
        return 1
    fi
    
    if [ "$DETAILED" = true ]; then
        local redis_keys=$(docker compose exec -T redis redis-cli DBSIZE 2>/dev/null | grep -oP '\d+')
        local redis_memory=$(docker compose exec -T redis redis-cli INFO memory 2>/dev/null | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
        
        log_info "Clés en cache: $redis_keys"
        log_info "Mémoire utilisée: $redis_memory"
        
        RESULTS[redis_keys]="$redis_keys"
        RESULTS[redis_memory]="$redis_memory"
    fi
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier Moodle
check_moodle() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "🎓 Moodle Application"
        echo "────────────────────"
    fi
    
    cd "$PROJECT_DIR"
    
    # Vérifier que Moodle répond en HTTP
    if docker compose exec -T moodle curl -f http://localhost/ >/dev/null 2>&1; then
        log_ok "Moodle répond en HTTP"
        RESULTS[moodle_http]="ok"
    else
        log_error "Moodle ne répond pas en HTTP"
        RESULTS[moodle_http]="failed"
    fi
    
    # Vérifier les fichiers critiques
    local critical_files=("/var/www/html/public/index.php" "/var/www/html/public/config.php" "/var/www/html/lib/components.json")
    for file in "${critical_files[@]}"; do
        if docker compose exec -T moodle test -f "$file" 2>/dev/null; then
            log_ok "Fichier présent: $file"
        else
            log_warn "Fichier manquant: $file"
        fi
    done
    
    # Vérifier les permissions
    if docker compose exec -T moodle test -w /var/www/moodledata 2>/dev/null; then
        log_ok "Permissions moodledata: OK"
        RESULTS[moodle_permissions]="ok"
    else
        log_error "Problème de permissions moodledata"
        RESULTS[moodle_permissions]="failed"
    fi
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier les volumes
check_volumes() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "💾 Docker Volumes"
        echo "─────────────────"
    fi
    
    local volumes=("db_data" "redis_data" "moodle_data")
    for vol in "${volumes[@]}"; do
        if docker volume inspect "moodle-coolify-stack_${vol}" >/dev/null 2>&1; then
            local size=$(docker run --rm -v "moodle-coolify-stack_${vol}":/data alpine du -sh /data 2>/dev/null | cut -f1)
            log_ok "Volume $vol: $size"
            RESULTS["volume_${vol}"]="$size"
        else
            log_error "Volume $vol: Introuvable"
            RESULTS["volume_${vol}"]="missing"
        fi
    done
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier l'espace disque
check_disk_space() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "💿 Disk Space"
        echo "─────────────"
    fi
    
    local disk_usage=$(df -h "$PROJECT_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
    
    if [ "$disk_usage" -lt 80 ]; then
        log_ok "Espace disque: ${disk_usage}% utilisé"
        RESULTS[disk_usage]="${disk_usage}%"
    elif [ "$disk_usage" -lt 90 ]; then
        log_warn "Espace disque: ${disk_usage}% utilisé (attention)"
        RESULTS[disk_usage]="${disk_usage}%"
    else
        log_error "Espace disque: ${disk_usage}% utilisé (critique!)"
        RESULTS[disk_usage]="${disk_usage}%"
    fi
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Vérifier le cron
check_cron() {
    if [ "$JSON_OUTPUT" = false ]; then
        echo "⏰ Cron Service"
        echo "───────────────"
    fi
    
    cd "$PROJECT_DIR"
    
    if docker compose ps cron 2>/dev/null | grep -q "Up"; then
        log_ok "Service cron actif"
        RESULTS[cron_service]="running"
        
        # Vérifier les logs récents
        if [ "$DETAILED" = true ]; then
            local last_run=$(docker compose logs --tail=50 cron 2>/dev/null | grep "Cron run completed" | tail -1 || echo "Aucune exécution récente")
            log_info "Dernière exécution: $last_run"
        fi
    else
        log_error "Service cron arrêté"
        RESULTS[cron_service]="stopped"
    fi
    
    if [ "$JSON_OUTPUT" = false ]; then echo ""; fi
}

# Générer le rapport JSON
generate_json_report() {
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"status\": \"$([ $ERRORS -eq 0 ] && echo 'healthy' || echo 'unhealthy')\","
    echo "  \"errors\": $ERRORS,"
    echo "  \"warnings\": $WARNINGS,"
    echo "  \"checks\": {"
    
    local first=true
    for key in "${!RESULTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo -n "    \"$key\": \"${RESULTS[$key]}\""
    done
    
    echo ""
    echo "  }"
    echo "}"
}

# Afficher le résumé
show_summary() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ SYSTÈME SAIN${NC}"
        echo "Tous les composants fonctionnent correctement"
    elif [ $ERRORS -eq 0 ]; then
        echo -e "${YELLOW}⚠️  AVERTISSEMENTS DÉTECTÉS${NC}"
        echo "$WARNINGS avertissement(s) - Vérifiez les détails ci-dessus"
    else
        echo -e "${RED}❌ PROBLÈMES DÉTECTÉS${NC}"
        echo "$ERRORS erreur(s) et $WARNINGS avertissement(s)"
        echo "Action requise - Consultez les logs"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Afficher l'aide
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --detailed    Afficher des informations détaillées
    --json        Sortie au format JSON
    --help        Afficher cette aide

Exemples:
    $0                  # Vérification basique
    $0 --detailed       # Vérification détaillée
    $0 --json           # Sortie JSON (pour monitoring)

Code de sortie:
    0  - Tous les checks sont OK
    1  - Des erreurs ont été détectées

EOF
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed)
            DETAILED=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Exécuter les vérifications
check_docker
check_healthchecks
check_database
check_redis
check_moodle
check_volumes
check_disk_space
check_cron

# Afficher le résultat
if [ "$JSON_OUTPUT" = true ]; then
    generate_json_report
else
    show_summary
    echo ""
fi

# Code de sortie
exit $ERRORS
