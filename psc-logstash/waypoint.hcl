project = "prosanteconnect/psc-ecosystem-components/psc-logstash"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true   
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-logstash"
    ignore_changes_outside_path = true
    ref = var.datacenter
  }
  poll {
    enabled = true
    interval = "24h"
  }
}
# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-logstash" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
      disable_entrypoint = true
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-logstash.nomad.tpl", {
        datacenter = var.datacenter
        image = var.image
        tag = var.tag
      })

    }
  }
}

variable "datacenter" {
  type = string
  default = "dc1"
}

variable "image" {
  type = string
  default = "library/logstash"
}

variable "tag" {
  type = string
  default = "7.14.2"
}
