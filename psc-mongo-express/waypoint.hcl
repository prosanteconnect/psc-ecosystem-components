project = "prosanteconnect/${workspace.name}/psc-ecosystem-components/psc-mongo-express"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  profile = "secpsc-${workspace.name}"
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-mongo-express"
    ignore_changes_outside_path = true
    ref = "${workspace.name}"
  }
  poll {
    enabled = false
  }
}

# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-mongo-express" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
      disable_entrypoint = true
    }
    registry {
      use "docker" {
        image = "prosanteconnect/psc-mongo-express"
        tag = var.tag
        username = var.registry_username
        password = var.registry_password
	local = true
        }
    }
  }

  # Deploy to Nomad
  deploy {
    use "nomad-jobspec" {
      jobspec = templatefile("${path.app}/psc-mongo-express.nomad.tpl", {
        datacenter = var.datacenter
        image = var.image
        tag = var.tag
        nomad_namespace = var.nomad_namespace
      })
    }
  }
}

variable "datacenter" {
  type = string
  default = ""
  env = ["NOMAD_DATACENTER"]
}

variable "nomad_namespace" {
  type = string
  default = ""
  env = ["NOMAD_NAMESPACE"]
}

variable "registry_username" {
  type    = string
  default = ""
  env     = ["REGISTRY_USERNAME"]
  sensitive = true
}

variable "registry_password" {
  type    = string
  default = ""
  env     = ["REGISTRY_PASSWORD"]
  sensitive = true
}

variable "image" {
  type    = string
  default = "mongo-express"
}

variable "tag" {
  type    = string
  default = "latest"
}
