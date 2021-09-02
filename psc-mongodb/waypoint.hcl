project = "prosanteconnect/psc-ecosystem-components/psc-mongodb"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-mongodb"
    ignore_changes_outside_path = true
  }
}

variable "image" {
  type    = string
  default = "mongo"
}

variable "tag" {
  type    = string
  default = "latest"
}

# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-mongodb" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-mongodb.nomad.tpl", {
        image = var.image
        tag = var.tag
      })

    }
  }
}


