# 📁 Logos des Sponsors

## Images requises

Placez les logos de vos partenaires et sponsors dans ce dossier.

### Fichiers à créer :

1. **sponsor1.png** - Premier partenaire
2. **sponsor2.png** - Deuxième partenaire  
3. **sponsor3.png** - Troisième partenaire
4. **sponsor4.png** - Quatrième partenaire
5. **sponsor5.png** - Cinquième partenaire

### Spécifications :

- **Format** : PNG avec fond transparent (recommandé)
- **Dimensions** : 200x200px (carrés)
- **Poids** : < 50KB par logo
- **Contenu** : Logo centré, bon contraste

### Chemin complet :

```
/moodle/theme/ceredis/pix/sponsors/sponsor1.png
/moodle/theme/ceredis/pix/sponsors/sponsor2.png
/moodle/theme/ceredis/pix/sponsors/sponsor3.png
/moodle/theme/ceredis/pix/sponsors/sponsor4.png
/moodle/theme/ceredis/pix/sponsors/sponsor5.png
```

### Modifier les noms dans le template

Si vous voulez changer les noms affichés sous les logos, éditez :
`/theme/ceredis/templates/frontpage.mustache`

Cherchez la section "Sponsors Carousel" et modifiez les `alt` et les `ceredis-sponsor-name`.

### Ajouter plus de sponsors

1. Dupliquez un bloc `.ceredis-sponsor-item` dans le template
2. Ajoutez le nouveau logo dans ce dossier
3. N'oubliez pas de vider le cache Moodle !

### Si vous n'avez pas encore les logos

Le carousel fonctionnera même sans les images (espaces vides avec fond gris), mais ajoutez-les dès que possible pour un meilleur rendu visuel.

### Logos placeholders

Si vous voulez des placeholders temporaires, vous pouvez :

1. Créer des images avec le nom du sponsor
2. Utiliser https://placehold.co/200x200/png pour générer des placeholders
3. Les remplacer plus tard par les vrais logos

### Optimisation

Pour de meilleures performances :
- Compressez avec https://tinypng.com/
- Format PNG-8 si possible (moins de couleurs)
- Fond transparent pour s'adapter au design
