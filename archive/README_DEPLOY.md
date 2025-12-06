# 🚀 Déploiement de Moodle via Coolify (Stack Docker personnalisée)

Ce guide t'explique comment déployer un **Moodle complet (non-Bitnami)** via **Coolify**, à partir du dépôt GitHub  
👉 [`https://github.com/fremar64/moodle-coolify-stack`](https://github.com/fremar64/moodle-coolify-stack)

Cette approche repose sur **Docker Compose** et te permet de garder la main sur :
- la version du code source Moodle,
- la base de données (MariaDB),
- le cache (Redis),
- le reverse proxy (Traefik avec SSL automatique via Let's Encrypt),
- les sauvegardes automatiques vers Dropbox.

---

## 🔹 Étape 1 : Préparer ton dépôt GitHub

1. Vérifie que le dépôt contient à la racine :
```
docker-compose.yml
.env.example
.gitignore
README.md
README_DEPLOY.md
moodle/                  # Code source Moodle 5.0.1
```

2. Le code source de Moodle est déjà inclus dans le dossier `moodle/` du dépôt.

---

## 🔹 Étape 2 : Déployer avec Coolify

1. Va dans **Coolify → Applications → New Application**  
2. Choisis **Git Based → Public Repository**
3. Renseigne les informations suivantes :
   - **Repository URL** : `https://github.com/fremar64/moodle-coolify-stack`
   - **Branch** : `main`
   - **Build Path** : `/` (racine du dépôt)
4. Clique sur **Save** puis **Deploy** 🚀

---

## 🔹 Étape 3 : Configurer les variables d'environnement

⚠️ **IMPORTANT** : Coolify possède son propre Traefik intégré, n'ajoutez PAS de service Traefik dans votre docker-compose.yml !

1. Dans Coolify, va dans **Environment Variables**
2. Configure les variables **OBLIGATOIRES** suivantes :

```env
# Variables OBLIGATOIRES pour le déploiement
DOMAIN=ecole-en-ligne.ceredis.net
MYSQL_ROOT_PASSWORD=VotreMotDePasseSecurise!
MOODLE_DB_PASSWORD=VotreAutreMotDePasse!
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=VotreMotDePasseAdmin!
MOODLE_ADMIN_EMAIL=admin@ceredis.net
```

3. Variables **OPTIONNELLES** (pour intégrations avancées) :
```env
# Paramètres système
TIMEZONE=Africa/Brazzaville
PHP_MEMORY_LIMIT=512M
UPLOAD_MAX_SIZE=256M

# Intégrations externes (optionnel)
LRS_ENDPOINT=https://learning-locker.ceredis.net/data/xAPI/
LTI_PLATFORM_URL=https://sesalab.ceredis.net
DROPBOX_TOKEN={"access_token":"VOTRE_TOKEN",...}
```

---

## 🔹 Étape 4 : Configurer ton domaine

1. Une fois l'application créée, ouvre-la dans Coolify
2. Va dans **Domains → Add Domain** et ajoute :  
   `https://ecole-en-ligne.ceredis.net`
3. Coolify générera automatiquement un **certificat SSL (Let's Encrypt)**
4. Vérifie que le **DNS OVH** du domaine `ecole-en-ligne.ceredis.net` pointe bien vers ton serveur Contabo

---

## 🔹 Étape 5 : Installation initiale de Moodle

1. Accède à ton site :  
   👉 [https://ecole-en-ligne.ceredis.net](https://ecole-en-ligne.ceredis.net)
2. Suis l'assistant d'installation :
   - Choisis la **langue** : Français
   - Base de données :
     - **Hôte** : `db`
     - **Nom** : `moodle`
     - **Utilisateur** : `moodle`
     - **Mot de passe** : défini dans tes variables d'environnement
   - Crée le compte **administrateur Moodle**
3. Moodle se configurera automatiquement et sera prêt à l'emploi 🎓

---

## 🔹 Étape 6 : Connexions externes

### 🔸 a) Intégration avec SeSaLab
1. Dans Moodle : *Administration du site → Plugins → Outils externes*
2. Crée un **outil externe (LTI)** avec :
   - **URL de la plateforme** : `https://sesalab.ceredis.net`
   - **Clé et secret** : fournis par l'application SeSaLab

### 🔸 b) Connexion au LRS Learning Locker
1. Dans Moodle : *Administration du site → Serveur → Paramètres du LRS*
2. Configure ton **endpoint xAPI** :
   - **URL** : `https://learning-locker.ceredis.net/data/xAPI/`
   - **Authentification** : token API Learning Locker

---

## 🔹 Étape 7 : Sauvegardes automatiques vers Dropbox

Le conteneur `backup` (inclus dans le `docker-compose.yml`) génère :
- des sauvegardes quotidiennes du dossier `moodledata`
- des dumps de la base MariaDB

Ces fichiers sont envoyés vers ton espace **Dropbox** via l'API (token défini dans les variables d'environnement).

---

## 🔹 Étape 8 : Mettre à jour Moodle

Pour mettre à jour Moodle vers une version plus récente, consulte le guide :
👉 **[UPDATE_GUIDE.md](UPDATE_GUIDE.md)**

---

## ✅ Avantages de cette approche

| Fonctionnalité               | Description                             |
| ---------------------------- | --------------------------------------- |
| 🔧 Personnalisation complète | Code source Moodle libre et modifiable  |
| 🧱 Stack modulaire           | MariaDB + Redis + Traefik + Moodle      |
| 🔒 Sécurité                  | HTTPS automatique + volumes persistants |
| 🔁 Mises à jour faciles      | Basées sur Git et scripts automatisés   |
| ☁️ Sauvegardes Cloud         | Intégration Dropbox                     |
| 🤝 Interopérabilité          | LTI (SeSaLab) + xAPI (Learning Locker)  |

---

## 🚨 Dépannage

### Problèmes courants

1. **Erreur "port 80 already allocated"** :
   - ❌ Vous avez probablement laissé le service `traefik:` dans docker-compose.yml
   - ✅ Supprimez complètement ce service, Coolify a son propre Traefik intégré

2. **Erreur "DOMAIN variable is not set"** :
   - ❌ La variable DOMAIN n'est pas configurée dans Coolify
   - ✅ Ajoutez `DOMAIN=ecole-en-ligne.ceredis.net` dans Environment Variables

3. **Erreur de connexion base de données** :
   - ❌ Mots de passe incorrects ou non configurés
   - ✅ Vérifiez `MYSQL_ROOT_PASSWORD` et `MOODLE_DB_PASSWORD` dans Environment Variables
   - ✅ Attendez que le conteneur MariaDB soit complètement démarré

4. **Certificat SSL non généré** :
   - ❌ DNS ne pointe pas vers votre serveur
   - ✅ Vérifiez que le DNS pointe bien vers votre serveur Coolify
   - ✅ Attendez quelques minutes pour la propagation DNS

5. **Performances lentes** :
   - ❌ Ressources insuffisantes ou Redis inactif
   - ✅ Vérifiez que Redis est bien actif
   - ✅ Augmentez `PHP_MEMORY_LIMIT` si nécessaire

### Logs utiles

```bash
# Dans Coolify, consultez les logs de chaque service :
# - Service "moodle" pour les erreurs PHP/Apache
# - Service "db" pour les erreurs de base de données  
# - Service "redis" pour les erreurs de cache
```

---

### 👨‍💻 Auteur

**Projet :** CEREDIS – Centre de Ressources Didactiques et Scolaires Numériques  
**Responsable :** Frédéric Ouamba  
**Dépôt GitHub :** [fremar64/moodle-coolify-stack](https://github.com/fremar64/moodle-coolify-stack)  
**Domaine de déploiement :** [https://ecole-en-ligne.ceredis.net](https://ecole-en-ligne.ceredis.net)