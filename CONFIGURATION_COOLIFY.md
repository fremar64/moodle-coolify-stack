# 🔧 Configuration Domaine Coolify - URGENT

**Date** : 2025-12-11  
**Problème** : "no available server" car labels Traefik manuels retirés  
**Solution** : Configurer le domaine via l'interface Coolify

---

## 🎯 Procédure de configuration (5 minutes)

### Étape 1 : Accéder aux paramètres de l'application

1. **Ouvrir Coolify** : https://votre-serveur-coolify.com (ou IP:8000)
2. **Naviguer** : Applications → Votre application Moodle
3. **Cliquer** : **Settings** (ou **Configuration**)

### Étape 2 : Configurer le domaine

Dans la section **Domains** (ou **Domaines**) :

1. **Trouver le champ "Domain"** ou "URL"
2. **Entrer** : `ecole-en-ligne.ceredis.net`
3. **Port** : `80` (port interne du conteneur Moodle)
4. **HTTPS** : ✅ Activer (Let's Encrypt)
5. **Redirect HTTP to HTTPS** : ✅ Activer

### Étape 3 : Configuration avancée (si disponible)

Si Coolify propose des paramètres avancés :

**Upload Limits** :
- Max request body size : `512M` ou `536870912` bytes

**Timeouts** :
- Request timeout : `300s`
- Read timeout : `300s`

**Headers** :
- Pass host header : ✅ Activer
- X-Forwarded-For : ✅ Activer

### Étape 4 : Sauvegarder et redéployer

1. **Cliquer** : **Save** ou **Enregistrer**
2. **Redéployer** :
   - Bouton **Deploy** ou **Redéployer**
   - Attendre 2-3 minutes

### Étape 5 : Vérifier

```bash
curl -I https://ecole-en-ligne.ceredis.net
# Attendu : HTTP/2 200
```

Ou ouvrir dans le navigateur : https://ecole-en-ligne.ceredis.net

---

## 📸 Captures d'écran attendues

### Interface Coolify typique :

```
┌─────────────────────────────────────────┐
│ Application: Moodle                     │
├─────────────────────────────────────────┤
│ Settings                                │
│                                         │
│ ┌─ Domains ───────────────────────────┐ │
│ │                                     │ │
│ │ Domain: [ecole-en-ligne.ceredis.net]│ │
│ │ Port:   [80]                        │ │
│ │                                     │ │
│ │ [✓] Enable HTTPS (Let's Encrypt)   │ │
│ │ [✓] Redirect HTTP to HTTPS         │ │
│ │                                     │ │
│ │ [Save]                              │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 🔍 Si la section "Domains" n'existe pas

### Alternative 1 : Configuration via fichier .env Coolify

Si Coolify utilise des variables d'environnement :

1. **Aller dans** : Settings → Environment Variables
2. **Ajouter ou vérifier** :
   ```
   DOMAIN=https://ecole-en-ligne.ceredis.net
   APP_URL=https://ecole-en-ligne.ceredis.net
   ```
3. **Sauvegarder et redéployer**

### Alternative 2 : Configuration réseau Coolify

1. **Aller dans** : Networks ou Proxy
2. **Vérifier que Traefik est actif**
3. **Ajouter une route manuelle** :
   - Host : `ecole-en-ligne.ceredis.net`
   - Service : Moodle (conteneur `moodle_app`)
   - Port : `80`

### Alternative 3 : Commande CLI Coolify

Si accès SSH au serveur Coolify :

```bash
# Lister les applications
coolify application list

# Configurer le domaine (adapter l'ID)
coolify application domain set <app-id> ecole-en-ligne.ceredis.net

# Activer HTTPS
coolify application ssl enable <app-id>

# Redéployer
coolify application deploy <app-id>
```

---

## 🚨 Si aucune de ces options n'est disponible

### Solution de dernier recours : Labels Traefik via interface Coolify

Certaines versions de Coolify permettent d'ajouter des labels Docker custom :

1. **Dans Coolify** : Settings → Advanced → Custom Labels
2. **Ajouter ces labels** :

```yaml
traefik.enable=true
traefik.http.services.moodle.loadbalancer.server.port=80
traefik.http.routers.moodle.rule=Host(`ecole-en-ligne.ceredis.net`)
traefik.http.routers.moodle.entrypoints=websecure
traefik.http.routers.moodle.tls.certresolver=letsencrypt
```

3. **Sauvegarder et redéployer**

---

## ✅ Vérification finale

Après configuration, tester :

### Test 1 : DNS résolu
```bash
nslookup ecole-en-ligne.ceredis.net
# Doit pointer vers l'IP du serveur Coolify
```

### Test 2 : Port accessible
```bash
curl -v http://IP-SERVEUR-COOLIFY:80
# Doit répondre (même si erreur 404, c'est normal)
```

### Test 3 : HTTPS fonctionnel
```bash
curl -I https://ecole-en-ligne.ceredis.net
# Attendu : HTTP/2 200
```

### Test 4 : Page Moodle
```bash
curl https://ecole-en-ligne.ceredis.net/login/index.php
# Doit contenir : <title>Log in</title>
```

---

## 📞 En cas de blocage

**Informations à collecter** :

1. **Version Coolify** :
   - Dans Coolify UI : Settings → About
   - Ou SSH : `coolify --version`

2. **Logs Traefik** :
   ```bash
   docker logs <traefik-container-name> | grep moodle
   ```

3. **Configuration actuelle** :
   - Capture d'écran de la page Settings dans Coolify
   - Sortie de : `docker inspect <moodle-container-id> | grep -A 20 Labels`

4. **Test réseau** :
   ```bash
   # Depuis le serveur Coolify
   curl -I http://localhost:80 -H "Host: ecole-en-ligne.ceredis.net"
   ```

---

## 🎯 Pourquoi cette approche ?

**Coolify est conçu pour gérer Traefik automatiquement** :
- Il génère les labels Traefik dynamiquement
- Il configure les certificats SSL (Let's Encrypt)
- Il gère les redirections HTTP → HTTPS

**Les labels manuels dans docker-compose.yml** :
- Créent des conflits avec la configuration Coolify
- Peuvent être ignorés ou écrasés par Coolify
- Ne sont pas la méthode recommandée pour Coolify

**En configurant via l'UI Coolify** :
- ✅ Configuration centralisée
- ✅ Gestion SSL automatique
- ✅ Pas de conflits
- ✅ Facilite les mises à jour

---

## 📝 Après résolution

Une fois le site accessible, documenter :
1. **Méthode utilisée** (Domain UI, Custom Labels, ou CLI)
2. **Paramètres exacts** (port, domaine, options activées)
3. **Capture d'écran** de la configuration Coolify

Cela servira de référence pour :
- Futures mises à jour
- Configuration d'autres services
- Documentation de l'infrastructure

---

**Commit associé** : Retrait labels Traefik manuels  
**Prochaine étape** : Configurer le domaine via Coolify UI  
**Résultat attendu** : Site accessible en HTTPS avec certificat Let's Encrypt
