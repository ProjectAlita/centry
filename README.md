# Centry deployment for Alita

## Requirements
- Docker
- Docker compose (docker-compose-plugin preferred)

## Quick start

Next steps provides quick start and interactive service configuring

1. Run next commands to install terraform binary for the current user ($HOME/.local/bin)
```sh
make get_tools
source ~/.bashrc # for bash
# or 
source ~/.zshrc  # for zsh
```

2. Source **env_file** in the root of repo for configuring service according your shell 
```sh
source env_bash  # for bash
# or
source env_sh  # for zsh

```

3. Copy TLS/SSL certs (server.crt, server.key, ca.crt) into ssl dir if you have them **[Optional]**

4. Run next commands to up the service
```sh
make init
make apply
make up
```

5. To stop service
```sh
make down
```

### Make targets
use make \<target\> to run approriate command

| target | description | effect |
|--------|-------------|---------|
| help |  shows available targets | -|
| up |  starts all docker compose containers | all containers will be in UP/running state |
| up_minimal | starts minimal working configuration | starts only main and auth pylons |
| down | stops all docker compose containers   | all containers are stopped, service is down |
| logs | shows all logs in 'follow' mode | shows logs from all running containers |
| -|- |-|
| check | run check section and creates .label file   | checks if your environment fits requirements, will be skipped after first run |
| -|- |-|
| clean_images | removes service images and .label files | images will be removed |
| clean_volumes | remove service volumes | volumes will be removed |
| clean_local_db | removes database files for each pylon |  pylon.db files will be removed, your confings will be deleted | 
| clean_local_plugins | removes plugin/ and  requirements/ directories for each pylon  | plugins and related files will be removed |
| clean_local_cache | removes cache  | cache directories, static, libcloud will be removed |
| clean_start | removes local pylons data without removing docker images and volumes | cache directories, static, libcloud, pylon dbs will be removed |
| tf_clean | remove all terraform related files | .terrform/, tfstate, lock files will be removed |
| compose_clean | rendered files will be deleted | docker-compose.yml and ovveride.env will be deleted  |
| clean_full | starts full clean sequence DBs, plugins, images, terraform etc | all service related data will be removed |
| -|- |-|
| get_tools | downloads and installs useful tools for current user | ctop,terraform will be installed |
| init | install terraform providers | terraform providers will be installed into ./tmpl/.terraform |
| plan | plan terraform changes | changes will be showed |
| apply | apply terraform changes | changes will be applied, files will be rendered |


## Manual Configuration
1. Copy envs/default.env to envs/override.env

2. Edit envs/override.env:
  - Set APP_HOST to IP/DNS of platform
  - Set LICENSE_USERNAME and LICENSE_PASSWORD to your github username and token in order for pylons to clone private repositories automatically
  - Change passwords/keys (for production, use default ones for dev at your own risk)
    > Special command for SECRETS_MASTER_KEY:
    > ```sh
    > docker run --rm --entrypoint= getcarrier/pylon:1.2.8 python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'
    > ```

3. SSL (optional): copy your server.crt, server.key, ca.crt to ssl/, then:
  - edit pylon_*/pylon.yml: uncomment SSL-related settings
  - edit docker-compose.yml: uncommend SSL-related settings
  - edit envs/override.env: set APP_PROTO to https

4. OpenID Connect SSO (optional):
  - edit pylon_auth/configs/auth_core.yml: set auth_provider to oidc
  - edit pylon_auth/configs/auth_oidc.yml: insert config for your OIDC provider
  - edit pylon_auth/configs/auth_init.yml: specify ID from your provider (e.g. email) for default platform admin

## Manual Start
```sh
docker compose pull
docker compose up -d
docker compose logs -f
```

## First-time platform configuration
1. Create AI integration in Administration mode
2. Create HF integration in Administration mode
3. Create PG integration in Administration mode
