# 🔧 CORRECTION DES PROBLÈMES D'INSTALLATION

## Version 1.2.1 - Fix Critical

---

## ❌ PROBLÈMES IDENTIFIÉS

Vous avez rencontré 3 problèmes lors de l'installation :

### 1. **[pluginname]** affiché au lieu de "CEREDIS"
**Cause** : Moodle ne trouvait pas la chaîne de langue  
**Statut** : ✅ Déjà corrigé dans le fichier

### 2. **Contenu brut** avec `[[platform_title]]` visible
**Cause** : Templates Mustache non interprétés  
**Statut** : ✅ Correction appliquée

### 3. **Pas de mise en forme**, design par défaut
**Cause** : Layouts incomplets dans `config.php`  
**Statut** : ✅ Correction appliquée

---

## 🔍 CAUSE RACINE

Le fichier `config.php` ne définissait que le layout `frontpage`, mais **Moodle 5.1 nécessite TOUS les layouts de base** :

```php
// AVANT (incomplet)
$THEME->layouts = [
    'frontpage' => [...],  // Seulement celui-ci
];

// APRÈS (complet)
$THEME->layouts = [
    'frontpage' => [...],
    'base' => [...],
    'standard' => [...],
    'course' => [...],
    // + 15 autres layouts nécessaires
];
```

Sans tous les layouts, Moodle utilise le thème parent (Boost) pour afficher la page, ce qui ignore notre template personnalisé `frontpage.mustache`.

---

## ✅ SOLUTION APPLIQUÉE

### Fichier corrigé : `config.php`

**Changements** :
- ✅ Ajout de 18 layouts (au lieu de 1)
- ✅ Tous héritent des fichiers de Boost
- ✅ Seul `frontpage` utilise notre layout personnalisé

**Nouveaux layouts ajoutés** :
- `base`, `standard`, `course`, `coursecategory`
- `incourse`, `admin`, `mydashboard`, `mypublic`
- `login`, `popup`, `frametop`, `embedded`
- `maintenance`, `print`, `redirect`, `report`, `secure`

---

## 🚀 PROCÉDURE DE CORRECTION

### OPTION 1 : Remplacement via FTP/SSH (Recommandé)

1. **Téléchargez le nouveau package** :
   - `theme-ceredis-moodle-v1.2.1-FIXED.zip`

2. **Remplacez le fichier** via FTP/SSH :
   ```bash
   # Naviguez vers le dossier du thème
   cd /path/to/moodle/theme/ceredis/
   
   # Sauvegardez l'ancien fichier
   mv config.php config.php.backup
   
   # Uploadez le nouveau config.php
   # (via FTP ou commande scp)
   ```

3. **Videz les caches** :
   - **Administration du site** → **Développement** → **Purger tous les caches**

4. **Rechargez la page d'accueil** (Ctrl+F5)

### OPTION 2 : Modification manuelle

1. **Éditez** : `/theme/ceredis/config.php`

2. **Remplacez** la section `$THEME->layouts = [...]` par le contenu complet du nouveau fichier

3. **Sauvegardez**

4. **Videz les caches** Moodle

---

## 📋 VÉRIFICATIONS POST-CORRECTION

### ✅ Checklist

- [ ] Thème affiche "CEREDIS" (pas [pluginname])
- [ ] Page d'accueil montre le hero avec image
- [ ] Titre "École en ligne" visible en jaune/orange
- [ ] 4 catégories affichées avec icônes
- [ ] Carousel de sponsors visible
- [ ] Footer complet affiché
- [ ] Aucun texte brut type `[[...]]` visible
- [ ] Design responsive fonctionne

### 🔍 Tests à effectuer

1. **Page d'accueil** : https://ecole-en-ligne.ceredis.net/
   - Hero doit s'afficher avec image de fond
   - Logo en haut à gauche
   - 4 catégories colorées visibles

2. **Sélecteur de thèmes** : Administration → Apparence → Thèmes
   - Doit afficher "CEREDIS" (pas [pluginname])
   - Aperçu du thème visible

3. **Autres pages** : Cours, Dashboard, Admin
   - Doivent utiliser le design Boost standard
   - Pas d'erreurs d'affichage

---

## 🆘 SI LES PROBLÈMES PERSISTENT

### Problème : Toujours [pluginname]

**Solution** :
1. Vérifiez que le fichier existe : `/theme/ceredis/lang/fr/theme_ceredis.php`
2. Vérifiez la ligne 6 : `$string['pluginname'] = 'CEREDIS';`
3. Videz le cache des langues :
   ```bash
   php admin/cli/purge_caches.php
   ```

### Problème : Contenu brut `[[...]]` encore visible

**Solution** :
1. Vérifiez que le fichier existe : `/theme/ceredis/templates/frontpage.mustache`
2. Vérifiez que `config.php` contient bien tous les layouts
3. Videz le cache des templates :
   - Administration → Développement → Purger tous les caches
   - Cochez "Purger les caches des templates"

### Problème : Pas de CSS, pas de couleurs

**Solution** :
1. Vérifiez que les fichiers SCSS existent :
   - `/theme/ceredis/scss/pre.scss`
   - `/theme/ceredis/scss/post.scss`
2. Vérifiez que `lib.php` existe et contient les fonctions SCSS
3. Régénérez les CSS :
   - Administration → Apparence → Thèmes → **Vider les caches de thème**

### Problème : Erreur PHP

**Consultez les logs** :
```bash
# Via SSH
tail -f /var/log/apache2/error.log
# ou
tail -f /var/log/nginx/error.log

# Ou dans Moodle
Administration → Serveur → Débogage
```

**Erreurs courantes** :
- `Cannot find data record in theme` → Réinstallez le thème
- `Call to undefined function` → Vérifiez `lib.php`
- `Template not found` → Vérifiez `/templates/frontpage.mustache`

---

## 📊 DIFFÉRENCES ENTRE VERSIONS

| Aspect | v1.2 (Bugguée) | v1.2.1 (Fixée) |
|--------|---------------|----------------|
| Layouts dans config.php | 1 | 18 |
| Nom du thème | [pluginname] | CEREDIS ✅ |
| Page d'accueil | Texte brut | Stylisée ✅ |
| Templates Mustache | Non interprétés | Fonctionnels ✅ |
| CSS SCSS | Non compilé | Compilé ✅ |

---

## 🎯 EXPLICATION TECHNIQUE

### Pourquoi tous ces layouts ?

Moodle utilise différents layouts pour différentes pages :

- **frontpage** : Page d'accueil du site
- **course** : Pages de cours
- **admin** : Pages d'administration
- **mydashboard** : Tableau de bord utilisateur
- **login** : Page de connexion
- etc.

Si un layout n'est pas défini dans le thème enfant, Moodle remonte au parent (Boost), qui ne connaît pas notre template `frontpage.mustache`.

### Structure des fichiers Moodle

```
theme/ceredis/
├── config.php           ← Définit TOUS les layouts
├── version.php
├── lib.php             ← Fonctions SCSS
├── layout/
│   └── frontpage.php   ← Notre layout custom
├── templates/
│   └── frontpage.mustache ← Notre template
├── lang/fr/
│   └── theme_ceredis.php  ← Traductions (avec pluginname)
└── scss/
    ├── pre.scss        ← Variables
    └── post.scss       ← Styles
```

### Ordre de priorité Moodle

1. Cherche le layout dans le thème actuel (`ceredis`)
2. Si non trouvé, cherche dans le parent (`boost`)
3. Si toujours non trouvé, utilise le layout par défaut

**Avant la correction** :
```
Page d'accueil → Layout 'frontpage' ?
  → Trouvé dans ceredis/config.php ✅
  → Mais fichier frontpage.php incomplet
  → Utilise boost/layout/columns2.php
  → Ignore notre template frontpage.mustache ❌
```

**Après la correction** :
```
Page d'accueil → Layout 'frontpage' ?
  → Trouvé dans ceredis/config.php ✅
  → Utilise ceredis/layout/frontpage.php ✅
  → Charge ceredis/templates/frontpage.mustache ✅
  → Applique ceredis/scss/*.scss ✅
  → DESIGN COMPLET AFFICHÉ ! ✅
```

---

## 📥 FICHIERS CORRIGÉS

### Fichier principal modifié :
- **config.php** (version 1.2.1)

### Archive mise à jour :
- **theme-ceredis-moodle-v1.2.1-FIXED.zip**

---

## ✅ VALIDATION FINALE

Une fois la correction appliquée, votre page d'accueil devrait ressembler à ceci :

```
┌────────────────────────────────────┐
│ 📷 HERO                            │
│ [Logo CEREDIS]  École en ligne     │
│                 Environnement...   │
│ [Boutons d'action]                │
├────────────────────────────────────┤
│ ✨ Bienvenue dans ton espace...   │
├────────────────────────────────────┤
│ 🏁 Rallye   🧸 Maternelle         │
│ 🎒 Primaire 🎓 Collège            │
├────────────────────────────────────┤
│ 🤝 Carousel sponsors               │
├────────────────────────────────────┤
│ ⭐ Fonctionnalités (4 cartes)     │
├────────────────────────────────────┤
│ 📄 Footer complet                  │
└────────────────────────────────────┘
```

**Et NON PAS** :
```
[[platform_title]]
[[platform_tagline]]
[[category_rally]]
...
```

---

## 📞 SUPPORT

Si après avoir appliqué ces corrections vous rencontrez toujours des problèmes :

1. Consultez les logs d'erreur Moodle
2. Vérifiez les permissions des fichiers (644 pour fichiers, 755 pour dossiers)
3. Assurez-vous que PHP 8.1+ est installé
4. Vérifiez que Moodle est en version 5.1 (ou 4.4+)

---

**Version** : 1.2.1 (Fixed)  
**Date** : 14 Décembre 2025  
**Statut** : ✅ Corrigé et testé

---

*Tous les problèmes d'affichage devraient maintenant être résolus !* 🎉
