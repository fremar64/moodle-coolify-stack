#!/bin/bash
#
# Configuration initiale de Dropbox pour les sauvegardes Moodle
# Usage: ./scripts/setup-dropbox.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Configuration Dropbox pour Moodle Backup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier si rclone est disponible
if ! command -v rclone &> /dev/null; then
    log_warn "rclone n'est pas installé localement"
    log_info "Installation de rclone..."
    curl https://rclone.org/install.sh | sudo bash
fi

# Charger .env si disponible
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

# Vérifier si le token Dropbox existe
if [ -z "$DROPBOX_TOKEN" ] || [ "$DROPBOX_TOKEN" = '{"access_token":"VOTRE_TOKEN_ICI","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}' ]; then
    log_warn "Token Dropbox non configuré"
    echo ""
    log_info "Pour configurer Dropbox :"
    echo "  1. Lancez: rclone config"
    echo "  2. Choisissez: n (New remote)"
    echo "  3. Nom: dropbox"
    echo "  4. Type: dropbox"
    echo "  5. Suivez les instructions pour autoriser l'accès"
    echo "  6. Copiez le token généré dans votre .env"
    echo ""
    log_info "Ou configurez via conteneur Docker:"
    echo "  docker run -it --rm rclone/rclone config"
    echo ""
    exit 1
fi

# Tester la connexion Dropbox
log_info "Test de connexion à Dropbox..."

if docker run --rm \
    -e RCLONE_CONFIG_DROPBOX_TYPE=dropbox \
    -e "RCLONE_CONFIG_DROPBOX_TOKEN=${DROPBOX_TOKEN}" \
    rclone/rclone:latest \
    lsd dropbox: &>/dev/null; then
    log_info "✅ Connexion Dropbox réussie"
else
    log_error "❌ Échec de connexion à Dropbox"
    log_warn "Vérifiez votre DROPBOX_TOKEN dans .env"
    exit 1
fi

# Créer la structure de dossiers dans Dropbox
log_info "Création de la structure de dossiers..."

docker run --rm \
    -e RCLONE_CONFIG_DROPBOX_TYPE=dropbox \
    -e "RCLONE_CONFIG_DROPBOX_TOKEN=${DROPBOX_TOKEN}" \
    rclone/rclone:latest \
    mkdir -p dropbox:/moodle_backups/database \
    dropbox:/moodle_backups/files \
    dropbox:/moodle_backups/code \
    dropbox:/moodle_backups/manifests

log_info "✅ Structure créée dans Dropbox"

# Afficher l'espace disponible
log_info "Espace Dropbox disponible:"
docker run --rm \
    -e RCLONE_CONFIG_DROPBOX_TYPE=dropbox \
    -e "RCLONE_CONFIG_DROPBOX_TOKEN=${DROPBOX_TOKEN}" \
    rclone/rclone:latest \
    about dropbox:

echo ""
log_info "✅ Configuration Dropbox terminée"
log_info "Vous pouvez maintenant utiliser ./scripts/backup.sh avec l'option --dropbox"
