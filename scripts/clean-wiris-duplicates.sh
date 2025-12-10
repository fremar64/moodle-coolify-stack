#!/bin/bash
# Script de nettoyage des doublons de plugins Wiris
# À exécuter une seule fois pour corriger les warnings

set -e

cd /home/ceredis/moodle-coolify-stack/moodle

echo "🧹 Nettoyage des plugins Wiris dupliqués..."

# Les versions correctes sont dans public/ (Moodle 5.1+)
# On supprime les anciennes versions à la racine

PLUGINS_TO_REMOVE=(
    "local/wirisquizzes"
    "filter/wiris"
    "question/type/wq"
    "question/type/essaywiris"
    "question/type/matchwiris"
    "question/type/multianswerwiris"
    "question/type/multichoicewiris"
    "question/type/shortanswerwiris"
    "question/type/truefalsewiris"
)

for plugin in "${PLUGINS_TO_REMOVE[@]}"; do
    if [ -d "$plugin" ] && [ ! -L "$plugin" ]; then
        echo "  ❌ Suppression de: $plugin (doublon, version valide dans public/)"
        rm -rf "$plugin"
    fi
done

echo "✅ Nettoyage terminé. Les plugins Wiris sont maintenant uniquement dans public/"
