job "webhooker" {
  datacenters = ["${datacenter}"]
  type = "service"

  group "webhooker" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }
    ephemeral_disk {
      size = 300
    }

	network {
	  mode = "host"
	  port "webhooker" { to = "8080" }
	}
	
    task "webhooker" {
        template {
        change_mode = "noop"
        destination = "local/config.yaml"
        data = <<EOH
# cache size for blocked tasks
# 50 * 1024 * 1024 = 50 MB
block_cache_size: 52428800

# pool size for new tasks
# locks webhook if overflow
pool_size: 100

# runners count for parallel actions execute
runners: 5

# remote config refresh interval
# rules refreshed only
remote_config_refresh_interval: 60s

# list of rules to check and act
rules:
- name: pscload
  conditions:
    alert_labels:
      severity: continue
  actions:
  - executor: http
    parameters:
      url: http://{{env "NOMAD_IP_webhooker"}}:9999/pscload/v2/continue
      header Accept: "application/json"
	  success_http_status: 202
    block: 10m
EOH
        }

      driver = "docker"
      config {
        image = ${image}:${tag}
        volumes = ["local:/config"]
        args = [ "--verbose" 
		]
        ports = [ "webhooker" ]
      }

      service {
        name = "webhooker"
        tags = ["urlprefix-/webhooker"]
        port = "webhooker"
        check {
          name     = "webhooker port alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
