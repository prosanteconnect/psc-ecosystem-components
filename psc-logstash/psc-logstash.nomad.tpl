job "logstash" {

  type = "service"

  datacenters = ["${datacenter}"]

  update {
    stagger = "30s"
    max_parallel = 1
  }

  group "logstash" {
    count = 1

    network {
      port "logstash" { to = 5044 }
    }

    task "logstash" {
      driver = "docker"

      config {
        image = "${image}:${tag}"
        volumes = ["local:/usr/share/logstash/pipeline"]
        ports = ["logstash"]
      }
      template {
               data =  <<EOH
HTTP_HOST="0.0.0.0"
{{range service "elasticsearch" }}XPACK_MONITORING_ELASTICSEARCH_HOSTS=[ "http://{{.Address}}:{{.Port}}" ]{{end}}
EOH
                destination = "secrets/file.env"
                env = true
                }
        template {
          data = <<EOH
input {
  beats {
    port => 5044
  }
}

filter {
  grok {
    match     => { "message" => "\u0025\u0025{DATE_EU:date}\u0025\u0025{SPACE}\u0025\u0025{TIME:time}\u0025\u0025{SPACE}\u0025\u0025{LOGLEVEL:level}\u0025\u0025{SPACE}\u0025\u0025{WORD:hostname}\u0025\u0025{SPACE}\[\u0025\u0025{DATA:connector}\]\u0025\u0025{SPACE}(?<class>(?:\.?[a-zA-Z$_][a-zA-Z$_0-9]*\.)*[a-zA-Z$_][a-zA-Z$_0-9]*)\u0025\u0025{SPACE}:\u0025\u0025{SPACE}\u0025\u0025{GREEDYDATA:message}" }
    overwrite => [ "message" ]
  }
  date {
    match => ["timestamp", "yyyy-MM-dd HH:mm:ss:SSS"]
  }
}

output {
  if "_grokparsefailure" not in [tags] {
    elasticsearch {
      {{range service "elasticsearch" }}hosts => [ "http://{{.Address}}:{{.Port}}" ]{{end}}
      index => "\u0025\u0025{[@metadata][beat]}-\u0025\u0025{[@metadata][version]}-\u0025\u0025{+YYYY.MM.dd}"
      manage_template => false
    }
  }
#  stdout {
#    codec => rubydebug
#  }
}

EOH
            destination = "local/logstash.conf"
         }

      resources {
        cpu = 200
        memory = 1024
      }

      service {
        name = "logstash"
        port = "logstash"
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
