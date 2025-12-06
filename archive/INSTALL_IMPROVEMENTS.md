# Améliorations de l'installation Moodle

## Problèmes résolus

### 1. Dépendances Composer manquantes
**Problème :** Composer dependencies were not found.
**Solution :** Ajout d'un entrypoint qui exécute automatiquement `composer install --no-dev --classmap-authoritative --no-interaction`

### 2. Configuration PHP de sécurité
**Problème :** zend.exception_ignore_args non activé
**Solution :** Création automatique du fichier `/usr/local/etc/php/conf.d/zend-security.ini` avec `zend.exception_ignore_args = On`

### 3. Pack de langue français
**Problème :** Installation en anglais par défaut
**Solution :** Téléchargement automatique du pack de langue français 5.1 depuis le site officiel Moodle

## Améliorations techniques

### Volume persistant pour les langues
- Ajout du volume `moodle_lang:/var/www/html/lang`
- Les packs de langue sont conservés entre les redéploiements
- Évite le re-téléchargement à chaque redémarrage

### Script d'initialisation optimisé
L'entrypoint exécute dans l'ordre :
1. Configuration PHP de sécurité
2. Installation des dépendances Composer (si composer.json existe)
3. Téléchargement du pack français (si absent)
4. Configuration des permissions
5. Démarrage d'Apache

### Gestion des permissions
- Configuration automatique de `www-data:www-data` pour `/var/www/html` et `/var/www/moodledata`
- Garantit le bon fonctionnement de Moodle

## Utilisation

Après redéploiement dans Coolify :
1. Les dépendances Composer seront automatiquement installées
2. Le français sera disponible dès la première page d'installation
3. Les vérifications de sécurité PHP passeront au vert
4. L'installation Moodle devrait se dérouler sans erreur

## Logs de démarrage

Le conteneur affichera ces messages au démarrage :
```
Configuration de PHP pour la sécurité...
Vérification des dépendances Composer...
Téléchargement du pack de langue français...
Pack de langue français installé avec succès
Configuration des permissions...
Démarrage d Apache...
```

## Temps de démarrage

Le premier démarrage peut prendre 30-60 secondes supplémentaires pour :
- Installer les dépendances Composer (~20 secondes)
- Télécharger le pack français (~10 secondes)
- Configurer les permissions (~5 secondes)

Les redémarrages suivants seront plus rapides grâce au cache du volume persistant.