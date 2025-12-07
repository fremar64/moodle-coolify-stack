#!/bin/bash
#
# Script de sauvegarde Moodle - Manuel ou Automatique
# Usage: ./scripts/backup.sh [--type full|db|files] [--output /path/to/backup]
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TYPE="${1:-full}"
OUTPUT_DIR="${2:-$BACKUP_DIR}"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Banner
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Moodle Backup Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier si Docker Compose est disponible
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé"
    exit 1
fi

# Créer le dossier de backup s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

# Charger les variables d'environnement
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
    log_info "Variables d'environnement chargées depuis .env"
else
    log_warn "Fichier .env non trouvé, utilisation des variables système"
fi

# Fonction de sauvegarde de la base de données
backup_database() {
    log_info "Sauvegarde de la base de données..."
    
    DB_BACKUP_FILE="$OUTPUT_DIR/moodle_db_${TIMESTAMP}.sql"
    
    if docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db \
        mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" moodle > "$DB_BACKUP_FILE" 2>/dev/null; then
        
        # Compresser le dump
        gzip "$DB_BACKUP_FILE"
        DB_SIZE=$(du -h "${DB_BACKUP_FILE}.gz" | cut -f1)
        log_info "✅ Base de données sauvegardée: ${DB_BACKUP_FILE}.gz (${DB_SIZE})"
        echo "$DB_BACKUP_FILE.gz"
    else
        log_error "❌ Échec de la sauvegarde de la base de données"
        exit 1
    fi
}

# Fonction de sauvegarde des fichiers
backup_files() {
    log_info "Sauvegarde des fichiers Moodle..."
    
    FILES_BACKUP_FILE="$OUTPUT_DIR/moodle_files_${TIMESTAMP}.tar.gz"
    
    if docker run --rm \
        -v moodle-coolify-stack_moodle_data:/data:ro \
        -v "$OUTPUT_DIR":/backup \
        alpine tar czf "/backup/moodle_files_${TIMESTAMP}.tar.gz" -C /data . 2>/dev/null; then
        
        FILES_SIZE=$(du -h "$FILES_BACKUP_FILE" | cut -f1)
        log_info "✅ Fichiers sauvegardés: $FILES_BACKUP_FILE ($FILES_SIZE)"
        echo "$FILES_BACKUP_FILE"
    else
        log_error "❌ Échec de la sauvegarde des fichiers"
        exit 1
    fi
}

# Fonction de sauvegarde du code source
backup_code() {
    log_info "Sauvegarde du code source Moodle..."
    
    CODE_BACKUP_FILE="$OUTPUT_DIR/moodle_code_${TIMESTAMP}.tar.gz"
    
    if tar czf "$CODE_BACKUP_FILE" -C "$PROJECT_DIR" moodle/ \
        --exclude='moodle/.git' \
        --exclude='moodle/node_modules' 2>/dev/null; then
        
        CODE_SIZE=$(du -h "$CODE_BACKUP_FILE" | cut -f1)
        log_info "✅ Code source sauvegardé: $CODE_BACKUP_FILE ($CODE_SIZE)"
        echo "$CODE_BACKUP_FILE"
    else
        log_error "❌ Échec de la sauvegarde du code source"
        exit 1
    fi
}

# Fonction de sauvegarde complète
backup_full() {
    log_info "Démarrage d'une sauvegarde complète..."
    echo ""
    
    DB_FILE=$(backup_database)
    echo ""
    
    FILES_FILE=$(backup_files)
    echo ""
    
    CODE_FILE=$(backup_code)
    echo ""
    
    # Créer un fichier manifest
    MANIFEST_FILE="$OUTPUT_DIR/backup_manifest_${TIMESTAMP}.txt"
    cat > "$MANIFEST_FILE" <<EOF
Moodle Backup Manifest
======================
Date: $(date)
Type: Full Backup
Hostname: $(hostname)

Files:
------
Database: $(basename "$DB_FILE")
Files: $(basename "$FILES_FILE")
Code: $(basename "$CODE_FILE")

Sizes:
------
Database: $(du -h "$DB_FILE" | cut -f1)
Files: $(du -h "$FILES_FILE" | cut -f1)
Code: $(du -h "$CODE_FILE" | cut -f1)
Total: $(du -ch "$DB_FILE" "$FILES_FILE" "$CODE_FILE" | tail -1 | cut -f1)

Checksums (SHA256):
-------------------
$(sha256sum "$DB_FILE" "$FILES_FILE" "$CODE_FILE")
EOF
    
    log_info "✅ Manifest créé: $MANIFEST_FILE"
    echo ""
}

# Nettoyage des anciennes sauvegardes (garder les 7 dernières)
cleanup_old_backups() {
    log_info "Nettoyage des anciennes sauvegardes (conservation: 7 dernières)..."
    
    cd "$OUTPUT_DIR"
    
    # Supprimer les sauvegardes de plus de 7 jours
    find . -name "moodle_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    find . -name "moodle_*.sql.gz" -mtime +7 -delete 2>/dev/null || true
    find . -name "backup_manifest_*.txt" -mtime +7 -delete 2>/dev/null || true
    
    log_info "✅ Nettoyage terminé"
}

# Afficher l'aide
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --type TYPE        Type de sauvegarde: full, db, files, code (défaut: full)
    --output DIR       Dossier de sortie (défaut: ./backups)
    --cleanup          Nettoyer les anciennes sauvegardes (>7 jours)
    --help             Afficher cette aide

Exemples:
    $0                           # Sauvegarde complète
    $0 --type db                 # Sauvegarde base de données uniquement
    $0 --type files              # Sauvegarde fichiers uniquement
    $0 --output /mnt/backups     # Sauvegarde dans un dossier personnalisé
    $0 --cleanup                 # Nettoyer les anciennes sauvegardes

EOF
}

# Parser les arguments
CLEANUP=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            mkdir -p "$OUTPUT_DIR"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
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

# Exécuter le type de sauvegarde demandé
case $BACKUP_TYPE in
    full)
        backup_full
        ;;
    db|database)
        backup_database
        ;;
    files)
        backup_files
        ;;
    code)
        backup_code
        ;;
    *)
        log_error "Type de sauvegarde invalide: $BACKUP_TYPE"
        show_help
        exit 1
        ;;
esac

# Nettoyage si demandé
if [ "$CLEANUP" = true ]; then
    echo ""
    cleanup_old_backups
fi

# Résumé final
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Sauvegarde terminée avec succès!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Emplacement: $OUTPUT_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""
