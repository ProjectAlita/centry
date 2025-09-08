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

2. Source **env_file** in the root of repo for configuring service
```sh
source env_file # for bash/sh/zsh

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
1. Login with **admin** account and wait for private project to be created (~5-10 minutes, refresh the page periodically untill **Public and Private** projects are present in dropdown)


2. [PGVector] In **Public** project **Settings -> AI Configuration** create new **PgVector** credential:
    - Label: **elitea-pgvector**
    - Shared: **NO** (do not check)
    - Set as default: **NO** (do not check)
    - Connection string: **postgresql+psycopg://POSTGRES\_USER:POSTGRES\_PASSWORD@pgvector:POSTGRES\_PORT/POSTGRES\_DB** use values from your default.env/override.env; example: **postgresql+psycopg://centry:changeme@pgvector:5432/db**


3. [PGVector] In **Administration** mode **Tasks** **/\~/administration/\~/tasks/tasks/** start:
    - Task: **sync\_pgvector\_credentials**
    - Parameter (input below task dropdown): **force\_recreate,save\_connstr\_to\_secrets**


4. [LiteLLM] In **Administration** mode **Tasks** **/\~/administration/\~/tasks/tasks/** start:
    - Task: **create\_database**
    - Parameter (input below task dropdown): **litellm**


5. [LiteLLM] In **Tasks** table open logs ("file" action) for created task (usually last one with meta: **{'task': 'create\_database'}**) and copy **connection string** from log.


6. [LiteLLM] In **Administration** mode **Runtime -> Remote** **/\~/administration/\~/runtime/remote/** open **runtime\_engine\_litellm** config ("file" action)
    - Click **Load (Raw)**
    - Change **database\_url** from **null** to copied **connection string**
    - Generate master key in format **sk-[alphanumeric]** (example: **sk-abcd1234ABCD**)
    - Change **litellm\_master\_key** to generated master key
    - Click **Save**
    > Example:
    > ```
    > database_url: postgresql://aaa:bbb@ccc:5432/litellm
    > litellm_master_key: sk-abcd1234ABCD
    > ```


7. [LiteLLM] In **Administration** mode **Runtime -> Pylons** **/\~/administration/\~/runtime/pylons/** open **pylon-predicts** settings ("cog / wheel" action)
    - Click **Restart**
    - Wait for **pylon-predicts** to restart


8. [LiteLLM] In **Administration** mode **Tasks** **/\~/administration/\~/tasks/tasks/** start:
    - Task: **sync\_llm\_entities**
    - Parameter: **(leave empty)**


9. [Agent state] In **Administration** mode **Tasks** **/\~/administration/\~/tasks/tasks/** start:
    - Task: **create\_database**
    - Parameter (input below task dropdown): **agentstate**


10. [Agent state] In **Tasks** table open logs ("file" action) for created task (usually last one with meta: **{'task': 'create\_database'}**) and copy **connection string** from log.


11. [Agent state] In **Administration** mode **Runtime -> Remote** **/\~/administration/\~/runtime/remote/** open **indexer\_worker** config ("file" action)
    - Click **Load (Raw)**
    - Uncomment **agent_memory_config** block
    - Change **connection\_string** to copied **connection string**
    - Click **Save**
    > Example:
    > ```
    > agent_memory_config:
    >   type: postgres
    >   connection_string: postgresql://aaa:bbb@ccc:5432/agentstate
    >   connection_kwargs:
    >     autocommit: true
    > ```
