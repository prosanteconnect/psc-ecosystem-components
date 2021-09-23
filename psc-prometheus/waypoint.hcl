project = "psc-prometheus"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-prometheus"
    ignore_changes_outside_path = true
  }
}

variable "datacenter" {
  type    = string
  default = "production"
}


# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-prometheus" {

  build {
    use "docker-pull" {
      image = "prom/prometheus"
      tag   = "latest"
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-prometheus.nomad.tpl", {
        datacenter = var.datacenter
        image = "prom/prometheus"
        tag   = "latest"
      })
    }
  }
}

