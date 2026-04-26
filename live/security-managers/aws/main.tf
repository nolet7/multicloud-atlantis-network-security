provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "tfstate" {
  description = "KMS key for Terraform state and enterprise secrets"
}
