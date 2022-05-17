job "psc-prometheus" {
  datacenters = ["${datacenter}"]
  type = "service"

  vault {
    policies = ["psc-ecosystem"]
    change_mode = "restart"
  }


  group "monitoring" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    network {
      mode = "host"
      port "ui" {
        to = 9090
      }
    }

    constraint {
      attribute = "$\u007Bnode.class\u007D"
      value     = "data"
    }

    ephemeral_disk {
      size = 300
    }

    task "psc-prometheus" {
      driver = "docker"

      config {
        image = "${image}:${tag}"
        mount {
          type = "bind"
          target = "/etc/prometheus"
          source = "local"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--web.external-url=https://$\u007BPUBLIC_HOSTNAME\u007D/psc-prometheus/",
          "--web.route-prefix=/psc-prometheus",
          "--storage.tsdb.retention.time=30d"
        ]
        ports = [
          "ui"
        ]
      }

      template {
        change_mode = "restart"
        destination = "local/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:

  - job_name: 'pscload-actuator'
    metrics_path: '/pscload/v2/actuator/prometheus'
    scrape_interval: 5s
    static_configs:
    - targets: ['{{ range service "pscload" }}{{ .Address }}:{{ .Port }}{{ end }}']

  - job_name: 'rabbitmq'
    metrics_path: '/metrics/per-object'
    scrape_interval: 15s
    static_configs:
    - targets: ['{{ range service "psc-rabbitmq-metrics" }}{{ .Address }}:{{ .Port }}{{ end }}']

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - '{{ range service "psc-alertmanager" }}{{ .Address }}:{{ .Port }}{{ end }}'

rule_files:
  - /etc/prometheus/rules.yml

EOH
      }
      template {
        change_mode = "restart"
        destination = "local/rules.yml"

        data = <<EOH
groups:
- name: pscload
  rules:
# DELETING RULES
#
#
  - alert: pscload-critical-adeli-delete-size
    expr: ps_metric{idType="ADELI",operation="delete"} > scalar(ps_metric{idType="ADELI",operation="reference"}/100)
    labels:
      severity: critical
    annotations:
      Total ADELI delete: {{`{{$value}}`}}
  - alert: pscload-critical-finess-delete-size
    expr: ps_metric{idType="FINESS",operation="delete"} > scalar(ps_metric{idType="FINESS",operation="reference"}/100)
    labels:
      severity: critical
    annotations:
      Total FINESS delete: {{`{{$value}}`}}
  - alert: pscload-critical-siret-delete-size
    expr: ps_metric{idType="SIRET",operation="delete"} > scalar(ps_metric{idType="SIRET",operation="reference"}/100)
    labels:
      severity: critical
    annotations:
      Total SIRET delete: {{`{{$value}}`}}
  - alert: pscload-critical-rpps-delete-size
    expr: ps_metric{idType="RPPS",operation="delete"} > scalar(ps_metric{idType="RPPS",operation="reference"}/100)
    labels:
      severity: critical
    annotations:
      Total RPPS delete: {{`{{$value}}`}}
# UPDATING RULES
#
#
  - alert: pscload-critical-adeli-update-size
    expr: sum(ps_metric{idType="ADELI",operation="update"}) > scalar(ps_metric{idType="ADELI",operation="reference"}*5/100)
    labels:
      severity: critical
    annotations:
      Total ADELI updates: {{`{{$value}}`}}
  - alert: pscload-critical-finess-update-size
    expr: sum(ps_metric{idType="FINESS",operation="update"}) > scalar(ps_metric{idType="FINESS",operation="reference"}*5/100)
    labels:
      severity: critical
    annotations:
      Total FINESS updates: {{`{{$value}}`}}
  - alert: pscload-critical-siret-update-size
    expr: sum(ps_metric{idType="SIRET",operation="update"}) > scalar(ps_metric{idType="SIRET",operation="reference"}*5/100)
    labels:
      severity: critical
    annotations:
      Total SIRET updates: {{`{{$value}}`}}
  - alert: pscload-critical-rpps-update-size
    expr: sum(ps_metric{idType="RPPS",operation="update"}) > scalar(ps_metric{idType="RPPS",operation="reference"}*5/100)
    labels:
      severity: critical
    annotations:
      Total RPPS updates: {{`{{$value}}`}}

  - alert: pscload-continue
    expr: pscload_stage == 50
    for: 2m
    labels:
      severity: continue
    annotations:
      summary: RASS metrics OK
EOH
      }
      template {
        change_mode = "restart"
        destination = "local/file.env"
        env = true
        data = <<EOF
PUBLIC_HOSTNAME={{ with secret "psc-ecosystem/admin" }}{{ .Data.data.admin_public_hostname }}{{ end }}
EOF
      }

      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D"
        tags = [
          "urlprefix-$\u007BPUBLIC_HOSTNAME\u007D/psc-prometheus"]
        port = "ui"

        check {
          name = "prometheus port alive"
          type = "http"
          path = "/psc-prometheus/-/healthy"
          interval = "30s"
          timeout = "2s"
          failures_before_critical = 5
        }
      }
    }
  }
}

