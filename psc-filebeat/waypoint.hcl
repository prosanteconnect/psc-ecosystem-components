project = "${workspace.name}/psc-filebeat"

# Labels can be specified for organizational purposes.
labels = {
  "domaine" = "psc"
}

runner {
  enabled = true
  profile = "secpsc-${workspace.name}"
  data_source "git" {
    url = "https://github.com/prosanteconnect/psc-ecosystem-components.git"
    path = "psc-filebeat"
    ignore_changes_outside_path = true
    ref = "${workspace.name}"
  }
  poll {
    enabled = false
  }
}

# An application to deploy.
app "prosanteconnect/psc-filebeat" {
  # Build specifies how an application should be deployed. In this case,
  # we'll build using a Dockerfile and keeping it in a local registry.
  build {
    use "docker" {
      dockerfile = "${path.app}/${var.dockerfile_path}"
    }
    # Uncomment below to use a remote docker registry to push your built images.
    registry {
      use "docker" {
        image = "${var.registry_username}/filebeat"
        tag = "7.17.0"
        username = var.registry_username
        password = var.registry_password
        local = true
      }
    }
  }

  deploy {
    use "exec" {
      command = ["echo", "Noop"]
    }
  }
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

variable "dockerfile_path" {
  type = string
  default = "Dockerfile"
}
