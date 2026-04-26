# Run guide

## 1. Save the bootstrap script
Save the attached `project-bootstrap.sh` file anywhere on your system.

## 2. Run it
```bash
bash project-bootstrap.sh
```

To create the repo in a custom path:
```bash
bash project-bootstrap.sh /path/to/multicloud-atlantis-network-security
```

## 3. Fill in environment values
```bash
cd multicloud-atlantis-network-security
cp .env.example .env
```

Edit `.env` and replace placeholder values.

## 4. Validate the created structure
```bash
bash scripts/validate-local-static.sh
```

## 5. Commit and push
```bash
bash scripts/bootstrap-project.sh
```

## 6. Start Atlantis locally for a quick container check
```bash
docker compose -f docker-compose.atlantis.yml --env-file .env up -d
docker ps
```

## 7. Deploy to your GCP Atlantis VM
Copy the repo to the VM, then run:
```bash
docker compose -f docker-compose.atlantis.yml --env-file .env up -d
```

## 8. DNS and webhook
Create:
- `A` record: `atlantis.olalat.xyz` -> your GCP VM public IP

Then configure GitHub webhook:
- URL: `https://atlantis.olalat.xyz/events`
- Secret: same value as `ATLANTIS_GH_WEBHOOK_SECRET`

## 9. First PR workflow
Create a branch, change Terraform, push, then open a PR.
Atlantis should comment on the PR after the webhook is working.
