project = "prosanteconnect/psc-ecosystem-components/psc-rabbitmq"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-rabbitmq"
    ignore_changes_outside_path = true
  }
}

variable "public_hostname" {
  type    = string
  default = "forge.psc.henix.asipsante.fr"
}

variable "image" {
  type    = string
  default = "rabbitmq"
}

variable "tag" {
  type    = string
  default = "3.8.6-management-alpine"
}

# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-rabbitmq" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-rabbitmq.nomad.tpl", {
        public_hostname = var.public_hostname
        image = var.image
        tag = var.tag
      })
    }
  }
}
