# publish-from-notion

> Turn Notion into your multi-platform publishing CMS.

[Lire en francais → README.fr.md](README.fr.md)

[![GitHub Sponsors](https://img.shields.io/github/sponsors/davanac?style=social)](https://github.com/sponsors/davanac)

## What this does

You write in Notion. The pipeline pushes your articles to Ghost (your primary SEO blog) and publishes your platform-specific posts to LinkedIn, Twitter, Facebook, Mastodon, and Bluesky — on schedule, with anti-duplicate protection. One publication date, all platforms.

## Pipeline

```
Notion (you write here)
  │
  ├── direct push
  ▼
Ghost (primary SEO publication)
  │
  ├── you create differentiated posts
  ▼
Social platforms
  ├── LinkedIn    master + 0 min
  ├── Facebook    master + 15 min
  ├── Twitter     master + 30 min
  ├── Mastodon    master + 45 min
  └── Bluesky     master + 60 min
```

## Quick start

```bash
# 1. Clone the skill
git clone https://github.com/davanac/publish-from-notion.git ~/.claude/skills/publish-from-notion

# 2. Run the setup wizard
/publish-from-notion

# 3. Follow the prompts — Claude walks you through database creation, API setup, and scheduling
```

## What's inside

| File | Purpose |
|------|---------|
| `SKILL.md` | Interactive setup wizard for Claude Code |
| `docs/architecture.md` | Pipeline overview and database schema |
| `docs/state-machine.md` | The publication state machine |
| `docs/scheduling.md` | Master clock and cross-platform scheduling |
| `docs/api-setup.md` | Step-by-step API credentials guide |
| `docs/add-a-platform.md` | How to add new platforms |
| `templates/common.sh` | Lock files, venv, notifications |
| `templates/.env.example` | API credentials template |
| `templates/scheduler/` | launchd, systemd templates |

## The state machine

| Status | Meaning |
|--------|---------|
| Draft | Not ready |
| Ready | Triggers pipeline |
| Generated | Content created in platform database |
| Scheduled | Publication date set |
| Published | Live on the platform |

## You write the content

This pipeline does **not** generate content. You write your articles in Notion (pushed to Ghost), and create your own platform-specific posts. Use your favorite AI prompts, write manually, or build your own automation — the pipeline handles publication, scheduling, and duplicate prevention.

## Supported platforms

Ghost, LinkedIn, Twitter/X, Facebook, Mastodon, Bluesky.

Modular — pick any combination.

## Works on

macOS (launchd), Linux (systemd), any OS (cron).

## Built by

This is the open-source infrastructure behind [da.van.ac](https://da.van.ac). The editorial intelligence is not included — only the plumbing. The boring parts that took months to get right.

## Support

Star the repo, share it, or [sponsor on GitHub](https://github.com/sponsors/davanac). See [SUPPORT.md](SUPPORT.md).

## License

MIT
