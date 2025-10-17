# Installer un plugin Moodle via Git (recommandé)

Ce guide décrit une méthode traçable et reproductible pour ajouter des plugins dans ce dépôt Git, puis les déployer via Coolify.

## Principe

- On ajoute le code du plugin dans l’arborescence Moodle (dirroot) au bon emplacement.
- On versionne les changements (git add/commit/push).
- Coolify reconstruit et déploie; Moodle détecte le nouveau plugin et propose l’installation/mise à jour.

## Emplacements des plugins (Moodle 5.1)

Note Moodle 5.1 (DocumentRoot = `moodle/public/`):
- Les thèmes résident sous `moodle/public/theme/` (exposés côté web).
- La plupart des autres types de plugins (mod, blocks, local, auth, etc.) restent à la racine `moodle/`.

| Type      | Dossier cible                                   | Exemple                                   |
|-----------|--------------------------------------------------|-------------------------------------------|
| Thème     | `moodle/public/theme/<nom_du_theme>`             | `moodle/public/theme/adaptable`           |
| Module    | `moodle/mod/<nom_du_module>`                    | `moodle/mod/assign`                       |
| Bloc      | `moodle/blocks/<nom_du_bloc>`                   | `moodle/blocks/timeline`                  |
| Outil     | `moodle/admin/tool/<nom_de_l_outil>`            | `moodle/admin/tool/health`                |
| Auth      | `moodle/auth/<nom_du_plugin>`                   | `moodle/auth/oidc`                        |
| Local     | `moodle/local/<nom_du_plugin>`                  | `moodle/local/mailtest`                   |
| Filter    | `moodle/filter/<nom_du_plugin>`                 | `moodle/filter/multilang2`                |

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
