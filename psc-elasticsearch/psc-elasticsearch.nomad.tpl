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

      config {
        image = "${image}:${tag}"
        ports = ["es", "ed"]
        volumes = [
          "name=${nomad_namespace}-elasticsearch,io_priority=high,size=20,repl=2:/usr/share/elasticsearch/data"
        ]
        volume_driver = "pxd"
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
