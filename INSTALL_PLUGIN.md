# Installer un plugin Moodle via Git (recommandé)

Ce guide décrit une méthode traçable et reproductible pour ajouter des plugins dans ce dépôt Git, puis les déployer via Coolify.

## Principe

- On ajoute le code du plugin dans l’arborescence Moodle (dirroot) au bon emplacement.
- On versionne les changements (git add/commit/push).
- Coolify reconstruit et déploie; Moodle détecte le nouveau plugin et propose l’installation/mise à jour.

## Emplacements des plugins (Moodle 5.1)

Note Moodle 5.1 (DocumentRoot = `moodle/public/`):
- Les thèmes résident sous `moodle/public/theme/` (exposés côté web).
- Les autres types de plugins (mod, blocks, local, auth, filter, question, etc.) résident également sous `moodle/public/` dans ce dépôt (les parties web-accessibles y sont servies).

| Type      | Dossier cible                                        | Exemple                                           |
|-----------|-------------------------------------------------------|---------------------------------------------------|
| Thème     | `moodle/public/theme/<nom_du_theme>`                  | `moodle/public/theme/adaptable`                   |
| Module    | `moodle/public/mod/<nom_du_module>`                   | `moodle/public/mod/assign`                        |
| Bloc      | `moodle/public/blocks/<nom_du_bloc>`                  | `moodle/public/blocks/timeline`                   |
| Outil     | `moodle/public/admin/tool/<nom_de_l_outil>`           | `moodle/public/admin/tool/health`                 |
| Auth      | `moodle/public/auth/<nom_du_plugin>`                  | `moodle/public/auth/oidc`                         |
| Local     | `moodle/public/local/<nom_du_plugin>`                 | `moodle/public/local/mailtest`                    |
| Filter    | `moodle/public/filter/<nom_du_plugin>`                | `moodle/public/filter/multilang2`                 |
| Type question (qtype) | `moodle/public/question/type/<nom_du_type>`      | `moodle/public/question/type/wq`                  |
| Plugin Tiny (éditeur) | `moodle/public/lib/editor/tiny/plugins/<nom_du_plugin>` | `moodle/public/lib/editor/tiny/plugins/wiris` |

Référence complète: https://docs.moodle.org/dev/Plugin_types

## Compatibilité

- Vérifiez la compatibilité du plugin avec votre version de Moodle (ici 5.1).
- Préférez les versions publiées pour 5.1 (ou supérieures si indiquées compatibles).

## Exemple: thème Adaptable

1. Téléchargez depuis le répertoire officiel la version compatible 5.1, ou clonez si un repo Git existe.
2. Placez le code dans `moodle/public/theme/adaptable` (le dossier doit contenir version.php, settings.php, lang/, etc.).
3. Versionnez et poussez:

```
# À la racine du dépôt
git add moodle/public/theme/adaptable
git commit -m "Ajout: thème Adaptable"
git push origin main
```

4. Déployez dans Coolify (l’application Git-Based). À la fin du déploiement, allez dans:
   - Administration du site → Notifications
   - Suivez les écrans pour installer/migrer le plugin
   - Vider tous les caches (Administration du site → Développement → Vider tous les caches)

### Alternative conseillée en cas de timeouts (CLI)

Si l’interface web est lente ou provoque des 504 lors de l’installation/mise à jour des plugins, exécutez la migration via CLI dans le conteneur web:

```
# Dans le conteneur moodle_app
php /var/www/html/public/admin/cli/upgrade.php --non-interactive --allow-unstable
php /var/www/html/public/admin/cli/purge_caches.php
```

Cela contourne le proxy et évite les timeouts HTTP.

## Permissions & propriétaire

- Le conteneur règle déjà les permissions au démarrage, mais côté plugin, assurez-vous que l’owner soit bien `www-data` dans le conteneur:

```
# (Optionnel) Dans le conteneur web
chown -R www-data:www-data /var/www/html/public/theme/adaptable
find /var/www/html/public/theme/adaptable -type d -exec chmod 775 {} \;
find /var/www/html/public/theme/adaptable -type f -exec chmod 664 {} \;
```

## Désinstallation / rollback

- Pour retirer un plugin ajouté par Git:
  - Supprimez le dossier du plugin dans le dépôt
  - Commit/push
  - Déployez et finissez la désinstallation via l’interface Moodle si nécessaire

## Bonnes pratiques

- Un plugin = un commit dédié (message clair)
- Documentez la source et la version du plugin dans le message de commit
- Après ajout/suppression, purge des caches
- Surveillez les notifications Moodle après déploiement
