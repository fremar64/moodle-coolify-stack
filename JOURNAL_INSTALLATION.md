# 📝 Journal d'Installation - Moodle Coolify Stack

## ✅ Ce qui a été réalisé

### 1. Structure du projet créée
```
moodle-coolify-stack/
├── docker-compose.yml      # Configuration Docker Compose complète
├── .env.example            # Template des variables d'environnement
├── .env                    # Variables d'environnement locales (ignoré par Git)
├── .gitignore              # Fichiers à ignorer par Git
├── README.md               # Documentation complète
├── backups/                # Dossier pour les sauvegardes
│   └── .gitkeep           
├── moodle/                 # Code source Moodle 5.0.1 (29 000+ fichiers)
│   ├── config-dist.php
│   ├── index.php
│   ├── admin/
│   ├── course/
│   ├── lib/
│   └── ...
└── journal d'installation.txt
```

### 2. Code source Moodle 5.0.1 intégré
- ✅ Clonage depuis le dépôt officiel Moodle
- ✅ Version stable MOODLE_501_STABLE
- ✅ ~29 000 fichiers de code source ajoutés
- ✅ Permet personnalisations complètes (plugins, thèmes, modifications)

### 3. Docker Compose configuré
- ✅ Service Moodle avec environnement PHP/Apache optimisé
- ✅ Base de données MariaDB 11.4
- ✅ Cache Redis pour les performances
- ✅ Cron automatique pour les tâches Moodle
- ✅ Reverse proxy Traefik avec SSL Let's Encrypt
- ✅ Système de backup automatique vers Dropbox

### 4. Volumes optimisés
- ✅ `./moodle` → Code source monté directement (accès complet)
- ✅ `moodle_data` → Données persistantes (cours, plugins installés)
- ✅ `db_data` → Base de données MariaDB
- ✅ `redis_data` → Cache Redis
- ✅ `traefik_letsencrypt` → Certificats SSL

### 5. Dépôt GitHub configuré
- ✅ Poussé vers https://github.com/fremar64/moodle-coolify-stack
- ✅ Code source Moodle inclus (75+ MB de données)
- ✅ Documentation complète mise à jour
- ✅ Prêt pour déploiement avec Coolify

## 🚀 Prochaines étapes

1. **Déployer avec Coolify** :
   - Créer une nouvelle application Docker Compose Empty
   - Pointer vers le dépôt GitHub
   - Configurer les variables d'environnement
   - Déployer

2. **Configuration DNS** :
   - Vérifier que `ecole-en-ligne.ceredis.net` pointe vers le serveur

3. **Première installation** :
   - Accéder à l'URL après déploiement
   - Suivre l'assistant d'installation Moodle
   - Configurer l'admin et terminer l'installation

## 💡 Avantages de cette approche

- **Code source accessible** → Modifications directes possibles
- **Plugins personnalisés** → Installation facile de modules tiers  
- **Débogage facilité** → Accès direct aux logs et code
- **Sauvegardes complètes** → Code source inclus dans les backups
- **Contrôle total** → Aucune limitation d'image pré-construite

---
**Date de création** : 4 octobre 2025  
**Auteur** : Frédéric OUAMBA  
**Version Moodle** : 5.0.1 (MOODLE_501_STABLE)

.................................................................................................................

14/10/2025

Problème :
Voici les différentes variables dont je dois renseigner les valeurs dans le formulaire de réglage de la base de données :
Serveur de base de données :
Nom de la base de données
Utilisateur de la base de données
Mot de passe de la base de données
Préfixe des tables
Port de la base de données
Socket Unix

Quelles sont les valeurs correctes que je dois écrire pour chaque variable ?

Solution:

Voici les valeurs à renseigner pour notre stack (MariaDB 11.4 dans Docker):

Type de base de données: MariaDB (native/mariadb) — déjà sélectionné
Serveur de base de données: db
Nom de la base de données: moodle
Utilisateur de la base de données: moodle
Mot de passe de la base de données: la valeur de MOODLE_DB_PASSWORD que tu as définie dans Coolify
Préfixe des tables: mdl_ (par défaut; change-le uniquement si tu partages la même base avec une autre instance)
Port de la base de données: 3306
Socket Unix: laisser vide
Notes:

N’utilise pas “localhost” comme serveur, sinon Moodle tentera un socket Unix; “db” est le bon hôte sur le réseau Docker.
MariaDB 11.4 utilise InnoDB par défaut (recommandé par Moodle) et utf8mb4 sera appliqué automatiquement.

Problème :

Sur l'écran suivant, la quasi totalité des prérequis, concernant notamment les extensions PHP nécessaires, sont ok, sauf pour 'unicode'. Moodle affiche le message suivant :

"L’extension doit être installée et activée. Toutes les données doivent être enregistrées au format Unicode (UTF-8). Pour les nouvelles installations, la base de données doit avoir par défaut un jeu de caractères Unicode (UTF-8). Si vous effectuez une mise à jour, vous devez procéder à la migration de votre base de données en UTF-8."

Que faut-il faire ?

Solution :

Je vais appliquer une amélioration côté base de données pour forcer utf8mb4 par défaut (évite l’avertissement “unicode”), puis je vérifierai la validité YAML et committerai/pousserai. Ensuite, je te donnerai deux chemins: corriger la base existante (ALTER DATABASE) ou repartir propre.
Bonne nouvelle: c’est un simple check d’unicode/UTF-8. Voici quoi faire selon ta situation.

Si tu es en nouvelle installation (base vide):

J’ai mis à jour le service MariaDB pour forcer utf8mb4 par défaut:
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
skip-character-set-client-handshake
Action: redeploie l’app dans Coolify pour prendre en compte ce réglage. Puis relance l’installateur Moodle; le prérequis “unicode” passera au vert.
Si tu as déjà créé la base et qu’elle n’est pas en utf8mb4:

Option A (recommandée si aucune donnée): supprime la base et laisse Moodle la recréer après le redeploy avec les bons defaults.
Option B (si des données existent déjà): convertis en place:
ALTER DATABASE moodle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
Puis pour chaque table non conforme, convertir la table et ses colonnes vers utf8mb4. Ça peut être long; l’outil de conversion de Moodle ou des scripts SQL ciblés aident. Comme tu es en phase d’install, privilégie A.
Rappels:

MariaDB 11.4 + InnoDB + utf8mb4 est la configuration recommandée par Moodle.
Le driver “MariaDB (native/mariadb)” convient parfaitement.
Après redeploi:

Reviens sur l’écran des prérequis; “unicode” devrait être OK.
Si ça persiste, purge le conteneur db (ou recrée les volumes de db) pour garantir l’application des nouveaux defaults.

Problème :
J'ai supprimé la base de données 'moodle'.
Mais après redéploiement le navigateur affiche un message d'erreur :
Error

Error: Database connection failed

It is possible that the database is overloaded or otherwise not running properly.

The site administrator should also check that the database details have been correctly specified in config.php

Solution :

Merci pour les détails. Le message “Database connection failed” vient du fait que tu as supprimé la base “moodle”, mais MariaDB n’a pas recréé automatiquement la base (les scripts d’initialisation ne tournent qu’au tout premier démarrage du volume). Et ton config.php existe déjà avec des identifiants qui doivent correspondre à un utilisateur/bdd réels.

Voici deux chemins clairs, au choix.

Option A — propre et rapide (recommandée si tu peux repartir de zéro)

Dans Coolify, supprime le volume de la base (db_data) du service MariaDB de cette app.
Redéploie l’app pour ré-initialiser MariaDB avec:
base: moodle
user: moodle
pass: MOODLE_DB_PASSWORD (ta variable Coolify)
charset/collation: utf8mb4 (déjà forcés)
Supprime moodle/config.php (dans le volume de code) pour relancer l’installateur web, puis refais l’installation.
À l’écran DB: Type = MariaDB (native/mariadb), Hôte = db, Base = moodle, User = moodle, Pass = ta variable MOODLE_DB_PASSWORD, Port = 3306, Socket = vide.
Option B — corriger l’existant (si tu veux garder le volume db)

Crée (ou recrée) la base et aligne le mot de passe de l’utilisateur:
Dans la console du conteneur MariaDB:
Créer la base: CREATE DATABASE moodle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
Aligner l’utilisateur “moodle” avec le mot de passe du config.php (ou l’inverse):
Soit tu gardes le pass du config.php (dc6…): ALTER USER 'moodle'@'%' IDENTIFIED BY 'dc6arqPMpVZVXRb8Y';
Soit tu préfères ta variable Coolify (MOODLE_DB_PASSWORD): ALTER USER 'moodle'@'%' IDENTIFIED BY '<ta_valeur_MOODLE_DB_PASSWORD>';
Puis: GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'%'; FLUSH PRIVILEGES;
Si tu as changé le mot de passe côté DB, vérifie que config.php a bien la même valeur dans $CFG->dbpass.
Rappels utiles

Ne mets pas “localhost” comme hôte: utilise “db”.
Si tu veux relancer l’installateur web, supprime moodle/config.php avant de recharger la page.
Tu peux aussi en profiter pour régénérer/rotater MOODLE_DB_PASSWORD dans Coolify, puis aligner à la fois la DB (ALTER USER) et config.php.
Si tu veux, je peux te donner les commandes exactes à exécuter dans la console de la base sous Coolify pour l’Option B.

Problème :
Si je supprime le volume 'l880gc0sosck0oscssok8c8k_db-data', Coolify va en créer automatiquement un autre ?

Est-ce qu'après la suppression de ce volume et du fichier 'config.php'Moodle créera la nouvelle base de données avec la bonne collation cette fois-ci ?

Oui et oui, voici les précisions et la marche à suivre.

Suppression du volume DB
Oui. Si tu supprimes le volume MariaDB (ex: l880gc0sosck0oscssok8c8k_db-data) dans Coolify, au prochain déploiement Docker/Coolify créera automatiquement un volume neuf pour le volume Compose db_data. Le nom interne peut changer, c’est normal.
Recréation de la base avec la bonne collation
Oui. Avec un volume DB vierge, l’image officielle MariaDB initialise la base “moodle”, l’utilisateur “moodle” et applique les options serveur définies dans docker-compose (utf8mb4 + collation par défaut).
En supprimant aussi le fichier moodle/config.php, l’installateur web repartira de zéro et créera le schéma Moodle en UTF-8. L’exigence “unicode” passera au vert.
Checklist rapide

Supprime le volume DB de l’app dans Coolify.
Supprime le fichier moodle/config.php du code monté.
Redeploie l’app.
Attends que MariaDB finisse son init (quelques secondes) puis relance l’installateur.
À l’écran DB: Type = MariaDB (native/mariadb), Hôte = db, Base = moodle, User = moodle, Pass = MOODLE_DB_PASSWORD, Port = 3306.
Note collations

Nous forçons utf8mb4 côté serveur. Moodle peut choisir une collation moderne (utf8mb4_uca1400_ai_ci) au niveau des tables; c’est très bien. Si tu veux un alignement parfait des “defaults” serveur/côté Moodle, on peut passer la collation serveur à utf8mb4_uca1400_ai_ci (optionnel).


Problème :

N'est-il pas nécessaire de supprimer aussi le volume l880gc0sosck0oscssok8c8k_moodle-data ?

Solution :

Pas indispensable pour le problème “unicode” (qui ne concerne que la base), mais recommandé si tu veux une réinstallation 100% propre.

Ce que fait ce volume:
moodle-data contient les fichiers de la plateforme (cache, sessions, fichiers déposés, etc.), pas la base de données.
Quand le supprimer:
Nouvelle installation / aucun contenu à conserver: oui, supprime-le pour repartir sainement (ça évite des caches/sessions résiduels).
Si tu as déjà des contenus à garder: ne le supprime pas. Dans ce cas, purge au minimum les caches.
Impact sur “unicode”:
Aucun. Le check “unicode” dépend de MariaDB (charset/collation). On l’a corrigé côté DB; moodle-data n’influe pas là-dessus.
Option si tu gardes moodle-data: purge les caches (à exécuter dans le conteneur web)


rm -rf /var/www/moodledata/{cache,localcache,muc,sessions,temp}
chown -R www-data:www-data /var/www/moodledata
chmod -R 2775 /var/www/moodledata

En résumé:

Supprimer DB volume: oui (fait).
Supprimer moodle-data: optionnel; fais-le si tu n’as rien à conserver pour une install “neuve”. Sinon, purge les caches et garde-le.




.................................................................................................................

15/10/2025
Problème :
L'installation s'est enfin bien déroulé jusqu'au bout. Cependant, lors du processus d'enregistrement du site dans le répertoire officiel des sites Moodle il y a eu un message d'erreur :

"The hub cannot access your site at https://ecole-en-ligne.ceredis.net - Unexpected HTTP response code 403. Your Moodle site and the hub need to be able to communicate with each another. If you are unable to register your site please contact us via https://moodle.com/contact/?selection=community#form

More information about this error"

Que signifie ce message ?


Solution :

Bonne nouvelle: l’installation est OK. Le message de registre 403 signifie simplement que le serveur du hub Moodle (moodle.net) a tenté d’accéder à ton site pour le valider, et ton site/proxy lui a répondu “Forbidden”. Ce n’est pas un bug de Moodle, c’est un refus côté serveur/proxy.

Causes probables (les plus courantes):

Accès public restreint: site en maintenance, “forcer la connexion” activé, ou page d’accueil non accessible en anonyme.
Proxy/WAF/pare-feu: règle qui bloque certains User-Agent ou IP (ex: bot/hub), géo‑blocage, liste blanche IP manquante.
Middleware Traefik (auth, IP allowlist) qui renvoie 403.
.htaccess ou règle Apache qui restreint des méthodes/agents.
Ce que je te propose de vérifier, dans l’ordre:

Page d’accueil accessible publiquement
Depuis un poste externe (pas via le conteneur), teste:
curl -I https://ecole-en-ligne.ceredis.net/
Attendu: 200 OK (ou redirection vers la page d’accueil/login), surtout pas 403.
Désactive temporairement “Administration du site → Sécurité → Forcer la connexion” si activé, et toute maintenance.
Proxy/Coolify/Traefik
Assure-toi qu’aucun middleware d’authentification ou de restriction IP n’est attaché à l’app (dans les labels Traefik/côté Coolify).
Pas de filtrage WAF externe (Fail2ban/iptables/Cloudflare, etc.) qui bloquerait un “bot”.
Logs pour identifier la requête 403
Regarde les logs du service “moodle” dans Coolify au moment de l’erreur et recherche une ligne en 403 (tu verras l’URL et le User-Agent).
S’il s’agit d’un User-Agent particulier (ex: MoodleBot), confirme qu’il n’est pas bloqué.
Re‑essayer l’enregistrement
Une fois l’accès public confirmé (pas de 403 pour un GET/HEAD anonyme), relance l’enregistrement sur moodle.net.
La registration n’affecte pas le fonctionnement du site; tu peux aussi la faire plus tard.
Si tu veux, donne-moi un extrait de logs (la ligne avec le 403) et je te dis exactement quelle règle l’a déclenché et quoi ajuster.

................................................................................................................

16/10/2025

Problème :
Je constate aussi qu'à maintes reprises l'affiche du site Moodle se plante avec le message d'erreur : "gateway time-out" "Error code 504". Chaque fois, quand je recharge la page, elle s'affiche enfin. Cela s'est reproduit plusieurs fois.

Solution :

Merci, les 504 “Gateway Time-out” viennent généralement du proxy (Traefik) qui attend trop longtemps la réponse d’Apache/PHP. Comme le rechargement finit par marcher, c’est très probablement ponctuel (pics lents pendant le “warm‑up” des caches, compilation CSS/JS ou IO/CPU un peu tendus).

Voici comment stabiliser et éliminer ces timeouts:

Réglages Moodle (performance)
Désactiver le “mode concepteur de thèmes” (designer mode).
Activer le cache JS/CSS et le cache de templates.
Purger les caches une fois (Administration du site > Développement > Vider tous les caches).
Vérifier que le cron tourne (dans notre stack il tourne toutes les 5 min); dans “Administration du site > Notifications”, l’heure du dernier cron doit être récente.
Activer/optimiser le cache Redis
Ajoute maintenant le bloc Redis dans moodle/config.php (sessions + cache global si tu veux), comme dans le README:
session_handler_class = \core\session\redis + host=redis/port=6379
(optionnel) cachestore_redis_server = 'redis' avec un préfixe
Purge à nouveau les caches. Ça réduit fortement la charge PHP et les latences.
PHP/OPcache un peu plus généreux
Si tu observes encore des lenteurs, monte légèrement:
PHP_MEMORY_LIMIT à 768M
OPCACHE_MEMORY_CONSUMPTION à 512
OPCACHE_MAX_FILES à 20000
Ces variables sont lues au démarrage par le conteneur et appliquées automatiquement (notre entrypoint génère 99-custom-settings.ini).
Éviter les 404 “/public/”
Dans les logs, les 404 sur “/public/” viennent d’URL externes ou d’utilisateurs qui appellent explicitement /public (alors que le DocumentRoot est déjà public). Ce n’est pas lié aux 504, mais on peut ajouter une petite redirection /public → / pour nettoyer ces 404. Dis‑moi si tu veux que je l’applique.
Proxy Traefik (timeouts/réessais)
Si, malgré tout, tu constates encore quelques 504 (surtout lors de gros bursts), on peut:
Ajouter un middleware de retry (ex: 2–3 tentatives) côté Traefik via labels.
Éventuellement augmenter les timeouts de transport Traefik (si Coolify permet de référencer un serversTransport). C’est rarement nécessaire si les points 1–3 sont bien en place.
Ressources serveur
Les 504 ponctuels sont aussi typiques d’un hôte un peu chargé (CPU/IO). Surveille brièvement l’usage CPU/RAM/IO du VPS pendant que tu charges la page d’accueil et l’admin; si tu vois des pics, on affinera l’Apache MPM (KeepAlive, MaxRequestWorkers) ou on rehaussera les ressources.
Ce que montrent tes logs

Beaucoup de 200 sur des ressources lourdes (theme/styles.php, requirejs, fonts), ce qui est normal après installation et purge des caches.
Les 404 “/public/” ne sont pas critiques et indépendants des 504.
Pas de 5xx côté Apache au moment des symptômes → le 504 vient bien du proxy en amont (délai dépassé avant réception des en‑têtes de réponse).
Si tu veux, je:

Ajoute la redirection /public → / dans la conf Apache.
Monte les valeurs OPcache par défaut dans l’entrypoint (512/20000).
Propose un patch de labels Traefik pour un middleware de retry.


...................................................................................
17/10/2025

Problème : Installation des plugins 
J'ai voulu installer le plugin du thème "Adapatable". Mais Moodle affiche un message d'erreur : "Erreur lors de la vérification des droits d’accès en écriture".

Solution :

D’accord, on règle l’erreur de “droits d’accès en écriture” pour installer le thème Adaptable, puis on retente proprement.

Plan rapide:

Vérifier/forcer les permissions d’écriture côté conteneur.
Te donner 2 voies: installation via Git (recommandée pour la traçabilité) ou via l’interface (en rendant les dossiers écrivable).
Vérifier la compatibilité du thème Adaptable avec Moodle 5.1 avant de retenter.
Vérifier et corriger les permissions dans le conteneur
Objectif: Apache (www-data) doit pouvoir créer/modifier le dossier du plugin de thème sous le code (dirroot).
Exécute ces commandes dans le conteneur web pour diagnostiquer puis corriger si besoin:
À exécuter dans le conteneur moodle_app:
whoami
ls -ld /var/www/html /var/www/html/theme
stat -c "%U:%G %A" /var/www/html /var/www/html/theme
Si tu vois que l’owner n’est pas www-data, applique:
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 775 {} ;
find /var/www/html -type f -exec chmod 664 {} ;
Notes:
Dans notre image, on fait déjà un chown/chmod au démarrage, mais selon le système de fichiers/volume, ça peut ne pas s’appliquer comme attendu. Les commandes ci-dessus le forcent à nouveau.
Assure-toi que le montage n’est pas en lecture seule (ro) dans Coolify/Compose (notre compose ne met pas ro).
Chemin recommandé: installation via Git (traçabilité totale)
Télécharge la version d’Adaptable compatible Moodle 5.1 depuis le répertoire officiel.
Décompresse le zip dans le dépôt local ici:
moodle/theme/adaptable
Le dossier final doit contenir version.php, settings.php, lang/, etc.
Commit/push:
git add moodle/theme/adaptable
git commit -m "Ajout thème Adaptable"
git push
Redéploie dans Coolify, puis va sur Administration du site → Notifications pour terminer l’installation/maj de la base.
Avantages:
Modifications versionnées; pas de surprises d’écriture à chaud en prod.
Voie alternative: installation via l’interface web
Après la correction des permissions ci-dessus (owner = www-data, chmod dossiers 775), réessaye l’upload du zip Adaptable dans l’interface.
Une fois installé, purge les caches: Administration du site → Développement → Vider tous les caches.
Compatibilité du thème Adaptable
Vérifie que la version du thème supporte Moodle 5.1. Si le plugin n’est pas déclaré compatible 5.1, l’installation peut échouer plus loin (même si les droits sont OK).
Si tu as un doute, dis-moi la version exacte du zip (ou le lien) et je te confirme la compatibilité.
Option bonus: rendre les répertoires “plugins” plus tolérants
Si tu veux vraiment garder l’installation via UI, on peut ajuster l’entrypoint pour s’assurer que les répertoires de plugins courants soient toujours créables/modifiables (ex: chmod 775 sur theme/, mod/, local/, blocks/, filter/, auth/, etc.). Dis-moi si tu veux que je pousse ce petit durcissement automatique.
Tu me dis ce que tu préfères (Git vs UI) et, si tu veux, je peux intégrer un mini doc INSTALL_PLUGIN.md avec la procédure Git et les commandes de vérification des permissions.

Je vais ajouter un guide INSTALL_PLUGIN.md détaillant l’installation de plugins via Git (avec exemple Adaptable), lier ce guide depuis le README, puis committer et pousser les changements.
Parfait—on passe en mode Git pour les plugins, avec la doc intégrée.

Ce que j’ai fait

Créé INSTALL_PLUGIN.md
Procédure Git pas-à-pas, tableau des emplacements (theme/mod/block/…), checks de compatibilité 5.1, exemple pour le thème Adaptable, permissions côté conteneur, bonnes pratiques et rollback.
Mis à jour README.md
Ajout d’un lien vers INSTALL_PLUGIN.md dans la section Documentation.
Commit & push
Commit “Docs: ajouter INSTALL_PLUGIN.md (procédure Git, exemple Adaptable) et lier depuis README”
Poussé sur main: OK.
Installer “Adaptable” via Git (rappel)

Place le code du thème dans moodle/theme/adaptable (version compatible Moodle 5.1).
Commit/push, redeploie dans Coolify.
Administration du site → Notifications: termine l’installation du plugin.
Purge les caches.
Tu veux que je prépare un squelette de branche (ex: feature/theme-adaptable) + checklist de validation (pages, styles, caches, perf) pour tes prochains ajouts de plugins ?


Problème :

J'ai examiné la structure du dépôt 'moodle-coolify-stack'. Le chemin du répertoire des thèmes est : '/moodle/public/theme' et non moodle/theme/adaptable comme tu l'as écrit dans le guide 'INSTALL_PLUGIN.md', n'est-ce pas ? Dans c répertoire il y a déjà les dossiers des thèmes 'boost' et 'classic'. Tu peux vérifier.

Solution :

Pour corriger le guide avec le bon chemin des thèmes (public/theme) et ajuster les commandes de permissions, je vais mettre à jour INSTALL_PLUGIN.md puis committer et pousser.
Bien vu — pour cette architecture Moodle 5.1, les thèmes résident sous theme (et non moodle/theme/). J’ai corrigé le guide.

Ce que j’ai mis à jour

INSTALL_PLUGIN.md
Chemin des thèmes: moodle/public/theme/<nom_du_theme> (ex: moodle/public/theme/adaptable)
Commandes de permissions ajustées: /var/www/html/public/theme/...
Note que les autres types de plugins (mod, blocks, local, auth, etc.) restent à la racine moodle
Commit & push effectués sur main.
Pour installer le thème Adaptable via Git maintenant:

Place le code dans moodle/public/theme/adaptable (version compatible Moodle 5.1).
Commit/push, redeploie dans Coolify.
Puis Administration du site → Notifications pour terminer l’installation et Vider tous les caches.
Tu veux que je crée un répertoire moodle/public/theme/adaptable/ vide (avec un README placeholder) pour te servir de gabarit, ou tu préfères déposer directement les fichiers du thème et je ferai le commit ensuite ?

Je vais vérifier les fichiers ajoutés du thème, les indexer, committer avec un message clair, puis pousser sur GitHub; ensuite je t’indiquerai les étapes de déploiement et finalisation côté Moodle.
Top, j’ai intégré le thème Adaptable dans le dépôt et poussé sur GitHub.

Ce que j’ai fait

Ajouté le répertoire du thème: adaptable (350 fichiers)
Commit: “Thème: ajouter Adaptable (moodle/public/theme/adaptable) — installation via Git, compatible Moodle 5.1”
Push sur main: OK
Prochaines étapes dans Moodle

Redéploie l’app dans Coolify (Git-Based → Deploy).
Va dans Administration du site → Notifications: tu devrais voir l’écran d’installation/mise à jour du thème Adaptable.
Suis l’assistant, puis purge les caches: Administration du site → Développement → Vider tous les caches.
Active le thème: Administration du site → Apparence → Thèmes → Sélectionner “Adaptable”.
Vérifie quelques pages (accueil, cours, page de login) et, si besoin, configure les options du thème (beaucoup de réglages).
Optionnel pour la perf/stabilité

Redis activé pour sessions/caches (comme dans le README).
Désactiver le “mode concepteur de thèmes”.
Si compilation SCSS lourde: purge caches après premiers réglages du thème.
Tu veux que je crée un court checklist “validation thème” dans le repo (pages à vérifier, réglages clés à activer) ?

............................................................................


Problème :
J'ai redéployé Moodle sur Coolify.
Quand je clique sur 'Administration du site", le navigateur affiche un message d'erreur : "Gateway time-out Error code 504"

Solution :

Je vais appliquer des correctifs pour réduire les 504: augmenter les défauts OPcache, ajouter une redirection /public → / côté Apache, et ajouter un middleware de retry Traefik via labels; ensuite je committerai et pousserai.
J’ai appliqué des ajustements côté Traefik, Apache et PHP pour réduire les 504 quand vous ouvrez “Administration du site”; je résume ce que j’ai changé et ce qu’on fait ensuite.

Actions prises
docker-compose.yml
Ajout d’un serversTransport Traefik avec des timeouts plus larges (dial=30s, responseHeader=180s, read/write=180s).
Ajout d’un middleware de retry (2 tentatives, 500ms) et liaison au router.
Liaison explicite du router → service et service → serversTransport.
docker-entrypoint.sh
Augmentation des limites par défaut PHP: max_execution_time et max_input_time passent à 600s.
OPcache plus généreux: memory_consumption=512, max_accelerated_files=20000.
Apache: Timeout 300.
Rewrite: redirection de toute URL “/public/*” vers “/” (le DocumentRoot est déjà public) pour éviter des 404 “cosmétiques”.
Commit/push effectués sur main; le déploiement Coolify devrait se déclencher.
Qualité rapide: config shell et YAML valides (lint PASS).

Ce que vous devez faire maintenant
Redéployer dans Coolify (si l’auto-deploy n’est pas activé) puis réessayer:
Administration du site → la page peut prendre un peu de temps au premier chargement (construction des caches).
Après ouverture, allez dans:
Administration du site → Développement → Vider tous les caches (cela réduit fortement la charge des prochains accès).
Si vous voyez encore un 504:
Réessayez une seconde fois (le retry Traefik peut aider après warm-up).
Patientez 2-3 minutes et réessayez (le cron et les caches se calent progressivement).
Notes sur vos logs
La ligne Slim “HttpNotFoundException … referer: /admin/search.php” correspond typiquement à une sous‑route manquante (ex. ressource/route interne) ou à favicon.ico en 404; ce n’est pas la cause du 504.
Le 504 provient du proxy qui coupe avant la réponse Apache; d’où l’élargissement des timeouts côté Traefik et Apache + des limites PHP.
Si le 504 persiste malgré tout
On peut pousser un cran plus loin:
Élargir encore Traefik: responseHeaderTimeout/read/write à 300s.
Apache Timeout à 600.
Si vous avez beaucoup de plugins, exécuter une purge des caches via CLI dans le conteneur web: php public/admin/cli/purge_caches.php.
Vérifier la base (migrations longues): MariaDB peut être lent la première fois; le retry et les timeouts aident à laisser l’opération se terminer.
Dites-moi si, après ce nouveau déploiement, la page “Administration du site” s’affiche sans 504; si besoin je pousserai les timeouts et vous donnerai la commande CLI exacte pour purger/initialiser les caches via Coolify.

................................................................................................

Problème :

Moodle n'est plus accessible. Le navigateur affiche le message : "no available server".

Solution :

Je retire les labels Traefik serversTransport non supportés (probable cause de “no available server”) tout en gardant le middleware de retry, puis je pousse pour redéployer.
Merci pour les détails—je viens de corriger la cause probable de “no available server” côté Traefik et je résume la suite.

Ce que j’ai fait à l’instant
J’ai retiré des labels Traefik “serversTransport” qui ne sont visiblement pas supportés par l’instance Traefik de Coolify (c’est typiquement la source du “no available server”). Le middleware de retry (2 tentatives) est conservé.
Les optimisations précédentes restent actives:
Apache/PHP: max_execution_time et max_input_time à 600s, Apache Timeout 300.
OPcache plus généreux (mémoire 512, 20k fichiers).
Rewrite /public/* → / pour éviter des 404 bruitées.
J’ai committé et poussé sur main; le déploiement Coolify devrait s’enclencher.
Ce que vous pouvez faire maintenant
Redéployer dans Coolify (si l’auto-deploy n’est pas actif).
Tester l’accès à https://ecole-en-ligne.ceredis.net/ et “Administration du site”.
Si l’accès n’est pas rétabli:
Vérifier dans l’app Coolify que la variable DOMAIN vaut bien ecole-en-ligne.ceredis.net (elle est utilisée par Traefik pour la règle Host(${DOMAIN})).
Dans Coolify, confirmer que l’application est bien exposée à Traefik (pas de middleware d’auth ou d’IP allowlist bloquants).
Regarder les logs de l’app proxy (Traefik) pour un message lié au router “moodle” (souvent très parlant).
À propos des logs fournis
MariaDB: RAS, service “ready for connections” (les warnings io_uring sont bénins).
Apache: service UP et en écoute.
Petit détail: l’owner de /var/www/html/public/index.php ressort “root:root” dans votre dernier log. Ce n’est pas bloquant pour servir le site, mais si vous installez des plugins via l’interface (moins recommandé que via Git), il faudra que www-data ait les droits d’écriture sur les dossiers concernés. On peut l’ajuster au besoin.
Si jamais vous revoyez des 504
Les timeouts Traefik personnalisés ont été retirés (car non supportés dans votre contexte), mais les réglages côté Apache/PHP/OPcache sont conservés.
Si les 504 réapparaissent ponctuellement sur “Administration du site” (pages lourdes):
Ouvrez une fois la page (warm-up), puis purgez les caches via l’UI.
Activez Redis dans config.php (sessions + caches) si ce n’est pas déjà fait (voir README).
Dites-moi et je pousserai un ajustement supplémentaire (par ex. augmenter encore Apache Timeout) si besoin.
Tenez-moi au courant dès que vous avez redeployé: si l’accès est revenu, on validera ensuite l’ouverture d’“Administration du site” sans 504 et, si vous voulez, on activera/validera le thème Adaptable.

................................................................................

Après redéploiement, Moodle a affiché la page d'installation du plugin (thème Adaptable). Mais il y a eu une erreur 504 ( Gateway time-out Error code 504 ). J'ai relancé la page et cette fois-là le processus d'installation s'est déroulé jusqu'au bout.
J'ai purgé tous les caches ensuite.
Qu'est-ce qui provoque cette erreur de time-out qui revient régulièrement ? Comment y mettre fin ?

Je vais pousser des améliorations concrètes pour réduire durablement les 504: tuning MariaDB (buffer pool), réglages Apache (KeepAlive/MPM) et ajout d’une procédure d’installation via CLI dans INSTALL_PLUGIN.md pour contourner les timeouts web. Ensuite je committerai et pousserai.

Merci pour le retour détaillé. Les 504 récurrents viennent d’un cumul de facteurs “lents” pendant les opérations lourdes (installation/mise à jour de plugins, compilation SCSS, purge de caches) et du proxy qui coupe avant que PHP/Apache ne réponde. J’ai appliqué plusieurs améliorations concrètes pour les faire disparaître ou, au minimum, les rendre très rares.

Ce que j’ai changé maintenant
Base de données
InnoDB buffer pool augmenté à 512M pour limiter les accès disque lors des migrations/installs de plugins.
Apache/PHP
KeepAlive activé avec paramètres prudents (réutilisation des connexions).
MPM prefork ajusté (StartServers/MaxRequestWorkers/MaxConnectionsPerChild) pour un VPS.
On garde vos augmentations PHP/OPcache et Timeout 300 déjà en place.
Documentation
Ajout d’une procédure “alternative CLI” dans INSTALL_PLUGIN.md pour installer/migrer les plugins sans passer par l’interface web (qui est soumise aux timeouts du proxy).
Ces changements sont commités et poussés; redéployez dans Coolify pour les prendre en compte.

Pourquoi ça time-out et comment l’éviter
Cause typique:
Au premier passage sur “Notifications” ou lors d’une installation de plugin, Moodle reconstruit beaucoup de caches, lit/écrit en base et compile du SCSS. C’est CPU/IO/DB intensif. Si la réponse met trop de temps, le proxy (Traefik) coupe → 504.
Mesures déjà en place:
PHP/Apache/OPcache élargis, KeepAlive et MPM réglés.
DB plus “large” (buffer pool 512M).
Middleware retry Traefik (2 tentatives).
Quand c’est encore lourd:
Utiliser l’upgrade via CLI dans le conteneur web évite complètement le proxy:
php /var/www/html/public/admin/cli/upgrade.php --non-interactive --allow-unstable
php /var/www/html/public/admin/cli/purge_caches.php
Recommandations pour stabiliser définitivement
Après ce déploiement
Ouvrez “Administration du site” une fois (warm-up), puis “Développement → Vider tous les caches”.
Désactivez le “mode concepteur de thèmes” si activé.
Activez Redis pour les sessions et caches (exemple dans README).
Pour les futures installations/mises à jour de plugins
Préférez la méthode Git (comme pour Adaptable), puis faites l’upgrade via CLI.
Terminez par une purge des caches via CLI.
Si malgré tout vous observez encore des 504
Dites-le moi: je pourrai pousser un cran plus loin (Apache Timeout 600 et, selon vos ressources VPS, relever MaxRequestWorkers).
On peut aussi augmenter PHP_MEMORY_LIMIT (ex: 768M) et OPCACHE_MEMORY_CONSUMPTION (ex: 512) via variables d’environnement si vos ressources le permettent.
En bref: ces réglages + la procédure CLI pour les étapes lourdes éliminent généralement les 504. Redéployez et testez; si vous voyez encore le symptôme, donnez-moi l’heure exacte et je corrélerai avec les logs pour un ajustement ciblé.

