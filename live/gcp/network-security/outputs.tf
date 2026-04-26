output "network_name" {
  value = google_compute_network.main.name
}

output "firewall_name" {
  value = google_compute_firewall.https_in.name
}
