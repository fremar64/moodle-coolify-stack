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

1. Dans Coolify, va dans **Environment Variables**
2. Copie le contenu de `.env.example` et adapte :
   - `DOMAIN=ecole-en-ligne.ceredis.net`
   - `MYSQL_ROOT_PASSWORD=TonMotDePasseSecurise!`
   - `MOODLE_DB_PASSWORD=TonAutreMotDePasse!`
   - `MOODLE_ADMIN_PASS=MotDePasseAdmin!`
   - `DROPBOX_TOKEN={"access_token":"TON_TOKEN_DROPBOX",...}`

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

1. **Erreur de connexion base de données** :
   - Vérifiez les variables `MOODLE_DB_PASSWORD` et `MYSQL_ROOT_PASSWORD`
   - Attendez que le conteneur MariaDB soit complètement démarré

2. **Certificat SSL non généré** :
   - Vérifiez que le DNS pointe bien vers votre serveur
   - Attendez quelques minutes pour la propagation DNS

3. **Performances lentes** :
   - Vérifiez que Redis est bien actif
   - Augmentez la mémoire PHP si nécessaire

---

### 👨‍💻 Auteur

**Projet :** CEREDIS – Centre de Ressources Didactiques et Scolaires Numériques  
**Responsable :** Frédéric Ouamba  
**Dépôt GitHub :** [fremar64/moodle-coolify-stack](https://github.com/fremar64/moodle-coolify-stack)  
**Domaine de déploiement :** [https://ecole-en-ligne.ceredis.net](https://ecole-en-ligne.ceredis.net)