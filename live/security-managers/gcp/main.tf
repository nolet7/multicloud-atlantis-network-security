terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_secret_manager_secret" "network_automation" {
  secret_id = "multicloud-network-automation"

  replication {
    auto {}
  }

  labels = {
    owner       = "platform-engineering"
    environment = var.environment
    managed_by  = "terraform-atlantis"
  }
}

resource "google_secret_manager_secret_version" "placeholder" {
  secret      = google_secret_manager_secret.network_automation.id
  secret_data = jsonencode({ example = "replace-through-secure-process-not-git" })
}
