job "psc-rabbitmq" {
  datacenters = ["dc1"]
  type = "service"

  vault {
    policies = ["rabbitmq"]
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
      canary            = 1
      min_healthy_time  = "30s"
      progress_deadline = "5m"
      healthy_deadline  = "2m"
      auto_revert       = true
      auto_promote      = true
    }

    network {
      port "endpoint" { to = 5672 }
      port "management" { to = 15672 }
    }
    task "rabbitmq" {
      driver = "docker"
      env = {
        RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS = "-rabbitmq_management path_prefix \"/psc-rabbitmq\""
      }
      config {
        image = "rabbitmq:3.8.6-management-alpine"
        ports = ["endpoint","management"]
        volumes = ["name=rabbitmq,io_priority=high,size=5,repl=2:/var/lib/rabbitmq"]
        volume_driver = "pxd"
      }
      template {
        data = <<EOH
RABBITMQ_DEFAULT_USER="{{ with secret "components/rabbitmq/authentication" }}{{ .Data.data.user }}{{ end }}"
RABBITMQ_DEFAULT_PASS="{{ with secret "components/rabbitmq/authentication" }}{{ .Data.data.password }}{{ end }}"
EOH
        destination = "secrets/file.env"
        env = true
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
        tags = ["urlprefix-${public_hostname}/psc-rabbitmq/"]
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
