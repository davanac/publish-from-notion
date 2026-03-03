# API Setup Guide

Step-by-step instructions to get API credentials for each platform. Follow only the sections for platforms you selected during setup.

---

## Notion (required)

You need a Notion integration token and your database IDs.

### Create an integration

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **New integration**
3. Name it (e.g., "Newsroom Pipeline")
4. Select your workspace
5. Under Capabilities, ensure **Read content**, **Update content**, and **Insert content** are checked
6. Click **Submit**
7. Copy the **Internal Integration Secret** (starts with `secret_`)

### Share databases

For each database (Articles + platform databases):
1. Open the database in Notion
2. Click **...** (top right) → **Connections** → **Connect to** → select your integration
3. Click **Confirm**

### Get database IDs

Open each database as a full page. The URL looks like:
```
https://www.notion.so/yourworkspace/abc123def456?v=...
                                    ^^^^^^^^^^^^
                                    This is the database ID
```

Copy this ID for each database into your `.env`.

---

## Ghost

Ghost is the recommended primary publication platform — open source, SEO-optimized, and self-hostable.

### Create a custom integration

1. Go to your Ghost Admin panel → **Settings** → **Integrations**
2. Click **Add custom integration**
3. Name it (e.g., "Notion Pipeline")
4. You'll see two keys:
   - **Content API Key** — for reading (not needed here)
   - **Admin API Key** — for creating/updating posts (this is the one you need)
5. Copy the **Admin API Key**

### Format

The Admin API Key format is `{key_id}:{key_secret}` — a long string with a colon in the middle. Copy the entire thing.

### .env values

```bash
GHOST_API_URL=https://your-site.ghost.io    # Your Ghost URL (no trailing slash)
GHOST_ADMIN_KEY=64XXX...XXX:8fXXX...XXX     # The full Admin API Key
```

---

## LinkedIn

LinkedIn's API setup is the most complex. Follow carefully.

### Step 1: Create a LinkedIn App

1. Go to [linkedin.com/developers](https://www.linkedin.com/developers/)
2. Click **Create App**
3. Fill in:
   - **App name**: your choice
   - **LinkedIn Page**: you MUST associate a Company Page (create one if needed)
   - **Logo**: any image
4. Click **Create app**

### Step 2: Request API access

1. In your app dashboard, go to the **Products** tab
2. Find **Share on LinkedIn** and click **Request access**
3. Accept the terms. Access is usually granted immediately.

### Step 3: Generate an OAuth token

This is the tricky part. LinkedIn uses OAuth 2.0 with a browser-based authorization flow.

**Option A: Use LinkedIn's token generator (quickest)**
1. In your app dashboard, go to the **Auth** tab
2. Under **OAuth 2.0 tools**, click **Generate token**
3. Select scopes: `w_member_social` and `r_liteprofile`
4. Complete the browser authorization
5. Copy the access token

**Option B: Manual OAuth flow**
1. Build the authorization URL:
   ```
   https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=YOUR_REDIRECT_URI&scope=w_member_social
   ```
2. Visit the URL in your browser, authorize, and copy the `code` parameter from the redirect
3. Exchange the code for a token via POST to `https://www.linkedin.com/oauth/v2/accessToken`

### Common pitfalls

- **Company Page required**: You cannot create a LinkedIn app without associating a Company Page
- **Token expires in 60 days**: Set a calendar reminder to regenerate it
- **Person URN**: You need your LinkedIn member URN. Find it via the `/me` API endpoint or check your app dashboard

### .env values

```bash
LINKEDIN_ACCESS_TOKEN=AQV...long-token...
LINKEDIN_PERSON_URN=urn:li:person:XXXXXXXXX
```

---

## Twitter / X

### Step 1: Apply for developer access

1. Go to [developer.twitter.com](https://developer.twitter.com/)
2. Sign up for a Developer Account if you don't have one
3. The **Free** tier allows 1,500 tweets/month — sufficient for most newsrooms

### Step 2: Create a Project and App

1. Go to the **Developer Portal** → **Projects & Apps**
2. Click **New Project** → give it a name
3. Create an **App** within the project

### Step 3: Set permissions FIRST

**This is critical — do this BEFORE generating tokens:**

1. Go to your App → **Settings** → **User authentication settings** → **Edit**
2. Set App permissions to **Read and Write**
3. Save

If you generate tokens with Read-only permissions and then change to Read+Write, the old tokens won't work. You'll need to regenerate them.

### Step 4: Generate tokens

1. Go to your App → **Keys and Tokens**
2. Generate and copy all four values:
   - API Key (Consumer Key)
   - API Key Secret (Consumer Secret)
   - Access Token
   - Access Token Secret

### .env values

```bash
TWITTER_API_KEY=...
TWITTER_API_SECRET=...
TWITTER_ACCESS_TOKEN=...
TWITTER_ACCESS_SECRET=...
```

---

## Mastodon

Mastodon is the simplest API to set up. Each instance manages its own apps.

### Create an application

1. Log into YOUR Mastodon instance (e.g., mastodon.social, fosstodon.org)
2. Go to **Preferences** → **Development** → **New Application**
3. Fill in:
   - **Application name**: your choice
   - **Redirect URI**: `urn:ietf:wg:oauth:2.0:oob`
   - **Scopes**: check `read` and `write:statuses`
4. Click **Submit**
5. Click on your new application
6. Copy the **Access token**

### Common pitfalls

- **Instance-specific**: The token only works on the instance where you created it
- **URL matters**: Use the URL of YOUR instance, not mastodon.social (unless that IS your instance)

### .env values

```bash
MASTODON_INSTANCE_URL=https://your-instance.social
MASTODON_ACCESS_TOKEN=...
```

---

## Bluesky

Bluesky uses App Passwords — the simplest auth model of all platforms.

### Create an App Password

1. Log into [bsky.app](https://bsky.app/)
2. Go to **Settings** → **App Passwords**
3. Click **Add App Password**
4. Name it (e.g., "Newsroom Pipeline")
5. Copy the generated password

### Common pitfalls

- **App Password, not account password**: Never put your real password in `.env`
- **Handle format**: Use your full handle (e.g., `yourname.bsky.social`)

### .env values

```bash
BLUESKY_HANDLE=yourname.bsky.social
BLUESKY_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx
```

---

## Facebook

Facebook's API is powerful but requires careful setup.

### Step 1: Create a Facebook App

1. Go to [developers.facebook.com](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Select app type: **Business**
4. Fill in app details and click **Create App**

### Step 2: Add the Pages product

1. In your app dashboard, find **Add Products**
2. Add **Facebook Login** (needed for token generation)
3. Add **Pages** (needed for posting)

### Step 3: Generate a Page Access Token

**Important: You need a PAGE token, not a User token.**

1. Go to the [Graph API Explorer](https://developers.facebook.com/tools/explorer/)
2. Select your app
3. Click **Generate Access Token**
4. Grant permissions: `pages_manage_posts`, `pages_read_engagement`
5. In the token field, you now have a short-lived User Token
6. Use the [Access Token Debugger](https://developers.facebook.com/tools/debug/accesstoken/) to exchange it for a long-lived token
7. Then use the Graph API to get a Page Access Token:
   ```
   GET /me/accounts?access_token=YOUR_LONG_LIVED_USER_TOKEN
   ```
8. Find your page in the response and copy its `access_token`

### Common pitfalls

- **Page token, not User token**: User tokens can't post to Pages
- **Token expiration**: Page tokens derived from long-lived user tokens don't expire, but if you regenerate the user token, the old page token breaks
- **Business verification**: Some features require business verification (can take days)

### .env values

```bash
FACEBOOK_PAGE_ID=123456789012345
FACEBOOK_ACCESS_TOKEN=EAAG...long-token...
```

---

## Testing your credentials

After setting up each platform, test that your tokens work:

```bash
# Activate your venv
source venv/bin/activate

# Test Notion
python3 -c "import requests; r = requests.get('https://api.notion.com/v1/users/me', headers={'Authorization': 'Bearer YOUR_TOKEN', 'Notion-Version': '2022-06-28'}); print(r.status_code, r.json().get('name', 'ERROR'))"

# Test Ghost
# The pipeline will test this during the end-to-end check

# Test each social platform
# The /publish-from-notion skill runs a validation step for each configured platform
```

The `/publish-from-notion` skill includes a test step that validates all your credentials before activating the pipeline.
