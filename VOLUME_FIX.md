# CORRECTION CRITIQUE - Volume Moodle incorrect

## 🚨 Problème identifié

**Erreur 404** sur `/admin/index.php` alors que `index.php` racine était accessible.

### Cause racine découverte
- Le volume `./moodle:/var/www/html` montait la **racine du dépôt**
- Mais la **vraie racine web de Moodle** est dans `./moodle/public/`
- Résultat : `index.php` trouvé (dans `./moodle/`) mais `admin/index.php` manquant (dans `./moodle/public/admin/`)

## ✅ Solution appliquée

### Volume corrigé dans docker-compose.yml
```yaml
# AVANT (incorrect)
volumes:
  - ./moodle:/var/www/html

# APRÈS (correct)
volumes:
  - ./moodle/public:/var/www/html
```

### Structure Moodle clarifiée
```
moodle/
├── composer.json              ← Dépendances du projet
├── config-dist.php           ← Configuration template
├── index.php                 ← Redirection vers public/
└── public/                   ← VRAIE RACINE WEB
    ├── admin/
    │   └── index.php         ← Fichier d'installation
    ├── index.php             ← Page d'accueil Moodle
    ├── lib/
    ├── course/
    └── ...
```

## 🎯 Avantages de cette approche

### **Sécurité renforcée**
- ✅ **Document root** sur `/public/` (best practice)
- ✅ **Fichiers sensibles** (composer.json, config) **hors web**
- ✅ **Structure moderne** Moodle

### **Personnalisation maintenue**
- ✅ **Code source** toujours versionné dans Git
- ✅ **Plugins/thèmes** → `./moodle/public/mod/`, `./moodle/public/theme/`
- ✅ **Configurations** → `./moodle/public/config.php`

### **Architecture propre**
- ✅ **Séparation** code source / web assets
- ✅ **Composer** fonctionne depuis `./moodle/`
- ✅ **Web server** sert uniquement `./moodle/public/`

## 🚀 Résultats attendus

Après redéploiement :
- ✅ **https://ecole-en-ligne.ceredis.net** → `./moodle/public/index.php`
- ✅ **Installation accessible** → `./moodle/public/admin/index.php`
- ✅ **Tous les assets** disponibles (CSS, JS, images)
- ✅ **Sécurité optimale** (pas d'accès aux fichiers hors public/)

Cette correction respecte les standards modernes et maintient votre contrôle total sur le code source !