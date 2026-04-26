package terraform.security

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_security_group"
  ingress := rc.change.after.ingress[_]
  ingress.from_port == 22
  ingress.to_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := "Public SSH is not allowed"
}
