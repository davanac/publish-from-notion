---
name: publish-from-notion
description: Mettre en place un pipeline de publication multi-plateforme automatise depuis Notion. A utiliser pour construire une redaction qui publie vers Ghost, LinkedIn, Twitter, Facebook, Mastodon ou Bluesky depuis un CMS Notion central.
---

> [Read in English → SKILL.md](SKILL.md)

# Pipeline de publication multi-plateforme depuis Notion

Un assistant de configuration interactif qui construit un pipeline de publication complet : ecrivez dans Notion, publiez sur Ghost et les reseaux sociaux, planifiez une seule fois, le pipeline gere le reste.

## Quand utiliser ce skill

- Mise en place d'un nouveau pipeline de publication multi-plateforme
- Ajout d'une nouvelle plateforme sociale a une configuration existante
- Configuration de l'horloge principale et de la planification cross-plateforme
- Diagnostic de problemes dans le pipeline de publication
- Comprehension de la machine a etats et des mecanismes anti-doublon

## Le principe en 30 secondes

```
Ecrire dans Notion
  → pousser vers Ghost (votre plateforme SEO principale)
    → creer des posts specifiques dans chaque base de donnees
      → definir UNE date de publication (horloge principale)
        → le pipeline publie partout avec des decalages horaires
          → les gardes anti-doublon empechent la double publication
```

Le pipeline ne genere PAS de contenu. Il publie ce que vous placez dans les bases de donnees.

---

## Flux de configuration interactif

Guidez l'utilisateur a travers chaque etape. Ne configurez que les plateformes selectionnees. Demandez confirmation avant de passer a l'etape suivante.

### Etape 1 : Selection des plateformes

Demandez a l'utilisateur vers quelles plateformes il souhaite publier.

**Plateformes disponibles :**

| Plateforme | Role | Notes |
|------------|------|-------|
| Ghost | Publication principale (SEO, blog) | Recommande. Open source, auto-hebergeable. |
| LinkedIn | Distribution professionnelle | Format long, audience orientee carriere |
| Twitter/X | Distribution format court | Schema accroche + lien |
| Facebook | Distribution grand public | Ton conversationnel, accessible |
| Mastodon | Distribution federee | Audience technique, analytique |
| Bluesky | Distribution decentralisee | Concis, communautaire |

**Regles :**
- La configuration est modulaire. Seules les plateformes selectionnees sont configurees.
- Ghost est fortement recommande comme plateforme principale mais n'est pas obligatoire.
- Au moins une plateforme doit etre selectionnee.

Demandez : "Vers quelles plateformes souhaitez-vous publier ? Je ne configurerai que ce dont vous avez besoin."

### Etape 2 : Configuration des bases Notion

Guidez l'utilisateur dans la creation des bases de donnees Notion. Deux types : une base Articles centrale (toujours), et une base par plateforme selectionnee.

#### Base Articles (hub central)

Chaque article y est enregistre. Chaque plateforme selectionnee obtient une propriete de statut.

| Propriete | Type | Fonction |
|-----------|------|----------|
| Title | Title | Titre de l'article |
| URL | URL | URL source ou lien de reference |
| _[Plateforme]_ | Select | Une par plateforme selectionnee (voir options de statut ci-dessous) |

**Options de statut pour chaque propriete Select de plateforme :**

| Option | Signification |
|--------|---------------|
| `Draft` | Pas encore pret pour le pipeline |
| `Ready` | Declenche le traitement par le pipeline |
| `Generated` | Contenu cree dans la base de la plateforme |
| `Scheduled` | Date de publication definie |
| `Published` | Publie avec succes |

Ne creez les proprietes Select que pour les plateformes selectionnees a l'etape 1.

#### Bases plateforme (une par plateforme)

Chaque plateforme selectionnee dispose de sa propre base ou l'utilisateur redige le contenu du post.

| Propriete | Type | Fonction |
|-----------|------|----------|
| Name | Title | Titre ou identifiant du post |
| Articles | Relation -> Articles DB | Lien vers l'article source |
| Publication Date | Date | Date de publication |
| Platform URL | URL | Rempli par le pipeline apres publication |

Le contenu du post est redige dans le **corps de la page**, pas dans les proprietes.

**Integration Notion :** Rappelez a l'utilisateur de partager toutes les bases avec son integration Notion (... -> Connexions -> nom de l'integration). Guidez-le dans la creation de l'integration s'il n'en a pas (voir etape 4).

### Etape 3 : Configuration de la machine a etats

Expliquez comment les articles progressent dans le pipeline.

```
  Draft        Ready       Generated    Scheduled    Published
    🚧    ->    🚀    ->     ✅     ->     ⏰    ->     📢

              vous le      vous ou      le pipeline   le pipeline
             definissez    votre auto-   definit       definit
             manuellement  matisation
```

**Qui fait quoi :**

| Transition | Qui | Ce qui se passe |
|------------|-----|-----------------|
| -> Ready | Utilisateur | Signale l'intention de publier sur cette plateforme |
| Ready -> Generated | **Utilisateur** | Vous redigez le post dans la base plateforme, puis passez a ✅ |
| Generated -> Scheduled | Pipeline | L'orchestrateur de dates definit les dates de publication |
| Scheduled -> Published | Pipeline | Le script de publication appelle l'API de la plateforme |

> **Point cle :** L'etape 🚀 → ✅ est **manuelle par defaut**. Le pipeline ne genere pas de contenu. Vous redigez le post (manuellement, avec des prompts IA, ou avec votre propre automatisation), puis vous le marquez ✅. Si vous ne redigez jamais le contenu, l'article reste a 🚀 — le pipeline ne le touchera pas. C'est volontaire.

**En cas d'echec :** le pipeline revient a l'etat precedent pour que le cycle suivant puisse reessayer automatiquement.

**Garde-fou contenu vide :** Le publisher verifie que le corps du post n'est pas vide avant d'appeler l'API de la plateforme. Un post vide reste a ⏰ et est ignore jusqu'a ce que du contenu soit ajoute.

Details complets : `docs/state-machine.md`

### Etape 4 : Identifiants API

Pour chaque plateforme selectionnee, guidez l'utilisateur pas a pas dans la configuration des API. Referez-vous a `docs/api-setup.md` pour les instructions detaillees par plateforme.

**Notion (toujours requis) :**
1. Creez une integration sur notion.so/my-integrations
2. Accordez les capacites Read, Update et Insert content
3. Copiez l'Internal Integration Secret (`secret_...`)
4. Partagez chaque base de donnees avec l'integration
5. Copiez l'ID de chaque base depuis l'URL

**Ghost :**
- Panneau d'administration -> Settings -> Integrations -> Add custom integration
- Copiez l'Admin API Key (format : `{key_id}:{key_secret}`)

**LinkedIn :**
- Creez une LinkedIn App (necessite une Page Entreprise)
- Demandez l'acces au produit "Share on LinkedIn"
- Generez un token OAuth avec le scope `w_member_social`
- Recuperez le person URN depuis le endpoint `/me`
- Attention : le token expire apres 60 jours

**Twitter/X :**
- Compte developpeur sur developer.twitter.com
- Creez un Project + App
- Definissez les permissions sur Read and Write AVANT de generer les tokens
- Generez les quatre cles (API Key, API Secret, Access Token, Access Secret)

**Facebook :**
- Creez une Business app sur developers.facebook.com
- Ajoutez les produits Facebook Login et Pages
- Generez un **Page** Access Token (pas un User token) via le Graph API Explorer
- Echangez-le pour un token longue duree

**Mastodon :**
- Sur VOTRE instance : Preferences -> Development -> New Application
- Scopes : `read` et `write:statuses`
- Copiez l'Access token

**Bluesky :**
- Settings -> App Passwords -> Add App Password
- Utilisez le format handle : `votrenom.bsky.social`
- N'utilisez jamais le mot de passe du compte dans le `.env`

**Generez le fichier `.env`** avec uniquement les sections pertinentes decommentees selon les plateformes selectionnees :

```bash
# ==============================================================================
# publish-from-notion configuration
# ==============================================================================

# Timezone for scheduling
TIMEZONE=Europe/Paris

# Master clock platform (which platform's date drives all others)
MASTER_CLOCK_PLATFORM=linkedin

# --- Notion (required) ---
NOTION_TOKEN=secret_...
NOTION_DB_ARTICLES=your-articles-database-id

# --- Ghost ---
# GHOST_API_URL=https://your-site.ghost.io
# GHOST_ADMIN_KEY=64XXX...XXX:8fXXX...XXX
# NOTION_DB_GHOST=your-ghost-database-id

# --- LinkedIn ---
# LINKEDIN_ACCESS_TOKEN=AQV...
# LINKEDIN_PERSON_URN=urn:li:person:XXXXXXXXX
# NOTION_DB_LINKEDIN=your-linkedin-database-id

# --- Twitter/X ---
# TWITTER_API_KEY=...
# TWITTER_API_SECRET=...
# TWITTER_ACCESS_TOKEN=...
# TWITTER_ACCESS_SECRET=...
# NOTION_DB_TWITTER=your-twitter-database-id

# --- Facebook ---
# FACEBOOK_PAGE_ID=123456789012345
# FACEBOOK_ACCESS_TOKEN=EAAG...
# NOTION_DB_FACEBOOK=your-facebook-database-id

# --- Mastodon ---
# MASTODON_INSTANCE_URL=https://your-instance.social
# MASTODON_ACCESS_TOKEN=...
# NOTION_DB_MASTODON=your-mastodon-database-id

# --- Bluesky ---
# BLUESKY_HANDLE=yourname.bsky.social
# BLUESKY_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx
# NOTION_DB_BLUESKY=your-bluesky-database-id

# --- Monitoring (optional) ---
# MONITORING_WEBHOOK_URL=https://your-webhook-url
```

Ne decommentez que les sections correspondant aux plateformes selectionnees.

### Etape 5 : Generation des scripts

Generez les scripts de publication Python et les wrappers Bash pour chaque plateforme selectionnee.

#### Patron du script de publication (Python)

Chaque publisher suit la meme structure :

```python
"""Publish [platform] posts from Notion database."""

import os
from datetime import datetime, timezone
from dotenv import load_dotenv
from notion_client import Client

load_dotenv()

notion = Client(auth=os.environ["NOTION_TOKEN"])

DB_ID = os.environ["NOTION_DB_PLATFORM"]
ARTICLES_DB_ID = os.environ["NOTION_DB_ARTICLES"]
STATUS_PROPERTY = "Platform"  # Name of the Select property on Articles DB

def get_posts_to_publish():
    """Query platform DB for posts with date <= now and empty URL."""
    now = datetime.now(timezone.utc).isoformat()
    response = notion.databases.query(
        database_id=DB_ID,
        filter={
            "and": [
                {"property": "Publication Date", "date": {"on_or_before": now}},
                {"property": "Platform URL", "url": {"is_empty": True}},
            ]
        },
    )
    return response["results"]

def get_article_status(article_id):
    """Check the article's platform status."""
    page = notion.pages.retrieve(page_id=article_id)
    status = page["properties"][STATUS_PROPERTY]["select"]
    return status["name"] if status else None

def set_idempotency_flag(post_id):
    """Claim the post to prevent double-publishing."""
    notion.pages.update(
        page_id=post_id,
        properties={"Platform URL": {"url": "publishing.in.progress"}},
    )

def clear_idempotency_flag(post_id):
    """Release the claim on failure."""
    notion.pages.update(
        page_id=post_id,
        properties={"Platform URL": {"url": None}},
    )

def mark_published(post_id, url, article_id):
    """Write the published URL and update article status."""
    notion.pages.update(
        page_id=post_id,
        properties={"Platform URL": {"url": url}},
    )
    notion.pages.update(
        page_id=article_id,
        properties={STATUS_PROPERTY: {"select": {"name": "Published"}}},
    )

def get_post_content(page_id):
    """Extract page body content. Raises ValueError if empty."""
    blocks = notion.blocks.children.list(block_id=page_id)["results"]
    text_types = ("paragraph", "heading_1", "heading_2", "heading_3",
                  "bulleted_list_item", "numbered_list_item", "quote")
    content = ""
    for block in blocks:
        if block["type"] in text_types:
            rich_texts = block[block["type"]].get("rich_text", [])
            content += "".join(rt["plain_text"] for rt in rich_texts)
    content = content.strip()
    if not content:
        raise ValueError(f"Post {page_id} has no content")
    return content

def publish_to_platform(post_content):
    """Call the platform API. Returns the published URL."""
    # Platform-specific implementation goes here
    raise NotImplementedError("Implement platform API call")

def main():
    posts = get_posts_to_publish()
    for post in posts:
        # Get linked article
        articles_relation = post["properties"]["Articles"]["relation"]
        if not articles_relation:
            continue
        article_id = articles_relation[0]["id"]

        # Guard: skip if already published
        status = get_article_status(article_id)
        if status == "Published":
            continue

        # Guard: skip if post body is empty
        try:
            content = get_post_content(post["id"])
        except ValueError as e:
            print(f"Skipping {post['id']}: {e}")
            continue

        # Claim the post
        set_idempotency_flag(post["id"])

        try:
            # Publish
            published_url = publish_to_platform(content)

            # Success
            mark_published(post["id"], published_url, article_id)

        except Exception as e:
            # Failure: release the claim
            clear_idempotency_flag(post["id"])
            print(f"Failed to publish {post['id']}: {e}")

if __name__ == "__main__":
    main()
```

**Adaptez `publish_to_platform()` pour chaque API de plateforme.** Le reste de la structure reste identique.

#### Patron du wrapper Bash

Chaque script Python dispose d'un wrapper Bash qui gere le lock, l'activation du venv et les notifications d'echec :

```bash
#!/bin/bash
source "$(dirname "$0")/common.sh"
acquire_lock "platform_publish"
activate_venv
cd "$PROJECT_DIR"
run_with_notify "platform-publish" python3 src/publish_platform.py
```

Copiez `templates/common.sh` dans votre repertoire `scripts/`. Il fournit :
- `acquire_lock "name"` -- lock base sur le PID avec detection des processus obsoletes
- `activate_venv` -- active le venv Python
- `run_with_notify "name" cmd` -- execute la commande, envoie une alerte webhook en cas d'echec (anti-spam : une fois toutes les 15 minutes maximum)

Generez un wrapper par script du pipeline. Pour une configuration complete (Ghost + 5 reseaux sociaux), cela donne :

| Script | Fonction | Intervalle |
|--------|----------|------------|
| `run_ghost_sync.sh` | Pousser les articles Notion vers Ghost | 120s |
| `run_ghost_published.sh` | Detecter le statut de publication Ghost | 300s |
| `run_linkedin_publish.sh` | Publier les posts LinkedIn | 60s |
| `run_twitter_publish.sh` | Publier les posts Twitter | 60s |
| `run_facebook_publish.sh` | Publier les posts Facebook | 60s |
| `run_mastodon_publish.sh` | Publier les posts Mastodon | 60s |
| `run_bluesky_publish.sh` | Publier les posts Bluesky | 60s |
| `run_sync_dates.sh` | Propager les dates de l'horloge principale | 120s |

Ne generez que les scripts des plateformes selectionnees.

### Etape 6 : Creation du contenu (votre responsabilite)

**Ce point est essentiel a communiquer clairement.**

Le pipeline ne genere PAS de contenu. Il publie ce que vous placez dans les bases de donnees.

Le flux de travail est le suivant :
1. **Vous redigez votre article** dans Notion (la synchronisation Ghost le pousse directement vers Ghost)
2. **Vous passez a 🚀 (Ready)** sur une plateforme dans la base Articles — cela signale votre intention
3. **Vous redigez le post** dans la base plateforme (ex. LinkedIn, Twitter)
4. **Vous passez a ✅ (Generated)** — cela indique au pipeline que le contenu est pret
5. **Le pipeline prend le relais** — planification, publication, gardes anti-doublon

**L'etape 🚀 → ✅ est manuelle par defaut.** Si vous passez a 🚀 sans jamais rediger de contenu ni passer a ✅, l'article reste a 🚀 indefiniment. Le pipeline ne le touchera pas. C'est volontaire — le pipeline gere la logistique, pas les decisions editoriales.

C'est le point d'extension. Vous pouvez :
- **Rediger manuellement** dans chaque base plateforme
- **Utiliser des prompts IA** pour generer des posts differencies a partir de votre article Ghost
- **Construire votre propre automatisation** qui lit la base Articles et cree les posts plateforme

Le pipeline ne se soucie pas de la facon dont le contenu arrive dans les bases. Il se soucie uniquement :
1. Que du contenu existe dans le corps de la page (le publisher le verifie — les posts vides sont ignores)
2. Que le statut soit a ✅ ou au-dela

Dites a l'utilisateur : "C'est ici que vous branchez votre propre generation de contenu. Utilisez vos prompts IA preferes, redigez manuellement, ou construisez votre propre automatisation -- le pipeline gere le reste. Assurez-vous simplement que le post contient du contenu avant de le marquer ✅."

### Etape 7 : Configuration du planificateur

Detectez le systeme d'exploitation de l'utilisateur et generez la configuration de planification appropriee.

#### Detection de l'OS

```bash
uname -s  # Darwin = macOS, Linux = Linux
```

#### macOS : LaunchAgents

Generez des fichiers `.plist` a partir de `templates/scheduler/launchagent.plist`. Un par script du pipeline.

```bash
# Installation
cp templates/scheduler/launchagent.plist \
  ~/Library/LaunchAgents/com.VOTRENOM.PLATEFORME-publish.plist
# Editez : remplacez VOTRENOM, PLATEFORME, les chemins et l'intervalle

# Chargement
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.VOTRENOM.PLATEFORME-publish.plist

# Verification
launchctl list | grep VOTRENOM

# Dechargement
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.VOTRENOM.PLATEFORME-publish.plist
```

Parametres cles dans le plist :
- `StartInterval` : intervalle de polling en secondes (60 pour les publishers, 120 pour la synchronisation)
- `WorkingDirectory` : chemin absolu vers le projet
- `RunAtLoad` : definir a `false` (demarre au prochain intervalle, pas immediatement)

#### Linux : timers systemd

Generez des paires de fichiers `.service` et `.timer` a partir de `templates/scheduler/`. Une paire par script du pipeline.

```bash
mkdir -p ~/.config/systemd/user/

# Copie et personnalisation
cp templates/scheduler/systemd.service \
  ~/.config/systemd/user/notion-PLATEFORME-publish.service
cp templates/scheduler/systemd.timer \
  ~/.config/systemd/user/notion-PLATEFORME-publish.timer

# Activation
systemctl --user daemon-reload
systemctl --user enable --now notion-PLATEFORME-publish.timer

# Verification
systemctl --user status notion-PLATEFORME-publish.timer
journalctl --user -u notion-PLATEFORME-publish.service
```

Parametres cles dans le timer :
- `OnUnitActiveSec` : intervalle de polling (60 pour les publishers, 120 pour la synchronisation)
- `Persistent=true` : rattrape les executions manquees apres une mise en veille ou un redemarrage

#### Solution de repli : cron

Si ni launchd ni systemd ne sont disponibles :

```cron
# Publishers (toutes les minutes)
* * * * * /path/to/project/scripts/run_linkedin_publish.sh >> /path/to/project/logs/linkedin_publish.log 2>&1

# Scripts de synchronisation (toutes les 2 minutes)
*/2 * * * * /path/to/project/scripts/run_ghost_sync.sh >> /path/to/project/logs/ghost_sync.log 2>&1

# Orchestrateur de dates (toutes les 2 minutes)
*/2 * * * * /path/to/project/scripts/run_sync_dates.sh >> /path/to/project/logs/sync_dates.log 2>&1
```

Details complets : `docs/scheduling.md`

### Etape 8 : Test de bout en bout

Guidez l'utilisateur a travers un cycle complet pour verifier que tout fonctionne.

**Procedure de test :**

1. **Creez un article de test** dans la base Articles
   - Titre : "Pipeline Test - [date]"
   - Definissez le statut d'une plateforme sur Ready

2. **Executez le script de synchronisation manuellement**
   ```bash
   bash scripts/run_ghost_sync.sh  # ou la plateforme concernee
   ```
   - Verifiez : le statut est passe de Ready a Generated
   - Verifiez : une nouvelle page est apparue dans la base plateforme

3. **Definissez une date de publication** sur le post plateforme
   - Definissez la date quelques minutes dans le passe
   - Executez l'orchestrateur de dates :
     ```bash
     bash scripts/run_sync_dates.sh
     ```
   - Verifiez : le statut est passe de Generated a Scheduled (ou verifiez que les autres plateformes ont recu leurs dates)

4. **Executez le publisher manuellement**
   ```bash
   bash scripts/run_linkedin_publish.sh  # ou la plateforme concernee
   ```
   - Verifiez : Platform URL contient maintenant l'URL publiee
   - Verifiez : le statut de l'article est passe a Published

5. **Executez le publisher a nouveau** -- il ne devrait rien faire (verification anti-doublon)

6. **Verifiez les locks**
   ```bash
   ls locks/  # Devrait etre vide apres la fin des scripts
   ```

En cas d'echec a une etape, consultez `logs/` pour les messages d'erreur.

---

## Reference

### Resume de la machine a etats

Cinq etats, trois transitions automatisees :

| Etat | Emoji | Defini par | Suivant |
|------|-------|------------|---------|
| Draft | `Draft` | Utilisateur | Ready (manuel) |
| Ready | `Ready` | Utilisateur | Generated (vous redigez le contenu, puis passez a ✅) |
| Generated | `Generated` | Utilisateur (ou automatisation) | Scheduled (pipeline) |
| Scheduled | `Scheduled` | Pipeline | Published (pipeline) |
| Published | `Published` | Pipeline | Terminal |

En cas d'echec : retour a l'etat precedent pour reessai automatique. Les posts vides sont ignores (garde-fou de validation du contenu).

Reference complete : `docs/state-machine.md`

### Planification par horloge principale

Definissez UNE date sur UNE plateforme. Toutes les autres sont calculees automatiquement.

```
Ghost      <- master - 15 min   (le blog est en ligne avant que les reseaux sociaux n'y renvoient)
LinkedIn   <- horloge principale (vous definissez cette date)
Facebook   <- master + 15 min
Twitter    <- master + 30 min
Mastodon   <- master + 45 min
Bluesky    <- master + 60 min
```

La plateforme de l'horloge principale est configurable via `MASTER_CLOCK_PLATFORM` dans le `.env`. Par defaut : LinkedIn.

Les decalages sont configurables dans le dictionnaire `OFFSETS` du script orchestrateur de dates.

Reference complete : `docs/scheduling.md`

### Protection anti-doublon

Trois couches empechent la publication en double d'un meme article :

**Couche 1 : Lock au niveau OS.**
`acquire_lock` dans `common.sh` garantit qu'une seule instance de chaque script s'execute a la fois. Utilise des fichiers PID avec detection des processus obsoletes.

**Couche 2 : Verification de relation.**
Avant de creer une page plateforme, le script de synchronisation interroge la base plateforme : "Une page existe-t-elle deja pour cet article ?" Si oui, on passe.

**Couche 3 : Avancement preventif du statut.**
Le script de synchronisation passe Ready -> Generated AVANT de creer la page plateforme. Si un cycle concurrent s'execute, il voit Generated et passe. En cas d'echec, le retour a Ready permet le reessai.

**Idempotence de publication :**
```
1. Ecrire URL = "publishing.in.progress"   (reserver le post)
2. Appeler l'API de la plateforme          (publier)
3a. Succes -> URL = URL reelle publiee
3b. Echec -> URL = vide                    (liberer la reservation)
```

### Gestion des fichiers lock

Fournie par `templates/common.sh`, source au debut de chaque wrapper.

- **`acquire_lock "name"`** -- cree `locks/{name}.lock` avec le PID courant. Si un lock existe, verifie si le PID est actif. PID mort = lock obsolete, nettoye automatiquement. PID actif = execution ignoree proprement.
- **Nettoyage** -- trap sur EXIT, INT, TERM supprime le fichier lock.
- **Repertoire des locks** -- `locks/` a la racine du projet, cree automatiquement.

### Ajouter une nouvelle plateforme

Le pipeline est concu pour etre extensible. Pour toute plateforme disposant d'une API de publication :

1. Creez une base de donnees Notion (meme schema que les autres bases plateforme)
2. Ajoutez une propriete Select de statut a la base Articles
3. Ecrivez un script de publication suivant le patron du publisher
4. Creez un wrapper Bash utilisant `common.sh`
5. Ajoutez un decalage dans l'orchestrateur de dates
6. Ajoutez une entree dans le planificateur

Guide complet : `docs/add-a-platform.md`

---

## Reference du schema Notion

### Base Articles (centrale)

| Propriete | Type | Requis | Fonction |
|-----------|------|--------|----------|
| Title | Title | Toujours | Titre de l'article |
| URL | URL | Toujours | URL source ou reference |
| Ghost | Select | Si Ghost utilise | Statut de publication Ghost |
| LinkedIn | Select | Si LinkedIn utilise | Statut de publication LinkedIn |
| Twitter | Select | Si Twitter utilise | Statut de publication Twitter |
| Facebook | Select | Si Facebook utilise | Statut de publication Facebook |
| Mastodon | Select | Si Mastodon utilise | Statut de publication Mastodon |
| Bluesky | Select | Si Bluesky utilise | Statut de publication Bluesky |

Chaque propriete Select utilise les memes options : `Draft`, `Ready`, `Generated`, `Scheduled`, `Published`.

### Base plateforme (modele generique)

| Propriete | Type | Fonction |
|-----------|------|----------|
| Name | Title | Titre ou identifiant du post |
| Articles | Relation -> Articles DB | Lien vers l'article source |
| Publication Date | Date | Date de publication (definie par l'horloge principale ou manuellement) |
| Platform URL | URL | Vide jusqu'a la publication, contient ensuite l'URL en ligne |

Le contenu du post est redige dans le **corps de la page**. Chaque plateforme dispose de sa propre base pour que les posts puissent etre adaptes a son audience.

---

## Metadonnees du skill

| Champ | Valeur |
|-------|--------|
| Version | 1.0.0 |
| Domaine | Publication, Automatisation |
| Complexite | Intermediaire |
| Prerequis | Python 3.10+, espace de travail Notion, au moins une plateforme cible |
