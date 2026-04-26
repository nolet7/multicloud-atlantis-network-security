#!/usr/bin/env bash
set -euo pipefail

echo "Configure a GitHub webhook with these values:"
echo "Payload URL: https://atlantis.olalat.xyz/events"
echo "Content type: application/json"
echo "Events: Pull requests, Issue comments, Push"
echo "Secret: same value as ATLANTIS_GH_WEBHOOK_SECRET in .env"
