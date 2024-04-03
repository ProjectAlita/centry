# Centry deployment for Alita

## Requirements
- Docker
- Docker compose (docker-compose-plugin preferred)

## Configuration
1. Copy envs/default.env to envs/override.env

2. Edit envs/override.env:
  - Set APP_HOST to IP/DNS of platform
  - Set GITHUB_USERNAME and GITHUB_TOKEN in order for pylons to clone private repositories automatically
  - Change passwords/keys (for production, use default ones for dev at your own risk)
    > Special command for SECRETS_MASTER_KEY:
    > ```sh
    > docker run --rm --entrypoint= getcarrier/pylon:tasknode python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'
    > ```

3. SSL (optional): copy your server.crt, server.key, ca.crt to ssl/, then:
  - edit pylon_*/pylon.yml: uncomment SSL-related settings
  - edit docker-compose.yml: uncommend SSL-related settings
  - edit envs/override.env: set APP_PROTO to https

4. OpenID Connect SSO (optional):
  - edit pylon_auth/configs/auth_core.yml: set auth_provider to oidc
  - edit pylon_auth/configs/auth_oidc.yml: insert config for your OIDC provider
  - edit pylon_auth/configs/auth_init.yml: specify ID from your provider (e.g. email) for default platform admin

5. Interceptor docker network for lambdas (optional):
  - edit docker-compose.yml: uncomment and tweak LAMBDA_DOCKER_NETWORK for interceptors

## Start
```sh
docker compose pull
docker compose up -d
docker compose logs -f
```

## First-time platform configuration
1. Create project for public prompt library

2. Create AI integration in Administration mode

3. Create secret in Administration mode: ai_project_id, should contain project ID (created at step 1)

4. Restart main pylon

5. Enable schedule projects_create_personal_project
