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
          type = "volume"
          target = "/prometheus/data"
          source = "psc-prometheus"
          readonly = false
          volume_options {
            no_copy = false
            driver_config {
              name = "pxd"
              options {
                io_priority = "high"
                size = 1
                repl = 2
              }
            }
          }
        }
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
  - alert: pscload-critical-adeli-delete-size
    expr: ps_metric{idType="ADELI",operation="delete"} > scalar(ps_metric{idType="ADELI",operation="upload"}/100)
    labels:
      severity: critical
    annotations:
      summary: Total changes creations > {{`{{$value}}`}}
  - alert: pscload-critical-finess-delete-size
    expr: ps_metric{idType="FINESS",operation="delete"} > scalar(ps_metric{idType="FINESS",operation="upload"}/100)
    labels:
      severity: critical
    annotations:
      summary: Total changes creations > {{`{{$value}}`}}
  - alert: pscload-critical-siret-delete-size
    expr: ps_metric{idType="SIRET",operation="delete"} > scalar(ps_metric{idType="SIRET",operation="upload"}/100)
    labels:
      severity: critical
    annotations:
      summary: Total changes creations > {{`{{$value}}`}}
  - alert: pscload-critical-rpps-delete-size
    expr: ps_metric{idType="RPPS",operation="delete"} > scalar(ps_metric{idType="RPPS",operation="upload"}/100)
    labels:
      severity: critical
    annotations:
      summary: Total changes creations > {{`{{$value}}`}}

  - alert: pscload-OK
    expr: absent(ps_metric{idType="ADELI",operation="delete"} >= scalar(ps_metric{idType="ADELI",operation="upload"}/100)) * absent(ps_metric{idType="FINESS",operation="delete"} >= scalar(ps_metric{idType="FINESS",operation="upload"}/100)) * absent(ps_metric{idType="SIRET",operation="delete"} >= scalar(ps_metric{idType="SIRET",operation="upload"}/100)) * absent(ps_metric{idType="RPPS",operation="delete"} >= scalar(ps_metric{idType="RPPS",operation="upload"}/100)) * scalar(ps_metric{idType="ANY", operation="delete"} > 0) * scalar(ps_metric{idType="ANY",operation="update"} > 0) * scalar(ps_metric{idType="ANY",operation="create"} > 0)
    labels:
      severity: pscload-OK
    annotations:
      summary: RASS metrics OK
EOH
      }
      template {
        change_mode = "restart"
        destination = "local/file.env"
        env = true
        data = <<EOF
PUBLIC_HOSTNAME={{ with secret "psc-ecosystem/prometheus" }}{{ .Data.data.public_hostname }}{{ end }}
EOF
      }

      resources {
        cpu = 500
        memory = 1024
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

