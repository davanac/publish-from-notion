# Pipeline Architecture

## The three layers

publish-from-notion organizes your content in three layers:

```
Notion (editorial hub — you write here)
   │
   │  Direct content push
   ▼
Ghost (primary publication — SEO, open source)
   │
   │  You create platform-specific posts in each database
   ▼
Social platforms (differentiated distribution)
   ├── LinkedIn   (professional, long-form)
   ├── Twitter/X  (hook + link)
   ├── Facebook   (conversational, accessible)
   ├── Mastodon   (analytical, technical)
   └── Bluesky    (concise, community-driven)
```

**Each platform gets its own content.** This is not cross-posting. You write differentiated posts tailored to each audience. The pipeline handles the logistics of publishing them at the right time.

## Notion database schema

### Central: Articles database

This is your content hub. Every article lives here. Each platform has a status property tracking where it is in the publication pipeline.

| Property | Type | Purpose |
|----------|------|---------|
| Title | Title | Article title |
| URL | URL | Source URL or reference |
| Ghost | Select | Ghost publication status |
| LinkedIn | Select | LinkedIn publication status |
| Twitter | Select | Twitter publication status |
| Facebook | Select | Facebook publication status |
| Mastodon | Select | Mastodon publication status |
| Bluesky | Select | Bluesky publication status |

Each status property uses the same set of options:

| Value | Meaning |
|-------|---------|
| 🚧 | Draft — not ready |
| 🚀 | Ready — triggers the pipeline |
| ✅ | Content created in platform database |
| ⏰ | Scheduled — publication time set |
| 📢 | Published |

Only create status properties for platforms you actually use.

### Per-platform databases

Each social platform has its own database where you write the post content. These databases are linked to the Articles database via a relation.

| Property | Type | Purpose |
|----------|------|---------|
| Name | Title | Post title or identifier |
| Articles | Relation → Articles DB | Links back to source article |
| Publication Date | Date | When to publish |
| Platform URL | URL | Published URL (filled by pipeline) |

The post content itself is written in the page body — not in properties.

## The three pipeline phases

### Phase 1: Content creation

You write your article in Notion. When ready:

1. **Ghost**: Set the Ghost status to 🚀. The pipeline pushes the Notion page content directly to Ghost as a draft. Status becomes ✅.
2. **Social platforms**: Set each platform status to 🚀. Create the corresponding post in the platform database (write it yourself, or use your own AI prompts to generate it). Status becomes ✅.

### Phase 2: Scheduling

You set a publication date on ONE platform (the master clock — typically LinkedIn). The date orchestrator automatically calculates and sets dates for all other platforms with configurable offsets.

See [scheduling.md](scheduling.md) for the master clock pattern.

### Phase 3: Publication

Publisher scripts poll each platform database for posts whose publication date has passed. When the time comes:

1. Mark the post with a temporary flag (`publishing.in.progress`)
2. Call the platform API
3. On success: write the published URL, update status to 📢
4. On failure: remove the flag, status stays at ⏰ for retry

See [state-machine.md](state-machine.md) for the full state transition model.

## Wrapper script pattern

Each pipeline step is a Python script wrapped in a Bash runner:

```bash
#!/bin/bash
source "$(dirname "$0")/common.sh"
acquire_lock "ghost_sync"
activate_venv
cd "$PROJECT_DIR"
run_with_notify "ghost-sync" python3 src/sync_ghost.py
```

The wrapper handles:
- **Lock acquisition** — prevents concurrent execution
- **Virtual environment** — activates Python venv
- **Failure notification** — alerts via webhook on error
- **Anti-spam** — won't alert more than once per 15 minutes

See `templates/common.sh` for the implementation.

## Where you plug in your content generation

The pipeline does not generate content. It publishes what you put in the databases.

This is the extension point. You can:
- **Write manually** in each platform database
- **Use AI prompts** to generate platform-specific posts from your Ghost article
- **Build your own automation** that reads from the Articles database and creates platform posts

The pipeline doesn't care how the content gets into the databases. It only cares that it's there when publication time arrives.
