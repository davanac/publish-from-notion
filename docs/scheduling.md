# Scheduling Architecture

## The master clock pattern

You schedule ONE publication time on ONE platform. All other platforms are calculated automatically with configurable offsets.

```
Ghost      ← master - 15 min    (blog is live before social posts link to it)
LinkedIn   ← master clock       (you set this date manually)
Facebook   ← master + 15 min
Twitter    ← master + 30 min
Mastodon   ← master + 45 min
Bluesky    ← master + 60 min
```

### Why this works

- **One decision, six publications.** You only think about timing once.
- **Ghost publishes first** so social posts can link to a live article.
- **Staggered social posts** avoid audience fatigue and API rate limits.
- **Each platform hits its audience** at slightly different times.

### Choosing your master clock

The default master clock is LinkedIn because it typically drives the most strategic timing decisions (professional audience, weekday mornings). But you can set any platform as master via `MASTER_CLOCK_PLATFORM` in your `.env`.

## Offset configuration

The date orchestrator script reads the master clock publication date and applies offsets to all other platforms:

```python
OFFSETS = {
    "ghost":    -15,   # minutes before master
    "facebook":  15,   # minutes after master
    "twitter":   30,
    "mastodon":  45,
    "bluesky":   60,
}
```

To customize offsets, edit the `OFFSETS` dictionary in your date orchestrator script.

### Rules

- Offsets are in minutes. Negative = before master, positive = after.
- The orchestrator only updates dates that differ from the calculated value (tolerance: 1 minute).
- Only processes publications within the last 7 days to avoid touching old content.
- Respects your configured timezone (`TIMEZONE` in `.env`).

## Cross-platform scheduler setup

The pipeline runs on intervals using your OS scheduler. Each script type has a recommended interval:

| Script type | Interval | Purpose |
|-------------|----------|---------|
| Publisher | 60s | Time-sensitive — publishes when date arrives |
| Sync | 120s | Creates platform pages from 🚀 articles |
| Date orchestrator | 120s | Propagates dates from master clock |

### macOS: launchd

LaunchAgents are the native macOS way to run periodic tasks.

**Install a LaunchAgent:**
```bash
# Copy and customize the template
cp templates/scheduler/launchagent.plist ~/Library/LaunchAgents/com.yourname.ghost-sync.plist
# Edit the plist: replace placeholders with your paths

# Load it
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.yourname.ghost-sync.plist
```

**Manage:**
```bash
# Check if running
launchctl list | grep yourname

# Stop
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.yourname.ghost-sync.plist

# Reload after editing
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.yourname.ghost-sync.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.yourname.ghost-sync.plist
```

See `templates/scheduler/launchagent.plist` for the full template.

### Linux: systemd

User-level systemd timers are the modern Linux equivalent.

**Install a timer:**
```bash
mkdir -p ~/.config/systemd/user/

# Copy and customize both files
cp templates/scheduler/systemd.service ~/.config/systemd/user/notion-ghost-sync.service
cp templates/scheduler/systemd.timer ~/.config/systemd/user/notion-ghost-sync.timer
# Edit both files: replace placeholders

# Enable and start
systemctl --user daemon-reload
systemctl --user enable --now notion-ghost-sync.timer
```

**Manage:**
```bash
# Check status
systemctl --user status notion-ghost-sync.timer
systemctl --user list-timers

# View logs
journalctl --user -u notion-ghost-sync.service

# Stop
systemctl --user disable --now notion-ghost-sync.timer
```

See `templates/scheduler/systemd.service` and `systemd.timer`.

### Cron (universal fallback)

If you can't use launchd or systemd, cron works everywhere:

```cron
# Publisher scripts — every minute
* * * * * /path/to/project/scripts/run_ghost_publish.sh >> /path/to/project/logs/ghost_publish.log 2>&1

# Sync scripts — every 2 minutes
*/2 * * * * /path/to/project/scripts/run_linkedin_sync.sh >> /path/to/project/logs/linkedin_sync.log 2>&1

# Date orchestrator — every 2 minutes
*/2 * * * * /path/to/project/scripts/run_sync_dates.sh >> /path/to/project/logs/sync_dates.log 2>&1
```

**Note:** Cron's minimum interval is 1 minute. For sub-minute polling, use launchd or systemd.

## Recommended agent setup

For a typical 6-platform setup (Ghost + 5 social), you need these scheduled scripts:

| Agent | Script | Interval |
|-------|--------|----------|
| Ghost sync | `run_ghost_sync.sh` | 120s |
| Ghost publish detector | `run_ghost_published.sh` | 300s |
| LinkedIn publish | `run_linkedin_publish.sh` | 60s |
| Twitter publish | `run_twitter_publish.sh` | 60s |
| Facebook publish | `run_facebook_publish.sh` | 60s |
| Mastodon publish | `run_mastodon_publish.sh` | 60s |
| Bluesky publish | `run_bluesky_publish.sh` | 60s |
| Date orchestrator | `run_sync_dates.sh` | 120s |

That's 8 agents. The `/publish-from-notion` skill generates all of them for your selected platforms.
