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
- shared
- auth
- admin
- projects
- secrets
- artifacts
- scheduling
#
- theme
- design-system
#
- logging_hub
#
- worker_client
#
- promptlib_shared
- applications
- chat
#
- social
- notifications
#
- alita_ui
#
- monitoring
- monitoring_hub
#
- configurations
#
- runtime_interface_litellm
#
- provider_hub
#
- mcp_sse
