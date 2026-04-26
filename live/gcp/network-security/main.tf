resource "google_compute_network" "main" {
  name                    = "${var.vpc_name}-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "app" {
  name          = "snet-${var.project_name}-${var.environment}"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "allow_http" {
  name    = "fw-${var.project_name}-${var.environment}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [var.allowed_ingress_cidr]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "fw-${var.project_name}-${var.environment}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ingress_cidr]
  target_tags   = ["admin"]
}
