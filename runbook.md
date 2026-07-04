# Operations runbook

Single-node deployment: one app container (Bun + SQLite in WAL mode on the `/data`
volume) + an optional litestream replica container. One replica only - SQLite is
single-writer. Everything below assumes the compose deployment from the README.

## Observability

- `GET /healthcheck` - liveness (process up; never touches the DB).
- `GET /ready` - readiness in the standard health-checks JSON shape
  (`status`/`entries`/`totalDuration`); 503 until migrations have run. Wired into the
  Docker HEALTHCHECK.
- `GET /metrics` - Prometheus. Process defaults plus:
  `tasktracker_http_requests_total`, `tasktracker_http_request_duration_seconds`,
  `tasktracker_claims_total{result}`, `tasktracker_leases_reaped_total`,
  `tasktracker_rate_limited_total`, `tasktracker_conflicts_total`,
  `tasktracker_sse_connections`.
- Logs: one JSON object per line on stdout in Serilog-compact (CLEF) shape
  (`@t`/`@l`/`@m` + properties). Every response carries `X-Correlation-Id`
  (incoming header wins), and the request log line includes it - grep that id to
  follow one request end to end. Ship stdout with your usual collector
  (`docker compose logs`, Loki, CloudWatch...).

Alerting starting points: `rate(tasktracker_leases_reaped_total[15m]) > 0` (agents
crashing mid-claim), `tasktracker_sse_connections` dropping to 0 while users are
active (proxy killing streams), any `/ready` 503.

## Updates

Manual: the admin badge says a new image exists; `docker compose pull app && docker
compose up -d app`. Unattended: the optional watchtower profile
(`docker compose --profile autoupdate up -d`) pulls and recreates the app container
within an hour of a release - including running migrations, so keep the litestream backup
on if you enable it.

## Backup (litestream)

Default deploys have NO backup. Enable it once per deployment:

1. Set the five `LITESTREAM_*` keys in `.env` (bucket + endpoint + region + creds).
2. `docker compose --profile litestream up -d` (add `-f docker-compose.image.yml` on
   image deploys).
3. Verify replication is really running (do not skip):
   `docker compose logs litestream | tail` - you want `replicating to`, no errors -
   and confirm objects appear in the bucket.

## Restore drills (rehearse BEFORE you need them)

**Automatic path (volume lost / new host).** The app container's first boot step runs
`litestream restore -if-replica-exists` whenever `/data` has no database and
`LITESTREAM_BUCKET` is set. So: provision the host, copy `.env`, `docker compose up -d`
- the data comes back from the replica before migrations run. Verify with
`curl localhost:3000/ready` and by opening the UI.

**Manual path (inspect a backup, restore elsewhere).** Refuses to overwrite an
existing DB - move it aside first:

```bash
docker compose --profile litestream run --rm --entrypoint /bin/sh \
  litestream -c "sh /scripts/litestream-restore.sh"
```

**Drill procedure** (run it once after enabling backup, then after big upgrades):

1. Create a marker: add a note in the UI titled `dr-drill-<date>`.
2. Wait ~30s (replication lag), then `docker compose down` and
   `docker volume rm <project>_tasktracker-data`.
3. `docker compose up -d` - watch the logs for
   `empty database + litestream configured: restoring`.
4. Confirm the marker note is back. If it is not, your replica config was wrong -
   fix it while you still have the original data elsewhere.

## Common failures

- **`/ready` 503, `entries.migrations` unhealthy** - the boot chain (restore ->
  migrate -> seed) has not finished or crashed; `docker compose logs app`.
- **litestream container crash-loops** - almost always a missing `LITESTREAM_*` key
  or wrong endpoint; its logs name the missing variable.
- **Disk full** - SQLite writes fail loudly. Free space, restart the app container;
  WAL recovers on open. The DB lives at `/data/tasktracker.db` in the volume.
- **Rollback after a bad update** - migrations are forward-only. Restore the DB from
  litestream (manual path above) and deploy the previous image tag
  (`TASKTRACKER_TAG=<old-sha> docker compose -f docker-compose.image.yml up -d`).
- **Lost admin access** - set `BOOTSTRAP_ADMIN_EMAIL` in `.env` to your email and
  restart; that account is admin on next sign-in.
