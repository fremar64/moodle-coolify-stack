# 🚨 Guide de Dépannage - Moodle Coolify Stack

Ce guide vous aide à résoudre les problèmes courants lors du déploiement avec Coolify.

---

## ⚠️ Erreurs de Déploiement

### 🔴 Erreur : "port 80 already allocated"

```
Error response from daemon: failed to set up container networking:
Bind for 0.0.0.0:80 failed: port is already allocated
```

**🚨 Cause :** Vous avez un service `traefik:` dans votre `docker-compose.yml` qui entre en conflit avec le Traefik intégré de Coolify.

**✅ Solution :**
1. Supprimez complètement le service `traefik:` de votre `docker-compose.yml`
2. Supprimez le réseau `proxy` 
3. Gardez seulement les labels Traefik sur le service `moodle:`
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.moodle.rule=Host(`${DOMAIN}`)"
  - "traefik.http.routers.moodle.entrypoints=websecure"
  - "traefik.http.routers.moodle.tls.certresolver=letsencrypt"
  - "traefik.http.services.moodle.loadbalancer.server.port=80"
```

---

### 🔴 Erreur : "DOMAIN variable is not set"

```
The "DOMAIN" variable is not set. Defaulting to a blank string.
```

**🚨 Cause :** La variable d'environnement `DOMAIN` n'est pas configurée dans Coolify.

**✅ Solution :**
1. Dans Coolify, allez dans votre application → **Environment Variables**
2. Ajoutez : `DOMAIN=ecole-en-ligne.ceredis.net`
3. Redéployez l'application

---

### 🔴 Erreur : Connexion base de données échouée

```
SQLSTATE[HY000] [2002] Connection refused
```

**🚨 Causes possibles :**
- Mots de passe incorrects
- Service MariaDB pas encore démarré
- Variables d'environnement manquantes

**✅ Solutions :**
1. Vérifiez les variables dans Coolify :
```env
MYSQL_ROOT_PASSWORD=VotreMotDePasseSecurise!
MOODLE_DB_PASSWORD=VotreAutreMotDePasse!
```
2. Attendez 2-3 minutes que MariaDB soit complètement initialisé
3. Consultez les logs du service `db` dans Coolify

---

## ⚙️ Problèmes de Configuration

### 🟡 Avertissement : "Could not determine server's FQDN"

```
AH00558: apache2: Could not reliably determine the server's fully qualified domain name
```

**🚨 Cause :** Apache ne connaît pas encore le nom de domaine final.

**✅ Solution :** C'est **normal** ! Une fois que Coolify aura configuré le routage, ce message disparaîtra.

---

### 🟡 Certificat SSL non généré

**🚨 Causes possibles :**
- DNS ne pointe pas vers le serveur
- Propagation DNS en cours
- Configuration de domaine incorrecte

**✅ Solutions :**
1. Vérifiez que `ecole-en-ligne.ceredis.net` pointe vers l'IP de votre serveur Coolify
2. Testez avec : `nslookup ecole-en-ligne.ceredis.net`
3. Attendez 10-15 minutes pour la propagation DNS
4. Dans Coolify, vérifiez que le domaine est correctement configuré

---

## 🐌 Problèmes de Performance

### 🟡 Moodle lent à répondre

**✅ Solutions :**
1. Vérifiez que Redis fonctionne :
```bash
# Dans les logs Coolify, service "redis"
# Vous devriez voir : "Ready to accept connections"
```

2. Augmentez la mémoire PHP :
```env
PHP_MEMORY_LIMIT=1024M
UPLOAD_MAX_SIZE=512M
MAX_EXECUTION_TIME=600
```

3. Vérifiez les ressources du serveur (CPU, RAM)

---

## 🔍 Diagnostic des Logs

### Dans Coolify, consultez les logs de chaque service :

**🔸 Service "moodle"** - Erreurs PHP/Apache
```
[error] PHP Fatal error: ...
[error] Apache error: ...
```

**🔸 Service "db"** - Erreurs MariaDB
```
[ERROR] mysqld: Can't connect to ...
[Note] mysqld: ready for connections
```

**🔸 Service "redis"** - État du cache
```
Ready to accept connections
```

**🔸 Service "cron"** - Tâches Moodle
```
Cron completed successfully
```

---

## 🛠️ Actions de Récupération

### Redémarrage propre

1. Dans Coolify → votre application → **Stop**
2. Attendez 30 secondes
3. **Start**

### Réinitialisation complète

⚠️ **ATTENTION : Cela supprimera toutes les données !**

1. **Stop** l'application
2. **Delete** tous les volumes persistants
3. **Redeploy** l'application
4. Reconfigurer Moodle depuis zéro

---

## 📞 Support

Si les problèmes persistent :

1. **Collectez les informations :**
   - Logs complets de chaque service
   - Configuration des variables d'environnement (sans les mots de passe)
   - Version de Coolify utilisée

2. **Vérifiez :**
   - [Documentation Coolify](https://coolify.io/docs)
   - [Issues GitHub du projet](https://github.com/fremar64/moodle-coolify-stack/issues)

3. **Ressources externes :**
   - [Documentation Moodle](https://docs.moodle.org/)
   - [Forum Moodle](https://moodle.org/forums/)

---

**Dernière mise à jour :** Octobre 2025  
**Version compatible :** Coolify v4+, Moodle 5.0.1