#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-multicloud-atlantis-network-security}"

echo "Creating/updating project in: ${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

mkdir -p .github/workflows \
         atlantis-vm \
         live/aws/network-security \
         live/azure/network-security \
         live/gcp/network-security \
         live/security-managers/aws \
         live/security-managers/azure \
         live/security-managers/gcp \
         policies/opa \
         scripts

cat > .env.example <<'EOF'
# GitHub and Atlantis
ATLANTIS_GH_USER=your-github-username
ATLANTIS_GH_TOKEN=your-github-token
ATLANTIS_GH_WEBHOOK_SECRET=replace-with-strong-secret
ATLANTIS_REPO_ALLOWLIST=github.com/nolet7/multicloud-atlantis-network-security
ATLANTIS_URL=https://atlantis.olalat.xyz

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=replace-me
AWS_SECRET_ACCESS_KEY=replace-me

# Azure
ARM_SUBSCRIPTION_ID=replace-me
ARM_TENANT_ID=replace-me
ARM_CLIENT_ID=replace-me
ARM_CLIENT_SECRET=replace-me

# GCP
GOOGLE_CREDENTIALS={"type":"service_account","project_id":"replace-me"}
GCP_PROJECT_ID=replace-me
GCP_REGION=us-central1
EOF

cat > README.md <<'EOF'
# Multi-Cloud Atlantis Network Security

Enterprise Terraform + Atlantis project for AWS, Azure, and GCP.

## Main URL
- Atlantis UI: https://atlantis.olalat.xyz
- GitHub webhook: https://atlantis.olalat.xyz/events

## Main folders
- `live/aws/network-security`
- `live/azure/network-security`
- `live/gcp/network-security`
- `live/security-managers/*`
- `policies/opa`
- `scripts`

## Bootstrap
1. Copy `.env.example` to `.env`
2. Fill in secrets and cloud IDs
3. Run `bash scripts/validate-local-static.sh`
4. Commit and push
5. Deploy Atlantis VM and point DNS for `atlantis.olalat.xyz`
EOF

cat > atlantis.yaml <<'EOF'
version: 3
parallel_plan: true
parallel_apply: false

projects:
  - name: aws-network-security
    dir: live/aws/network-security
    workspace: default
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
        - "../../../policies/**/*.rego"
    apply_requirements:
      - approved
      - mergeable

  - name: azure-network-security
    dir: live/azure/network-security
    workspace: default
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
        - "../../../policies/**/*.rego"
    apply_requirements:
      - approved
      - mergeable

  - name: gcp-network-security
    dir: live/gcp/network-security
    workspace: default
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
        - "../../../policies/**/*.rego"
    apply_requirements:
      - approved
      - mergeable

  - name: aws-security-manager
    dir: live/security-managers/aws
    workspace: default
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
    apply_requirements:
      - approved
      - mergeable

  - name: azure-security-manager
    dir: live/security-managers/azure
    workspace: default
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
    apply_requirements:
      - approved
      - mergeable

  - name: gcp-security-manager
    dir: live/security-managers/gcp
    workspace: default
    autoplan:
      enabled: true
      when_modified:
        - "*.tf"
        - "*.tfvars"
    apply_requirements:
      - approved
      - mergeable
EOF

cat > repos.yaml <<'EOF'
repos:
  - id: github.com/nolet7/multicloud-atlantis-network-security
    branch: /main/
    apply_requirements: [approved, mergeable, undiverged]
    allowed_overrides: [workflow, apply_requirements, autoplan]
    allow_custom_workflows: false
EOF

cat > docker-compose.atlantis.yml <<'EOF'
version: "3.8"
services:
  atlantis:
    image: ghcr.io/runatlantis/atlantis:latest
    container_name: atlantis
    restart: unless-stopped
    ports:
      - "4141:4141"
    env_file:
      - .env
    environment:
      ATLANTIS_REPO_CONFIG: /atlantis/repos.yaml
      ATLANTIS_ATLANTIS_URL: ${ATLANTIS_URL}
      ATLANTIS_GH_USER: ${ATLANTIS_GH_USER}
      ATLANTIS_GH_TOKEN: ${ATLANTIS_GH_TOKEN}
      ATLANTIS_GH_WEBHOOK_SECRET: ${ATLANTIS_GH_WEBHOOK_SECRET}
      ATLANTIS_REPO_ALLOWLIST: ${ATLANTIS_REPO_ALLOWLIST}
    volumes:
      - ./repos.yaml:/atlantis/repos.yaml:ro
EOF

cat > .github/workflows/terraform-static-checks.yml <<'EOF'
name: terraform-static-checks

on:
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform fmt
        run: terraform fmt -check -recursive

      - name: Verify required files exist
        run: |
          test -f atlantis.yaml
          test -f repos.yaml
          test -f docker-compose.atlantis.yml
EOF

cat > policies/aws-atlantis-network-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetObject", "s3:PutObject"],
      "Resource": [
        "arn:aws:s3:::olalat-terraform-state",
        "arn:aws:s3:::olalat-terraform-state/*"
      ]
    },
    {
      "Sid": "TerraformLockTable",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/olalat-terraform-locks"
    }
  ]
}
EOF

cat > policies/checkov-skip-guidance.md <<'EOF'
# Checkov skip guidance

Use skips only when:
- there is a documented business reason
- the risk is accepted
- the control is compensated elsewhere

Do not add blanket skips without review.
EOF

cat > policies/opa/network_security.rego <<'EOF'
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
EOF

cat > policies/opa/required_metadata.rego <<'EOF'
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
EOF

cat > live/aws/network-security/backend.tf.example <<'EOF'
terraform {
  backend "s3" {
    bucket         = "olalat-terraform-state"
    key            = "aws/network-security/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "olalat-terraform-locks"
    encrypt        = true
  }
}
EOF

cat > live/aws/network-security/providers.tf <<'EOF'
provider "aws" {
  region = var.aws_region
}
EOF

cat > live/aws/network-security/versions.tf <<'EOF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF

cat > live/aws/network-security/variables.tf <<'EOF'
variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "allowed_https_cidrs" { type = list(string) }
EOF

cat > live/aws/network-security/terraform.tfvars.example <<'EOF'
aws_region           = "us-east-1"
project_name         = "olalat"
environment          = "dev"
vpc_cidr             = "10.10.0.0/16"
allowed_https_cidrs  = ["10.0.0.0/8", "192.168.0.0/16"]
EOF

cat > live/aws/network-security/main.tf <<'EOF'
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Environment = var.environment
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow HTTPS from approved ranges"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-sg"
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Environment = var.environment
  }
}
EOF

cat > live/aws/network-security/outputs.tf <<'EOF'
output "vpc_id" {
  value = aws_vpc.main.id
}

output "security_group_id" {
  value = aws_security_group.web.id
}
EOF

cat > live/azure/network-security/backend.tf.example <<'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "olalat-tfstate-rg"
    storage_account_name = "olalattfstate001"
    container_name       = "tfstate"
    key                  = "azure/network-security/terraform.tfstate"
  }
}
EOF

cat > live/azure/network-security/providers.tf <<'EOF'
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
EOF

cat > live/azure/network-security/versions.tf <<'EOF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
EOF

cat > live/azure/network-security/variables.tf <<'EOF'
variable "subscription_id" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "vnet_cidr" { type = string }
EOF

cat > live/azure/network-security/terraform.tfvars.example <<'EOF'
subscription_id = "00000000-0000-0000-0000-000000000000"
project_name    = "olalat"
environment     = "dev"
location        = "East US"
vnet_cidr       = "10.20.0.0/16"
EOF

cat > live/azure/network-security/main.tf <<'EOF'
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]

  tags = {
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Environment = var.environment
  }
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.project_name}-${var.environment}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Owner       = "platform-team"
    CostCenter  = "shared-services"
    Environment = var.environment
  }
}
EOF

cat > live/azure/network-security/outputs.tf <<'EOF'
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "nsg_name" {
  value = azurerm_network_security_group.web.name
}
EOF

cat > live/gcp/network-security/backend.tf.example <<'EOF'
terraform {
  backend "gcs" {
    bucket = "olalat-terraform-state"
    prefix = "gcp/network-security"
  }
}
EOF

cat > live/gcp/network-security/providers.tf <<'EOF'
provider "google" {
  project = var.project_id
  region  = var.region
}
EOF

cat > live/gcp/network-security/versions.tf <<'EOF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
EOF

cat > live/gcp/network-security/variables.tf <<'EOF'
variable "project_id" { type = string }
variable "region" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
EOF

cat > live/gcp/network-security/terraform.tfvars.example <<'EOF'
project_id   = "replace-me"
region       = "us-central1"
project_name = "olalat"
environment  = "dev"
EOF

cat > live/gcp/network-security/main.tf <<'EOF'
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
EOF

cat > live/gcp/network-security/outputs.tf <<'EOF'
output "network_name" {
  value = google_compute_network.main.name
}

output "firewall_name" {
  value = google_compute_firewall.https_in.name
}
EOF

cat > live/security-managers/aws/variables.tf <<'EOF'
variable "aws_region" { type = string }
EOF

cat > live/security-managers/aws/main.tf <<'EOF'
provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "tfstate" {
  description = "KMS key for Terraform state and enterprise secrets"
}
EOF

cat > live/security-managers/azure/variables.tf <<'EOF'
variable "subscription_id" { type = string }
variable "location" { type = string }
EOF

cat > live/security-managers/azure/main.tf <<'EOF'
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "security" {
  name     = "olalat-security-rg"
  location = var.location
}

resource "azurerm_key_vault" "main" {
  name                          = "olalat-security-kv001"
  location                      = azurerm_resource_group.security.location
  resource_group_name           = azurerm_resource_group.security.name
  tenant_id                     = "00000000-0000-0000-0000-000000000000"
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
}
EOF

cat > live/security-managers/gcp/variables.tf <<'EOF'
variable "project_id" { type = string }
EOF

cat > live/security-managers/gcp/main.tf <<'EOF'
provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_secret_manager_secret" "atlantis_webhook" {
  secret_id = "atlantis-webhook-secret"

  replication {
    auto {}
  }
}
EOF

cat > scripts/bootstrap-project.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

git init
git add .
git commit -m "Initial enterprise Atlantis multicloud network security project"
git branch -M main

if ! git remote | grep -q '^origin$'; then
  git remote add origin https://github.com/nolet7/multicloud-atlantis-network-security.git
fi

git push -u origin main
EOF

cat > scripts/configure-github-webhook.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Configure a GitHub webhook with these values:"
echo "Payload URL: https://atlantis.olalat.xyz/events"
echo "Content type: application/json"
echo "Events: Pull requests, Issue comments, Push"
echo "Secret: same value as ATLANTIS_GH_WEBHOOK_SECRET in .env"
EOF

cat > scripts/validate-local-static.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Checking required files..."
test -f atlantis.yaml
test -f repos.yaml
test -f docker-compose.atlantis.yml
test -f .env.example
test -f policies/opa/network_security.rego
test -f policies/opa/required_metadata.rego

echo "Checking Terraform folders..."
for d in \
  live/aws/network-security \
  live/azure/network-security \
  live/gcp/network-security \
  live/security-managers/aws \
  live/security-managers/azure \
  live/security-managers/gcp
do
  test -d "$d"
done

echo "Checking shell script permissions..."
chmod +x scripts/*.sh

echo "Static validation passed."
EOF

chmod +x scripts/*.sh

echo "Project files created and updated successfully."
echo "Next:"
echo "  1. cp .env.example .env"
echo "  2. edit .env"
echo "  3. bash scripts/validate-local-static.sh"
echo "  4. bash scripts/bootstrap-project.sh"
