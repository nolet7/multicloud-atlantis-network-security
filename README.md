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
