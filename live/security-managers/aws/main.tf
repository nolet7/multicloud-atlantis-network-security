terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "network_automation" {
  name                    = "multicloud/network-automation"
  description             = "Secrets used by Atlantis for AWS network automation"
  recovery_window_in_days = 7

  tags = {
    Owner       = "platform-engineering"
    Environment = var.environment
    ManagedBy   = "terraform-atlantis"
  }
}

resource "aws_secretsmanager_secret_version" "placeholder" {
  secret_id = aws_secretsmanager_secret.network_automation.id
  secret_string = jsonencode({
    example = "replace-through-secure-process-not-git"
  })
}
