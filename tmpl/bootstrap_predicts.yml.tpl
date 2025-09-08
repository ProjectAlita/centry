debug: true


mesh:
  event_node:
    type: ZeroMQEventNode
    connect_sub: "tcp://pylon_auth:5010"
    connect_push: "tcp://pylon_auth:5011"
    topic: mesh
    hmac_key: mesh
    hmac_digest: sha512
    callback_workers: 16
    mute_first_failed_connections: 10
    log_errors: true


%{ if ALITA_REMOTE_REPO == 1 }
plugin_repo:
- type: elitea_github
  release: $${ALITA_RELEASE}
  license_username: $${LICENSE_USERNAME}
  license_password: $${LICENSE_PASSWORD}
  add_source_data: true
  add_head_data: true
%{else}
plugin_repo:
- type: repo_depot
  release: $${ALITA_RELEASE}
  license_token: $${LICENSE_TOKEN}
%{ endif }


preordered_plugins:
- worker_core
#
- monitoring
#
# - ai_dial_worker
# - open_ai_azure_worker
- hugging_face_worker
# - ai_preload_shim_worker
# - vertex_ai_worker
# - amazon_bedrock_worker
# - open_ai_worker
#
- runtime_engine_litellm
