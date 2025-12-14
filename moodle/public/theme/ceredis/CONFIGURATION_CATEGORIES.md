# 🎯 CONFIGURATION DES CATÉGORIES DE COURS

## Version 1.2 - Avec 4 catégories

---

## 📋 VOS CATÉGORIES

Vous avez configuré 4 catégories dans Moodle :

1. **00. Rallye scolaire**
2. **01. Éducation maternelle**
3. **02. École primaire**
4. **03. Collège**

---

## 🔍 TROUVER LES IDS DE VOS CATÉGORIES

### Méthode 1 : Via l'interface Moodle

1. Connectez-vous en tant qu'administrateur
2. Allez dans : **Administration du site** → **Cours** → **Gérer les cours et catégories**
3. Vous verrez vos catégories listées
4. Cliquez sur une catégorie
5. Dans l'URL du navigateur, notez le `categoryid=X`

**Exemple d'URL** :
```
https://ecole-en-ligne.ceredis.net/course/management.php?categoryid=5
                                                                  ↑
                                                            ID de la catégorie
```

### Méthode 2 : Via la base de données

Si vous avez accès à la base de données MySQL/MariaDB :

```sql
SELECT id, name, idnumber 
FROM mdl_course_categories 
WHERE name LIKE '%Rallye%' 
   OR name LIKE '%maternelle%' 
   OR name LIKE '%primaire%' 
   OR name LIKE '%Collège%'
ORDER BY name;
```

---

## 📝 NOTEZ VOS IDS ICI

Remplissez ce tableau avec vos vrais IDs :

| Catégorie | Nom Moodle | ID trouvé | À remplacer dans le template |
|-----------|------------|-----------|------------------------------|
| Rallye | 00. Rallye scolaire | _____ | categoryid=1 |
| Maternelle | 01. Éducation maternelle | _____ | categoryid=2 |
| Primaire | 02. École primaire | _____ | categoryid=3 |
| Collège | 03. Collège | _____ | categoryid=4 |

---

## ✏️ MODIFIER LE TEMPLATE

### Fichier à éditer :

```
/theme/ceredis/templates/frontpage.mustache
```

### Rechercher et remplacer :

1. **Pour le Rallye scolaire** :
   - Cherchez : `categoryid=1`
   - Remplacez par : `categoryid=VOTRE_ID_RALLYE`

2. **Pour l'Éducation maternelle** :
   - Cherchez : `categoryid=2`
   - Remplacez par : `categoryid=VOTRE_ID_MATERNELLE`

3. **Pour l'École primaire** :
   - Cherchez : `categoryid=3`
   - Remplacez par : `categoryid=VOTRE_ID_PRIMAIRE`

4. **Pour le Collège** :
   - Cherchez : `categoryid=4`
   - Remplacez par : `categoryid=VOTRE_ID_COLLEGE`

### Exemple concret :

Si vos IDs sont : Rallye=5, Maternelle=6, Primaire=7, Collège=8

**AVANT** :
```html
<a href="{{config.wwwroot}}/course/index.php?categoryid=1">
<a href="{{config.wwwroot}}/course/index.php?categoryid=2">
<a href="{{config.wwwroot}}/course/index.php?categoryid=3">
<a href="{{config.wwwroot}}/course/index.php?categoryid=4">
```

**APRÈS** :
```html
<a href="{{config.wwwroot}}/course/index.php?categoryid=5">
<a href="{{config.wwwroot}}/course/index.php?categoryid=6">
<a href="{{config.wwwroot}}/course/index.php?categoryid=7">
<a href="{{config.wwwroot}}/course/index.php?categoryid=8">
```

---

## 🎨 PERSONNALISER LES DESCRIPTIONS

Vous pouvez aussi modifier les descriptions de chaque catégorie.

### Fichier à éditer :

```
/theme/ceredis/lang/fr/theme_ceredis.php
```

### Chaînes à personnaliser :

```php
// Rallye scolaire
$string['category_rally'] = 'Rallye scolaire';
$string['category_rally_desc'] = 'Défis et compétitions éducatives pour tous les niveaux';

// Éducation maternelle
$string['category_preschool'] = 'Éducation maternelle';
$string['category_preschool_desc'] = 'Apprentissages ludiques pour les tout-petits (3-6 ans)';

// École primaire
$string['category_primary'] = 'École primaire';
$string['category_primary_desc'] = 'Du CP au CM2 : lectures, calculs, découvertes';

// Collège
$string['category_secondary'] = 'Collège';
$string['category_secondary_desc'] = 'De la 6ème à la 3ème : approfondissement et excellence';
```

---

## 🎯 ORDRE D'AFFICHAGE

Les catégories s'affichent dans cet ordre sur la page d'accueil :

```
┌────────────────┬────────────────┐
│   🏁 RALLYE    │  🧸 MATERNELLE │
├────────────────┼────────────────┤
│  🎒 PRIMAIRE   │   🎓 COLLÈGE   │
└────────────────┴────────────────┘
```

Sur mobile (< 768px), elles s'empilent verticalement :

```
┌────────────────┐
│   🏁 RALLYE    │
├────────────────┤
│  🧸 MATERNELLE │
├────────────────┤
│  🎒 PRIMAIRE   │
├────────────────┤
│   🎓 COLLÈGE   │
└────────────────┘
```

---

## 🎨 COULEURS DES CATÉGORIES

Chaque catégorie a sa propre palette de couleurs :

### Rallye scolaire
- Bandeau : Orange → Jaune (#FF9800 → #FFD700)
- Icône : Dégradé orange-jaune
- Bouton : Jaune (warning)

### Éducation maternelle
- Bandeau : Rose → Magenta (#FF69B4 → #E91E63)
- Icône : Dégradé rose-magenta
- Bouton : Cyan (info)

### École primaire
- Bandeau : Vert → Cyan (#4CAF50 → #00BCD4)
- Icône : Dégradé vert-cyan
- Bouton : Vert (success)

### Collège
- Bandeau : Bleu → Violet (#2196F3 → #9C27B0)
- Icône : Dégradé bleu-violet
- Bouton : Bleu (primary)

---

## 🔄 APRÈS MODIFICATION

**N'oubliez pas de** :

1. ✅ Enregistrer le fichier `frontpage.mustache`
2. ✅ Vider le cache Moodle
   - **Administration du site** → **Développement** → **Purger tous les caches**
3. ✅ Recharger la page (Ctrl+F5)
4. ✅ Tester tous les liens

---

## ✅ CHECKLIST DE VÉRIFICATION

- [ ] IDs des 4 catégories trouvés
- [ ] IDs modifiés dans `frontpage.mustache`
- [ ] Cache Moodle vidé
- [ ] Page d'accueil rechargée
- [ ] Clic sur "Rallye scolaire" → bonne page
- [ ] Clic sur "Éducation maternelle" → bonne page
- [ ] Clic sur "École primaire" → bonne page
- [ ] Clic sur "Collège" → bonne page
- [ ] Responsive testé sur mobile

---

## 🆘 DÉPANNAGE

### Les liens ne fonctionnent pas

**Problème** : Clic sur une catégorie → erreur ou mauvaise page

**Solution** :
1. Vérifiez que les IDs sont corrects
2. Testez manuellement l'URL : `https://ecole-en-ligne.ceredis.net/course/index.php?categoryid=X`
3. Assurez-vous que les catégories existent et sont visibles

### Les catégories ne s'affichent pas

**Problème** : Les cartes sont vides ou manquantes

**Solution** :
1. Videz le cache Moodle
2. Vérifiez que le fichier `frontpage.mustache` est bien enregistré
3. Consultez les logs Moodle pour les erreurs

### Les couleurs sont incorrectes

**Problème** : Toutes les catégories ont la même couleur

**Solution** :
1. Vérifiez que le fichier `scss/post.scss` contient les styles des catégories
2. Videz le cache Moodle + navigateur
3. Rechargez avec Ctrl+F5

---

## 📊 STRUCTURE COMPLÈTE DE LA PAGE

```
┌───────────────────────────────────────┐
│  HERO (image + logo + titre)          │
├───────────────────────────────────────┤
│  Message de bienvenue                 │
├───────────────────────────────────────┤
│  4 CATÉGORIES (grille 2x2)           │
│  - Rallye scolaire                    │
│  - Éducation maternelle               │
│  - École primaire                     │
│  - Collège                            │
├───────────────────────────────────────┤
│  CAROUSEL DE SPONSORS                 │
│  (logos défilants)                    │
├───────────────────────────────────────┤
│  FONCTIONNALITÉS (4 cartes)          │
│  - Gamification                       │
│  - Suivi progrès                      │
│  - Accompagnement                     │
│  - Récompenses                        │
├───────────────────────────────────────┤
│  FOOTER (4 colonnes)                  │
│  - À propos                           │
│  - Liens rapides                      │
│  - Support                            │
│  - Contact                            │
│  - Copyright                          │
└───────────────────────────────────────┘
```

---

## 🎓 EXEMPLE COMPLET

Voici un exemple de configuration complète :

### Catégories Moodle :

```
ID  | Nom                        | Icône
----|----------------------------|-------
5   | 00. Rallye scolaire       | 🏁
6   | 01. Éducation maternelle  | 🧸
7   | 02. École primaire        | 🎒
8   | 03. Collège               | 🎓
```

### Modifications dans frontpage.mustache :

```mustache
{{! Rallye scolaire }}
<a href="{{config.wwwroot}}/course/index.php?categoryid=5">

{{! Éducation maternelle }}
<a href="{{config.wwwroot}}/course/index.php?categoryid=6">

{{! École primaire }}
<a href="{{config.wwwroot}}/course/index.php?categoryid=7">

{{! Collège }}
<a href="{{config.wwwroot}}/course/index.php?categoryid=8">
```

---

**C'est tout ! Votre page d'accueil affichera désormais vos 4 catégories de cours correctement configurées ! 🎉**
