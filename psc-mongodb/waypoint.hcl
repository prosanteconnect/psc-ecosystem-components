project = "prosanteconnect/psc-ecosystem-components/psc-mongodb"

# Labels can be specified for organizational purposes.
labels = { "domaine" = "psc" }

runner {
  enabled = true
  profile = "secpsc-${workspace.name}"
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-mongodb"
    ignore_changes_outside_path = true
    ref = "${workspace.name}"
  }
  poll {
    enabled = false
  }
}
# An application to deploy.
app "prosanteconnect/psc-ecosystem-components/psc-mongodb" {

  build {
    use "docker-pull" {
      image = var.image
      tag   = var.tag
      disable_entrypoint = true
    }
    registry {
      use "docker" {
        image = "prosanteconnect/mongodb"
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
      jobspec = templatefile("${path.app}/psc-mongodb.nomad.tpl", {
        image = var.image
        tag = var.tag
        nomad_namespace = var.nomad_namespace
        datacenter = var.datacenter
        registry_path = var.registry_username
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
  default = "mongo"
}

variable "tag" {
  type    = string
  default = "latest"
}
