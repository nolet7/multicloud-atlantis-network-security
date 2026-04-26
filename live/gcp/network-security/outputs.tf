output "gcp_vpc_name" {
  value = google_compute_network.main.name
}

output "gcp_subnet_name" {
  value = google_compute_subnetwork.app.name
}
