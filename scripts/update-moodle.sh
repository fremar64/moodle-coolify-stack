#!/bin/bash
#
# Script de mise à jour Moodle
# Usage: ./scripts/update-moodle.sh [--version MOODLE_XYZ_STABLE] [--auto]
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MOODLE_DIR="${PROJECT_DIR}/moodle"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fonctions d'affichage
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Banner
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔄 Moodle Update Script
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo ""

# Variables
TARGET_VERSION=""
AUTO_MODE=false
SKIP_BACKUP=false

# Vérifier les prérequis
check_prerequisites() {
    log_step "Vérification des prérequis..."
    
    if [ ! -d "$MOODLE_DIR" ]; then
        log_error "Dossier Moodle introuvable: $MOODLE_DIR"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "Git n'est pas installé"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    log_info "✅ Tous les prérequis sont satisfaits"
}

# Obtenir la version actuelle
get_current_version() {
    cd "$MOODLE_DIR"
    
    if [ -d ".git" ]; then
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        log_info "Version actuelle: $CURRENT_BRANCH ($CURRENT_COMMIT)"
    else
        log_warn "Le dossier Moodle n'est pas un dépôt Git"
        CURRENT_BRANCH="unknown"
        CURRENT_COMMIT="unknown"
    fi
}

# Lister les versions disponibles
list_versions() {
    log_step "Récupération des versions disponibles..."
    
    cd "$MOODLE_DIR"
    
    if [ ! -d ".git" ]; then
        log_error "Le dossier Moodle n'est pas un dépôt Git"
        exit 1
    fi
    
    git fetch --all --tags >/dev/null 2>&1
    
    echo ""
    echo "📋 Versions stables disponibles (10 plus récentes):"
    echo ""
    git branch -r | grep "STABLE" | sed 's|origin/||' | sort -V | tail -10
    echo ""
}

# Créer une sauvegarde
create_backup() {
    if [ "$SKIP_BACKUP" = true ]; then
        log_warn "Sauvegarde ignorée (--skip-backup)"
        return 0
    fi
    
    log_step "Création d'une sauvegarde de sécurité..."
    
    if [ -f "$SCRIPT_DIR/backup.sh" ]; then
        "$SCRIPT_DIR/backup.sh" --type full --cleanup
    else
        log_warn "Script de sauvegarde introuvable, sauvegarde manuelle recommandée"
        
        if [ "$AUTO_MODE" = false ]; then
            read -p "Continuer sans sauvegarde? (yes/no): " -r
            if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                log_warn "Mise à jour annulée"
                exit 0
            fi
        fi
    fi
}

# Activer le mode maintenance
enable_maintenance() {
    log_step "Activation du mode maintenance..."
    
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/maintenance.php --enable 2>/dev/null || {
        log_warn "Impossible d'activer le mode maintenance (Moodle non démarré?)"
    }
    
    log_info "✅ Mode maintenance activé"
}

# Désactiver le mode maintenance
disable_maintenance() {
    log_step "Désactivation du mode maintenance..."
    
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/maintenance.php --disable 2>/dev/null || {
        log_warn "Impossible de désactiver le mode maintenance"
    }
    
    log_info "✅ Mode maintenance désactivé"
}

# Mettre à jour le code Moodle
update_code() {
    local target="$1"
    
    log_step "Mise à jour du code Moodle vers: $target..."
    
    cd "$MOODLE_DIR"
    
    # Sauvegarder les modifications locales
    if ! git diff --quiet; then
        log_warn "Modifications locales détectées, création d'un stash..."
        git stash push -m "Auto-stash before update to $target"
    fi
    
    # Mettre à jour
    log_info "Récupération de $target..."
    git fetch origin "$target" >/dev/null 2>&1
    
    log_info "Checkout de $target..."
    if git checkout "$target"; then
        log_info "Pull des derniers changements..."
        git pull origin "$target"
        log_success "✅ Code mis à jour vers $target"
    else
        log_error "Échec du checkout de $target"
        exit 1
    fi
    
    # Réappliquer le stash si nécessaire
    if git stash list | grep -q "Auto-stash before update"; then
        log_info "Réapplication des modifications locales..."
        git stash pop || log_warn "Conflit lors de la réapplication du stash, résolution manuelle requise"
    fi
}

# Mettre à jour les dépendances
update_dependencies() {
    log_step "Mise à jour des dépendances..."
    
    # Composer (si présent)
    if [ -f "$MOODLE_DIR/composer.json" ]; then
        log_info "Installation des dépendances Composer..."
        docker compose -f "$PROJECT_DIR/docker-compose.yml" run --rm moodle \
            composer install --no-dev --optimize-autoloader 2>/dev/null || {
            log_warn "Échec de l'installation Composer (peut être normal)"
        }
    fi
    
    log_info "✅ Dépendances mises à jour"
}

# Mettre à jour la base de données
upgrade_database() {
    log_step "Mise à jour de la base de données Moodle..."
    
    log_info "Lancement de la mise à jour (peut prendre plusieurs minutes)..."
    
    if docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/upgrade.php --non-interactive; then
        log_success "✅ Base de données mise à jour avec succès"
    else
        log_error "❌ Échec de la mise à jour de la base de données"
        log_error "Consultez les logs pour plus de détails"
        exit 1
    fi
}

# Vider les caches
purge_caches() {
    log_step "Vidage des caches..."
    
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/purge_caches.php 2>/dev/null || {
        log_warn "Échec du vidage des caches"
    }
    
    log_info "✅ Caches vidés"
}

# Redémarrer les services
restart_services() {
    log_step "Redémarrage des services..."
    
    docker compose -f "$PROJECT_DIR/docker-compose.yml" restart moodle cron
    
    log_info "Attente du démarrage de Moodle..."
    sleep 10
    
    log_info "✅ Services redémarrés"
}

# Vérifier la santé post-mise à jour
health_check() {
    log_step "Vérification de la santé du système..."
    
    # Vérifier que Moodle répond
    if docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        curl -f http://localhost/ >/dev/null 2>&1; then
        log_success "✅ Moodle répond correctement"
    else
        log_error "❌ Moodle ne répond pas"
        log_error "Vérifiez les logs: docker compose logs moodle"
    fi
    
    # Utiliser health-check.sh si disponible
    if [ -f "$SCRIPT_DIR/health-check.sh" ]; then
        "$SCRIPT_DIR/health-check.sh"
    fi
}

# Afficher l'aide
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --version VERSION  Version Moodle cible (ex: MOODLE_501_STABLE)
    --list             Lister les versions disponibles
    --auto             Mode automatique (pas de confirmation)
    --skip-backup      Ignorer la sauvegarde automatique
    --help             Afficher cette aide

Exemples:
    # Lister les versions disponibles
    $0 --list

    # Mettre à jour vers Moodle 5.0.2
    $0 --version MOODLE_502_STABLE

    # Mise à jour automatique (CI/CD)
    $0 --version MOODLE_502_STABLE --auto

    # Mise à jour sans sauvegarde (non recommandé)
    $0 --version MOODLE_502_STABLE --skip-backup

EOF
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            TARGET_VERSION="$2"
            shift 2
            ;;
        --list)
            check_prerequisites
            list_versions
            exit 0
            ;;
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérifier qu'une version est spécifiée
if [ -z "$TARGET_VERSION" ]; then
    log_error "Aucune version cible spécifiée!"
    echo ""
    show_help
    exit 1
fi

# Confirmation en mode interactif
if [ "$AUTO_MODE" = false ]; then
    echo ""
    log_warn "⚠️  Vous allez mettre à jour Moodle vers: $TARGET_VERSION"
    echo ""
    get_current_version
    echo ""
    read -p "Continuer? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_warn "Mise à jour annulée"
        exit 0
    fi
fi

# Exécution de la mise à jour
echo ""
log_info "🚀 Démarrage de la mise à jour..."
echo ""

check_prerequisites
echo ""

create_backup
echo ""

enable_maintenance
echo ""

update_code "$TARGET_VERSION"
echo ""

update_dependencies
echo ""

upgrade_database
echo ""

purge_caches
echo ""

restart_services
echo ""

disable_maintenance
echo ""

health_check
echo ""

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "✅ Mise à jour terminée avec succès!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Version cible: $TARGET_VERSION"
log_info "Consultez votre site Moodle pour vérifier que tout fonctionne"
echo ""
