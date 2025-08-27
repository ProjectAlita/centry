.PHONY: up up_minimal down logs check clean_images clean_volumes clean_local_db clean_local_cache help clean_full clean_local_plugins get_tools init plan apply tf_clean compose_clean clean_start

SHELL := /bin/bash
FREE_SPACE_THRESHOLD ?= 30
PG_VECTOR_VERSION ?= pg16
PG_VERSION ?= 16.0
PYLON_VER ?= 1.2.7
MS_SDK_VERSION ?= 8.0
MS_ASPNET_VERSION ?= 9.0
HTTP_HOST_PORT ?= 80
HTTPS_HOST_PORT ?= 443
HTTPS ?= false
CTOP_URL = https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64
LOCAL_BIN_PATH = $(HOME)/.local/bin
TERRAFORM_BIN = $(HOME)/.local/bin/terraform

# --- Terraform cross-platform URL (Linux/macOS × amd64/arm64) ---
TERRAFORM_VERSION ?= 1.12.2
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
# Normalize OS
TF_OS := $(if $(filter Linux,$(UNAME_S)),linux,$(if $(filter Darwin,$(UNAME_S)),darwin,unsupported))
# Normalize ARCH
TF_ARCH := $(if $(filter x86_64 amd64,$(UNAME_M)),amd64,$(if $(filter arm64 aarch64,$(UNAME_M)),arm64,unsupported))
# Final URL
TERRAFORM_URL = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_$(TF_OS)_$(TF_ARCH).zip


APP_HOST ?= 172.1.1.1
ALITA_RELEASE ?= 1.6.0
ALITA_REMOTE_REPO ?= 1
ADMIN_PASSWORD ?= alita_admin
APP_AUTH_SECRET ?=
APP_MAIN_SECRET ?=
MASTER_KEY ?=
EVENT_HMAC_KEY ?=
RPC_HMAC_KEY ?=
EXPOSURE_HMAC_KEY ?=
INDEXER_HMAC_KEY ?=
REDIS_PASSWORD ?= redis_admin_pwd
PG_PASSWORD ?= pg_admin_pwd
LIC_USERNAME ?=
LIC_PASSWORD ?=
LICENSE_TOKEN ?=

DOCKER_COMPOSE := $(shell command -v docker-compose >/dev/null 2>&1 && echo docker-compose || echo docker compose)

help: ## Show this help
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  up               - start service"
	@echo "  up_minimal       - start minimal working configuration"
	@echo "  down             - down docker compose"
	@echo "  logs             - show logs flow"
	@echo "  check            - check section"
	@echo "  clean_images     - remove docker images only"
	@echo "  clean_volumes    - remove docker volumes only"
	@echo "  clean_local_db   - remove local pylon DBs"
	@echo "  clean_local_plugins - remove plugins and requirements"
	@echo "  clean_local_cache  - remove local cache/static/libcloud"
	@echo "  clean_start      - remove local files (keep images/volumes)"
	@echo "  clean_full       - full remove sequence"
	@echo "  tf_clean         - remove terraform files"
	@echo "  compose_clean    - remove docker-compose.yml and override.env"
	@echo "  init|plan|apply  - terraform workflow"
	@echo "  get_tools        - download ctop & terraform"

up: check
	@echo "Starting docker compose..."
	$(DOCKER_COMPOSE) -f docker-compose.yml up -d

up_minimal:
	@echo "Starting docker compose..."
	$(DOCKER_COMPOSE) -f docker-compose.yml up -d pylon_main pylon_auth

down:
	@echo "Stopping docker compose..."
	$(DOCKER_COMPOSE) -f docker-compose.yml down

logs:
	@echo "Showing logs..."
	$(DOCKER_COMPOSE) -f ./docker-compose.yml logs -f

check:
	@echo "Run Checks..."
	@if [ -f .label ]; then \
	  echo "It's not a first run...skipping checks....."; \
	else \
	  echo "Proceed checks...."; \
	  FREE_GB=$$(df -k . | awk 'NR==2 { printf "%d", $$4/1024/1024 }'); \
	  if [ "$$FREE_GB" -lt "$(FREE_SPACE_THRESHOLD)" ]; then \
	    echo "Not enough free space: got $${FREE_GB}G (need >= $(FREE_SPACE_THRESHOLD)G)"; \
	    exit 1; \
	  else \
	    echo "Enough free space $${FREE_GB}G...Continue....."; \
	    touch .label; \
	  fi; \
	fi

clean_images:
	@echo "Cleaning up..."
	@rm -f .label
	@rm -f  docker-compose.yml
	@rm -f ./envs/override.env
	@docker image rm pgvector/pgvector:$(PG_VECTOR_VERSION) getcarrier/pylon:$(PYLON_VER) mcr.microsoft.com/dotnet/sdk:$(MS_SDK_VERSION) mcr.microsoft.com/dotnet/aspnet:$(MS_ASPNET_VERSION) postgres:$(PG_VERSION) || true
	@echo "Cleanup complete."

clean_volumes:
	@echo "Cleaning up..."
	@vols=$$(docker volume ls -q --filter name=pgvector-data --filter name=postgres-data --filter name=redis-data); \
	if [ -n "$$vols" ]; then docker volume rm $$vols; else echo "No volumes to remove"; fi
	@echo "Cleanup complete."

clean_local_db:
	@printf "\nThis action removes 'local DBs files' !!!\n"
	@printf "%s" "Type 'remove' to delete DBs files: " ; \
	IFS= read -r answer ; \
	if [ $$answer = "remove" ]; then \
	        rm -f pylon_auth/pylon.db; \
	        rm -f pylon_indexer/pylon.db; \
	        rm -f pylon_main/pylon.db; \
	        rm -f pylon_predicts/pylon.db; \
	else \
	    echo "Skipped."; \
	        exit 0; \
	fi;

clean_local_plugins:
	@printf "\nThis action removes local 'plugins/' and 'requirements/' !!!\n"
	@printf "%s" "Type 'remove' to delete files: " ; \
	IFS= read -r answer ; \
	if [ $$answer = "remove" ]; then \
	        rm -rf pylon_auth/plugins; \
	        rm -rf pylon_indexer/plugins; \
	        rm -rf pylon_main/plugins; \
	        rm -rf pylon_predicts/plugins; \
	        rm -rf pylon_auth/requirements; \
	        rm -rf pylon_indexer/requirements; \
	        rm -rf pylon_main/requirements; \
	        rm -rf pylon_predicts/requirements; \
	else \
	    echo "Skipped."; \
	        exit 0; \
	fi;

clean_local_cache:
	@printf "\nThis action removes local 'cache' !!!\n"
	@printf "%s" "Type 'remove' to delete files: " ; \
	IFS= read -r answer ; \
	if [ $$answer = "remove" ]; then \
	        rm -rf pylon_auth/cache; \
	        rm -rf pylon_indexer/cache; \
	        rm -rf pylon_main/cache; \
	        rm -rf pylon_predicts/cache; \
			rm -rf pylon_main/static; \
			rm -rf pylon_main/libcloud; \
			rm -rf pylon_indexer/charts; \
	else \
	    echo "Skipped."; \
	        exit 0; \
	fi;

clean_start: clean_local_cache clean_local_plugins clean_local_db
	@echo -e "\nFiles have been removed for the clean start"

clean_full: clean_local_db clean_local_plugins clean_images clean_volumes tf_clean compose_clean clean_local_cache
	@echo "All data and images has been removed"

get_tools:
	@echo "Download tools..."
	@if [ "$(TF_OS)" = "unsupported" ] || [ "$(TF_ARCH)" = "unsupported" ]; then \
		echo "Unsupported platform: $(UNAME_S) $(UNAME_M)"; exit 1; \
	fi; \
	if [ ! -d $(LOCAL_BIN_PATH) ]; then mkdir -p $(LOCAL_BIN_PATH); \
	fi; \
	if command -v wget >/dev/null 2>&1; then \
		wget -L $(CTOP_URL) -O $(LOCAL_BIN_PATH)/ctop; \
		wget -L $(TERRAFORM_URL) -O $(LOCAL_BIN_PATH)/terraform.zip; \
	elif command -v curl >/dev/null 2>&1; then \
	  curl -L -o $(LOCAL_BIN_PATH)/ctop $(CTOP_URL); \
	  curl -L -o $(LOCAL_BIN_PATH)/terraform.zip $(TERRAFORM_URL); \
	else \
	  echo "wget and curl not found"; exit 1; \
	fi; \
	chmod +x $(LOCAL_BIN_PATH)/ctop; \
	if ! grep -q '$(LOCAL_BIN_PATH)' $(HOME)/.bashrc 2>/dev/null; then \
	  echo 'export PATH=$$PATH:$(LOCAL_BIN_PATH)' >> $(HOME)/.bashrc; \
	fi; \
	if [ -n "$$ZSH_NAME" ] && ! grep -q '$(LOCAL_BIN_PATH)' $(HOME)/.zshrc 2>/dev/null; then \
	  echo 'export PATH=$$PATH:$(LOCAL_BIN_PATH)' >> $(HOME)/.zshrc; \
	fi; \
	if command -v unzip >/dev/null 2>&1; then \
	  unzip -o $(LOCAL_BIN_PATH)/terraform.zip -d $(LOCAL_BIN_PATH)/; \
	  chmod +x $(LOCAL_BIN_PATH)/terraform; \
	  rm -f "$(LOCAL_BIN_PATH)/terraform.zip"; \
	else \
	  echo "Install unzip to extract Terraform archive..."; \
	fi

init:
	@echo "Init terraform providers"
	$(TERRAFORM_BIN) -chdir=./tmpl init

plan:
	@echo "Plan rendering docker compose"
	@$(TERRAFORM_BIN) -chdir=./tmpl plan -var PYLON_VER=$(PYLON_VER) -var PG_SQL_VER=$(PG_VERSION) -var PG_VECTOR_VER=$(PG_VECTOR_VERSION) \
	        -var HTTP_HOST_PORT=$(HTTP_HOST_PORT) -var HTTPS_HOST_PORT=$(HTTPS_HOST_PORT) -var HTTPS=$(HTTPS) -var ALITA_REMOTE_REPO=$(ALITA_REMOTE_REPO) \
	        -var ALITA_RELEASE=$(ALITA_RELEASE) -var ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
	        -var APP_AUTH_SECRET=$(APP_AUTH_SECRET) -var APP_MAIN_SECRET=$(APP_MAIN_SECRET) \
	        -var MASTER_KEY=$(MASTER_KEY) -var REDIS_PASSWORD=$(REDIS_PASSWORD) -var PG_PASSWORD=$(PG_PASSWORD) \
	        -var APP_HOST=$(APP_HOST) -var LIC_USERNAME=$(LIC_USERNAME) -var LIC_PASSWORD=$(LIC_PASSWORD) -var LICENSE_TOKEN=$(LICENSE_TOKEN)
apply:
	@echo "Rendering docker compose"
	@$(TERRAFORM_BIN) -chdir=./tmpl apply -auto-approve -var PYLON_VER=$(PYLON_VER) -var PG_SQL_VER=$(PG_VERSION) -var PG_VECTOR_VER=$(PG_VECTOR_VERSION) \
	        -var HTTP_HOST_PORT=$(HTTP_HOST_PORT) -var HTTPS_HOST_PORT=$(HTTPS_HOST_PORT) -var HTTPS=$(HTTPS) -var ALITA_REMOTE_REPO=$(ALITA_REMOTE_REPO) \
	        -var ALITA_RELEASE=$(ALITA_RELEASE) -var ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
	        -var APP_AUTH_SECRET=$(APP_AUTH_SECRET) -var APP_MAIN_SECRET=$(APP_MAIN_SECRET) \
	        -var MASTER_KEY=$(MASTER_KEY) -var REDIS_PASSWORD=$(REDIS_PASSWORD) -var PG_PASSWORD=$(PG_PASSWORD) \
	        -var APP_HOST=$(APP_HOST) -var LIC_USERNAME=$(LIC_USERNAME) -var LIC_PASSWORD=$(LIC_PASSWORD) -var LICENSE_TOKEN=$(LICENSE_TOKEN)

tf_clean:
	@echo "Removing terraform files"
	@rm -f ./tmpl/.terraform.lock
	@rm -rf ./tmpl/.terraform
	@rm -f ./tmpl/terraform.tfstate
	@rm -f ./tmpl/terraform.tfstate.backup
	@rm -f ./tmpl/.terraform.lock.hcl
	@echo "Done"

compose_clean:
	@echo "Removing docker-compose.yml and ovveride.env files"
	@rm -f docker-compose.yml
	@rm -f ./envs/override.env
	@echo "Done"
