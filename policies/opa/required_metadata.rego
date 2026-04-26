package terraform.required_metadata

required_tags := {"Owner", "Environment", "ManagedBy"}

deny[msg] {
  resource := input.resource_changes[_]
  startswith(resource.type, "aws_")
  missing := required_tags - {tag | resource.change.after.tags[tag]}
  count(missing) > 0
  msg := sprintf("AWS resource %s is missing required tags: %v", [resource.address, missing])
}

deny[msg] {
  resource := input.resource_changes[_]
  startswith(resource.type, "azurerm_")
  missing := required_tags - {tag | resource.change.after.tags[tag]}
  count(missing) > 0
  msg := sprintf("Azure resource %s is missing required tags: %v", [resource.address, missing])
}

required_labels := {"owner", "environment", "managed_by"}

deny[msg] {
  resource := input.resource_changes[_]
  startswith(resource.type, "google_")
  missing := required_labels - {label | resource.change.after.labels[label]}
  count(missing) > 0
  msg := sprintf("GCP resource %s is missing required labels: %v", [resource.address, missing])
}
