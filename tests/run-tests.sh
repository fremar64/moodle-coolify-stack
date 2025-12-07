#!/bin/bash
#
# Tests de validation pour Moodle Coolify Stack
# Utilisé en local et par GitHub Actions
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Compteurs
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Fonctions
test_pass() {
    echo -e "${GREEN}✅ PASS${NC} - $1"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

test_fail() {
    echo -e "${RED}❌ FAIL${NC} - $1"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

test_skip() {
    echo -e "${YELLOW}⊘  SKIP${NC} - $1"
}

# Banner
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🧪 Moodle Coolify Stack - Test Suite
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo ""

# Test 1: Vérifier les fichiers requis
echo "📁 Test 1: Fichiers requis"
echo "──────────────────────────"

required_files=(
    "docker-compose.yml"
    "Dockerfile"
    "docker-entrypoint.sh"
    ".env.example"
    ".gitignore"
    "README.md"
    "SETUP.md"
    "MAINTENANCE.md"
    "TROUBLESHOOTING.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        test_pass "Fichier présent: $file"
    else
        test_fail "Fichier manquant: $file"
    fi
done
echo ""

# Test 2: Vérifier docker-compose.yml
echo "🐳 Test 2: Configuration Docker Compose"
echo "────────────────────────────────────────"

if docker compose config > /dev/null 2>&1; then
    test_pass "docker-compose.yml valide"
else
    test_fail "docker-compose.yml invalide"
fi

# Vérifier les services
services=("db" "redis" "moodle" "cron" "backup")
for service in "${services[@]}"; do
    if docker compose config | grep -q "^\s*${service}:"; then
        test_pass "Service présent: $service"
    else
        test_fail "Service manquant: $service"
    fi
done

# Vérifier les healthchecks
if docker compose config | grep -q "healthcheck:"; then
    test_pass "Healthchecks configurés"
else
    test_fail "Healthchecks manquants"
fi
echo ""

# Test 3: Vérifier .env.example
echo "⚙️  Test 3: Variables d'environnement"
echo "──────────────────────────────────────"

critical_vars=(
    "DOMAIN"
    "MYSQL_ROOT_PASSWORD"
    "MOODLE_DB_PASSWORD"
    "MOODLE_ADMIN_USER"
    "MOODLE_ADMIN_PASS"
    "MOODLE_ADMIN_EMAIL"
)

for var in "${critical_vars[@]}"; do
    if grep -q "^${var}=" .env.example; then
        test_pass "Variable présente: $var"
    else
        test_fail "Variable manquante: $var"
    fi
done
echo ""

# Test 4: Vérifier .gitignore
echo "🙈 Test 4: Git Configuration"
echo "────────────────────────────"

if grep -q "^\.env$" .gitignore; then
    test_pass ".env dans .gitignore"
else
    test_fail ".env non ignoré"
fi

if grep -q "^archive/" .gitignore; then
    test_pass "archive/ dans .gitignore"
else
    test_fail "archive/ non ignoré"
fi
echo ""

# Test 5: Vérifier les scripts
echo "📜 Test 5: Scripts d'administration"
echo "────────────────────────────────────"

scripts=("backup.sh" "restore.sh" "update-moodle.sh" "health-check.sh")
for script in "${scripts[@]}"; do
    if [ -f "scripts/$script" ]; then
        if [ -x "scripts/$script" ]; then
            test_pass "Script exécutable: $script"
        else
            test_fail "Script non exécutable: $script"
        fi
    else
        test_fail "Script manquant: $script"
    fi
done
echo ""

# Test 6: Vérifier GitHub Actions
echo "🔄 Test 6: CI/CD Configuration"
echo "───────────────────────────────"

workflows=(
    ".github/workflows/docker-validation.yml"
    ".github/workflows/security-scan.yml"
    ".github/workflows/build-test.yml"
)

for workflow in "${workflows[@]}"; do
    if [ -f "$workflow" ]; then
        test_pass "Workflow présent: $(basename $workflow)"
    else
        test_fail "Workflow manquant: $(basename $workflow)"
    fi
done
echo ""

# Test 7: Vérifier la structure Moodle
echo "🎓 Test 7: Structure Moodle"
echo "────────────────────────────"

if [ -d "moodle" ]; then
    test_pass "Dossier moodle présent"
    
    moodle_files=(
        "moodle/index.php"
        "moodle/config-dist.php"
        "moodle/composer.json"
        "moodle/lib/setup.php"
        "moodle/public/index.php"
    )
    
    for file in "${moodle_files[@]}"; do
        if [ -f "$file" ]; then
            test_pass "Fichier Moodle présent: $(basename $file)"
        else
            test_fail "Fichier Moodle manquant: $(basename $file)"
        fi
    done
else
    test_fail "Dossier moodle manquant"
fi
echo ""

# Test 8: Vérifier la documentation
echo "📚 Test 8: Documentation"
echo "────────────────────────"

# Vérifier les liens dans README
if grep -q "SETUP.md" README.md && \
   grep -q "MAINTENANCE.md" README.md && \
   grep -q "TROUBLESHOOTING.md" README.md; then
    test_pass "Liens de navigation dans README.md"
else
    test_fail "Liens de navigation manquants dans README.md"
fi

# Vérifier que START_HERE.md existe
if [ -f "START_HERE.md" ]; then
    test_pass "Guide START_HERE.md présent"
else
    test_fail "Guide START_HERE.md manquant"
fi
echo ""

# Test 9: Vérifier Docker (si disponible)
echo "🐋 Test 9: Docker (optionnel)"
echo "──────────────────────────────"

if command -v docker &> /dev/null; then
    if docker info > /dev/null 2>&1; then
        test_pass "Docker daemon accessible"
        
        # Tester le build du Dockerfile
        if docker build --no-cache -t moodle-test . > /dev/null 2>&1; then
            test_pass "Dockerfile build réussi"
        else
            test_fail "Dockerfile build échoué"
        fi
    else
        test_skip "Docker daemon non accessible"
    fi
else
    test_skip "Docker non installé"
fi
echo ""

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé des Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total:  $TESTS_RUN tests"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ TOUS LES TESTS SONT PASSÉS !${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    echo "Veuillez corriger les erreurs ci-dessus"
    echo ""
    exit 1
fi
