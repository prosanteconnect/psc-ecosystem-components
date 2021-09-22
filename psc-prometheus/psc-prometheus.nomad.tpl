job "psc-prometheus" {
  datacenters = ["dc1"]
  type = "service"

  group "monitoring" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      mode = "host"
      port "ui" {
        to = 9090
      }
    }
    ephemeral_disk {
      size = 300
    }

    task "psc-prometheus" {
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
    metrics_path: '/pscload/v1/actuator/prometheus'
    scrape_interval: 5s
    static_configs:
    - targets: ['{{ range service "pscload" }}{{ .Address }}:{{ .Port }}{{ end }}']

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
  - alert: pscload-critical-create-size
    expr: ps_metric{group="total",operation="create"}*scalar(pscload_stage == bool 4) >= 5000
    labels:
      severity: critical
    annotations:
      summary: Total PS creations > {{`{{$value}}`}}
  - alert: pscload-critical-update-size
    expr: ps_metric{group="total",operation="update"}*scalar(pscload_stage == bool 4) >= 5000
    labels:
      severity: critical
    annotations:
      summary: Total PS updates > {{`{{$value}}`}}
  - alert: pscload-critical-delete-size
    expr: ps_metric{group="total",operation="delete"}*scalar(pscload_stage == bool 4) >= 5000
    labels:
      severity: critical
    annotations:
      summary: Total PS deletions > {{`{{$value}}`}}
  - alert: pscload-OK
    expr: (scalar(ps_metric{group="total",operation="create"}) + scalar(ps_metric{group="total",operation="update"}) + scalar(ps_metric{group="total",operation="delete"}) + 1) * scalar(pscload_stage == bool 4) == bool 1
    labels:
      severity: pscload-OK
    annotations:
      summary: RASS metrics OK
EOH
      }

      driver = "docker"

      config {
        image = "prom/prometheus"
        volumes = [
          "local:/etc/prometheus",
        ]
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--web.external-url=https://${public_hostname}/psc-prometheus/",
          "--web.route-prefix=/psc-prometheus",
          "--storage.tsdb.retention.time=30d"
        ]
        ports = [
          "ui"
        ]
      }

      resources {
        cpu = 500
        memory = 1024
      }

      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D"
        tags = ["urlprefix-${public_hostname}/psc-prometheus"]
        port = "ui"

        check {
          name     = "prometheus port alive"
          type     = "http"
          path     = "/psc-prometheus/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}

