# LydsReality deployment

Deployments run when a commit is pushed to `dev`, or when the **Build, Publish,
And Deploy** workflow is started manually.

The workflow:

1. runs the Laravel CI workflow;
2. builds `infra/Dockerfile` on the GitHub-hosted runner;
3. pushes immutable `sha-<commit>` and moving `dev` tags to GHCR;
4. pulls the immutable image onto the server over SSH;
5. updates the existing Dokploy Compose project with
   `docker-compose.dokploy.yml`; and
6. asks Dokploy to deploy and waits for the deployment to finish.

Dokploy never receives a Compose `build` directive and does not build the
application image.

CI is also containerized. GitHub builds `infra/Dockerfile.ci`, which installs
the test-only PHP extensions and Composer development dependencies, prepares a
temporary SQLite database, runs migrations, and executes the Laravel test
suite during the image build. The CI image is never pushed or deployed.

## Deployment files

- `.github/workflows/cd.yml` only defines the job order and GitHub Actions.
- `.github/scripts/validate-deployment.sh` validates variables, secrets, and paths.
- `.github/scripts/prepare-deployment.sh` creates the immutable image-only Compose file.
- `.github/scripts/configure-ssh.sh` prepares and validates the deployment SSH key.
- `.github/scripts/pull-ghcr-image.sh` authenticates and pulls the image on the server.
- `.github/scripts/deploy-dokploy.sh` uploads the deployment files and starts the remote deployment.
- `.github/scripts/dokploy-api-deploy.sh` updates Dokploy and monitors the deployment.
- `.github/scripts/healthcheck.sh` verifies the optional public health endpoint.

## GitHub repository variables

| Name | Value |
| --- | --- |
| `DOKPLOY_COMPOSE_ID` | `lydsreality-appanddb-hgvlpk` |
| `DOKPLOY_COMPOSE_NAME` | `lydsreality` |
| `RUNNER_OS` | `ubuntu-latest` |
| `SERVER_ENV_FILE` | `/home/ubuntu/env/lydsreality.env` |

Optional variables are `SSH_PORT` (defaults to `22`) and `HEALTHCHECK_URL`.

## GitHub repository secrets

- `DOKPLOY_API_KEY`
- `SSH_HOST`
- `SSH_PRIVATE_KEY` (the complete unencrypted private key, or its base64 form)
- `SSH_USER`

No separate GHCR secret is required. GitHub Actions publishes and pulls the
repository package with the short-lived `GITHUB_TOKEN` and `packages: write`
permission.

## Server environment

`SERVER_ENV_FILE` must exist on the Dokploy server and contain the production
Laravel and MySQL settings used by the Compose project. At minimum it needs
`APP_KEY`, `APP_URL`, `DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD`.

The production Compose project reuses the named volumes
`lydsreality_app_storage` and `lydsreality_database_data`. Database import or
seeding is intentionally not part of routine application deployments.
