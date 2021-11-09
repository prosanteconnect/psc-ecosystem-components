job "psc-rabbitmq" {
  datacenters = ["${datacenter}"]
  type = "service"

  vault {
    policies = ["psc-ecosystem"]
    change_mode = "restart"
  }

  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "psc-rabbitmq" {
    count = 1

    restart {
      attempts = 3
      delay = "60s"
      interval = "1h"
      mode = "fail"
    }

    constraint {
      attribute = "$\u007Bnode.class\u007D"
      value     = "data"
    }

    update {
      max_parallel      = 1
      min_healthy_time  = "30s"
      progress_deadline = "5m"
      healthy_deadline  = "2m"
    }

    network {
      port "endpoint" { to = 5672 }
      port "management" { to = 15672 }
    }

    task "psc-rabbitmq" {
      driver = "docker"
      config {
        image = "${image}:${tag}"
        ports = ["endpoint","management"]
        command = "run"
        args = ["--hostname", "psc-rabbitmq"]
        mount {
          type = "volume"
          target = "/var/lib/rabbitmq"
          source = "rabbitmq"
          readonly = false
          volume_options {
            no_copy = false
            driver_config {
              name = "pxd"
              options {
                io_priority = "high"
                size = 5
                repl = 3
              }
            }
          }
        }
        mount {
          type = "bind"
          target = "/etc/rabbitmq/conf.d/20-management.conf"
          source = "local/20-management.conf"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
        mount {
          type = "bind"
          target = "/etc/rabbitmq/definitions.json"
          source = "local/definitions.json"
          readonly = false
          bind_options {
            propagation = "rshared"
          }
        }
      }
      template {
        data = <<EOH
RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS = "-rabbitmq_management path_prefix \"/rabbitmq\""
RABBITMQ_DEFAULT_USER="{{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.user }}{{ end }}"
RABBITMQ_DEFAULT_PASS="{{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.password }}{{ end }}"
PUBLIC_HOSTNAME={{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.public_hostname }}{{ end }}
EOH
        destination = "secrets/file.env"
        env = true
      }
      template {
        change_mode = "restart"
        destination = "local/20-management.conf"
        data = <<EOF
management.load_definitions = /etc/rabbitmq/definitions.json
management.tcp.port = 15672
EOF
      }
      template {
        change_mode = "restart"
        destination = "local/definitions.json"
        data = <<EOF
{
        "bindings": [
                {
                        "arguments": {},
                        "destination": "file.upload",
                        "destination_type": "queue",
                        "routing_key": "file.upload",
                        "source": "amq.topic",
                        "vhost": "/"
                }
        ],
        "queues": [
                {
                        "arguments": {},
                        "auto_delete": false,
                        "durable": true,
                        "name": "file.upload",
                        "type": "classic",
                        "vhost": "/"
                }
        ]
}
EOF
      }

      resources {
        cpu    = 1000
        memory = 2048
      }
      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D"
        port = "endpoint"
        check {
          name         = "alive"
          type         = "tcp"
          interval     = "10s"
          timeout      = "2s"
          port         = "endpoint"
        }
      }
      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D-management"
        port = "management"
        tags = ["urlprefix-$\u007BPUBLIC_HOSTNAME\u007D/rabbitmq/"]
        check {
          name         = "alive"
          type         = "http"
          path         = "/rabbitmq/"
          interval     = "30s"
          timeout      = "2s"
          failures_before_critical = 5
          port         = "management"
        }
      }
    }
  }
}
