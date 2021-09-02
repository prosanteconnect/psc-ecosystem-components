project = "prosanteconnect/psc-ecosystem-components/psc-mongo-express"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-mongo-express"
    ignore_changes_outside_path = true
  }
}

# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-mongo-express" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-mongo-express.nomad.tpl", {
        public_hostname = var.public_hostname
        image = var.image
        tag = var.tag
      })
    }
  }
}

variable "public_hostname" {
  type    = string
  default = "forge.psc.henix.asipsante.fr"
}

variable "image" {
  type    = string
  default = "mongo-express"
}

variable "tag" {
  type    = string
  default = "latest"
}
