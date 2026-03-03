# The Publication State Machine

## The five states

Every article tracks per-platform status independently. Each platform property on the Articles database moves through these states:

```
  Draft        Ready        Generated     Scheduled     Published
┌────────┐  ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐
│   🚧   │  │   🚀   │   │   ✅   │   │   ⏰   │   │   📢   │
│  Draft  │──│ Ready  │──▶│ Created│──▶│Scheduled│──▶│Published│
└────────┘  └────────┘   └────────┘   └────────┘   └────────┘
               you set     pipeline      pipeline      pipeline
              manually      sets          sets          sets
                              │
                              │ on failure
                              ▼
                         rollback to 🚀
```

| State | Who sets it | What it means |
|-------|-------------|---------------|
| 🚧 | You | Draft. Not ready for the pipeline. |
| 🚀 | You | Ready. Triggers generation/sync. |
| ✅ | Pipeline | Content has been created in the platform database. |
| ⏰ | Pipeline | Publication date is set and in the future. |
| 📢 | Pipeline | Published. URL is written back to the database. |

## Transition rules

### 🚀 → ✅ (Content creation)

The sync script detects articles with status 🚀 and processes them:

1. **Check for duplicates** — query the platform database to see if a page already exists for this article (via the Articles relation)
2. **Lock the article** — immediately set status from 🚀 to ✅, BEFORE creating the platform page
3. **Create the platform page** — write content to the platform database
4. **On failure: rollback** — set status back to 🚀 so the next cycle can retry

The "lock before create" pattern prevents duplicate pages. If two sync cycles overlap, the second one sees ✅ and skips the article.

### ✅ → ⏰ (Scheduling)

The publisher script detects posts with a publication date in the future and an empty URL:
- If the Articles status is ✅, advance it to ⏰
- This is informational — it tells you the post is scheduled

### ⏰ → 📢 (Publication)

When the publication date arrives:

1. **Guard check** — verify the article status is not already 📢 (anti-republication)
2. **Idempotency flag** — write a temporary URL like `publishing.in.progress` to claim the post
3. **API call** — publish to the platform
4. **On success** — write the real URL, set status to 📢
5. **On failure** — clear the temporary URL, status stays at ⏰

## Anti-duplicate protection

Three layers prevent the same article from being published twice:

### Layer 1: OS-level lock

The `acquire_lock` function in `common.sh` ensures only one instance of each script runs at a time. Uses PID files with stale detection.

### Layer 2: Relation check

Before creating a platform page, the sync script queries: "Does a page in this platform database already have a relation to this article?" If yes, skip.

### Layer 3: Status pre-advancement

Setting 🚀 → ✅ BEFORE creating the page means concurrent cycles see the updated status and skip. If page creation fails, rollback to 🚀 allows retry on the next cycle.

## Idempotency pattern

The publication step uses a two-phase approach:

```
1. Write URL = "publishing.in.progress"  (claim the post)
2. Call platform API                      (actually publish)
3a. Success → URL = real published URL
3b. Failure → URL = empty                (release the claim)
```

This prevents double-posting if the publisher script runs twice while a post is being published.

## Failure recovery

| Failure point | What happens | Recovery |
|---------------|-------------|----------|
| Sync script crashes after setting ✅ | No platform page exists, but article is ✅ | Manual: set back to 🚀 to retry |
| Page creation fails | Status rolls back to 🚀 automatically | Automatic retry next cycle |
| API call fails | Idempotency flag is cleared | Automatic retry next cycle |
| API call succeeds but status update fails | Post is live, status stuck at ⏰ | Manual: set to 📢, write URL |
