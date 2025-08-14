#
# General server config
#
server:
  name: $${NAME}
  path: /forward-auth/
  proxy:
    x_for: 1
    x_proto: 1
    x_host: 1
  host: "0.0.0.0"
  port: 8080
  health:
    healthz: true
    livez: true
    readyz: true

#
# Logging
#
log:
  level: info

#
# SSL CAs

%{ if HTTPS }
ssl:
  certs:
  - /ssl/ca.crt
%{ endif }

#
# Exposure
#
exposure:
  event_node:
    type: RedisEventNode
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    event_queue: $${NAME_PREFIX}_exposure_events
    hmac_key: $${EXPOSURE_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: 16
    use_ssl: $${REDIS_SSL}
  expose: true
  announce_interval: 3
  zmq:
    enabled: true

#
# Pylon DB
#
pylon_db:
  engine_url: sqlite:////data/pylon.db

#
# Local paths to modules and config
#
modules:
  plugins:
    provider:
      type: folder
      path: /data/plugins
  #
  requirements:
    mode: relaxed
    activation: bulk
    cache: /data/cache/pip
    provider:
      type: folder
      path: /data/requirements
  #
  config:
    provider:
      type: folder
      path: /data/configs
  #
  preload:
    bootstrap:
      provider:
        type: git
        delete_git_dir: false
        depth: null
      source: https://github.com/centry-core/bootstrap.git
      branch: $${ALITA_RELEASE}

#
# Environment configuration
#
environment:
  NLTK_DATA: /data/cache/nltk
  TRANSFORMERS_CACHE: /data/cache/transformers

#
# Persistent sessions
#
sessions:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}
  prefix: $${NAME_PREFIX}_auth_session_

#
# Events queue
#
events:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}
    queue: $${NAME_PREFIX}_events
    hmac_key: $${EVENT_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: 16

#
# RPC
#
rpc:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}
    queue: $${NAME_PREFIX}_rpc
    hmac_key: $${RPC_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: 32
  id_prefix: $${NAME_PREFIX}_auth_rpc_

#
# SIO
#
socketio:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}

#
# Settings for Flask application
#
application:
  SECRET_KEY: $${APPLICATION_SECRET_KEY}
  SERVER_NAME: $${APP_HOST}
  APPLICATION_ROOT: /forward-auth/
  SESSION_COOKIE_NAME: $${NAME_PREFIX}_auth_session
  SESSION_COOKIE_DOMAIN: $${APP_HOST}
  SESSION_COOKIE_PATH: /
  SESSION_COOKIE_HTTPONLY: true
  SESSION_COOKIE_SECURE: $${COOKIES_SECURE}
  PREFERRED_URL_SCHEME: $${APP_PROTO}
