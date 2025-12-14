# 🎓 Thème CEREDIS pour Moodle

Thème enfant basé sur Boost pour l'École en Ligne CEREDIS.

## 📋 Prérequis

- Moodle 4.4+ (testé sur Moodle 5.1)
- Thème Boost (inclus par défaut dans Moodle)
- Droits administrateur

## 📦 Installation

### Méthode 1 : Upload via l'interface Moodle

1. Compressez le dossier `ceredis` en fichier ZIP
2. Connectez-vous en tant qu'administrateur
3. Allez dans : **Administration du site** → **Plugins** → **Installer des plugins**
4. Uploadez le fichier ZIP
5. Suivez les instructions d'installation
6. Cliquez sur **"Mettre à jour la base de données Moodle"**

### Méthode 2 : Installation manuelle via FTP/SSH

1. Uploadez le dossier `ceredis` dans : `/path/to/moodle/theme/`
2. La structure doit être : `/moodle/theme/ceredis/`
3. Allez dans : **Administration du site** → **Notifications**
4. Cliquez sur **"Mettre à jour la base de données Moodle"**

## 🎨 Activation du thème

1. Allez dans : **Administration du site** → **Apparence** → **Thèmes** → **Sélecteur de thèmes**
2. Sélectionnez **CEREDIS** comme thème par défaut
3. Enregistrez les modifications

## 📁 Structure des fichiers

```
ceredis/
├── config.php                    # Configuration principale du thème
├── version.php                   # Informations de version
├── lib.php                       # Fonctions PHP du thème
├── README.md                     # Ce fichier
│
├── lang/
│   └── fr/
│       └── theme_ceredis.php     # Chaînes de langue françaises
│
├── layout/
│   └── frontpage.php             # Layout de la page d'accueil
│
├── scss/
│   ├── pre.scss                  # Variables SCSS
│   └── post.scss                 # Styles principaux
│
├── templates/
│   └── frontpage.mustache        # Template Mustache de la page d'accueil
│
└── pix/
    └── ceredis.png               # Logo CEREDIS (à ajouter)
```

## 🖼️ Ajouter votre logo

1. Placez votre logo CEREDIS dans : `/theme/ceredis/pix/ceredis.png`
2. Format recommandé : PNG avec fond transparent
3. Dimensions recommandées : 300px de largeur, hauteur proportionnelle

## 🎨 Personnalisation des couleurs

Les couleurs CEREDIS sont définies dans `scss/pre.scss` :

```scss
$ceredis-cyan: #00BCD4;
$ceredis-navy: #1A3B5C;
$ceredis-magenta: #E91E63;
$ceredis-green: #4CAF50;
$ceredis-blue: #2196F3;
$ceredis-purple: #9C27B0;
$ceredis-orange: #FF9800;
```

Pour modifier ces couleurs :
1. Éditez le fichier `/theme/ceredis/scss/pre.scss`
2. Videz le cache Moodle
3. Rechargez la page

## 🔗 Configurer les liens des catégories

Dans le template `templates/frontpage.mustache`, modifiez les liens des boutons :

```mustache
{{! Pour le primaire - remplacez categoryid=1 par votre ID }}
<a href="{{config.wwwroot}}/course/index.php?categoryid=1">
    
{{! Pour le collège - remplacez categoryid=2 par votre ID }}
<a href="{{config.wwwroot}}/course/index.php?categoryid=2">
```

Pour trouver vos IDs de catégories :
1. Allez dans : **Administration du site** → **Cours** → **Gérer les cours et catégories**
2. Notez les IDs dans l'URL quand vous cliquez sur une catégorie

## 🧹 Vider le cache

Après toute modification du thème :

1. Allez dans : **Administration du site** → **Développement** → **Purger tous les caches**
2. Cliquez sur **"Purger tous les caches"**
3. Rechargez votre page (Ctrl+F5)

## 🎯 Fonctionnalités

### Page d'accueil

- ✅ Hero section avec dégradé et animations
- ✅ Message de bienvenue
- ✅ Cartes pour Primaire et Collège
- ✅ Section des fonctionnalités
- ✅ Design responsive (mobile, tablette, desktop)
- ✅ Animations CSS natives (bulles flottantes)

### Styles globaux

- ✅ Palette de couleurs CEREDIS
- ✅ Typographie optimisée
- ✅ Boutons personnalisés
- ✅ Transitions fluides
- ✅ Ombres douces

## 🔧 Dépannage

### Le thème ne s'active pas

- Vérifiez que tous les fichiers sont bien uploadés
- Vérifiez les permissions (755 pour les dossiers, 644 pour les fichiers)
- Consultez les logs : **Administration du site** → **Rapports** → **Logs**

### Les styles ne s'appliquent pas

- Videz le cache Moodle
- Videz le cache de votre navigateur (Ctrl+F5)
- Vérifiez que le fichier `scss/post.scss` est bien présent
- Vérifiez la console du navigateur (F12) pour les erreurs

### Le logo ne s'affiche pas

- Vérifiez que le fichier existe bien dans `/theme/ceredis/pix/ceredis.png`
- Vérifiez les permissions du fichier
- Essayez avec un autre format d'image

### Les animations ne fonctionnent pas

- Vérifiez que JavaScript est activé dans votre navigateur
- Consultez la console du navigateur (F12) pour les erreurs
- Les animations CSS devraient fonctionner dans tous les navigateurs modernes

## 📱 Compatibilité

| Navigateur | Version | Support |
|------------|---------|---------|
| Chrome | 90+ | ✅ Complet |
| Firefox | 88+ | ✅ Complet |
| Safari | 14+ | ✅ Complet |
| Edge | 90+ | ✅ Complet |
| Mobile (iOS/Android) | Moderne | ✅ Complet |

## 🆕 Mises à jour

Pour mettre à jour le thème :

1. Sauvegardez vos modifications personnalisées
2. Remplacez les fichiers du thème
3. Allez dans : **Administration du site** → **Notifications**
4. Suivez les instructions de mise à jour
5. Videz le cache

## 📄 Licence

Ce thème est fourni sous licence MIT.

## 🤝 Support

Pour toute question ou problème :

- Consultez la documentation Moodle : https://docs.moodle.org/
- Forums Moodle : https://moodle.org/mod/forum/

## 👨‍💻 Développement

Développé pour CEREDIS - École en Ligne  
**"L'éducation à l'ère du numérique"**

Version : 1.0  
Date : Décembre 2025

---

**Bon apprentissage ! 🚀**
