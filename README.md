# Deploy tasktracker (agent-runnable, zero decisions)

This document is self-contained: an agent (or a human) can deploy a production
tasktracker instance by following it top to bottom. No source checkout is needed -
the app ships as a container image; TLS is included (Caddy obtains certificates
automatically). All choices are already made; only the three placeholders vary.

**One instance hosts MANY projects.** To use tasktracker for two (or ten) projects,
deploy ONCE and create the projects inside it. Do not deploy per project.

## You need (fill these three placeholders)

| Placeholder | Meaning | Example |
| --- | --- | --- |
| `DOMAIN` | DNS A-record already pointing at the server | `tracker.example.com` |
| `ADMIN_EMAIL` | The one account that becomes admin on first sign-in | `you@company.com` |
| `GHCR_TOKEN` | GitHub token with `read:packages` for the private image | `ghp_...` |

To mint `GHCR_TOKEN`: GitHub -> Settings -> Developer settings -> Personal access
tokens (classic) -> Generate new token -> scope `read:packages` only.
The image is private: the maintainer must first grant your GitHub account read access
(Packages -> tasktracker -> Package settings -> Manage access -> add user, role Read).

Server: any Linux box with ports 80/443 open. Everything below runs as root (or a
user in the `docker` group).

## 1. Docker (skip if `docker compose version` already works)

```bash
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh
docker compose version   # expect: Docker Compose version v2.x
```

## 2. Log in to the registry

```bash
echo "GHCR_TOKEN" | docker login ghcr.io -u ekuznetski --password-stdin
# expect: Login Succeeded
```

## 3. Create the deployment

```bash
mkdir -p /opt/tasktracker && cd /opt/tasktracker

cat > .env <<EOF
BETTER_AUTH_URL=https://DOMAIN
BASE_URL=https://DOMAIN
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
BOOTSTRAP_ADMIN_EMAIL=ADMIN_EMAIL
EOF
chmod 600 .env

cat > Caddyfile <<'EOF'
{$TT_DOMAIN} {
    # Private instance: keep it out of search engines.
    respond /robots.txt "User-agent: *\nDisallow: /" 200
    reverse_proxy app:3000
}
EOF

cat > docker-compose.yml <<'EOF'
services:
  app:
    image: ghcr.io/ekuznetski/tasktracker:latest
    env_file: .env
    environment:
      DATABASE_PATH: /data/tasktracker.db
    volumes:
      - tasktracker-data:/data
    labels:
      - com.centurylinklabs.watchtower.scope=tasktracker
    restart: unless-stopped

  # Optional UNATTENDED auto-update (see "Automatic updates"). Enable with:
  #   docker compose --profile autoupdate up -d
  # nicholas-fedor/watchtower is the maintained fork (same flags/labels); the original
  # containrrr image is abandoned and crashes on Docker Engine 25+ (client API too old).
  watchtower:
    image: ghcr.io/nicholas-fedor/watchtower:1.19.0
    profiles: ["autoupdate"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/.docker/config.json:/config.json:ro
    command: --scope tasktracker --interval 3600 --cleanup
    labels:
      - com.centurylinklabs.watchtower.scope=tasktracker
    restart: unless-stopped

  caddy:
    image: caddy:2
    ports:
      - "80:80"
      - "443:443"
    environment:
      TT_DOMAIN: DOMAIN
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data
      - caddy-config:/config
    restart: unless-stopped

  # Optional continuous SQLite backup to any S3-compatible store. Enable with:
  #   docker compose --profile litestream up -d
  # after setting the five LITESTREAM_* keys in .env (see step 6).
  litestream:
    image: litestream/litestream:0.5
    profiles: ["litestream"]
    command: ["replicate"]
    env_file: .env
    depends_on:
      - app
    volumes:
      - tasktracker-data:/data
      - ./litestream.yml:/etc/litestream.yml:ro
    restart: unless-stopped

volumes:
  tasktracker-data:
  caddy-data:
  caddy-config:
EOF

cat > litestream.yml <<'EOF'
dbs:
  - path: /data/tasktracker.db
    replicas:
      - type: s3
        bucket: ${LITESTREAM_BUCKET}
        path: tasktracker
        endpoint: ${LITESTREAM_ENDPOINT}
        region: ${LITESTREAM_REGION}
        access-key-id: ${LITESTREAM_ACCESS_KEY_ID}
        secret-access-key: ${LITESTREAM_SECRET_ACCESS_KEY}
EOF
```

Set your two values once (as shell vars, reused by every command below), then substitute
them into the files:

```bash
export DOMAIN=tracker.example.com   # your DNS A-record
export ADMIN_EMAIL=you@company.com  # the first/admin account
sed -i "s/ADMIN_EMAIL/$ADMIN_EMAIL/" .env
sed -i "s/DOMAIN/$DOMAIN/" .env docker-compose.yml
grep -E "DOMAIN|ADMIN" .env docker-compose.yml   # verify: no placeholder left
```

The rest of this guide uses `$DOMAIN`, so run the following steps in the SAME shell
session (re-run the two `export`s if you open a new terminal).

## 4. Start + verify

```bash
docker compose up -d
sleep 15
curl -fsS https://$DOMAIN/ready
# expect JSON with "status":"Healthy" (the app migrates on first boot)
curl -s https://$DOMAIN/version
# expect {"name":"tasktracker","version":...,"gitSha":"..."}
```

If `/ready` is not reachable: `docker compose ps` (all Up?), `docker compose logs app | tail -30`,
`docker compose logs caddy | tail -10` (certificate errors = DNS not pointing here yet).

**Domain behind Cloudflare?** Caddy's automatic Let's Encrypt only works when the DNS
record points DIRECTLY at this box. Pick ONE:

- **DNS-only (simplest):** in Cloudflare DNS, switch the record to "DNS only" (grey
  cloud). Automatic certificates then just work.
- **Keep the proxy (orange cloud):** issue a Cloudflare **Origin Certificate**
  (SSL/TLS -> Origin Server -> Create, 15-year), save the two PEMs next to the
  Caddyfile as `origin.pem` / `origin.key`, mount them into caddy
  (`- ./origin.pem:/etc/caddy/origin.pem:ro` and the key alike), and change the
  Caddyfile site block to use them: `tls /etc/caddy/origin.pem /etc/caddy/origin.key`.
  Set the zone's SSL mode to **Full (strict)**. No renewals needed.

## 5. First sign-in + projects

1. Open `https://$DOMAIN`, click "No account? Create one", register with **$ADMIN_EMAIL**
   (email + password). That account is the admin; anyone else needs an invite.
2. Create your projects (top-left switcher -> Create project) - one per codebase,
   e.g. `PROJ1`, `PROJ2`. Both live in this one instance.
3. Invite teammates per project: Project settings -> Members (invite = allowlisted
   email + role viewer/editor/admin).

## 6. Connect agents (per developer machine)

```bash
claude mcp add --transport http --client-id tasktracker-cli --callback-port 8080 tasktracker https://$DOMAIN/mcp
```

Sign in once in the browser window it opens; restart the agent session. Then, in each
codebase, drop the session-start reminder hook so every agent session begins with
`get_started` + KB search - packs for Claude Code / Cursor / Codex live in
[`onboarding/`](https://github.com/ekuznetski/tasktracker-releases/tree/main/onboarding)
(also shown in the UI under Access control).

## 7. Backup (recommended - default is NO backup)

Append the five keys to `.env` (any S3-compatible store - AWS S3, Cloudflare R2, minio):

```bash
cat >> .env <<EOF
LITESTREAM_BUCKET=...
LITESTREAM_ENDPOINT=...
LITESTREAM_REGION=...
LITESTREAM_ACCESS_KEY_ID=...
LITESTREAM_SECRET_ACCESS_KEY=...
EOF
docker compose --profile litestream up -d
docker compose logs litestream | tail   # expect "replicating to", no errors
```

Restore is automatic on an empty volume (the app restores from the replica BEFORE
migrating). Rehearse it once: see the
[runbook](https://github.com/ekuznetski/tasktracker-releases/blob/main/runbook.md)
("Restore drills").

## 8. Optional: SSO login (Google / Azure / any OIDC provider)

Email+password works out of the box and needs nothing. To let people sign in with a
company identity provider instead, add the credentials to `.env` and restart - the
sign-in screen renders exactly the providers you configured (it reads `/config`).

**Google:**

1. Create an OAuth 2.0 Client (type: Web application) at
   https://console.cloud.google.com/apis/credentials
2. Authorized redirect URI: `https://DOMAIN/api/auth/callback/google`
3. ```bash
   cat >> .env <<EOF
   GOOGLE_CLIENT_ID=...
   GOOGLE_CLIENT_SECRET=...
   EOF
   docker compose up -d app
   ```

**Any OIDC provider - Azure (Entra ID), Okta, Auth0, Keycloak, ...:**

1. Register a web app at your IdP with redirect URI
   `https://DOMAIN/api/auth/oauth2/callback/oidc`
2. Take the issuer URL (the discovery document lives at
   `<issuer>/.well-known/openid-configuration`):
   - Azure / Entra ID: `https://login.microsoftonline.com/<TENANT_ID>/v2.0`
   - Okta: `https://<org>.okta.com`
   - Keycloak: `https://<host>/realms/<realm>`
3. ```bash
   cat >> .env <<EOF
   OIDC_ISSUER=...
   OIDC_CLIENT_ID=...
   OIDC_CLIENT_SECRET=...
   EOF
   docker compose up -d app
   ```
   The button shows up as "Sign in with SSO". Scopes default to
   `openid profile email`; override with `OIDC_SCOPES` if your IdP needs others.

Notes:
- The allowlist still gates who may sign in: invite people (Project settings ->
  Members) or add a domain rule (Access control) so everyone `@company.com` gets in.
- To force SSO-only, add `EMAIL_PASSWORD_AUTH=false` to `.env` (do this AFTER the
  admin account works via SSO, or you lock yourself out until you revert it).

## 9. Updating

Admins see an **"Update available" badge** in the top bar when a newer image is
published (the instance polls a public release channel hourly; disable with
`UPDATE_CHECK=false` in `.env`). To update manually:

```bash
cd /opt/tasktracker && docker compose pull app && docker compose up -d app
curl -s https://$DOMAIN/version   # confirm the new gitSha
```

**Automatic updates (optional).** The server can update ITSELF: the compose file
already contains a `watchtower` service that checks the registry hourly and, when a
new image appears, pulls it and recreates the app container (migrations run on boot;
the old image is cleaned up). It reuses the registry login from step 2. Turn it on:

```bash
docker compose --profile autoupdate up -d
docker compose logs watchtower | tail   # expect "Watchtower ... Scheduling first run"
```

Know the trade-off: updates (including database migrations) then happen unattended at
whatever hour the check lands. Keep it off if you prefer pressing the button when the
badge shows up. If your `docker login` was done as a non-root user, adjust the
`/root/.docker/config.json` mount to that user's path.

Two credential rules for unattended pulls:
- Log in with a **long-lived (non-expiring) `read:packages` PAT**: when an expiring
  token dies, watchtower's pulls start failing with 401 **silently** and updates stop.
- After rotating the token, re-run step 2 and `docker compose restart watchtower`.

Pin instead of `latest` by setting the image tag to a git sha, e.g.
`ghcr.io/ekuznetski/tasktracker:0418099`.

## 10. Recovering from a failed migration

Migrations run on boot and are forward-only. Before applying a pending migration to an
already-populated database, the app first checkpoints the WAL and copies the database
aside to `/data/backups/pre-migrate-<timestamp>.db` (inside the `tasktracker-data`
volume). If a migration then fails, the app logs `MIGRATION FAILED ...` with the exact
snapshot path and exits without upgrading the schema. Restore locally:

```bash
cd /opt/tasktracker
docker compose logs app | grep -A3 "MIGRATION FAILED"   # note the snapshot path

# Pin the image to the last known-good tag FIRST, so the restored (older) DB is not
# immediately re-upgraded by the same broken migration on the next boot.
sed -i 's#tasktracker:latest#tasktracker:<PREVIOUS_GITSHA>#' docker-compose.yml
docker compose stop app

# Copy the pre-migrate snapshot over the live DB (adjust the timestamp to the log).
docker compose run --rm --entrypoint sh app -c \
  'cp /data/backups/pre-migrate-<timestamp>.db /data/tasktracker.db && rm -f /data/tasktracker.db-wal /data/tasktracker.db-shm'
docker compose up -d app
curl -s https://$DOMAIN/version   # confirm it booted on the pinned tag
```

Then report the failing migration upstream and unpin once a fixed image is published.
If litestream backup (step 7) is on, `litestream restore` from the S3 replica is the
alternative (it restores the last replicated state); see the
[runbook](https://github.com/ekuznetski/tasktracker-releases/blob/main/runbook.md).

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `docker compose pull` -> denied | `GHCR_TOKEN` missing `read:packages`, or not logged in (step 2) |
| `/ready` 503, `entries.migrations` unhealthy | boot chain still running or crashed: `docker compose logs app` |
| Browser shows certificate error | DNS for `DOMAIN` not pointing at this server yet; `docker compose logs caddy` |
| OAuth/agent connect fails | `BETTER_AUTH_URL` in `.env` must EXACTLY equal `https://DOMAIN` (no trailing slash) |
| litestream container restarts | one of the five `LITESTREAM_*` keys missing - its logs name it |
| Lost admin access | set `BOOTSTRAP_ADMIN_EMAIL` in `.env` to your email, `docker compose up -d app` |
