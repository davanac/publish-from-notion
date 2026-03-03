# The Publication State Machine

## The five states

Every article tracks per-platform status independently. Each platform property on the Articles database moves through these states:

```
  Draft        Ready        Generated     Scheduled     Published
┌────────┐  ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐
│   🚧   │  │   🚀   │   │   ✅   │   │   ⏰   │   │   📢   │
│  Draft  │──│ Ready  │──▶│ Created│──▶│Scheduled│──▶│Published│
└────────┘  └────────┘   └────────┘   └────────┘   └────────┘
               you set    you or your    pipeline      pipeline
              manually    automation      sets          sets
                              │
                              │ (manual or automated)
                              ▼
                    content exists in platform DB
```

| State | Who sets it | What it means |
|-------|-------------|---------------|
| 🚧 | You | Draft. Not ready for the pipeline. |
| 🚀 | You | Ready. You intend to publish on this platform. |
| ✅ | You (or your automation) | Content is written in the platform database and ready to schedule. |
| ⏰ | Pipeline | Publication date is set and in the future. |
| 📢 | Pipeline | Published. URL is written back to the database. |

> **Important:** This pipeline does NOT generate content. The 🚀 → ✅ transition is **your responsibility**. You write the post (manually, with AI prompts, or with your own automation), then mark it ✅. The pipeline takes over from ✅ onward.
>
> If you set 🚀 but never write content and never set ✅, the article simply stays at 🚀. The pipeline will not touch it. This is by design — the pipeline publishes what you put in the databases, nothing more.

## Transition rules

### 🚀 → ✅ (Content creation — manual by default)

This is the **content creation step**. By default, it is manual:

1. You set 🚀 on a platform — this signals your intent to publish there
2. You write the post content in the platform database (page body)
3. You set the status to ✅ — this tells the pipeline the content is ready

**This is the extension point.** You can automate this step with your own scripts (AI-based or otherwise). If you build automation for 🚀 → ✅, apply the same safety patterns:

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
2. **Content validation** — verify the post body is not empty (see below)
3. **Idempotency flag** — write a temporary URL like `publishing.in.progress` to claim the post
4. **API call** — publish to the platform
5. **On success** — write the real URL, set status to 📢
6. **On failure** — clear the temporary URL, status stays at ⏰

## Content validation guard

The pipeline must never publish an empty post. Before calling any platform API, the publisher script validates that content exists:

```python
def get_post_content(page_id):
    """Extract page body content. Returns text or raises ValueError."""
    blocks = notion.blocks.children.list(block_id=page_id)["results"]
    text_blocks = [b for b in blocks if b["type"] in ("paragraph", "heading_1", "heading_2", "heading_3", "bulleted_list_item", "numbered_list_item", "quote")]
    content = ""
    for block in text_blocks:
        rich_texts = block[block["type"]].get("rich_text", [])
        content += "".join(rt["plain_text"] for rt in rich_texts)
    content = content.strip()
    if not content:
        raise ValueError(f"Post {page_id} has no content — skipping publication")
    return content
```

**What happens when content is empty:**
- The publisher skips the post and logs a warning
- The status stays at ⏰ — no rollback, no retry spam
- The post will be retried on the next cycle, giving the user time to add content
- A webhook notification is sent (if configured) so the user knows something needs attention

This guard prevents accidental publication of blank posts if someone sets ✅ and ⏰ before writing content.

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
