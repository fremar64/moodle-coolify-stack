# 🚀 INSTALLATION RAPIDE - Thème CEREDIS

## ⏱️ Temps estimé : 10 minutes

---

## ✅ ÉTAPE 1 : Préparer le logo (2 min)

1. Prenez votre logo CEREDIS (format PNG recommandé)
2. Renommez-le en : `ceredis.png`
3. Dimensions recommandées : 300px de largeur
4. **Gardez-le de côté** pour l'étape 4

---

## ✅ ÉTAPE 2 : Upload du thème (3 min)

### Option A : Via l'interface Moodle (recommandé)

1. **Compressez** le dossier `ceredis` en fichier ZIP
   - Sur Windows : Clic droit → Envoyer vers → Dossier compressé
   - Sur Mac : Clic droit → Compresser
   - Sur Linux : `zip -r ceredis.zip ceredis/`

2. Connectez-vous à Moodle en tant qu'**administrateur**

3. Allez dans : **Administration du site** → **Plugins** → **Installer des plugins**

4. Cliquez sur **"Choisir un fichier"**

5. Sélectionnez votre fichier `ceredis.zip`

6. Cliquez sur **"Installer le plugin depuis le fichier ZIP"**

7. Vérifiez que le type de plugin est : **Thème (theme)**

8. Cliquez sur **"Continuer"**

9. Lisez les informations et cliquez sur **"Continuer"**

10. Attendez la fin de l'installation

### Option B : Via FTP/SSH

1. Connectez-vous à votre serveur (FTP ou SSH)

2. Uploadez le dossier `ceredis` dans : `/path/to/moodle/theme/`

3. Vérifiez la structure : `/moodle/theme/ceredis/config.php` doit exister

4. Permissions recommandées :
   - Dossiers : 755
   - Fichiers : 644

5. Dans Moodle : **Administration du site** → **Notifications**

6. Cliquez sur **"Mettre à jour la base de données Moodle"**

---

## ✅ ÉTAPE 3 : Activer le thème (1 min)

1. Allez dans : **Administration du site** → **Apparence** → **Thèmes** → **Sélecteur de thèmes**

2. Sous **"Thème par défaut"**, sélectionnez : **CEREDIS**

3. Cliquez sur **"Enregistrer les modifications"**

✨ Le thème est maintenant activé !

---

## ✅ ÉTAPE 4 : Ajouter les images (3 min)

### Image 1 : Logo CEREDIS

1. Prenez votre fichier `Logo_du_ceredis.png`
2. Renommez-le en : `ceredis.png`
3. Via FTP/SSH, uploadez-le dans :
   ```
   /moodle/theme/ceredis/pix/ceredis.png
   ```

### Image 2 : Photo de fond (élèves)

1. Prenez une photo d'élèves en apprentissage (comme celle de "Billes & Calculs")
2. Renommez-la en : `hero-students.jpg`
3. Optimisez-la si possible (< 500KB)
4. Uploadez-la dans :
   ```
   /moodle/theme/ceredis/pix/hero-students.jpg
   ```

**Note** : Le thème fonctionnera même sans ces images (fond de couleur par défaut), mais elles sont recommandées pour un meilleur rendu visuel.

---

## ✅ ÉTAPE 5 : Configurer les liens (2 min)

### Trouver les IDs de vos catégories

1. Allez dans : **Administration du site** → **Cours** → **Gérer les cours et catégories**

2. Cliquez sur votre catégorie **"Primaire"**

3. Dans l'URL, notez le `categoryid=X`
   - Exemple : `...categoryid=5` → votre ID primaire est **5**

4. Faites de même pour la catégorie **"Collège"**

### Modifier les liens dans le template

1. Éditez le fichier : `/theme/ceredis/templates/frontpage.mustache`

2. Recherchez (Ctrl+F) : `categoryid=1`

3. Remplacez par votre ID primaire réel (ex: `categoryid=5`)

4. Recherchez : `categoryid=2`

5. Remplacez par votre ID collège réel (ex: `categoryid=6`)

6. **Enregistrez** le fichier

---

## ✅ ÉTAPE 6 : Vider le cache (1 min)

**IMPORTANT** : Pour que les changements soient visibles

1. Allez dans : **Administration du site** → **Développement** → **Purger tous les caches**

2. Cliquez sur **"Purger tous les caches"**

3. Attendez quelques secondes

4. Actualisez votre page d'accueil (Ctrl+F5 ou Cmd+Shift+R)

---

## ✅ ÉTAPE 7 : Tester (1 min)

1. Ouvrez votre page d'accueil : `https://ecole-en-ligne.ceredis.net`

2. Vérifiez que vous voyez :
   - ✅ Le hero avec dégradé vert-cyan-bleu
   - ✅ Votre logo (ou l'espace pour le logo)
   - ✅ Le titre "École en Ligne CEREDIS"
   - ✅ Les 3 boutons d'action
   - ✅ Le message de bienvenue
   - ✅ Les 2 cartes (Primaire / Collège)
   - ✅ La section des fonctionnalités
   - ✅ Les animations des bulles

3. Testez sur mobile/tablette (mode responsive du navigateur : F12)

---

## 🎨 PERSONNALISATION OPTIONNELLE

### Changer les couleurs

Éditez : `/theme/ceredis/scss/pre.scss`

```scss
// Modifiez ces valeurs selon vos préférences
$ceredis-cyan: #00BCD4;      // Votre cyan
$ceredis-green: #4CAF50;      // Votre vert
$ceredis-blue: #2196F3;       // Votre bleu
```

N'oubliez pas de vider le cache après !

### Modifier les textes

Éditez : `/theme/ceredis/lang/fr/theme_ceredis.php`

Vous pouvez changer :
- Le titre de la plateforme
- Le slogan
- Les descriptions des niveaux
- Les noms des matières
- Tous les textes affichés

---

## 🔧 DÉPANNAGE RAPIDE

### Le thème ne s'affiche pas

1. Videz le cache Moodle
2. Videz le cache de votre navigateur (Ctrl+F5)
3. Vérifiez que tous les fichiers sont bien uploadés
4. Consultez les logs Moodle

### Le logo ne s'affiche pas

1. Vérifiez le chemin : `/theme/ceredis/pix/ceredis.png`
2. Vérifiez les permissions (644)
3. Essayez un autre format d'image

### Les liens des catégories ne fonctionnent pas

1. Vérifiez que vous avez bien modifié `frontpage.mustache`
2. Vérifiez que les IDs correspondent à vos vraies catégories
3. Videz le cache

### Erreur lors de l'installation

1. Vérifiez la version de Moodle (4.4+ requis)
2. Vérifiez que le thème Boost est bien présent
3. Consultez les logs : **Administration** → **Rapports** → **Logs**

---

## 📋 CHECKLIST FINALE

Avant de dire "c'est fini" :

- [ ] ✅ Thème CEREDIS installé
- [ ] ✅ Thème activé dans le sélecteur
- [ ] ✅ Logo uploadé dans `/pix/ceredis.png`
- [ ] ✅ IDs des catégories modifiés dans `frontpage.mustache`
- [ ] ✅ Cache vidé
- [ ] ✅ Page d'accueil testée
- [ ] ✅ Test sur mobile/tablette effectué
- [ ] ✅ Tous les liens fonctionnent

---

## 🎉 FÉLICITATIONS !

Votre plateforme CEREDIS a maintenant une page d'accueil moderne et professionnelle !

### Prochaines étapes :

1. **Créer des cours** dans vos catégories Primaire et Collège
2. **Créer des comptes élèves** et enseignants
3. **Ajouter du contenu** (ressources, activités, H5P)
4. **Configurer la gamification** (badges, niveaux)
5. **Former les utilisateurs**

---

## 📞 BESOIN D'AIDE ?

- Documentation Moodle : https://docs.moodle.org/
- Forums Moodle : https://moodle.org/mod/forum/
- Consultez le fichier `README.md` du thème

---

**Temps total** : ~10 minutes  
**Difficulté** : Facile à Moyenne  
**Résultat** : Page d'accueil professionnelle et attrayante ! 🚀

---

*Développé avec ❤️ pour CEREDIS - L'éducation à l'ère du numérique*
