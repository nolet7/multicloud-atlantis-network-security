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
