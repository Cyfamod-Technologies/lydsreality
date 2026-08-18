# LydsReality Docker deployment

The Compose stack contains LydsReality on Laravel/Apache and MySQL 8.4. It does not
contain a domain, certificate, or reverse proxy, so it can run behind Dokploy,
Traefik, Caddy, Nginx, or a cloud load balancer.

## Required environment variables

Copy `.env.example` to `.env` for a regular Docker Compose deployment, or add
these variables in your deployment platform:

- `APP_KEY` — generate with `php artisan key:generate --show` or
  `echo "base64:$(openssl rand -base64 32)"`
- `APP_URL` — the final public URL, such as `https://example.com`
- `DB_DATABASE`
- `DB_USERNAME`
- `DB_PASSWORD`
- `MYSQL_ROOT_PASSWORD`

For HTTPS deployments, also set:

```env
SESSION_SECURE_COOKIE=true
FORCE_SCHEMA=https
FORCE_ROOT_URL=https://example.com
```

`APP_PORT` defaults to `8080` and controls the published host port. The
database dump is imported only when the MySQL volume is created for the first
time.

The database and uploaded files use stable named volumes by default:

```env
DATABASE_VOLUME_NAME=lydsreality_database_data
APP_STORAGE_VOLUME_NAME=lydsreality_app_storage
```

Keep these names unchanged between automatic deployments. Routine image
rebuilds and `docker compose up -d` deployments preserve both volumes. Never
run `docker compose down --volumes`, delete the volumes in Dokploy, or enable a
deployment cleanup option that removes persistent volumes. Those actions erase
the database or uploaded files. Changing a volume name creates a new empty
volume; on an empty database volume, `database.sql` is imported again.

## Dokploy

1. Create a Compose application from this repository.
2. Add the required environment variables above in Dokploy.
3. Deploy the Compose stack.
4. Add a domain to service `app` using container port `80`, then enable HTTPS.

No source file needs to change when the domain changes.

Redis is not required. The default deployment uses file-backed cache and
sessions plus the synchronous queue driver. Redis can be introduced later if
the application is scaled to multiple replicas or moved to background queues.

## Dockerfile-only deployment

Docker Compose is optional. In Dokploy or another container platform, create
an application directly from this repository with:

- Dockerfile path: `infra/Dockerfile`
- Container port: `80`
- Persistent volume mount: `/var/www/html/storage`
- A separate MySQL 8 database supplied by the platform or another server

Configure the Laravel variables listed above and set `DB_HOST`, `DB_PORT`,
`DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD` to the external database
connection details. Keep `CACHE_STORE=file`, `SESSION_DRIVER=file`, and
`QUEUE_CONNECTION=sync` when Redis is not used.

Unlike the Compose deployment, a Dockerfile-only deployment does not import
`database.sql` automatically. Import it once into the external database before
opening the application:

```bash
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p "$DB_DATABASE" < database.sql
```

Do not publish MySQL directly to the public internet. Use the platform's
private network or an allow-listed database connection.

## Standard Docker Compose

```bash
cp .env.example .env
# Set APP_KEY and replace the example database passwords in .env first.
docker compose up -d --build
```

The application is available on `http://localhost:8080` unless `APP_PORT` is
changed.

## Generic GitHub Actions deployment

`.github/workflows/deploy.yml` is reusable in any repository that contains a
Compose file. It creates versioned releases on a Docker server, deploys with a
stable Compose project name, waits for container health checks, rolls back to
the previous release when startup fails, and retains the newest five releases
by default. Named Docker volumes are not removed during deployment.

Configure these GitHub Actions secrets:

- `SSH_HOST`
- `SSH_USER`
- `SSH_PRIVATE_KEY` (recommended) or `SSH_PASSWORD`
- `SSH_KNOWN_HOSTS` (recommended; `ssh-keyscan` is used when omitted)
- `DEPLOY_ENV_FILE` (optional multiline contents of the production `.env`)

Configure these repository variables:

- `SERVER_DEPLOY_PATH` — required, for example `/opt/my-application`
- `COMPOSE_PROJECT_NAME` — recommended stable name, for example `my-application`
- `COMPOSE_FILE` — optional; defaults to `docker-compose.yml`
- `SSH_PORT` — optional; defaults to `22`
- `SERVER_ENV_FILE` — optional existing absolute `.env` path on the server
- `HEALTHCHECK_URL` — optional public URL checked after deployment
- `RELEASES_TO_KEEP` — optional; defaults to `5`

If `DEPLOY_ENV_FILE` is set, it is stored at
`SERVER_DEPLOY_PATH/shared/.env` with mode `0600` and reused between releases.
If it is not set, the workflow uses `SERVER_ENV_FILE` or an existing shared
`.env`. Keep `COMPOSE_PROJECT_NAME` stable so Compose-managed volume and network
identity remains consistent across releases.
