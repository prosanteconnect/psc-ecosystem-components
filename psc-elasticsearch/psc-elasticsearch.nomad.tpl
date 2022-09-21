job "elasticsearch" {

  type = "service"
  datacenters = ["${datacenter}"]
  namespace = "${nomad_namespace}"

  update {
    stagger = "30s"
    max_parallel = 1
  }

  group "elasticsearch" {
    count = 1
    constraint {
      attribute = "$\u007Bnode.class\u007D"
      value     = "data"
    }
    network {
      port "es" { to = 9200 }
      port "ed" { to = 9300 }
    }
    task "elasticsearch" {
      driver = "docker"

      template {
        change_mode = "restart"
        destination = "local/install_and_run_elasticsearch.sh"
        data = <<EOF
cd /usr/share/elasticsearch
bin/elasticsearch-plugin install -b repository-s3
exec /bin/tini -- /usr/local/bin/docker-entrypoint.sh eswrapper
EOF
      }

      config {
        image = "${image}:${tag}"
        ports = ["es", "ed"]
        volumes = [
          "name=${nomad_namespace}-elasticsearch-with-plugin,io_priority=high,size=20,repl=2:/usr/share/elasticsearch/data"
        ]
        volume_driver = "pxd"

        entrypoint = [
          "/bin/bash",
          "/local/install_and_run_elasticsearch.sh"
        ]
      }

      resources {
        cpu = 1000
        memory = 2048
      }

      env = {
        "discovery.type" = "single-node"
      }

      service {
        name = "$\u007BNOMAD_NAMESPACE\u007D-elasticsearch"
        tags = ["global","elasticsearch"]
        port = "es"
        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
  }
}
