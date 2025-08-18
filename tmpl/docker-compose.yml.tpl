---

services:
  redis:
    image: redis:alpine
    command: sh -c 'exec redis-server --requirepass $$REDIS_PASSWORD --save 300 1 --dir /data/ --dbfilename dump.rdb'
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    volumes:
      - redis-data:/data
    networks:
      - centry
  
  postgres:
    image: postgres:${PG_SQL_VER}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    environment:
      - PGDATA=/data/pgdata
    volumes:
      - postgres-data:/data
    networks:
      - centry

  pgvector:
    image: pgvector/pgvector:${PG_VECTOR_VER}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    environment:
      - PGDATA=/data/pgdata
    volumes:
      - pgvector-data:/data
    networks:
      - centry

  pylon_auth:
    image: getcarrier/pylon:${PYLON_VER}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    environment:
      - NAME=pylon-auth
      - PYLON_WEB_RUNTIME=gevent
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    volumes:
      - ./pylon_auth:/data
      %{ if HTTPS }- ./ssl:/ssl%{ endif }
    depends_on:
      - redis
      - postgres
    networks:
      - centry
  
  pylon_main:
    image: getcarrier/pylon:${PYLON_VER}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    environment:
      - NAME=pylon-main
      - PYLON_WEB_RUNTIME=gevent
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    volumes:
      - ./pylon_main:/data
      %{ if HTTPS }- ./ssl:/ssl%{ endif }
    ports:
      - ${HTTP_HOST_PORT}:8080
      %{ if HTTPS }- ${HTTPS_HOST_PORT}:8443%{ endif }
    depends_on:
      - redis
      - postgres
    networks:
      - centry

  pylon_indexer:
    image: getcarrier/pylon:${PYLON_VER}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    environment:
      - NAME=pylon-indexer
      - PYLON_WEB_RUNTIME=waitress
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    volumes:
      - ./pylon_indexer:/data
      %{ if HTTPS }- ./ssl:/ssl%{ endif }
    depends_on:
      - redis
    networks:
      - centry

  pylon_predicts:
    image: getcarrier/pylon:${PYLON_VER}
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/default.env
      - ./envs/override.env
    environment:
      - NAME=pylon-predicts
      - PYLON_WEB_RUNTIME=waitress
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    volumes:
      - ./pylon_predicts:/data
      %{ if HTTPS }- ./ssl:/ssl%{ endif }
    depends_on:
      - redis
    networks:
      - centry

volumes:
  redis-data:
  postgres-data:
  pgvector-data:

networks:
  centry:
