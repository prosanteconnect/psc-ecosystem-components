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
      env = {
        RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS = "-rabbitmq_management path_prefix \"/rabbitmq\""
      }
      config {
        image = "${image}:${tag}"
        ports = ["endpoint","management"]
        volumes = ["name=rabbitmq,io_priority=high,size=5,repl=3:/var/lib/rabbitmq"]
        volume_driver = "pxd"
      }
      template {
        data = <<EOH
RABBITMQ_DEFAULT_USER="{{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.user }}{{ end }}"
RABBITMQ_DEFAULT_PASS="{{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.password }}{{ end }}"
EOH
        destination = "secrets/file.env"
        env = true
      }
      template {
        change_mode = "restart"
        destination = "local/file.env"
        env = true
        data = <<EOF
PUBLIC_HOSTNAME={{ with secret "psc-ecosystem/rabbitmq" }}{{ .Data.data.public_hostname }}{{ end }}
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
          address_mode = "driver"
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
          path         = "/"
          interval     = "10s"
          timeout      = "2s"
          address_mode = "driver"
          port         = "management"
        }
      }
    }
  }
}
