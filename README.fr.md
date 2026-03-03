# publish-from-notion

> Transformez Notion en votre CMS de publication multi-plateforme.

[Read in English → README.md](README.md)

[![GitHub Sponsors](https://img.shields.io/github/sponsors/davanac?style=social)](https://github.com/sponsors/davanac)

## Ce que ca fait

Vous ecrivez dans Notion. Le pipeline pousse vos articles vers Ghost (votre blog SEO principal) et publie vos posts specifiques a chaque plateforme sur LinkedIn, Twitter, Facebook, Mastodon et Bluesky -- selon le calendrier prevu, avec protection anti-doublon. Une seule date de publication, toutes les plateformes.

## Pipeline

```
Notion (vous ecrivez ici)
  │
  ├── push direct
  ▼
Ghost (publication SEO principale)
  │
  ├── vous creez des posts differencies
  ▼
Plateformes sociales
  ├── LinkedIn    master + 0 min
  ├── Facebook    master + 15 min
  ├── Twitter     master + 30 min
  ├── Mastodon    master + 45 min
  └── Bluesky     master + 60 min
```

## Demarrage rapide

```bash
# 1. Clonez le skill
git clone https://github.com/davanac/publish-from-notion.git ~/.claude/skills/publish-from-notion

# 2. Lancez l'assistant de configuration
/publish-from-notion

# 3. Suivez les instructions — Claude vous guide a travers la creation de la base de donnees, la configuration des API et la planification
```

## Contenu du projet

| Fichier | Role |
|---------|------|
| `SKILL.md` | Assistant de configuration interactif pour Claude Code |
| `docs/architecture.md` | Vue d'ensemble du pipeline et schema de base de donnees |
| `docs/state-machine.md` | La machine a etats de publication |
| `docs/scheduling.md` | Horloge principale et planification cross-platform |
| `docs/api-setup.md` | Guide pas a pas pour les credentials API |
| `docs/add-a-platform.md` | Comment ajouter de nouvelles plateformes |
| `templates/common.sh` | Fichiers lock, venv, notifications |
| `templates/.env.example` | Template des credentials API |
| `templates/scheduler/` | Templates launchd, systemd |

## La machine a etats

| Statut | Signification |
|--------|---------------|
| Draft | Pas pret |
| Ready | Declenche le pipeline |
| Generated | Contenu cree dans la base de donnees de la plateforme |
| Scheduled | Date de publication definie |
| Published | En ligne sur la plateforme |

## Vous ecrivez le contenu

Ce pipeline ne genere **pas** de contenu. Vous ecrivez vos articles dans Notion (pousses vers Ghost), et vous creez vos propres posts specifiques a chaque plateforme. Utilisez vos prompts IA preferes, ecrivez manuellement, ou construisez votre propre automatisation -- le pipeline gere la publication, la planification et la prevention des doublons.

## Plateformes supportees

Ghost, LinkedIn, Twitter/X, Facebook, Mastodon, Bluesky.

Modulaire -- choisissez la combinaison qui vous convient.

## Fonctionne sur

macOS (launchd), Linux (systemd), tout OS (cron).

## Qui est derriere

Ceci est l'infrastructure open-source derriere [da.van.ac](https://da.van.ac). L'intelligence editoriale n'est pas incluse -- uniquement la tuyauterie. Les parties ennuyeuses qui ont pris des mois a stabiliser.

## Support

Mettez une etoile au repo, partagez-le, ou [sponsorisez sur GitHub](https://github.com/sponsors/davanac). Voir [SUPPORT.md](SUPPORT.md).

## Licence

MIT
