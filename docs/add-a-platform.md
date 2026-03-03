# Adding a New Platform

The pipeline is designed to be extensible. Follow these steps to add a platform that isn't included by default.

## What you need

1. A platform with a posting API (REST or SDK)
2. A Notion database for that platform's posts
3. A publish script that calls the API
4. A scheduler entry to run it periodically

## Step-by-step

### 1. Create the Notion database

Create a new database with these properties:

| Property | Type | Purpose |
|----------|------|---------|
| Name | Title | Post title or identifier |
| Articles | Relation → Articles DB | Links back to source article |
| Publication Date | Date | When to publish |
| Platform URL | URL | Filled after publication |

Share the database with your Notion integration (... → Connections → your integration).

Copy the database ID to your `.env`:
```bash
NOTION_DB_NEWPLATFORM=your-database-id
```

### 2. Add a status property to Articles

In your Articles database, add a new Select property named after your platform (e.g., "NewPlatform") with these options:

| Option | Color |
|--------|-------|
| 🚧 | Gray |
| 🚀 | Blue |
| ✅ | Green |
| ⏰ | Yellow |
| 📢 | Purple |

### 3. Create the publish script

Create `src/publish_newplatform.py`. The script should:

1. Load config from `.env`
2. Query the platform database for posts where:
   - `Publication Date` is in the past (or now)
   - `Platform URL` is empty
3. For each post:
   a. **Guard**: Check that the Articles status is not already 📢
   b. **Claim**: Set `Platform URL` to `publishing.in.progress`
   c. **Publish**: Call the platform API
   d. **On success**: Set `Platform URL` to the real URL, set Articles status to 📢
   e. **On failure**: Clear `Platform URL` (set to empty)

### 4. Create the wrapper script

Create `scripts/run_newplatform_publish.sh`:

```bash
#!/bin/bash
source "$(dirname "$0")/common.sh"
acquire_lock "newplatform_publish"
activate_venv
cd "$PROJECT_DIR"
run_with_notify "newplatform-publish" python3 src/publish_newplatform.py
```

Make it executable:
```bash
chmod +x scripts/run_newplatform_publish.sh
```

### 5. Add scheduling offset

In your date orchestrator script (`src/sync_publication_dates.py`), add the new platform to the offsets dictionary:

```python
OFFSETS = {
    "ghost":        -15,
    "facebook":      15,
    "twitter":       30,
    "mastodon":      45,
    "bluesky":       60,
    "newplatform":   75,   # 75 minutes after master
}
```

Also add the platform's configuration:

```python
PLATFORMS = {
    # ... existing platforms ...
    "newplatform": {
        "db_id": config["NOTION_DB_NEWPLATFORM"],
        "date_property": "Publication Date",
        "url_property": "Platform URL",
    },
}
```

### 6. Add a scheduler entry

**macOS (launchd):**
```bash
cp templates/scheduler/launchagent.plist ~/Library/LaunchAgents/com.yourname.newplatform-publish.plist
# Edit: replace PLATFORM with newplatform, set interval to 60
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.yourname.newplatform-publish.plist
```

**Linux (systemd):**
```bash
cp templates/scheduler/systemd.service ~/.config/systemd/user/notion-newplatform-publish.service
cp templates/scheduler/systemd.timer ~/.config/systemd/user/notion-newplatform-publish.timer
# Edit both files
systemctl --user daemon-reload
systemctl --user enable --now notion-newplatform-publish.timer
```

### 7. Test

1. Create a test post in the new platform database
2. Link it to an article via the Articles relation
3. Set a publication date in the past
4. Run the publish script manually:
   ```bash
   bash scripts/run_newplatform_publish.sh
   ```
5. Verify the post was published and the URL was written back

## Platform API tips

- **Rate limits**: Most platforms have rate limits. The lock file pattern ensures only one instance runs at a time, but be aware of per-minute or per-day limits.
- **Error handling**: Always handle HTTP 429 (rate limited) with exponential backoff.
- **Image uploads**: If your platform supports images, upload them separately before creating the post. Most APIs require a media ID, not a URL.
- **Link previews**: Some platforms (Bluesky, Mastodon) need you to fetch OpenGraph metadata to build link cards. Others (Twitter, Facebook) generate previews automatically.

## Example: Adding Threads

If Meta releases a public Threads API, you would:

1. Create a Threads database in Notion
2. Add a "Threads" select property to Articles
3. Create `src/publish_threads.py` using the Threads API
4. Add offset: `"threads": 90` (90 minutes after master)
5. Schedule with a 60s interval

The pattern is always the same. The only thing that changes is the API call.
