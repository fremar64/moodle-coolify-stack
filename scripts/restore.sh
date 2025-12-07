#!/bin/bash
#
# Script de restauration Moodle
# Usage: ./scripts/restore.sh --db backup.sql.gz --files backup.tar.gz
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Banner
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Moodle Restore Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Variables
DB_BACKUP=""
FILES_BACKUP=""
CODE_BACKUP=""
SKIP_CONFIRMATION=false

# Charger les variables d'environnement
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
    log_info "Variables d'environnement chargées"
else
    log_error "Fichier .env non trouvé!"
    exit 1
fi

# Fonction de restauration de la base de données
restore_database() {
    local backup_file="$1"
    
    log_step "Restauration de la base de données..."
    
    if [ ! -f "$backup_file" ]; then
        log_error "Fichier de sauvegarde introuvable: $backup_file"
        exit 1
    fi
    
    # Décompresser si nécessaire
    if [[ "$backup_file" == *.gz ]]; then
        log_info "Décompression du fichier SQL..."
        local temp_sql="/tmp/moodle_restore_$$.sql"
        gunzip -c "$backup_file" > "$temp_sql"
        backup_file="$temp_sql"
    fi
    
    # Activer le mode maintenance
    log_info "Activation du mode maintenance..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/maintenance.php --enable 2>/dev/null || true
    
    # Restaurer la base de données
    log_info "Import de la base de données..."
    if docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db \
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" moodle < "$backup_file"; then
        
        log_info "✅ Base de données restaurée avec succès"
        
        # Nettoyer le fichier temporaire
        [ -f "/tmp/moodle_restore_$$.sql" ] && rm -f "/tmp/moodle_restore_$$.sql"
    else
        log_error "❌ Échec de la restauration de la base de données"
        [ -f "/tmp/moodle_restore_$$.sql" ] && rm -f "/tmp/moodle_restore_$$.sql"
        exit 1
    fi
    
    # Vider les caches
    log_info "Vidage des caches Moodle..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/purge_caches.php 2>/dev/null || true
    
    # Désactiver le mode maintenance
    log_info "Désactivation du mode maintenance..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/maintenance.php --disable 2>/dev/null || true
}

# Fonction de restauration des fichiers
restore_files() {
    local backup_file="$1"
    
    log_step "Restauration des fichiers Moodle..."
    
    if [ ! -f "$backup_file" ]; then
        log_error "Fichier de sauvegarde introuvable: $backup_file"
        exit 1
    fi
    
    # Activer le mode maintenance
    log_info "Activation du mode maintenance..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/maintenance.php --enable 2>/dev/null || true
    
    # Restaurer les fichiers
    log_info "Extraction des fichiers..."
    if docker run --rm \
        -v moodle-coolify-stack_moodle_data:/data \
        -v "$(dirname "$backup_file")":/backup:ro \
        alpine sh -c "rm -rf /data/* && tar xzf /backup/$(basename "$backup_file") -C /data"; then
        
        log_info "✅ Fichiers restaurés avec succès"
    else
        log_error "❌ Échec de la restauration des fichiers"
        exit 1
    fi
    
    # Corriger les permissions
    log_info "Correction des permissions..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        chown -R www-data:www-data /var/www/moodledata 2>/dev/null || true
    
    # Désactiver le mode maintenance
    log_info "Désactivation du mode maintenance..."
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T moodle \
        php /var/www/html/public/admin/cli/maintenance.php --disable 2>/dev/null || true
}

# Fonction de restauration du code source
restore_code() {
    local backup_file="$1"
    
    log_step "Restauration du code source Moodle..."
    
    if [ ! -f "$backup_file" ]; then
        log_error "Fichier de sauvegarde introuvable: $backup_file"
        exit 1
    fi
    
    # Sauvegarder le code actuel
    log_warn "Sauvegarde du code actuel avant restauration..."
    mv "$PROJECT_DIR/moodle" "$PROJECT_DIR/moodle.old.$(date +%s)" 2>/dev/null || true
    
    # Restaurer le code
    log_info "Extraction du code source..."
    if tar xzf "$backup_file" -C "$PROJECT_DIR"; then
        log_info "✅ Code source restauré avec succès"
        
        # Redémarrer Moodle pour appliquer les changements
        log_info "Redémarrage des services Moodle..."
        docker compose -f "$PROJECT_DIR/docker-compose.yml" restart moodle cron
    else
        log_error "❌ Échec de la restauration du code source"
        
        # Restaurer l'ancien code
        if [ -d "$PROJECT_DIR/moodle.old."* ]; then
            log_warn "Restauration de l'ancien code..."
            rm -rf "$PROJECT_DIR/moodle"
            mv "$PROJECT_DIR/moodle.old."* "$PROJECT_DIR/moodle"
        fi
        exit 1
    fi
}

# Fonction de confirmation
confirm_restore() {
    if [ "$SKIP_CONFIRMATION" = true ]; then
        return 0
    fi
    
    echo ""
    log_warn "⚠️  AVERTISSEMENT: Cette opération va écraser les données actuelles!"
    echo ""
    echo "Sauvegardes à restaurer:"
    [ -n "$DB_BACKUP" ] && echo "  - Base de données: $DB_BACKUP"
    [ -n "$FILES_BACKUP" ] && echo "  - Fichiers: $FILES_BACKUP"
    [ -n "$CODE_BACKUP" ] && echo "  - Code source: $CODE_BACKUP"
    echo ""
    read -p "Êtes-vous sûr de vouloir continuer? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_warn "Restauration annulée par l'utilisateur"
        exit 0
    fi
}

# Afficher l'aide
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --db FILE          Restaurer la base de données depuis FILE
    --files FILE       Restaurer les fichiers depuis FILE
    --code FILE        Restaurer le code source depuis FILE
    --yes              Sauter la confirmation
    --list             Lister les sauvegardes disponibles
    --help             Afficher cette aide

Exemples:
    # Restauration complète
    $0 --db backups/moodle_db_20241207.sql.gz \\
       --files backups/moodle_files_20241207.tar.gz \\
       --code backups/moodle_code_20241207.tar.gz

    # Restauration base de données uniquement
    $0 --db backups/moodle_db_20241207.sql.gz

    # Lister les sauvegardes disponibles
    $0 --list

EOF
}

# Lister les sauvegardes disponibles
list_backups() {
    echo "📦 Sauvegardes disponibles dans $BACKUP_DIR:"
    echo ""
    
    if [ -d "$BACKUP_DIR" ]; then
        echo "Base de données:"
        find "$BACKUP_DIR" -name "moodle_db_*.sql.gz" -type f -printf "  %f (%s bytes, %TY-%Tm-%Td %TH:%TM)\n" | sort -r | head -10
        echo ""
        
        echo "Fichiers:"
        find "$BACKUP_DIR" -name "moodle_files_*.tar.gz" -type f -printf "  %f (%s bytes, %TY-%Tm-%Td %TH:%TM)\n" | sort -r | head -10
        echo ""
        
        echo "Code source:"
        find "$BACKUP_DIR" -name "moodle_code_*.tar.gz" -type f -printf "  %f (%s bytes, %TY-%Tm-%Td %TH:%TM)\n" | sort -r | head -10
    else
        log_warn "Aucun dossier de sauvegarde trouvé: $BACKUP_DIR"
    fi
    
    exit 0
}

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --db)
            DB_BACKUP="$2"
            shift 2
            ;;
        --files)
            FILES_BACKUP="$2"
            shift 2
            ;;
        --code)
            CODE_BACKUP="$2"
            shift 2
            ;;
        --yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --list)
            list_backups
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

# Vérifier qu'au moins une sauvegarde est spécifiée
if [ -z "$DB_BACKUP" ] && [ -z "$FILES_BACKUP" ] && [ -z "$CODE_BACKUP" ]; then
    log_error "Aucune sauvegarde spécifiée!"
    echo ""
    show_help
    exit 1
fi

# Confirmation
confirm_restore

# Exécuter les restaurations
echo ""
log_info "Démarrage de la restauration..."
echo ""

[ -n "$DB_BACKUP" ] && restore_database "$DB_BACKUP" && echo ""
[ -n "$FILES_BACKUP" ] && restore_files "$FILES_BACKUP" && echo ""
[ -n "$CODE_BACKUP" ] && restore_code "$CODE_BACKUP" && echo ""

# Résumé final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Restauration terminée avec succès!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Vérifiez que votre site Moodle fonctionne correctement"
echo ""
