job "kibana" {
  namespace = "${nomad_namespace}"
  datacenters = ["${datacenter}"]
  type = "service"
  
  vault {
    policies = ["psc-ecosystem"]
    change_mode = "restart"
  }
  affinity {
    attribute = "$\u007Bnode.class\u007D"
    value = "standard"
  }
  group "kibana" {
    update {
      stagger = "10s"
      max_parallel = 1
    }
    count = 1
    restart {
      attempts = 5
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    network {
      port "healthcheck" { to = 5601}
    } #network
    task "kibana" {
      kill_timeout = "180s"
      template {
               data = <<EOH
server.name: kibana
server.basePath: "/kibana"
server.publicBaseUrl: "https://{{ with secret "psc-ecosystem/${nomad_namespace}/admin" }}{{ .Data.data.admin_public_hostname }}{{ end }}/kibana"
server.rewriteBasePath: true
{{range service "${nomad_namespace}-elasticsearch" }}elasticsearch.hosts: [ "http://{{.Address}}:{{.Port}}" ]{{end}}
server.host: "0.0.0.0"
xpack.monitoring.ui.container.elasticsearch.enabled: false

EOH
              destination = "local/kibana.yml"
              change_mode = "restart"
              env         = false
              }
      logs {
        max_files     = 5
        max_file_size = 10
      }
      driver = "docker"
      config {
        image = "${image}:${tag}"
        command = "kibana"
        args = [
               "--config=/local/kibana.yml"
               ]
        ports = [ "healthcheck" ]
      }
      resources {
        memory  = 1024
      } #resources
      service {
        name = "$\u007BNOMAD_NAMESPACE\u007D-kibana"
        tags = [ "urlprefix-$\u007BPUBLIC_HOSTNAME\u007D/kibana/" ]
        port = "healthcheck"
        check {
          name     = "kibana-internal-port-check"
          port     = "healthcheck"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        } #check
      } #service
    } #task
  } #group
} #job
