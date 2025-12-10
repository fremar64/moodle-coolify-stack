# 🔒 Guide de Sécurisation - Moodle CEREDIS

## Vue d'ensemble

Ce guide fournit les bonnes pratiques et étapes concrètes pour sécuriser votre installation Moodle en production éducative.

## Table des matières

1. [Sécurité des secrets et mots de passe](#1-sécurité-des-secrets-et-mots-de-passe)
2. [Configuration SSL/TLS](#2-configuration-ssltls)
3. [Sécurité de la base de données](#3-sécurité-de-la-base-de-données)
4. [Permissions et isolation](#4-permissions-et-isolation)
5. [Pare-feu et réseau](#5-pare-feu-et-réseau)
6. [Audit et monitoring](#6-audit-et-monitoring)
7. [Sauvegardes sécurisées](#7-sauvegardes-sécurisées)
8. [Checklist de production](#8-checklist-de-production)

---

## 1. Sécurité des secrets et mots de passe

### 1.1 Générer des secrets forts

**Ne jamais utiliser les valeurs par défaut de `.env.example` !**

```bash
# Générer un mot de passe sécurisé (32 caractères)
openssl rand -base64 32

# Générer plusieurs secrets en une fois
for i in {1..5}; do openssl rand -base64 32; done
```

### 1.2 Configurer les secrets dans Coolify

Dans l'interface Coolify :

1. **Allez dans** : Votre application Moodle → Environment Variables
2. **Configurez les variables suivantes** (OBLIGATOIRE) :

```bash
# Base de données
MYSQL_ROOT_PASSWORD=<SECRET_GENERE_1>
MOODLE_DB_PASSWORD=<SECRET_GENERE_2>

# Administrateur Moodle
MOODLE_ADMIN_USER=admin_ceredis
MOODLE_ADMIN_PASS=<SECRET_GENERE_3>
MOODLE_ADMIN_EMAIL=admin@ceredis.net

# LTI
LTI_CLIENT_SECRET=<SECRET_GENERE_4>

# Dropbox (si utilisé)
DROPBOX_TOKEN=<TOKEN_DEPUIS_RCLONE>
```

### 1.3 Rotation des secrets

**Fréquence recommandée** :
- Mots de passe DB : tous les 6 mois
- Secrets LTI : tous les 3 mois
- Admin Moodle : tous les 3 mois

**Procédure de rotation** :

```bash
# 1. Générer nouveau secret
NEW_DB_PASSWORD=$(openssl rand -base64 32)

# 2. Mettre à jour dans Coolify (Variables d'environnement)
# MOODLE_DB_PASSWORD=$NEW_DB_PASSWORD

# 3. Redéployer l'application
# Via UI Coolify : Deploy → Force Rebuild

# 4. Mettre à jour dans la base (si Moodle déjà installé)
docker compose exec db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \
  "ALTER USER 'moodle'@'%' IDENTIFIED BY '${NEW_DB_PASSWORD}';"
```

### 1.4 Sécuriser les fichiers de configuration

```bash
# Sur le serveur Coolify
cd /data/coolify/applications/moodle-*

# Restreindre les permissions
chmod 600 .env
chmod 600 moodle/config.php

# Vérifier qu'aucun secret n'est commité
git secrets --scan  # Nécessite git-secrets
```

---

## 2. Configuration SSL/TLS

### 2.1 Vérification SSL/TLS

**Coolify gère automatiquement SSL avec Let's Encrypt**, mais vérifiez :

```bash
# Tester le certificat SSL
curl -vI https://ecole-en-ligne.ceredis.net 2>&1 | grep -i 'SSL\|TLS'

# Vérifier l'expiration
echo | openssl s_client -servername ecole-en-ligne.ceredis.net \
  -connect ecole-en-ligne.ceredis.net:443 2>/dev/null | \
  openssl x509 -noout -dates

# Score SSL Labs (recommandé A+)
# Visitez: https://www.ssllabs.com/ssltest/analyze.html?d=ecole-en-ligne.ceredis.net
```

### 2.2 Configuration Moodle pour HTTPS strict

Dans `moodle/config.php` :

```php
// Forcer HTTPS
$CFG->wwwroot = 'https://ecole-en-ligne.ceredis.net';
$CFG->sslproxy = true;

// Cookies sécurisés
$CFG->cookiesecure = true;
$CFG->cookiehttponly = true;
$CFG->cookiesamesite = 'Lax';

// Content Security Policy
$CFG->additionalhtmlhead = '<meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">';
```

### 2.3 Headers de sécurité (via Traefik/Coolify)

Coolify configure automatiquement Traefik avec des headers sécurisés, mais vérifiez :

```bash
# Vérifier les headers de sécurité
curl -I https://ecole-en-ligne.ceredis.net | grep -i 'strict\|x-frame\|x-content'
```

Attendu :
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
```

---

## 3. Sécurité de la base de données

### 3.1 Isolation réseau

La base de données **ne doit PAS** être exposée publiquement :

```bash
# Vérifier qu'aucun port DB n'est ouvert
docker compose ps db
# Doit montrer : 3306/tcp (PAS 0.0.0.0:3306)

# Vérifier depuis l'extérieur
nmap -p 3306 votre-serveur.com
# Doit retourner : filtered ou closed
```

### 3.2 Durcissement MariaDB

Créez `scripts/secure-database.sh` :

```bash
#!/bin/bash
set -e

echo "🔒 Durcissement de la base de données MariaDB"

# Charger variables
source .env

# Connexion au conteneur DB
docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF

-- Supprimer les utilisateurs anonymes
DELETE FROM mysql.user WHERE User='';

-- Supprimer la base test
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Désactiver l'accès root distant (sauf depuis réseau Docker)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '%');

-- Limiter les privilèges de l'utilisateur moodle
REVOKE ALL PRIVILEGES ON *.* FROM 'moodle'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, 
      CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, 
      SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER 
      ON moodle.* TO 'moodle'@'%';

-- Activer le plugin de validation de mot de passe
INSTALL SONAME 'simple_password_check';
SET GLOBAL simple_password_check_minimal_length = 12;

-- Appliquer les changements
FLUSH PRIVILEGES;

SELECT 'Sécurisation terminée' AS Status;
EOF

echo "✅ Base de données sécurisée"
```

Exécutez :

```bash
chmod +x scripts/secure-database.sh
./scripts/secure-database.sh
```

### 3.3 Sauvegardes chiffrées

Modifiez `scripts/backup.sh` pour chiffrer les dumps :

```bash
# Ajoutez cette fonction
encrypt_backup() {
    local file=$1
    local password=${BACKUP_ENCRYPTION_KEY:-$(openssl rand -base64 32)}
    
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$file" \
        -out "${file}.enc" \
        -k "$password"
    
    rm "$file"  # Supprimer version non chiffrée
    echo "$password" > "${file}.key"
    chmod 600 "${file}.key"
    
    log_info "🔐 Fichier chiffré: ${file}.enc"
}
```

---

## 4. Permissions et isolation

### 4.1 Permissions des fichiers Moodle

```bash
# Définir le propriétaire correct
docker compose exec moodle chown -R www-data:www-data /var/www/html
docker compose exec moodle chown -R www-data:www-data /var/www/moodledata

# Permissions strictes
docker compose exec moodle find /var/www/html -type d -exec chmod 755 {} \;
docker compose exec moodle find /var/www/html -type f -exec chmod 644 {} \;

# Config.php en lecture seule
docker compose exec moodle chmod 444 /var/www/html/config.php

# Moodledata protégé
docker compose exec moodle chmod 700 /var/www/moodledata
```

### 4.2 Désactiver l'exécution dans les uploads

Dans `moodle/config.php` :

```php
// Empêcher l'exécution de PHP dans les dossiers d'upload
$CFG->preventexecpath = true;
```

Créez `.htaccess` dans `moodledata/` :

```apache
<FilesMatch "\.(php|phtml|php3|php4|php5|phps)$">
    Require all denied
</FilesMatch>
```

### 4.3 Isolation des conteneurs

Vérifiez que les conteneurs ne fonctionnent pas en root :

```bash
# Vérifier l'utilisateur dans le conteneur
docker compose exec moodle whoami
# Doit retourner: www-data (pas root!)

docker compose exec db whoami
# Acceptable: mysql
```

Si besoin, modifiez `Dockerfile` :

```dockerfile
# Après installation des dépendances
USER www-data
```

---

## 5. Pare-feu et réseau

### 5.1 Configuration UFW (Ubuntu)

```bash
# Activer UFW si ce n'est pas déjà fait
sudo ufw enable

# Autoriser uniquement les ports nécessaires
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP (redirection vers HTTPS)
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 8000/tcp    # Coolify UI (optionnel, restreindre par IP)

# Bloquer tout le reste
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Vérifier le statut
sudo ufw status verbose
```

### 5.2 Limiter l'accès à Coolify

```bash
# Restreindre Coolify à des IPs spécifiques
sudo ufw delete allow 8000/tcp
sudo ufw allow from VOTRE_IP_ADMIN to any port 8000 proto tcp

# Ou via VPN
sudo ufw allow from 10.8.0.0/24 to any port 8000 proto tcp
```

### 5.3 Rate limiting avec fail2ban

Installez et configurez fail2ban :

```bash
# Installation
sudo apt install fail2ban -y

# Créer config Moodle
sudo cat > /etc/fail2ban/filter.d/moodle-auth.conf <<'EOF'
[Definition]
failregex = ^<HOST> .* "POST /login/index.php.*" 200
ignoreregex =
EOF

# Activer le jail
sudo cat > /etc/fail2ban/jail.d/moodle.conf <<'EOF'
[moodle-auth]
enabled = true
port = http,https
filter = moodle-auth
logpath = /var/log/apache2/access.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

# Redémarrer fail2ban
sudo systemctl restart fail2ban
```

---

## 6. Audit et monitoring

### 6.1 Logs centralisés

Configurez la rétention des logs dans `docker-compose.yml` :

```yaml
services:
  moodle:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 6.2 Surveillance des logs

Créez `scripts/monitor-security.sh` :

```bash
#!/bin/bash

# Surveiller les tentatives de connexion échouées
echo "🔍 Connexions échouées (dernières 24h):"
docker compose logs moodle --since 24h | grep -i "failed login" | wc -l

# Tentatives d'accès à des fichiers sensibles
echo "⚠️  Accès suspects:"
docker compose logs moodle --since 24h | grep -E "config\.php|\.env|admin/cli"

# Erreurs SQL (injection possible)
echo "💉 Erreurs SQL:"
docker compose logs moodle --since 24h | grep -i "sql.*error" | tail -5
```

### 6.3 Alertes automatiques

Script d'alerte par email (nécessite `mailutils`) :

```bash
#!/bin/bash
# scripts/security-alerts.sh

ADMIN_EMAIL="admin@ceredis.net"
ALERT_THRESHOLD=10

FAILED_LOGINS=$(docker compose logs moodle --since 1h | grep -i "failed login" | wc -l)

if [ $FAILED_LOGINS -gt $ALERT_THRESHOLD ]; then
    echo "ALERTE: $FAILED_LOGINS tentatives de connexion échouées" | \
        mail -s "Moodle Security Alert" $ADMIN_EMAIL
fi
```

Ajoutez à cron :

```bash
# Vérifier toutes les heures
0 * * * * /chemin/vers/scripts/security-alerts.sh
```

---

## 7. Sauvegardes sécurisées

### 7.1 Chiffrement des sauvegardes Dropbox

Ajoutez dans `.env` :

```bash
# Clé de chiffrement pour les sauvegardes
BACKUP_ENCRYPTION_KEY=<GENERE_AVEC_openssl_rand_-base64_32>
```

Modifiez `scripts/backup.sh` :

```bash
# Avant upload vers Dropbox
if [ -n "$BACKUP_ENCRYPTION_KEY" ]; then
    log_info "Chiffrement de la sauvegarde..."
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$DB_BACKUP_FILE.gz" \
        -out "$DB_BACKUP_FILE.gz.enc" \
        -k "$BACKUP_ENCRYPTION_KEY"
    rm "$DB_BACKUP_FILE.gz"
    DB_BACKUP_FILE="$DB_BACKUP_FILE.gz.enc"
fi
```

### 7.2 Test de restauration

**Important** : Testez régulièrement vos sauvegardes !

```bash
# Tous les mois, vérifier qu'on peut restaurer
./scripts/restore.sh --test --from-dropbox --date 20251201
```

---

## 8. Checklist de production

### Avant mise en production

- [ ] Tous les secrets changés (pas de valeurs `.env.example`)
- [ ] HTTPS activé et fonctionnel (A+ sur SSL Labs)
- [ ] Base de données non accessible depuis Internet
- [ ] Permissions fichiers correctes (644/755)
- [ ] `config.php` en lecture seule
- [ ] Pare-feu UFW actif
- [ ] fail2ban configuré
- [ ] Sauvegardes automatiques testées
- [ ] Sauvegardes chiffrées
- [ ] Monitoring actif
- [ ] Alertes email configurées
- [ ] Logs rotatifs configurés
- [ ] LTI secrets générés et sécurisés
- [ ] Admin Moodle : MFA activé
- [ ] Politique de mots de passe stricte dans Moodle

### Maintenance mensuelle

- [ ] Vérifier les mises à jour de sécurité Moodle
- [ ] Revoir les logs d'authentification
- [ ] Tester une restauration de sauvegarde
- [ ] Vérifier l'espace disque
- [ ] Auditer les accès administrateurs
- [ ] Vérifier la date d'expiration SSL
- [ ] Nettoyer les anciennes sauvegardes

### Maintenance trimestrielle

- [ ] Rotation des secrets LTI
- [ ] Rotation mot de passe admin Moodle
- [ ] Audit des plugins installés
- [ ] Mise à jour Moodle (selon calendrier)
- [ ] Revue des permissions utilisateurs

### Maintenance semestrielle

- [ ] Rotation mot de passe base de données
- [ ] Audit de sécurité complet (nmap, etc.)
- [ ] Test de plan de reprise d'activité
- [ ] Formation utilisateurs sur sécurité

---

## 9. Ressources et contacts

### Documentation
- [Moodle Security](https://docs.moodle.org/en/Security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

### Outils recommandés
- [Mozilla Observatory](https://observatory.mozilla.org/)
- [SSL Labs](https://www.ssllabs.com/ssltest/)
- [Security Headers](https://securityheaders.com/)
- [Nmap](https://nmap.org/)

### Contact support CEREDIS
- Email : admin@ceredis.net
- Issues : GitHub repository

---

**Dernière mise à jour** : Décembre 2025  
**Version** : 1.0  
**Niveau de sécurité visé** : Production éducative
