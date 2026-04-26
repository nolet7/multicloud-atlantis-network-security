resource "google_compute_network" "main" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "https_in" {
  name    = "${var.project_name}-${var.environment}-allow-https"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
  target_tags   = ["web"]
}
