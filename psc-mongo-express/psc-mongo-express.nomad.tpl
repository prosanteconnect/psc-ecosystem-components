job "psc-mongo-express" {
  datacenters = ["dc1"]
  type = "service"

  vault {
    policies = ["psc-ecosystem"]
    change_mode = "restart"
  }

  group "psc-mongo-express" {
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
      port "ui" { to = 8081 }
    }

    task "psc-mongo-express" {
      driver = "docker"
      env = {
        ME_CONFIG_MONGODB_ADMINUSERNAME = "{{ with secret \"psc-ecosystem/mongodb\" }}{{ .Data.data.root_user }}{{ end }}"
        ME_CONFIG_MONGODB_ADMINPASSWORD = "{{ with secret \"psc-ecosystem/mongodb\" }}{{ .Data.data.root_pass }}{{ end }}"
        ME_CONFIG_SITE_BASEURL = "/psc-db/"
      }
      template {
        data = <<EOH
ME_CONFIG_MONGODB_SERVER="{{ range service "psc-mongodb" }}{{ .Address }}{{ end }}"
ME_CONFIG_MONGODB_PORT="{{ range service "psc-mongodb" }}{{ .Port }}{{ end }}"
EOH
        destination = "secrets/file.env"
        change_mode = "restart"
        env = true
      }
      config {
        image = "${image}:${tag}"
        ports = ["ui"]
      }
      resources {
        cpu    = 1000
        memory = 2048
      }
      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D"
        port = "ui"
        tags = ["urlprefix-${public_hostname}/psc-db/"]
        check {
          name         = "alive"
          type         = "tcp"
          interval     = "10s"
          timeout      = "5s"
          port         = "ui"
        }
      }
    }
  }
}
