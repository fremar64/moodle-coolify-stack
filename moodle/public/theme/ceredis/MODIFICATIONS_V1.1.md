# 🎨 MODIFICATIONS VISUELLES DU THÈME CEREDIS

## Version 1.1 - Décembre 2025

---

## 📋 RÉSUMÉ DES CHANGEMENTS

### ✅ Modifications effectuées :

1. **Image de fond Hero** - Ajout d'une photo d'élèves en arrière-plan
2. **Logo repositionné** - En haut à gauche dans un cadre blanc arrondi
3. **Titre en jaune/orange** - Style "Billes & Calculs" (#FFC107)
4. **Textes modifiés** - "École en ligne" / "Environnement numérique d'apprentissage adaptatif"
5. **Overlay amélioré** - Dégradé semi-transparent pour lisibilité

---

## 🎨 DESIGN DU HERO - AVANT / APRÈS

### AVANT (Version 1.0)

```
┌─────────────────────────────────────────────┐
│ Dégradé vert → cyan → bleu (uni)            │
│                                              │
│         🖼️  Logo centré                     │
│                                              │
│   📝 École en Ligne CEREDIS (blanc)        │
│   💬 Apprendre autrement... (blanc)         │
│                                              │
│   🔘 🔘 🔘 Boutons                         │
└─────────────────────────────────────────────┘
```

### APRÈS (Version 1.1)

```
┌─────────────────────────────────────────────┐
│ 📷 Photo élèves + overlay dégradé           │
│ ┌─────────┐                                 │
│ │🖼️ LOGO  │ (haut gauche, cadre blanc)     │
│ └─────────┘                                 │
│                                              │
│   📝 École en ligne (JAUNE/ORANGE)         │
│   💬 Environnement numérique... (blanc)     │
│                                              │
│   🔘 🔘 🔘 Boutons                         │
└─────────────────────────────────────────────┘
```

---

## 📸 IMAGES REQUISES

### 1. Logo CEREDIS

**Fichier** : `ceredis.png`  
**Emplacement** : `/theme/ceredis/pix/ceredis.png`

**Spécifications** :
- Format : PNG transparent
- Dimensions : ~250x50px
- Poids : < 50KB

### 2. Photo de fond Hero

**Fichier** : `hero-students.jpg`  
**Emplacement** : `/theme/ceredis/pix/hero-students.jpg`

**Spécifications** :
- Format : JPG ou PNG
- Dimensions : 1920x600px minimum
- Poids : < 500KB (optimisé)
- Contenu : Élèves avec matériel pédagogique

**Source recommandée** :
Extrayez l'image de fond de votre application "Billes & Calculs" :
`https://enaa-numeratie.ceredis.net/`

---

## 🎨 COULEURS UTILISÉES

### Titre principal
```css
color: #FFC107;  /* Jaune/Orange */
text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
font-size: 3.5rem;
```

### Sous-titre
```css
color: #FFFFFF;  /* Blanc */
text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.5);
font-size: 1.5rem;
```

### Overlay du hero
```css
background: linear-gradient(135deg, 
    rgba(76, 175, 80, 0.75) 0%,   /* Vert semi-transparent */
    rgba(0, 188, 212, 0.7) 50%,   /* Cyan semi-transparent */
    rgba(33, 150, 243, 0.75) 100% /* Bleu semi-transparent */
);
```

### Cadre du logo
```css
background: rgba(255, 255, 255, 0.95); /* Blanc quasi-opaque */
border-radius: 15px;
box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
```

---

## 📝 MODIFICATIONS DES FICHIERS

### Fichiers modifiés :

1. **scss/post.scss**
   - Ajout de `background-image` pour le hero
   - Modification de `.ceredis-hero-overlay`
   - Repositionnement de `.ceredis-hero-header`
   - Style du titre en jaune/orange

2. **lang/fr/theme_ceredis.php**
   - `platform_title` : "École en ligne"
   - `platform_tagline` : "Environnement numérique d'apprentissage adaptatif"

3. **pix/README.md**
   - Instructions pour les 2 images

---

## 🚀 INSTALLATION DES MODIFICATIONS

### Si vous aviez déjà installé la version 1.0 :

1. **Remplacez les fichiers modifiés** :
   - `/theme/ceredis/scss/post.scss`
   - `/theme/ceredis/lang/fr/theme_ceredis.php`
   - `/theme/ceredis/pix/README.md`

2. **Ajoutez les images** :
   - `/theme/ceredis/pix/ceredis.png`
   - `/theme/ceredis/pix/hero-students.jpg`

3. **Videz le cache Moodle** :
   - Administration → Développement → Purger tous les caches

4. **Rechargez la page** (Ctrl+F5)

### Si vous n'avez pas encore installé le thème :

Suivez le guide **INSTALLATION_RAPIDE.md** normalement.

---

## 🎯 RÉSULTAT ATTENDU

Le hero de votre page d'accueil ressemblera désormais à celui de "Billes & Calculs" :

✅ Photo d'élèves en arrière-plan  
✅ Logo en haut à gauche dans un cadre blanc  
✅ Titre en jaune/orange bien visible  
✅ Sous-titre en blanc lisible  
✅ Overlay dégradé pour harmonie visuelle  
✅ Design cohérent avec vos autres applications  

---

## 📐 PERSONNALISATION SUPPLÉMENTAIRE

### Changer la couleur du titre

Éditez `scss/post.scss`, ligne du titre :

```scss
.ceredis-hero-title {
    color: #FFC107;  // Changez cette valeur
}
```

**Suggestions** :
- Jaune vif : `#FFD700`
- Orange : `#FF9800`
- Blanc : `#FFFFFF`

### Ajuster la taille du titre

```scss
.ceredis-hero-title {
    font-size: 3.5rem;  // Modifiez cette valeur
}
```

**Responsive** :
```scss
@media (max-width: 768px) {
    .ceredis-hero-title {
        font-size: 2.5rem;  // Plus petit sur mobile
    }
}
```

### Changer l'opacité de l'overlay

Dans `.ceredis-hero-overlay` :

```scss
background: linear-gradient(135deg, 
    rgba(76, 175, 80, 0.75) 0%,   // Changez 0.75
    rgba(0, 188, 212, 0.7) 50%,   // Changez 0.7
    rgba(33, 150, 243, 0.75) 100% // Changez 0.75
);
```

**Plus transparent** : Valeurs plus basses (0.5, 0.4)  
**Plus opaque** : Valeurs plus hautes (0.85, 0.9)

---

## 🔧 OPTIMISATION DES IMAGES

### Logo CEREDIS

```bash
# Avec ImageMagick
convert Logo_du_ceredis.png -resize 250x ceredis.png

# Compression avec pngquant
pngquant --quality=80-90 ceredis.png
```

### Photo de fond

```bash
# Redimensionner
convert hero-students.jpg -resize 1920x600^ -gravity center -extent 1920x600 hero-students-resized.jpg

# Optimiser
jpegoptim --max=85 hero-students-resized.jpg
```

**Outils en ligne** :
- https://tinypng.com/ (compression)
- https://www.iloveimg.com/ (redimensionnement)

---

## 📋 CHECKLIST DE VÉRIFICATION

Après installation, vérifiez :

- [ ] Image de fond visible dans le hero
- [ ] Logo en haut à gauche dans cadre blanc
- [ ] Titre "École en ligne" en jaune/orange
- [ ] Sous-titre "Environnement numérique..." en blanc
- [ ] Texte lisible sur la photo de fond
- [ ] Design responsive sur mobile
- [ ] Pas d'erreurs dans la console (F12)

---

## 🆘 DÉPANNAGE

### L'image de fond ne s'affiche pas

**Vérifications** :
1. Fichier existe : `/theme/ceredis/pix/hero-students.jpg`
2. Permissions : 644
3. Nom exact : `hero-students.jpg` (avec tiret, pas d'espace)
4. Cache vidé

**Solution temporaire** :
Le thème fonctionnera avec le dégradé de couleur si l'image est absente.

### Le logo ne s'affiche pas

**Vérifications** :
1. Fichier existe : `/theme/ceredis/pix/ceredis.png`
2. Format PNG avec transparence
3. Taille raisonnable (< 50KB)

### Le titre n'est pas en jaune

**Solution** :
1. Videz le cache Moodle
2. Videz le cache du navigateur (Ctrl+F5)
3. Vérifiez que `scss/post.scss` est bien modifié

### L'overlay est trop sombre/clair

Modifiez les valeurs d'opacité dans `.ceredis-hero-overlay` (voir section Personnalisation)

---

## 📊 COMPATIBILITÉ

Ces modifications sont compatibles avec :

- ✅ Moodle 4.4+
- ✅ Moodle 5.1
- ✅ Tous navigateurs modernes
- ✅ Mobile, tablette, desktop
- ✅ Version 1.0 du thème (mise à jour facile)

---

## 📞 SUPPORT

Si vous rencontrez des problèmes :

1. Consultez ce document
2. Vérifiez le fichier **INSTALLATION_RAPIDE.md**
3. Consultez les logs Moodle
4. Vérifiez la console du navigateur (F12)

---

**Version** : 1.1  
**Date** : 13 Décembre 2025  
**Auteur** : CEREDIS - L'éducation à l'ère du numérique

---

✨ **Votre plateforme a maintenant un design cohérent avec vos autres applications !**
