provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_secret_manager_secret" "atlantis_webhook" {
  secret_id = "atlantis-webhook-secret"

  replication {
    auto {}
  }
}
