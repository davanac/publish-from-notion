---
name: publish-from-notion
description: Set up an automated multi-platform publishing pipeline from Notion. Use when building a newsroom that publishes to Ghost, LinkedIn, Twitter, Facebook, Mastodon, or Bluesky from a central Notion CMS.
---

# Multi-platform publishing pipeline from Notion

An interactive setup wizard that builds a complete publication pipeline: write in Notion, publish to Ghost and social platforms, schedule once, let the pipeline handle the rest.

## When to use

- Setting up a new multi-platform publishing pipeline
- Adding a new social platform to an existing setup
- Configuring the master clock and cross-platform scheduling
- Debugging publication pipeline issues
- Understanding the state machine and anti-duplicate patterns

## The pattern in 30 seconds

```
Write in Notion
  → push to Ghost (your primary SEO platform)
    → create platform-specific posts in each database
      → set ONE publication date (master clock)
        → pipeline publishes everywhere with staggered offsets
          → anti-duplicate guards prevent double-posting
```

The pipeline does NOT generate content. It publishes what you put in the databases.

---

## Interactive setup flow

Walk the user through each step. Only configure platforms they select. Ask before proceeding to the next step.

### Step 1: Platform selection

Ask the user which platforms they want to publish to.

**Available platforms:**

| Platform | Role | Notes |
|----------|------|-------|
| Ghost | Primary publication (SEO, blog) | Recommended. Open source, self-hostable. |
| LinkedIn | Professional distribution | Long-form, career-oriented audience |
| Twitter/X | Short-form distribution | Hook + link pattern |
| Facebook | Broad distribution | Conversational, accessible tone |
| Mastodon | Federated distribution | Technical, analytical audience |
| Bluesky | Decentralized distribution | Concise, community-driven |

**Rules:**
- The setup is modular. Only selected platforms are configured.
- Ghost is strongly recommended as the primary platform but not mandatory.
- At least one platform must be selected.

Ask: "Which platforms do you want to publish to? I'll configure only what you need."

### Step 2: Notion database setup

Guide the user through creating the Notion databases. Two types: one central Articles database (always), and one database per selected platform.

#### Articles database (central hub)

Every article lives here. Each selected platform gets a status property.

| Property | Type | Purpose |
|----------|------|---------|
| Title | Title | Article title |
| URL | URL | Source URL or reference link |
| _[Platform]_ | Select | One per selected platform (see status options below) |

**Status options for each platform Select property:**

| Option | Meaning |
|--------|---------|
| `Draft` | Not ready for the pipeline |
| `Ready` | Triggers pipeline processing |
| `Generated` | Content created in platform database |
| `Scheduled` | Publication date is set |
| `Published` | Published successfully |

Only create Select properties for platforms the user selected in Step 1.

#### Platform databases (one per platform)

Each selected platform gets its own database where the user writes the actual post content.

| Property | Type | Purpose |
|----------|------|---------|
| Name | Title | Post title or identifier |
| Articles | Relation -> Articles DB | Links back to the source article |
| Publication Date | Date | When to publish |
| Platform URL | URL | Filled by the pipeline after publication |

The post content itself goes in the **page body**, not in properties.

**Notion integration:** Remind the user to share all databases with their Notion integration (... -> Connections -> their integration name). Walk them through creating the integration if they don't have one (see Step 4).

### Step 3: State machine configuration

Explain how articles flow through the pipeline.

```
  Draft        Ready       Generated    Scheduled    Published
    🚧    ->    🚀    ->     ✅     ->     ⏰    ->     📢

              you set      pipeline     pipeline     pipeline
             manually       sets         sets         sets
```

**Who does what:**

| Transition | Who | What happens |
|------------|-----|-------------|
| -> Ready | User | Marks the article ready for a platform |
| Ready -> Generated | Pipeline | Sync script creates a page in the platform database |
| Generated -> Scheduled | Pipeline | Date orchestrator sets publication dates |
| Scheduled -> Published | Pipeline | Publisher script calls the platform API |

**On failure:** The pipeline rolls back to the previous state so the next cycle can retry automatically.

Full details: `docs/state-machine.md`

### Step 4: API credentials

For each selected platform, guide the user step-by-step through API setup. Reference `docs/api-setup.md` for detailed instructions per platform.

**Notion (always required):**
1. Create an integration at notion.so/my-integrations
2. Grant Read, Update, and Insert content capabilities
3. Copy the Internal Integration Secret (`secret_...`)
4. Share each database with the integration
5. Copy each database ID from the URL

**Ghost:**
- Admin panel -> Settings -> Integrations -> Add custom integration
- Copy the Admin API Key (format: `{key_id}:{key_secret}`)

**LinkedIn:**
- Create a LinkedIn App (requires a Company Page)
- Request "Share on LinkedIn" product access
- Generate OAuth token with `w_member_social` scope
- Get person URN from the `/me` endpoint
- Warn: token expires in 60 days

**Twitter/X:**
- Developer account at developer.twitter.com
- Create Project + App
- Set permissions to Read and Write BEFORE generating tokens
- Generate all four keys (API Key, API Secret, Access Token, Access Secret)

**Facebook:**
- Create a Business app at developers.facebook.com
- Add Facebook Login and Pages products
- Generate a **Page** Access Token (not User token) via Graph API Explorer
- Exchange for long-lived token

**Mastodon:**
- On YOUR instance: Preferences -> Development -> New Application
- Scopes: `read` and `write:statuses`
- Copy the Access token

**Bluesky:**
- Settings -> App Passwords -> Add App Password
- Use handle format: `yourname.bsky.social`
- Never use account password in `.env`

**Generate the `.env` file** with only the relevant sections uncommented based on selected platforms:

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

Uncomment only the sections for selected platforms.

### Step 5: Script generation

Generate Python publish scripts and Bash wrappers for each selected platform.

#### Publisher script pattern (Python)

Each publisher follows the same structure:

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

        # Claim the post
        set_idempotency_flag(post["id"])

        try:
            # Extract post content from page body
            content = get_post_content(post["id"])  # Implement per platform

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

**Customize `publish_to_platform()` for each platform API.** The rest of the structure stays identical.

#### Bash wrapper pattern

Each Python script gets a Bash wrapper that handles locking, venv activation, and failure notifications:

```bash
#!/bin/bash
source "$(dirname "$0")/common.sh"
acquire_lock "platform_publish"
activate_venv
cd "$PROJECT_DIR"
run_with_notify "platform-publish" python3 src/publish_platform.py
```

Copy `templates/common.sh` to your `scripts/` directory. It provides:
- `acquire_lock "name"` -- PID-based lock with stale detection
- `activate_venv` -- activates Python venv
- `run_with_notify "name" cmd` -- runs command, sends webhook alert on failure (anti-spam: max once per 15 minutes)

Generate one wrapper per pipeline script. For a full setup (Ghost + 5 social), that means:

| Script | Purpose | Interval |
|--------|---------|----------|
| `run_ghost_sync.sh` | Push Notion articles to Ghost | 120s |
| `run_ghost_published.sh` | Detect Ghost publication status | 300s |
| `run_linkedin_publish.sh` | Publish LinkedIn posts | 60s |
| `run_twitter_publish.sh` | Publish Twitter posts | 60s |
| `run_facebook_publish.sh` | Publish Facebook posts | 60s |
| `run_mastodon_publish.sh` | Publish Mastodon posts | 60s |
| `run_bluesky_publish.sh` | Publish Bluesky posts | 60s |
| `run_sync_dates.sh` | Propagate master clock dates | 120s |

Generate only the scripts for selected platforms.

### Step 6: Content generation extension point

**This is critical to communicate clearly.**

The pipeline does NOT generate content. It publishes what you put in the databases.

The workflow is:
1. **You write your article** in Notion (the Ghost sync pushes it to Ghost directly)
2. **You create platform-specific posts** in each platform database
3. **The pipeline publishes them** at the scheduled time

This is the extension point. You can:
- **Write manually** in each platform database
- **Use AI prompts** to generate differentiated posts from your Ghost article
- **Build your own automation** that reads from the Articles database and creates platform posts

The pipeline doesn't care how content gets into the databases. It only cares that it's there when publication time arrives.

Tell the user: "This is where you plug in your own content generation. Use your favorite AI prompts, write manually, or build your own automation -- the pipeline handles the rest."

### Step 7: Scheduler setup

Detect the user's OS and generate the appropriate scheduler configuration.

#### Detect OS

```bash
uname -s  # Darwin = macOS, Linux = Linux
```

#### macOS: LaunchAgents

Generate `.plist` files from `templates/scheduler/launchagent.plist`. One per pipeline script.

```bash
# Install
cp templates/scheduler/launchagent.plist \
  ~/Library/LaunchAgents/com.YOURNAME.PLATFORM-publish.plist
# Edit: replace YOURNAME, PLATFORM, paths, and interval

# Load
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.YOURNAME.PLATFORM-publish.plist

# Check
launchctl list | grep YOURNAME

# Unload
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.YOURNAME.PLATFORM-publish.plist
```

Key settings in the plist:
- `StartInterval`: polling interval in seconds (60 for publishers, 120 for sync)
- `WorkingDirectory`: absolute path to project
- `RunAtLoad`: set to `false` (start on next interval, not immediately)

#### Linux: systemd timers

Generate `.service` and `.timer` file pairs from `templates/scheduler/`. One pair per pipeline script.

```bash
mkdir -p ~/.config/systemd/user/

# Copy and customize
cp templates/scheduler/systemd.service \
  ~/.config/systemd/user/notion-PLATFORM-publish.service
cp templates/scheduler/systemd.timer \
  ~/.config/systemd/user/notion-PLATFORM-publish.timer

# Enable
systemctl --user daemon-reload
systemctl --user enable --now notion-PLATFORM-publish.timer

# Check
systemctl --user status notion-PLATFORM-publish.timer
journalctl --user -u notion-PLATFORM-publish.service
```

Key settings in the timer:
- `OnUnitActiveSec`: polling interval (60 for publishers, 120 for sync)
- `Persistent=true`: catch up on missed runs after sleep/reboot

#### Fallback: cron

If neither launchd nor systemd is available:

```cron
# Publishers (every minute)
* * * * * /path/to/project/scripts/run_linkedin_publish.sh >> /path/to/project/logs/linkedin_publish.log 2>&1

# Sync scripts (every 2 minutes)
*/2 * * * * /path/to/project/scripts/run_ghost_sync.sh >> /path/to/project/logs/ghost_sync.log 2>&1

# Date orchestrator (every 2 minutes)
*/2 * * * * /path/to/project/scripts/run_sync_dates.sh >> /path/to/project/logs/sync_dates.log 2>&1
```

Full details: `docs/scheduling.md`

### Step 8: End-to-end test

Walk the user through a complete cycle to verify everything works.

**Test procedure:**

1. **Create a test article** in the Articles database
   - Title: "Pipeline Test - [date]"
   - Set one platform status to Ready

2. **Run the sync script manually**
   ```bash
   bash scripts/run_ghost_sync.sh  # or whichever platform
   ```
   - Verify: status changed from Ready to Generated
   - Verify: a new page appeared in the platform database

3. **Set a publication date** on the platform post
   - Set the date to a few minutes in the past
   - Run the date orchestrator:
     ```bash
     bash scripts/run_sync_dates.sh
     ```
   - Verify: status changed from Generated to Scheduled (or check other platforms got dates)

4. **Run the publisher manually**
   ```bash
   bash scripts/run_linkedin_publish.sh  # or whichever platform
   ```
   - Verify: Platform URL is now filled with the published URL
   - Verify: article status changed to Published

5. **Run the publisher again** -- it should be a no-op (anti-duplicate check)

6. **Check locks**
   ```bash
   ls locks/  # Should be empty after scripts finish
   ```

If any step fails, check `logs/` for error output.

---

## Reference

### State machine summary

Five states, three automated transitions:

| State | Emoji | Set by | Next |
|-------|-------|--------|------|
| Draft | `Draft` | User | Ready (manual) |
| Ready | `Ready` | User | Generated (pipeline) |
| Generated | `Generated` | Pipeline | Scheduled (pipeline) |
| Scheduled | `Scheduled` | Pipeline | Published (pipeline) |
| Published | `Published` | Pipeline | Terminal |

On failure: rollback to previous state for automatic retry.

Full reference: `docs/state-machine.md`

### Master clock scheduling

Set ONE date on ONE platform. All others are calculated automatically.

```
Ghost      <- master - 15 min   (blog is live before social links to it)
LinkedIn   <- master clock      (you set this date)
Facebook   <- master + 15 min
Twitter    <- master + 30 min
Mastodon   <- master + 45 min
Bluesky    <- master + 60 min
```

The master clock platform is configurable via `MASTER_CLOCK_PLATFORM` in `.env`. Default: LinkedIn.

Offsets are configurable in the date orchestrator script's `OFFSETS` dictionary.

Full reference: `docs/scheduling.md`

### Anti-duplicate protection

Three layers prevent the same article from being published twice:

**Layer 1: OS-level lock.**
`acquire_lock` in `common.sh` ensures only one instance of each script runs at a time. Uses PID files with stale detection.

**Layer 2: Relation check.**
Before creating a platform page, the sync script queries the platform database: "Does a page already exist for this article?" If yes, skip.

**Layer 3: Status pre-advancement.**
The sync script sets Ready -> Generated BEFORE creating the platform page. If a concurrent cycle runs, it sees Generated and skips. On failure, rollback to Ready allows retry.

**Publication idempotency:**
```
1. Write URL = "publishing.in.progress"   (claim the post)
2. Call platform API                      (publish)
3a. Success -> URL = real published URL
3b. Failure -> URL = empty                (release the claim)
```

### Lock file management

Provided by `templates/common.sh`, sourced at the top of every wrapper script.

- **`acquire_lock "name"`** -- creates `locks/{name}.lock` with the current PID. If a lock exists, checks whether the PID is alive. Dead PID = stale lock, cleaned up automatically. Alive PID = skip execution gracefully.
- **Cleanup** -- trap on EXIT, INT, TERM removes the lock file.
- **Lock directory** -- `locks/` at project root, created automatically.

### Adding a new platform

The pipeline is designed to be extensible. For any platform with a posting API:

1. Create a Notion database (same schema as other platform DBs)
2. Add a status Select property to the Articles database
3. Write a publish script following the publisher pattern
4. Create a Bash wrapper using `common.sh`
5. Add an offset to the date orchestrator
6. Add a scheduler entry

Full guide: `docs/add-a-platform.md`

---

## Notion schema reference

### Articles database (central)

| Property | Type | Required | Purpose |
|----------|------|----------|---------|
| Title | Title | Always | Article title |
| URL | URL | Always | Source URL or reference |
| Ghost | Select | If using Ghost | Ghost publication status |
| LinkedIn | Select | If using LinkedIn | LinkedIn publication status |
| Twitter | Select | If using Twitter | Twitter publication status |
| Facebook | Select | If using Facebook | Facebook publication status |
| Mastodon | Select | If using Mastodon | Mastodon publication status |
| Bluesky | Select | If using Bluesky | Bluesky publication status |

Each Select property uses the same options: `Draft`, `Ready`, `Generated`, `Scheduled`, `Published`.

### Platform database (generic template)

| Property | Type | Purpose |
|----------|------|---------|
| Name | Title | Post title or identifier |
| Articles | Relation -> Articles DB | Links back to the source article |
| Publication Date | Date | When to publish (set by master clock or manually) |
| Platform URL | URL | Empty until published, then contains the live URL |

Post content is written in the **page body**. Each platform gets a separate database so posts can be tailored to that audience.

---

## Skill metadata

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Domain | Publishing, Automation |
| Complexity | Intermediate |
| Prerequisites | Python 3.10+, Notion workspace, at least one target platform |
