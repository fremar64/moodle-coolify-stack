#!/bin/bash
# Script de diagnostic pour les erreurs 504 Gateway Timeout
# Analyse les causes possibles et propose des solutions

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Diagnostic des erreurs 504 Gateway Timeout ===${NC}\n"

# Fonction pour afficher une section
print_section() {
    echo -e "\n${BLUE}[$1]${NC}"
}

# Fonction pour vérifier un service
check_service() {
    local service=$1
    echo -n "Vérification de $service... "
    if docker compose ps | grep -q "$service.*running"; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Stopped/Error${NC}"
        return 1
    fi
}

print_section "1. État des conteneurs"
docker compose ps

print_section "2. Utilisation des ressources"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

print_section "3. Vérification des services critiques"
check_service "moodle" || echo -e "${RED}⚠ Conteneur Moodle arrêté !${NC}"
check_service "db" || echo -e "${RED}⚠ Base de données arrêtée !${NC}"
check_service "redis" || echo -e "${RED}⚠ Redis arrêté !${NC}"

print_section "4. Logs Moodle (erreurs récentes)"
echo "Recherche d'erreurs dans les 200 dernières lignes..."
docker compose logs --tail=200 moodle | grep -E "(error|fatal|timeout|504|502|503)" -i | tail -20

print_section "5. Logs Apache (erreurs récentes)"
docker compose logs --tail=200 moodle | grep -E "apache2" -i | grep -E "(error|warn)" -i | tail -10

print_section "6. Vérification de la base de données"
echo "Connexions actives :"
docker compose exec -T db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null || echo "Erreur de connexion DB"

echo "Connexions max :"
docker compose exec -T db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null || echo "Erreur de connexion DB"

print_section "7. Vérification Redis"
docker compose exec -T redis redis-cli INFO stats | grep -E "(total_connections|rejected_connections|evicted_keys)" || echo "Erreur connexion Redis"

print_section "8. Espace disque"
df -h | grep -E "(Filesystem|/dev/)"

print_section "9. Processus PHP-FPM"
docker compose exec -T moodle ps aux | grep -E "php-fpm|apache" | head -10 || echo "Impossible d'accéder au conteneur"

print_section "10. Analyse des causes probables"

echo -e "\n${YELLOW}Causes possibles des erreurs 504 :${NC}"
echo ""
echo "1. ${YELLOW}Conteneur Moodle qui redémarre fréquemment${NC}"
echo "   → Vérifier si 'docker compose ps' montre des redémarrages (colonne STATUS)"
echo "   → Cause : OOM (Out Of Memory), crash PHP, DB inaccessible"
echo ""
echo "2. ${YELLOW}PHP-FPM qui sature ou crash${NC}"
echo "   → Trop de requêtes simultanées dépassant pm.max_children"
echo "   → Requêtes PHP qui prennent >60s (timeout par défaut)"
echo "   → Memory_limit PHP insuffisant"
echo ""
echo "3. ${YELLOW}Base de données lente/surchargée${NC}"
echo "   → Queries lentes qui font timeout"
echo "   → Too many connections"
echo "   → Lock de tables"
echo ""
echo "4. ${YELLOW}Traefik/Proxy timeout${NC}"
echo "   → Timeout Traefik par défaut trop court"
echo "   → Healthcheck qui échoue, Traefik retire le backend"
echo ""
echo "5. ${YELLOW}Ressources serveur insuffisantes${NC}"
echo "   → CPU/RAM saturés"
echo "   → Swap utilisé massivement"
echo "   → I/O disque saturé"
echo ""
echo "6. ${YELLOW}Cron Moodle qui monopolise les ressources${NC}"
echo "   → Tâches cron lourdes qui bloquent le serveur"
echo ""

print_section "11. Recommandations immédiates"

echo -e "${GREEN}Actions à entreprendre :${NC}"
echo ""
echo "1. Augmenter les timeouts Traefik (via Coolify labels)"
echo "2. Vérifier/augmenter PHP memory_limit et max_execution_time"
echo "3. Optimiser PHP-FPM (pm.max_children, pm settings)"
echo "4. Ajouter un healthcheck plus tolérant"
echo "5. Vérifier les slow queries MySQL"
echo "6. Monitorer en temps réel avec : watch -n 5 'docker stats --no-stream'"
echo ""

print_section "12. Collecte de logs pour analyse"

LOG_DIR="/tmp/moodle-504-logs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

echo "Sauvegarde des logs dans $LOG_DIR..."
docker compose logs --tail=500 moodle > "$LOG_DIR/moodle.log" 2>&1
docker compose logs --tail=500 db > "$LOG_DIR/db.log" 2>&1
docker compose logs --tail=500 redis > "$LOG_DIR/redis.log" 2>&1
docker stats --no-stream > "$LOG_DIR/docker-stats.txt" 2>&1
df -h > "$LOG_DIR/disk-usage.txt" 2>&1

echo -e "${GREEN}✓ Logs sauvegardés dans $LOG_DIR${NC}"
echo ""
echo -e "${BLUE}Examinez ces fichiers pour identifier le pattern des erreurs 504.${NC}"
