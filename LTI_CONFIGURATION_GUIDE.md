# 🔗 Guide de Configuration LTI - Moodle CEREDIS

## Vue d'ensemble

Ce guide explique comment configurer Moodle en tant que plateforme LTI (Learning Tools Interoperability) pour intégrer des applications externes comme :
- **SeSaLab** (fork personnalisé pour CEREDIS)
- **Billes et Calculs** (application Next.js sur Vercel)
- D'autres outils compatibles LTI 1.3

## Prérequis

### Configuration requise
- Moodle 4.0+ avec support LTI 1.3
- Accès administrateur à Moodle
- Domaine HTTPS configuré (requis pour LTI 1.3)
- Variables d'environnement configurées dans `.env`

### Variables d'environnement LTI

Dans votre fichier `.env` Coolify :

```bash
# LTI Configuration générale
LTI_CLIENT_ID=moodle_ceredis_platform
LTI_CLIENT_SECRET=VotreSecretTresFort_Genere_Aleatoirement

# Plateforme Moodle
LTI_PLATFORM_URL=https://ecole-en-ligne.ceredis.net

# Configuration SeSaLab (exemple)
LTI_SESALAB_URL=https://sesalab.ceredis.net
LTI_SESALAB_CLIENT_ID=sesalab_consumer
LTI_SESALAB_SECRET=SecretSesalab123

# Configuration Billes et Calculs (exemple)
LTI_BILLES_URL=https://billes-et-calculs.vercel.app
LTI_BILLES_CLIENT_ID=billes_consumer
LTI_BILLES_SECRET=SecretBilles456
```

## 1. Configuration de Moodle comme Plateforme LTI

### Étape 1.1 : Activer LTI dans Moodle

1. Connectez-vous en tant qu'administrateur
2. Allez dans **Administration du site** → **Plugins** → **Activités**
3. Activez le plugin **Outil externe (LTI)**
4. Configurez les paramètres par défaut :
   - ✅ Activer "External tool"
   - ✅ Activer "LTI Advantage"
   - ✅ Activer les services LTI (Note, Score, Result)

### Étape 1.2 : Configurer l'authentification LTI

1. **Administration du site** → **Plugins** → **Authentification**
2. Activez **LTI**
3. Configurez :
   ```
   URL de la plateforme: https://ecole-en-ligne.ceredis.net
   Issuer identifier: https://ecole-en-ligne.ceredis.net
   ```

## 2. Ajouter un Outil Externe (Provider)

### Méthode A : Configuration manuelle

1. **Administration du site** → **Plugins** → **Activités** → **Outil externe**
2. Cliquez sur **Gérer les outils**
3. Cliquez sur **Configurer un outil manuellement**

#### Pour SeSaLab :

```
Nom de l'outil: SeSaLab - Exercices Scientifiques
URL de l'outil: https://sesalab.ceredis.net/lti/launch
Consumer key (Client ID): sesalab_consumer
Shared secret: [Votre secret depuis .env]

Configuration LTI:
- Version LTI: LTI 1.3
- URL de lancement public: https://sesalab.ceredis.net/lti/launch
- URL de lancement pour connexion initiale: https://sesalab.ceredis.net/lti/login
- URL de redirection: https://sesalab.ceredis.net/lti/callback
- URL JWKS: https://sesalab.ceredis.net/.well-known/jwks.json

Services IMS LTI à activer:
✅ IMS LTI Assignment and Grade Services
✅ IMS LTI Names and Role Provisioning Services
✅ IMS LTI Deep Linking

Paramètres de confidentialité:
✅ Partager le nom du lanceur avec l'outil
✅ Partager l'adresse courriel du lanceur avec l'outil
✅ Accepter les notes de l'outil
```

#### Pour Billes et Calculs :

```
Nom de l'outil: Billes et Calculs - Mathématiques
URL de l'outil: https://billes-et-calculs.vercel.app/api/lti/launch
Consumer key: billes_consumer
Shared secret: [Votre secret depuis .env]

Configuration LTI:
- Version LTI: LTI 1.3
- URL de lancement public: https://billes-et-calculs.vercel.app/api/lti/launch
- URL de lancement pour connexion initiale: https://billes-et-calculs.vercel.app/api/lti/login
- URL de redirection: https://billes-et-calculs.vercel.app/api/lti/callback
- URL JWKS: https://billes-et-calculs.vercel.app/.well-known/jwks.json

Services IMS LTI:
✅ Assignment and Grade Services
✅ Names and Role Provisioning

Paramètres de confidentialité:
✅ Partager le nom
✅ Partager l'email
✅ Accepter les notes
```

### Méthode B : Configuration via JSON (LTI Advantage)

Créez un fichier de configuration LTI pour chaque outil :

**sesalab-lti-config.json**
```json
{
  "title": "SeSaLab - Exercices Scientifiques",
  "description": "Plateforme d'exercices interactifs pour sciences",
  "target_link_uri": "https://sesalab.ceredis.net/lti/launch",
  "oidc_initiation_url": "https://sesalab.ceredis.net/lti/login",
  "custom_parameters": {
    "locale": "$Person.address.timezone",
    "user_role": "$Context.role"
  },
  "extensions": [{
    "platform": "canvas.instructure.com",
    "settings": {
      "platform": "moodle",
      "placements": [{
        "placement": "course_navigation",
        "message_type": "LtiResourceLinkRequest",
        "target_link_uri": "https://sesalab.ceredis.net/lti/launch",
        "text": "SeSaLab",
        "icon_url": "https://sesalab.ceredis.net/icon.png"
      }]
    }
  }],
  "public_jwk_url": "https://sesalab.ceredis.net/.well-known/jwks.json",
  "scopes": [
    "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
    "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly",
    "https://purl.imsglobal.org/spec/lti-ags/scope/score",
    "https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly"
  ]
}
```

Importez ensuite via :
**Administration du site** → **Plugins** → **Outil externe** → **Importer une configuration**

## 3. Utiliser un Outil LTI dans un Cours

### Ajouter une activité LTI

1. Dans votre cours, activez le mode édition
2. Cliquez sur **Ajouter une activité ou une ressource**
3. Choisissez **Outil externe**
4. Configurez :

```
Nom de l'activité: "Exercice SeSaLab: Les forces"
Outil externe préconfigré: SeSaLab - Exercices Scientifiques

Options de lancement:
- Lancer dans une nouvelle fenêtre: Oui (recommandé)
- Largeur de la fenêtre: 1024
- Hauteur de la fenêre: 768

Paramètres personnalisés (optionnel):
exercise_id=forces_01
level=intermediaire
language=fr

Confidentialité:
✅ Partager le nom du lanceur
✅ Partager l'email du lanceur
✅ Accepter les notes de l'outil

Note:
- Évaluation maximale: 100
- Type d'évaluation: Point
```

5. **Enregistrer et revenir au cours**

### Paramètres personnalisés avancés

Pour passer des paramètres dynamiques à l'outil :

```
# Variables Moodle disponibles
user_id=$User.id
course_id=$CourseSection.sourcedId
context_title=$Context.title
user_email=$Person.email.primary
user_role=$Membership.role

# Exemple pour SeSaLab
exercise_set=physique_seconde
student_level=$User.id
return_url=$ResourceLink.id
```

## 4. Développer un Outil Compatible LTI

### Structure requise pour un outil externe

Si vous développez votre propre outil (fork de SeSaLab, nouvelle app Next.js...), vous devez implémenter :

#### Endpoints LTI 1.3 requis :

```
GET  /.well-known/jwks.json          # Clés publiques JWT
POST /lti/login                       # Initiation OIDC
POST /lti/launch                      # Point d'entrée principal
POST /lti/callback                    # Redirection après auth
POST /lti/deeplink                    # Deep Linking (optionnel)
```

#### Exemple Next.js (Billes et Calculs)

**app/api/lti/launch/route.ts**
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { verifyLtiToken, extractLtiClaims } from '@/lib/lti';

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const idToken = formData.get('id_token') as string;
    
    // Vérifier la signature JWT
    const payload = await verifyLtiToken(idToken);
    
    // Extraire les informations utilisateur
    const claims = extractLtiClaims(payload);
    
    // Créer une session
    const session = await createUserSession({
      userId: claims.sub,
      email: claims.email,
      name: claims.name,
      roles: claims.roles,
      contextId: claims.context.id,
      resourceLinkId: claims.resourceLink.id
    });
    
    // Rediriger vers l'activité
    return NextResponse.redirect(
      new URL(`/exercises/${claims.custom?.exercise_id}`, req.url)
    );
  } catch (error) {
    console.error('LTI Launch Error:', error);
    return NextResponse.json(
      { error: 'Invalid LTI request' },
      { status: 401 }
    );
  }
}
```

**lib/lti.ts**
```typescript
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: process.env.LTI_PLATFORM_JWKS_URL!,
  cache: true,
  cacheMaxAge: 86400000 // 24h
});

export async function verifyLtiToken(token: string) {
  const decoded = jwt.decode(token, { complete: true });
  if (!decoded) throw new Error('Invalid token');
  
  const key = await client.getSigningKey(decoded.header.kid);
  const publicKey = key.getPublicKey();
  
  return jwt.verify(token, publicKey, {
    algorithms: ['RS256'],
    issuer: process.env.LTI_PLATFORM_URL
  });
}

export function extractLtiClaims(payload: any) {
  return {
    sub: payload.sub,
    email: payload.email,
    name: payload.name,
    roles: payload['https://purl.imsglobal.org/spec/lti/claim/roles'],
    context: payload['https://purl.imsglobal.org/spec/lti/claim/context'],
    resourceLink: payload['https://purl.imsglobal.org/spec/lti/claim/resource_link'],
    custom: payload['https://purl.imsglobal.org/spec/lti/claim/custom']
  };
}
```

#### Retour de notes (Grade Passback)

**app/api/lti/grades/route.ts**
```typescript
export async function POST(req: NextRequest) {
  const { userId, score, maxScore, activityId } = await req.json();
  
  // Récupérer l'endpoint AGS depuis la session LTI
  const lineItemUrl = await getLtiLineItemUrl(activityId);
  const accessToken = await getLtiAccessToken();
  
  // Envoyer la note à Moodle
  const response = await fetch(`${lineItemUrl}/scores`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/vnd.ims.lis.v1.score+json'
    },
    body: JSON.stringify({
      timestamp: new Date().toISOString(),
      scoreGiven: score,
      scoreMaximum: maxScore,
      activityProgress: 'Completed',
      gradingProgress: 'FullyGraded',
      userId: userId
    })
  });
  
  return NextResponse.json({ success: response.ok });
}
```

## 5. Sécurité et Bonnes Pratiques

### Checklist de sécurité

- ✅ **HTTPS obligatoire** : LTI 1.3 nécessite SSL/TLS
- ✅ **Secrets forts** : Générez des secrets de 32+ caractères aléatoires
- ✅ **Validation JWT** : Vérifiez toujours la signature des tokens
- ✅ **CORS** : Configurez correctement pour vos domaines
- ✅ **Rate limiting** : Limitez les requêtes LTI
- ✅ **Logs** : Auditez les lancements et erreurs
- ✅ **Timeout** : Sessions LTI avec expiration

### Génération de secrets sécurisés

```bash
# Générer un secret LTI
openssl rand -base64 32

# Générer une paire de clés RSA pour JWT
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

### Configuration Moodle avancée

**config.php** (optionnel, pour surcharger) :
```php
// LTI Configuration avancée
$CFG->mod_lti_log_users = true;
$CFG->mod_lti_forcessl = true;
$CFG->mod_lti_coursevisible = 1;

// Timeout pour les lancements LTI
$CFG->sessiontimeout = 7200; // 2 heures

// Debug LTI (DÉSACTIVER EN PRODUCTION)
// $CFG->mod_lti_debugging = true;
```

## 6. Test et Validation

### Tester une intégration LTI

1. **Test manuel** :
   - Créez un cours de test
   - Ajoutez une activité LTI
   - Lancez en tant qu'étudiant
   - Vérifiez le retour de note

2. **Validation avec LTI Advantage Validator** :
   - https://lti-ri.imsglobal.org/
   - Testez votre implémentation contre les specs officielles

3. **Logs Moodle** :
```bash
# Consulter les logs LTI
docker compose logs moodle | grep -i lti

# Activer le debug temporairement
docker compose exec moodle sh -c "echo '\$CFG->debug = 32767;' >> /var/www/html/config.php"
```

### Dépannage commun

| Problème | Solution |
|----------|----------|
| "Invalid consumer key" | Vérifiez `LTI_CLIENT_ID` dans `.env` |
| "Signature verification failed" | Vérifiez les clés JWT et l'horloge système |
| "CORS error" | Ajoutez le domaine Moodle aux headers CORS de l'outil |
| "Grade not sent" | Vérifiez que le service AGS est activé |
| "User not found" | Assurez-vous du partage des infos utilisateur |

## 7. Exemples de Cas d'Usage CEREDIS

### Scénario 1 : SeSaLab pour exercices de Physique

```
Cours: Physique Seconde - Les Forces
Module: Chapitre 3 - Dynamique

Activité LTI:
  Nom: "TP Interactif: Chute libre"
  Outil: SeSaLab
  Paramètres:
    exercise_id=physique_chute_libre
    difficulty=progressive
    hints_enabled=true
  
  Évaluation:
    Note sur 20
    Retour automatique vers Moodle
    Critères: précision + démarche
```

### Scénario 2 : Billes et Calculs pour Mathématiques

```
Cours: Mathématiques CP - Numération
Module: Les nombres jusqu'à 100

Activité LTI:
  Nom: "Manipuler les nombres avec Billes et Calculs"
  Outil: Billes et Calculs
  Paramètres:
    activity=number_decomposition
    max_value=100
    language=fr
  
  Évaluation:
    Note sur 10
    Badge "Maître des Billes" si >80%
```

## 8. Ressources

### Documentation officielle
- [LTI 1.3 Core Specification](https://www.imsglobal.org/spec/lti/v1p3/)
- [LTI Advantage](https://www.imsglobal.org/lti-advantage-overview)
- [Moodle LTI Docs](https://docs.moodle.org/en/External_tool)

### Outils de développement
- [LTI Reference Implementation](https://github.com/IMSGlobal/lti-1-3-php-library)
- [Next.js LTI Library](https://www.npmjs.com/package/ltijs)
- [LTI Validator](https://lti-ri.imsglobal.org/)

### Support CEREDIS
- Repository: `moodle-coolify-stack`
- Issues: GitHub Issues
- Contact: admin@ceredis.net

---

**Dernière mise à jour** : Décembre 2025  
**Version** : 1.0  
**Maintenu par** : Équipe CEREDIS
