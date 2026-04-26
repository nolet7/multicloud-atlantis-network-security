#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release google-cloud-cli docker.io
systemctl enable docker
systemctl start docker

PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id)

read_secret() {
  local name="$1"
  gcloud secrets versions access latest --secret="$name" --project="$PROJECT_ID"
}

mkdir -p /opt/atlantis
cd /opt/atlantis

cat > /opt/atlantis/repos.yaml <<'REPOS'
repos:
  - id: /.*/
    branch: /main/
    apply_requirements: [approved, mergeable, undiverged]
    allowed_overrides: [workflow, apply_requirements, autoplan]
    allow_custom_workflows: false
    delete_source_branch_on_merge: true
REPOS

cat > /opt/atlantis/atlantis.env <<ENV
ATLANTIS_GH_USER=$(read_secret atlantis-gh-user)
ATLANTIS_GH_TOKEN=$(read_secret atlantis-gh-token)
ATLANTIS_GH_WEBHOOK_SECRET=$(read_secret atlantis-gh-webhook-secret)
ATLANTIS_REPO_ALLOWLIST=$(read_secret atlantis-repo-allowlist)
ATLANTIS_ATLANTIS_URL=$(read_secret atlantis-url)
AWS_ACCESS_KEY_ID=$(read_secret aws-access-key-id)
AWS_SECRET_ACCESS_KEY=$(read_secret aws-secret-access-key)
AWS_DEFAULT_REGION=$(read_secret aws-default-region)
ARM_CLIENT_ID=$(read_secret arm-client-id)
ARM_CLIENT_SECRET=$(read_secret arm-client-secret)
ARM_SUBSCRIPTION_ID=$(read_secret arm-subscription-id)
ARM_TENANT_ID=$(read_secret arm-tenant-id)
GOOGLE_PROJECT=$(read_secret google-project)
GOOGLE_REGION=$(read_secret google-region)
ENV

chmod 600 /opt/atlantis/atlantis.env

cat > /etc/systemd/system/atlantis.service <<'UNIT'
[Unit]
Description=Atlantis Terraform PR Automation
After=docker.service
Requires=docker.service

[Service]
Restart=always
EnvironmentFile=/opt/atlantis/atlantis.env
ExecStartPre=-/usr/bin/docker rm -f atlantis
ExecStart=/usr/bin/docker run --name atlantis \
  --env-file /opt/atlantis/atlantis.env \
  -v /opt/atlantis/repos.yaml:/etc/atlantis/repos.yaml:ro \
  -v atlantis-data:/home/atlantis \
  -p 4141:4141 \
  ghcr.io/runatlantis/atlantis:latest \
  server \
  --gh-user=$ATLANTIS_GH_USER \
  --gh-token=$ATLANTIS_GH_TOKEN \
  --gh-webhook-secret=$ATLANTIS_GH_WEBHOOK_SECRET \
  --repo-allowlist=$ATLANTIS_REPO_ALLOWLIST \
  --atlantis-url=$ATLANTIS_ATLANTIS_URL \
  --repo-config=/etc/atlantis/repos.yaml \
  --log-level=info
ExecStop=/usr/bin/docker stop atlantis

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable atlantis
systemctl start atlantis
