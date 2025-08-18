.PHONY: up up_minimal down logs check clean_images clean_volumes clean_local_db clean_local_cache help clean_full clean_local_plugins get_tools init plan apply tf_clean compose_clean

SHELL := /bin/bash
FREE_SPACE_THRESHOLD ?= 30
PG_VECTOR_VERSION ?= pg16
PG_VERSION ?= 16.0
CARRIER_VERSION ?= 1.2.7
MS_SDK_VERSION ?= 8.0
MS_ASPNET_VERSION ?= 9.0
HTTP_PORT ?= 80
HTTPS_PORT ?= 443
HTTPS ?= false
CTOP_URL = https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64
TERRAFORM_URL = https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip
LOCAL_BIN_PATH = $(HOME)/.local/bin
TERRAFORM_BIN = $(HOME)/.local/bin/terraform

APP_HOST ?= 172.1.1.1
ALITA_RELEASE ?= 1.6.0
ADMIN_PASSWORD ?= alita_admin
APP_AUTH_SECRET ?=
APP_MAIN_SECRET ?=
MASTER_KEY ?=
REDIS_PASSWORD ?= redis_admin_pwd
PG_PASSWORD ?= pg_admin_pwd
LIC_USERNAME ?=
LIC_PASSWORD ?=
LICENSE_TOKEN ?=


help: ## Show this help
	@printf "Usage: make <target> %s %s %s %s %s %s\n" \
	;  echo "make up - start service" \
	;  echo "make up_minimal - start minimal working configuration" \
	;  echo "make down - down docker compose" \
	;  echo "make logs - show logs flow" \
	;  echo "make check - check section" \
	;  echo "make clean_images - removes docker images only" \
	;  echo "make clean_volumes - removes docker volumes only" \
	;  echo "make clean_local_db - removes local pylon Dbs" \
	;  echo "make clean_local_plugins - removes plugins and requirements" \
	;  echo "make clean_local_cache - removes local cache, static, libcloud" \
	;  echo "make clean_start - removes local files for the clean start, keeps docker images and volumes" \
	;  echo "make clean_full - full remove sequence" \
	;  echo "make tf_clean - remove terraform files" \
	;  echo "make compose_clean - remove docker-compose.yml and ovveride.env" \
	;  echo "make init - init terraform providers" \
	;  echo "make plan - plan terraform changes" \
	;  echo "make apply - apply terraform changes"

up: check
	@echo "Starting docker compose..."
	docker compose -f docker-compose.yml up -d

up_minimal:
	@echo "Starting docker compose..."
	docker compose -f docker-compose.yml up -d pylon_main pylon_auth

down:
	@echo "Stopping docker compose..."
	docker compose -f docker-compose.yml down

logs:
	@echo "Showing logs..."
	docker compose -f ./docker-compose.yml logs -f

check:
	@echo "Run Checks..."
	@if [ -f .label ]; then \
	        echo "It's not a first run...skipping checks....."; \
	else \
	        echo "Proceed checks...."; \
	        FREE_GB=$$(df -T  -BG  . | awk 'NR==2 { sub(/G$$/,"",$$5); print $$5 }'); \
	        if (( "$$FREE_GB" < $(FREE_SPACE_THRESHOLD) )); then \
	                echo "Not enougth free space: got $${FREE_GB}G, (need >= $(FREE_SPACE_THRESHOLD)G)"; \
	                exit 1; \
	        else \
	                echo "Enough free space $${FREE_GB}G...Continue....."; \
	                touch .label; \
	        fi; \
	fi;

clean_images:
	@echo "Cleaning up..."
	@rm -f .label
	@docker image rm pgvector/pgvector:$(PG_VECTOR_VERSION) getcarrier/pylon:$(CARRIER_VERSION) mcr.microsoft.com/dotnet/sdk:$(MS_SDK_VERSION) mcr.microsoft.com/dotnet/aspnet:$(MS_ASPNET_VERSION) postgres:$(PG_VERSION) || true
	@echo "Cleanup complete."

clean_volumes:
	@echo "Cleaning up..."
	@docker volume ls -q --filter name=pgvector-data \
        --filter name=postgres-data \
        --filter name=redis-data \
		| xargs -r docker volume rm
	@echo "Cleanup complete."

clean_local_db:
	@echo -e "\nThis action removes 'local DBs files' !!!"
	@read -r -p "Type 'remove' to delete DBs files: " answer; \
	if [ $$answer == "remove" ]; then \
	        rm -f pylon_auth/pylon.db; \
	        rm -f pylon_indexer/pylon.db; \
	        rm -f pylon_main/pylon.db; \
	        rm -f pylon_predicts/pylon.db; \
	else \
	    echo "Skipped."; \
	        exit 0; \
	fi;

clean_local_plugins:
	@echo -e "\nThis action removes local 'plugins/' and 'requirements/' !!!"
	@read -r -p "Type 'remove' to delete files: " answer; \
	if [ $$answer == "remove" ]; then \
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
	@echo -e "\nThis action removes local 'cache' !!!"
	@read -r -p "Type 'remove' to delete files: " answer; \
	if [ $$answer == "remove" ]; then \
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
	@echo "Dowload tools..."
	@if [ ! -d $(LOCAL_BIN_PATH) ]; then \
	        mkdir -p $(LOCAL_BIN_PATH); \
	fi; \
	if command -v wget >/dev/null 2>&1; then \
	        wget $(CTOP_URL) -O $(LOCAL_BIN_PATH)/ctop; \
	        wget $(TERRAFORM_URL) -O $(LOCAL_BIN_PATH)/terraform.zip; \
	        chmod +x ~/.local/bin/ctop; \
	        echo "don't forget to run:  'source ~/.bashrc'"; \
	elif command -v curl >/dev/null 2>&1; then \
	        curl -o $(LOCAL_BIN_PATH)/ctop $(CTOP_URL); \
	        curl -o $(LOCAL_BIN_PATH)/terraform.zip $(TERRAFORM_URL); \
	        chmod +x $(LOCAL_BIN_PATH)/ctop; \
	        echo "don't forget to run:  'source ~/.bashrc'" \
	else \
	        echo "wget and curl not found"; \
	        exit 1; \
	fi; \
	if ! grep -q '$(LOCAL_BIN_PATH)' $(HOME)/.bashrc; then \
	        echo 'export PATH=$$PATH:$(LOCAL_BIN_PATH)' >> $(HOME)/.bashrc; \
	else \
	        echo "$(LOCAL_BIN_PATH) already in PATH in ~/.bashrc"; \
	fi; \
	if command -v unzip >/dev/null 2>&1; then \
	        unzip -o $(LOCAL_BIN_PATH)/terraform.zip -d $(LOCAL_BIN_PATH)/; \
	        chmod +x $(LOCAL_BIN_PATH)/terraform; \
	else \
	        echo "Install unzip to extract archive with tool..."; \
	fi;

init:
	@echo "Init terraform providers"
	$(TERRAFORM_BIN) -chdir=./tmpl init

plan:
	@echo "Plan rendering docker compose"
	@$(TERRAFORM_BIN) -chdir=./tmpl plan -var PYLON_VER=$(CARRIER_VERSION) -var PG_SQL_VER=$(PG_VERSION) -var PG_VECTOR_VER=$(PG_VECTOR_VERSION) \
	        -var HTTP_HOST_PORT=$(HTTP_PORT) -var HTTPS_HOST_PORT=$(HTTPS_PORT) -var HTTPS=$(HTTPS) \
	        -var ALITA_RELEASE=$(ALITA_RELEASE) -var ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
	        -var APP_AUTH_SECRET=$(APP_AUTH_SECRET) -var APP_MAIN_SECRET=$(APP_MAIN_SECRET) \
	        -var MASTER_KEY=$(MASTER_KEY) -var REDIS_PASSWORD=$(REDIS_PASSWORD) -var PG_PASSWORD=$(PG_PASSWORD) \
	        -var APP_HOST=$(APP_HOST) -var LIC_USERNAME=$(LIC_USERNAME) -var LIC_PASSWORD=$(LIC_PASSWORD) -var LICENSE_TOKEN=$(LICENSE_TOKEN)
apply:
	@echo "Rendering docker compose"
	@$(TERRAFORM_BIN) -chdir=./tmpl apply -auto-approve -var PYLON_VER=$(CARRIER_VERSION) -var PG_SQL_VER=$(PG_VERSION) -var PG_VECTOR_VER=$(PG_VECTOR_VERSION) \
	        -var HTTP_HOST_PORT=$(HTTP_PORT) -var HTTPS_HOST_PORT=$(HTTPS_PORT) -var HTTPS=$(HTTPS) \
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
