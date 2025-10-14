# Architecture de la Stack Moodle

## 🏗️ Structure des Volumes et Chemins

### Problème résolu : Erreur "components.json not found"

**Cause identifiée** : Moodle 5.1 a une architecture particulière avec des fichiers système séparés des fichiers web publics :

```
moodle/
├── lib/                    # Bibliothèques système (components.json, etc.)
├── composer.json           # Dépendances principales  
├── config-dist.php         # Configuration de base
├── index.php              # Redirecteur principal
└── public/                # Dossier web accessible
    ├── admin/
    ├── lib/               # Bibliothèques web
    ├── install.php        # Script d'installation
    ├── index.php         # Point d'entrée web
    └── ...               # Code web complet
```

### ✅ Solution Implementée

**Montage de volume** :
```yaml
volumes:
  - ./moodle:/var/www/html              # Montage racine complète
  - moodle_data:/var/www/moodledata     # Données utilisateur
```

**Configuration Apache** :
```bash
APACHE_DOCUMENT_ROOT=/var/www/html/public  # Point d'entrée web
```

### 🔧 Architecture Finale

```
Container Path Structure:
/var/www/html/
├── lib/
│   └── components.json     ✅ Accessible pour l'autoload
├── composer.json           ✅ Dépendances disponibles
├── config-dist.php         ✅ Configuration accessible
└── public/                 ← Apache Document Root
    ├── install.php         ✅ Installation accessible
    ├── index.php          ✅ Application accessible
    └── admin/
        └── cli/
            └── cron.php    ✅ Tâches cron accessibles
```

### 🎯 Avantages

1. **Fichiers système accessibles** : `lib/components.json`, autoloaders, etc.
2. **Sécurité maintenue** : Seul `/public` est exposé par Apache
3. **Fonctionnalité complète** : Installation, administration, cron
4. **Structure standard** : Respecte l'architecture Moodle officielle

### 🚀 Services Configurés

- **moodle** : Apache pointe vers `/var/www/html/public`
- **cron** : Exécute `/var/www/html/public/admin/cli/cron.php`
- **backup** : Accède aux données dans `/var/www/moodledata`

Cette architecture garantit le bon fonctionnement de Moodle tout en maintenant la sécurité et les bonnes pratiques.