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
    ```sh
    docker run --rm --entrypoint= getcarrier/pylon:tasknode python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'
    ```

## Start
```sh
docker compose pull
docker compose up -d
docker compose logs -f
```
