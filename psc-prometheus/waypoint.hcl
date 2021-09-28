project = "psc-prometheus"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-prometheus"
    ignore_changes_outside_path = true
    ref = var.datacenter
    poll {
      enabled = true
    }
  }
}

# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-prometheus" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-prometheus.nomad.tpl", {
        datacenter = var.datacenter
        image = var.image
        tag   = var.tag
      })
    }
  }
}

variable "datacenter" {
  type    = string
  default = "dc1"
}

variable "image" {
  type = string
  default = "prom/prometheus"
}

variable "tag" {
  type = string
  default = "latest"
}

