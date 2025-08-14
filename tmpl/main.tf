terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

variable "PG_SQL_VER" {
  type        = string
  default     = "16.0"
  description = "PGSQL version"
}

variable "PG_VECTOR_VER" {
  type        = string
  default     = "pg16"
  description = "PG vector version"
}

variable "PYLON_VER" {
  type        = string
  default     = "1.2.7"
  description = "Pylon version"
}

variable "HTTPS" {
  type        = bool
  default     = false
  description = "enabled htttps"
}

variable "HTTP_HOST_PORT" {
  type        = string
  default     = "80"
  description = "HTTP port"
}

variable "HTTPS_HOST_PORT" {
  type        = string
  default     = "443"
  description = "HTTP port"
}


resource "local_file" "docker_compose" {
  content = templatefile(
    "${path.module}/docker-compose.yml.tpl",
    {
      PG_SQL_VER      = var.PG_SQL_VER
      PG_VECTOR_VER   = var.PG_VECTOR_VER
      PYLON_VER       = var.PYLON_VER
      HTTP_HOST_PORT  = var.HTTP_HOST_PORT
      HTTPS_HOST_PORT = var.HTTPS_HOST_PORT
      HTTPS           = var.HTTPS
    }
  )
  filename = "../docker-compose.yml"
}



variable "APP_HOST" {
  type        = string
  default     = "172.1.1.3"
  description = "IP or dns of service"
}

variable "ALITA_RELEASE" {
  type        = string
  default     = "1.6.0"
  description = "Alita release"
}

variable "LIC_USERNAME" {
  type        = string
  default     = "github_username"
  description = "Github username"
}

variable "LIC_PASSWORD" {
  type        = string
  default     = "github_PASSWORD"
  description = "Github token"
}

variable "LICENSE_TOKEN" {
  type        = string
  default     = ""
  description = "LICENSE_TOKEN"
}

variable "ADMIN_PASSWORD" {
  type        = string
  default     = "admin"
  description = "Admin password"
}

variable "APP_AUTH_SECRET" {
  type        = string
  default     = ""
  description = "APPLICATION AUTH SECRET KEY"
}

variable "APP_MAIN_SECRET" {
  type        = string
  default     = ""
  description = "APPLICATION MAIN SECRET  KEY"
}

variable "REDIS_PASSWORD" {
  type        = string
  default     = "redis_admin"
  description = "redis password"
}

variable "MASTER_KEY" {
  type        = string
  default     = ""
  description = "SECRETS_MASTER_KEY"
}

variable "PG_PASSWORD" {
  type        = string
  default     = "pg_admin"
  description = "PG Password"
}


resource "random_id" "fernet_key" {
  byte_length = 32
}

resource "random_id" "rnd_auth_secret" {
  byte_length = 10
}

resource "random_id" "rnd_main_secret" {
  byte_length = 10
}

resource "local_file" "override" {
  content = templatefile(
    "${path.module}/override.env.tpl",
    {
      APP_HOST        = var.APP_HOST
      ALITA_RELEASE   = var.ALITA_RELEASE
      LIC_USERNAME    = var.LIC_USERNAME
      LIC_PASSWORD    = var.LIC_PASSWORD
      LICENSE_TOKEN   = var.LICENSE_TOKEN
      ADMIN_PASSWORD  = var.ADMIN_PASSWORD
      APP_AUTH_SECRET = var.APP_AUTH_SECRET != "" ? var.APP_AUTH_SECRET : random_id.rnd_auth_secret.b64_std
      APP_MAIN_SECRET = var.APP_MAIN_SECRET != "" ? var.APP_MAIN_SECRET : random_id.rnd_main_secret.b64_std
      MASTER_KEY      = var.MASTER_KEY != "" ? var.MASTER_KEY : random_id.fernet_key.b64_std
      REDIS_PASSWORD  = var.REDIS_PASSWORD
      PG_PASSWORD     = var.PG_PASSWORD

    }
  )
  filename = "../envs/override.env"
}


resource "local_file" "pylon_auth" {
  content = templatefile(
    "${path.module}/pylon_auth.yml.tpl",
    {
      HTTPS = var.HTTPS
    }
  )
  filename = "../pylon_auth/pylon.yml"
}

resource "local_file" "pylon_indexer" {
  content = templatefile(
    "${path.module}/pylon_indexer.yml.tpl",
    {
      HTTPS = var.HTTPS
    }
  )
  filename = "../pylon_indexer/pylon.yml"
}

resource "local_file" "pylon_main" {
  content = templatefile(
    "${path.module}/pylon_main.yml.tpl",
    {
      HTTPS = var.HTTPS
    }
  )
  filename = "../pylon_main/pylon.yml"
}


resource "local_file" "pylon_predicts" {
  content = templatefile(
    "${path.module}/pylon_predicts.yml.tpl",
    {
      HTTPS = var.HTTPS
    }
  )
  filename = "../pylon_predicts/pylon.yml"
}
