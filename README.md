# Centry deployment for Alita


## Requirements
- Docker
- Docker compose (docker-compose-plugin preferred)


## Configuration
1. Copy envs/default.env to envs/override.env


2. Edit envs/override.env:
    - Set APP_HOST to IP/DNS of platform
    - Set LICENSE_USERNAME and LICENSE_PASSWORD to your github username and token in order for pylons to clone private repositories automatically
    - Change passwords/keys (for production, use default ones for dev at your own risk)
    > Special command for SECRETS_MASTER_KEY:
    > ```sh
    > docker run --rm --entrypoint= getcarrier/pylon:1.2.22 python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'
    > ```


3. SSL (optional): copy your server.crt, server.key, ca.crt to ssl/, then:
    - edit pylon_*/pylon.yml: uncomment SSL-related settings
    - edit docker-compose.yml: uncommend SSL-related settings
    - edit envs/override.env: set APP_PROTO to https


4. OpenID Connect SSO (optional):
    - edit pylon_auth/configs/auth_core.yml: set auth_provider to oidc
    - edit pylon_auth/configs/auth_oidc.yml: insert config for your OIDC provider
    - edit pylon_auth/configs/auth_init.yml: specify ID from your provider (e.g. email) for default platform admin


## Start
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
