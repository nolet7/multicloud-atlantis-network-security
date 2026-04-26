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
