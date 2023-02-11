packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
    googlecompute = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/googlecompute"
    }
    git = {
      version = ">= 0.3.2"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}

data "git-commit" "cwd-head" {}
locals {
  truncated_sha = substr(data.git-commit.cwd-head.hash, 0, 8)
}

variable "gcp_project_id" {}
variable "gcp_ssh_username" {}
variable "gcp_zone" {
  type    = string
  default = "europe-west4-a"
}
variable "gcp_machine_type" {
  type    = string
  default = "e2-standard-4"
}
variable "gcp_build_image" {
  type    = string
  default = "rocky-linux-8"
}

source "googlecompute" "rockylinux8" {
  project_id          = var.gcp_project_id
  source_image_family = var.gcp_build_image
  image_name          = "vscode-gpus-${local.truncated_sha}-{{timestamp}}"
  ssh_username        = var.gcp_ssh_username
  zone                = var.gcp_zone
  machine_type        = var.gcp_machine_type
  disk_size           = 44
}

build {
  name = "sd"

  sources = [
    "source.googlecompute.rockylinux8",
  ]

  provisioner "ansible" {
    host_alias    = source.name
    command       = "${path.cwd}/venv/bin/ansible-playbook"
    playbook_file = "./ansible/ansible-playbook.yml"
    use_proxy     = false
    only          = ["googlecompute.rockylinux8"]
  }
}
