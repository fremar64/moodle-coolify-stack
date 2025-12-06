# 🔄 Guide de Mise à Jour - Moodle Coolify Stack

Ce guide vous accompagne pour mettre à jour votre installation Moodle en toute sécurité.

---

## 🧭 1️⃣ Préparer une sauvegarde complète avant toute mise à jour

Avant toute mise à jour, fais toujours une sauvegarde de :

* **la base de données** (conteneur MariaDB/MySQL)
* **le dossier `moodledata/`**
* **le dossier `moodle/` (code source actuel)**

Tu peux le faire rapidement avec :

```bash
# Sauvegarde de la base de données
docker exec -t moodle_db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} moodle > backup-moodle-$(date +%F).sql

# Sauvegarde des données Moodle (volumes Docker)
docker run --rm -v moodle-coolify-stack_moodle_data:/data -v $(pwd):/backup alpine tar czf /backup/backup-moodledata-$(date +%F).tar.gz -C /data .

# Sauvegarde du code source
tar czf backup-moodle-code-$(date +%F).tar.gz moodle
```

**💡 Conseil :** Stocke ces sauvegardes dans un endroit sûr (Dropbox, serveur externe, etc.)

---

## 🔁 2️⃣ Identifier la version cible de Moodle

Va sur la page officielle des branches :
👉 [https://github.com/moodle/moodle/branches](https://github.com/moodle/moodle/branches)

Par exemple :

* `MOODLE_404_STABLE` → Moodle 4.4.x
* `MOODLE_501_STABLE` → Moodle 5.0.1 (actuel)
* `MOODLE_502_STABLE` → Moodle 5.0.2
* `MOODLE_503_STABLE` → Moodle 5.0.3

**⚠️ Important :** Respecte toujours l'ordre des versions (ne saute pas de versions majeures).

---

## 🧩 3️⃣ Mettre à jour le code source dans le conteneur / le volume

### Option A — Si tu as cloné le dépôt Moodle localement

Tu peux te rendre dans le dossier `moodle/` :

```bash
cd moodle
git fetch --all
git checkout MOODLE_502_STABLE  # Remplace par la version souhaitée
```

### Option B — Si tu veux repartir à neuf

Supprime le dossier `moodle/` (sans toucher à `moodledata/`) :

```bash
rm -rf moodle
git clone -b MOODLE_502_STABLE https://github.com/moodle/moodle.git moodle
rm -rf moodle/.git  # Supprime l'historique Git pour éviter les conflits
```

---

## ⚙️ 4️⃣ Mettre à jour les dépendances PHP et les permissions

Arrête temporairement les services :

```bash
docker compose down
```

Démarre uniquement la base de données pour la mise à jour :

```bash
docker compose up -d db redis
```

Lance le container Moodle pour la mise à jour :

```bash
docker compose run --rm moodle bash -c "
    composer install --no-dev --optimize-autoloader &&
    chown -R www-data:www-data /var/www/html &&
    chown -R www-data:www-data /var/www/moodledata
"
```

---

## 🧠 5️⃣ Lancer la mise à jour via l'interface Moodle

### Option A : Via l'interface web (recommandée)

1. Redémarre tous les services :
   ```bash
   docker compose up -d
   ```

2. Ouvre ton site :
   👉 [https://ecole-en-ligne.ceredis.net](https://ecole-en-ligne.ceredis.net)

3. Connecte-toi en administrateur.

4. Moodle détectera automatiquement la nouvelle version.

5. Suis les étapes de mise à jour (Moodle va migrer la base de données).

### Option B : Via la ligne de commande

```bash
docker compose exec moodle php /var/www/html/admin/cli/upgrade.php --non-interactive
```

---

## ✅ 6️⃣ Redémarrer et vérifier

```bash
# Redémarrage complet
docker compose down
docker compose up -d

# Vérification des logs
docker compose logs -f moodle
```

Ensuite, vérifie dans **Administration du site → Notifications** que :
- La version affichée correspond bien à la nouvelle (ex. : *Moodle 5.0.2+*)
- Aucune notification d'erreur n'apparaît
- Les plugins sont compatibles

---

## 🚨 En cas de problème

### Rollback rapide

Si quelque chose ne fonctionne pas :

1. **Arrête les services :**
   ```bash
   docker compose down
   ```

2. **Restaure le code source :**
   ```bash
   rm -rf moodle
   tar xzf backup-moodle-code-$(date +%F).tar.gz
   ```

3. **Restaure la base de données :**
   ```bash
   docker compose up -d db
   docker exec -i moodle_db mysql -u root -p${MYSQL_ROOT_PASSWORD} moodle < backup-moodle-$(date +%F).sql
   ```

4. **Redémarre :**
   ```bash
   docker compose up -d
   ```

### Vérifications post-mise à jour

- [ ] Version Moodle correcte dans l'administration
- [ ] Connexion utilisateurs fonctionnelle
- [ ] Cours accessibles
- [ ] Plugins personnalisés fonctionnels
- [ ] Certificats SSL valides
- [ ] Sauvegardes automatiques actives

---

## 📚 Ressources utiles

- [Documentation officielle de mise à jour Moodle](https://docs.moodle.org/en/Upgrading)
- [Notes de version Moodle](https://docs.moodle.org/dev/Releases)
- [Dépôt GitHub Moodle](https://github.com/moodle/moodle)

---

**⚠️ Rappel important :** Ne jamais faire de mise à jour directement en production sans avoir testé sur un environnement de staging.