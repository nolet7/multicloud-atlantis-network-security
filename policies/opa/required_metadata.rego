package terraform.governance

required_tags := {"Owner", "CostCenter", "Environment"}

deny[msg] {
  rc := input.resource_changes[_]
  after := rc.change.after
  after.tags
  missing := required_tags - object.keys(after.tags)
  count(missing) > 0
  msg := sprintf("Missing required tags: %v", [missing])
}
