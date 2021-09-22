project = "prosanteconnect/psc-ecosystem-components/psc-prometheus"

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

variable "public_hostname" {
  type    = string
//  default is preprod
//  default = "forge.test.psc.henix.asipsante.fr"
}

variable "image" {
  type    = string
  default = "prom/prometheus"
}

variable "tag" {
  type    = string
  default = "latest"
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
        public_hostname = var.public_hostname
        image = var.image
        tag   = var.tag
      })
    }
  }
}

