# Multi-Cloud Network and Security Group Automation with Terraform and Atlantis

This repository creates network and security controls across AWS, Azure, and GCP using Terraform.
Terraform execution is controlled by Atlantis through GitHub pull requests.

## Clouds Covered
- AWS: VPC, subnets, route table, internet gateway, security group
- Azure: resource group, virtual network, subnet, network security group
- GCP: custom VPC, subnet, firewall rules

## Workflow
1. Create a feature branch.
2. Change Terraform files.
3. Open a pull request.
4. Atlantis runs plan.
5. Review plan and security checks.
6. Approved engineer comments: atlantis apply -p PROJECT_NAME
7. Atlantis applies centrally.

## Do Not
- Do not run terraform apply from laptops.
- Do not hardcode secrets.
- Do not expose SSH or RDP to 0.0.0.0/0.
