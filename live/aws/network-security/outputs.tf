output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_security_group_id" {
  value = aws_security_group.web.id
}
