# 🎓 Moodle Coolify Stack - CEREDIS Production

> Plateforme éducative complète avec intégrations LTI, sauvegardes automatisées et sécurité renforcée

[![Production](https://img.shields.io/badge/status-production-success)]()
[![Moodle](https://img.shields.io/badge/moodle-5.1-orange)](https://moodle.org/)
[![Docker](https://img.shields.io/badge/docker-compose-blue)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/license-GPL--3.0-lightgrey)]()

**URL Production** : https://ecole-en-ligne.ceredis.net

---

## 📋 Vue d'ensemble

Stack Moodle optimisée pour Coolify avec :
- ✅ **Moodle 5.1** avec structure source/public séparée
- ✅ **MariaDB 11.4** + **Redis 7** pour performances optimales
- ✅ **Sauvegardes automatiques** vers Dropbox avec chiffrement AES-256
- ✅ **Intégration LTI 1.3** pour outils externes (SeSaLab, Billes et Calculs)
- ✅ **Sécurité renforcée** (SSL/TLS, secrets, isolation réseau)
- ✅ **Support 100+ utilisateurs concurrents** avec monitoring

---

## 🚀 Démarrage rapide

### Pour les nouveaux utilisateurs

1. **Accédez à la plateforme** : https://ecole-en-ligne.ceredis.net
2. **Guide d'exploitation** : [EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md) 
3. **Configuration LTI** : [LTI_CONFIGURATION_GUIDE.md](LTI_CONFIGURATION_GUIDE.md)

### Pour les administrateurs système

```bash
# 1. Cloner le repository
git clone https://github.com/fremar64/moodle-coolify-stack.git
cd moodle-coolify-stack

# 2. Déployer via Coolify
# Configurer les variables d'environnement dans Coolify UI
# Lancer le déploiement

# 3. Vérifier l'état
docker compose ps
docker compose logs -f moodle

# 4. Configurer les sauvegardes Dropbox
./scripts/setup-dropbox.sh
./scripts/backup.sh --dropbox
```

---

## 📖 Documentation

| Guide | Description | Public cible |
|-------|-------------|--------------|
| **[EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md)** | 🎯 **Guide opérationnel complet** | Admins, Support |
| [LTI_CONFIGURATION_GUIDE.md](LTI_CONFIGURATION_GUIDE.md) | Configuration outils externes LTI | Admins Moodle |
| [SECURITY_HARDENING_GUIDE.md](SECURITY_HARDENING_GUIDE.md) | Sécurisation de la plateforme | DevOps, Sécurité |
| [PERFORMANCE_OPTIMIZATION_GUIDE.md](PERFORMANCE_OPTIMIZATION_GUIDE.md) | Optimisations et monitoring | DevOps |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Résolution de problèmes | Support |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Déploiement initial | Admins système |

---

## 🏗️ Architecture

Cette stack utilise une architecture optimisée :
- **Source Moodle** : `/var/www/html` (code principal)
- **Webroot public** : `/var/www/html/public` (exposition HTTP)
- **Données Moodle** : `/var/www/moodledata` (volumes persistants)
- **Séparation code/données** pour sécurité et performance

---

## 📦 Services

```yaml
moodle-stack/
├── db          → MariaDB 11.4 (base de données)
├── redis       → Redis 7 (cache sessions & données)
├── moodle      → Apache/PHP 8.3 + Moodle 5.1
├── cron        → Tâches planifiées Moodle (5 min)
└── backup      → Sauvegardes automatiques vers Dropbox

Volumes persistants:
├── db_data          → Données MariaDB
├── redis_data       → Cache Redis avec AOF
└── moodle_data      → Fichiers utilisateurs Moodle
```

---

## 🔐 Sécurité et Performance

### Sécurité
- ✅ SSL/TLS automatique via Let's Encrypt (Coolify/Traefik)
- ✅ Secrets gérés via variables d'environnement Coolify
- ✅ Isolation réseau Docker (réseau `moodle_net`)
- ✅ Sauvegardes chiffrées AES-256-CBC
- ✅ Firewall UFW configuré (ports 22/80/443 uniquement)
- ✅ Fail2ban pour protection brute-force

Voir [SECURITY_HARDENING_GUIDE.md](SECURITY_HARDENING_GUIDE.md) pour la configuration complète.

### Performance
- ✅ Redis cache pour sessions et données Moodle
- ✅ OPcache PHP activé (512MB)
- ✅ MariaDB buffer pool 2GB + indexation optimisée
- ✅ Compression Gzip + headers de cache HTTP
- ✅ Monitoring avec scripts d'alertes automatiques

Voir [PERFORMANCE_OPTIMIZATION_GUIDE.md](PERFORMANCE_OPTIMIZATION_GUIDE.md) pour les optimisations.

### Sauvegardes
- ✅ **Quotidiennes automatisées** : 3h du matin via cron
- ✅ **Dropbox** : Rétention 30 jours, chiffrement AES-256
- ✅ **Local** : Rétention 7 jours
- ✅ **Inclut** : Base de données, fichiers utilisateurs, configuration

```bash
# Sauvegarde manuelle
./scripts/backup.sh --dropbox

# Restauration
./scripts/restore.sh --from-dropbox --date 20251207
```

---

## 🎓 Intégration LTI

Configuration des outils externes pour accès depuis Moodle :
- **SeSaLab** (fork) : Exercices de physique/sciences
- **Billes et Calculs** (Vercel) : Application Next.js mathématiques

Guide complet : [LTI_CONFIGURATION_GUIDE.md](LTI_CONFIGURATION_GUIDE.md)

**Étapes rapides** :
1. Moodle → **Administration** → **Plugins** → **Outil externe**
2. **Configurer un outil manuellement**
3. Remplir Client ID, Secret, URL de lancement
4. Activer Services LTI (Assignment and Grade, etc.)
5. Ajouter l'activité "Outil externe" dans un cours

---

## 🛠️ Scripts disponibles

| Script | Description |
|--------|-------------|
| `backup.sh` | Sauvegarde complète ou partielle (DB/fichiers/code) |
| `restore.sh` | Restauration depuis sauvegarde locale ou Dropbox |
| `setup-dropbox.sh` | Configuration initiale Dropbox |
| `optimize-database.sh` | Optimisation mensuelle base de données |
| `performance-monitor.sh` | Monitoring temps réel avec alertes |
| `security-alerts.sh` | Surveillance événements sécurité |
| `health-check.sh` | Vérification état de tous les services |
| `update-moodle.sh` | Mise à jour Moodle (à venir) |

Tous les scripts dans `/scripts` avec documentation intégrée (`--help`).

---

## 🆘 Support et Troubleshooting

### Problèmes courants

**Moodle inaccessible ("no available server")** :
```bash
# Vérifier logs Traefik
docker logs traefik-coolify

# Vérifier réseau Docker
docker network inspect coolify

# Redémarrer Coolify stack
cd /root/.coolify && docker compose restart
```

**Erreur 500 sur Moodle** :
```bash
# Consulter logs
docker compose logs -f moodle

# Purger caches
docker compose exec moodle php /var/www/html/admin/cli/purge_caches.php
```

**Base de données lente** :
```bash
# Optimiser
./scripts/optimize-database.sh

# Vérifier slow queries
docker compose exec db mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
```

Voir [TROUBLESHOOTING.md](TROUBLESHOOTING.md) pour la liste complète.

---

## 📅 Maintenance

### Quotidien (automatisé)
- 02:00 : Purge caches Moodle
- 03:00 : Sauvegarde complète Dropbox
- Toutes les 15 min : Monitoring performances

### Mensuel (manuel)
- Optimiser base de données
- Nettoyer logs > 90 jours
- Tester restauration sauvegarde
- Audit sécurité léger

### Trimestriel
- Rotation secrets LTI
- Audit plugins installés
- Mise à jour Moodle

Calendrier complet : [EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md)

---

## 📂 Structure du projet

```
moodle-coolify-stack/
├── docker-compose.yml           # Orchestration services
├── Dockerfile                   # Image Moodle personnalisée
├── docker-entrypoint.sh         # Script d'initialisation
├── .env.example                 # Template variables
│
├── moodle/                      # Code source Moodle 5.1
│   ├── admin/
│   ├── lib/
│   ├── public/                  # Webroot exposé
│   └── ...
│
├── scripts/                     # Scripts opérationnels
│   ├── backup.sh
│   ├── restore.sh
│   ├── setup-dropbox.sh
│   ├── optimize-database.sh
│   ├── performance-monitor.sh
│   └── security-alerts.sh
│
└── docs/                        # Documentation
    ├── EXPLOITATION_GUIDE.md
    ├── LTI_CONFIGURATION_GUIDE.md
    ├── SECURITY_HARDENING_GUIDE.md
    ├── PERFORMANCE_OPTIMIZATION_GUIDE.md
    └── TROUBLESHOOTING.md
```

---

## 🤝 Contribution

Les contributions sont bienvenues !

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'feat: Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📜 Licence

GPL-3.0 (compatible avec Moodle)

---

## 🙏 Remerciements

- [Moodle](https://moodle.org/) - LMS open source
- [Coolify](https://coolify.io/) - Plateforme de déploiement self-hosted
- [Traefik](https://traefik.io/) - Reverse proxy moderne
- Communauté open source éducative

---

## 📞 Contact

- **Repository** : https://github.com/fremar64/moodle-coolify-stack
- **Issues** : https://github.com/fremar64/moodle-coolify-stack/issues
- **Email** : admin@ceredis.net

---

**Statut** : ✅ Production Ready  
**Dernière mise à jour** : Décembre 2025  
**Maintenu par** : Équipe CEREDIS
./scripts/backup.sh

# Sauvegarde base de données uniquement
./scripts/backup.sh --type db

# Avec nettoyage des anciennes sauvegardes
./scripts/backup.sh --cleanup
```

### 🔁 Restauration
```bash
# Lister les sauvegardes disponibles
./scripts/restore.sh --list

# Restaurer base de données et fichiers
./scripts/restore.sh \
  --db backups/moodle_db_20241207.sql.gz \
  --files backups/moodle_files_20241207.tar.gz
```

### ⬆️ Mise à jour Moodle
```bash
# Lister les versions disponibles
./scripts/update-moodle.sh --list

# Mettre à jour vers une version spécifique
./scripts/update-moodle.sh --version MOODLE_502_STABLE
```

### 🏥 Vérification de santé
```bash
# Check basique
./scripts/health-check.sh

# Check détaillé
./scripts/health-check.sh --detailed

# Sortie JSON (pour monitoring)
./scripts/health-check.sh --json
```

📖 **Documentation complète** : Voir [scripts/README.md](scripts/README.md)

---

## 🔧 Maintenance

### Sauvegardes automatiques

✅ **Quotidiennes** vers Dropbox (si configuré)
- Base de données MySQL
- Fichiers Moodle (`/var/www/moodledata`)

### Commandes Docker utiles

```bash
# Voir les logs
docker compose logs -f moodle

# Redémarrer un service
docker compose restart moodle

# Accéder au shell
docker exec -it moodle_app bash

# Vérifier la santé des services
docker compose ps

# Utiliser le script health-check
./scripts/health-check.sh --detailed
```

📖 **Guide complet** : Consultez [MAINTENANCE.md](MAINTENANCE.md)

---

## 🐛 Dépannage

### Problèmes courants

**❌ Erreur 502/503**
```bash
# Vérifier les healthchecks
docker compose ps

# Voir les logs
docker compose logs moodle
```

**❌ Base de données inaccessible**
```bash
# Vérifier MariaDB
docker compose logs db

# Tester la connexion
docker exec moodle_db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"
```

**❌ SSL non généré**
- Vérifiez le DNS : `nslookup votre-domaine.com`
- Attendez 10-15 minutes pour la propagation
- Consultez les logs Traefik dans Coolify

📖 **Guide complet** : Consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🤝 Contribution

Les contributions sont les bienvenues !

1. Forkez le projet
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Committez vos changements (`git commit -m 'Ajout fonctionnalité'`)
4. Poussez vers la branche (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

---

## 📄 Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus de détails.

Moodle est sous licence GPL. Voir [moodle.org](https://moodle.org) pour plus d'informations.

---

## 🙏 Remerciements

- **Moodle Community** - Pour la plateforme LMS open source
- **Coolify** - Pour la plateforme de déploiement simplifiée
- **MoodleHQ** - Pour les images Docker officielles

---

## 📞 Support

- 📖 **Documentation** : Voir le dossier `docs/`
- 🐛 **Issues** : [GitHub Issues](https://github.com/fremar64/moodle-coolify-stack/issues)
- 💬 **Discussions** : [Moodle Forums](https://moodle.org/forums)
- 📧 **Contact** : [Frédéric OUAMBA](https://github.com/fremar64)

---

**Fait avec ❤️ pour la communauté éducative**

[![Déployer sur Coolify](https://img.shields.io/badge/Déployer-Coolify-blue?style=for-the-badge)](https://coolify.io)
