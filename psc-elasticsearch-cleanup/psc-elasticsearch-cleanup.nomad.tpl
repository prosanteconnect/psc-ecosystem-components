job "elasticsearch-cleanup" {
  datacenters = ["${datacenter}"]
  type = "batch"
  namespace = "${nomad_namespace}"
  periodic {
    cron             = "30 00 * * * *"
    prohibit_overlap = true
  }
  group "es-cleanup" {
    count = 1

    task "free-space" {
      driver = "docker"
      config {
        image = "${image}:${tag}"
        args = [ "--config", "/local/config.yaml", "/local/actions.yaml" ]
      }
      template {
        data = <<EOH
---
client:
{{range service "${nomad_namespace}-elasticsearch" }}
  hosts: {{.Address}}
  port: {{.Port}}{{end}}
  url_prefix:
  use_ssl: False
  certificate:
  client_cert:
  client_key:
  ssl_no_validate: False
  username:
  password:
  timeout: 30
  master_only: False

logging:
  loglevel: INFO
  logfile:
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
EOH
        destination = "local/config.yaml"
      }
      template {
        data = <<EOH
---
actions:
  1:
    action: delete_indices
    description: >-
      Delete indices older than 45 days (based on index name), for filebeat-
      prefixed indices. Ignore the error if the filter does not result in an
      actionable list of indices (ignore_empty_list) and exit cleanly.
    options:
      ignore_empty_list: True
      disable_action: False
    filters:
    - filtertype: pattern
      kind: prefix
      value: filebeat-
    - filtertype: age
      source: name
      direction: older
      timestring: '%Y.%m.%d'
      unit: days
      unit_count: 45
EOH
        destination = "local/actions.yaml"
      }
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}

