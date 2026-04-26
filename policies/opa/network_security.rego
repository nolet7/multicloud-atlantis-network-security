package terraform.network_security

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group_rule"
  resource.change.after.type == "ingress"
  resource.change.after.from_port <= 22
  resource.change.after.to_port >= 22
  resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
  msg := "AWS security group must not expose SSH port 22 to 0.0.0.0/0"
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_network_security_rule"
  resource.change.after.direction == "Inbound"
  resource.change.after.destination_port_range == "22"
  resource.change.after.source_address_prefix == "*"
  msg := "Azure NSG must not expose SSH port 22 to all sources"
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "google_compute_firewall"
  resource.change.after.source_ranges[_] == "0.0.0.0/0"
  allow := resource.change.after.allow[_]
  allow.ports[_] == "22"
  msg := "GCP firewall must not expose SSH port 22 to 0.0.0.0/0"
}
