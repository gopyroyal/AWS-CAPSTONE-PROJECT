#!/usr/bin/env bash
set -euo pipefail
for env in dev staging prod; do
  echo ">>> Deploying $env"
  terraform -chdir=envs/$env init -upgrade
  terraform -chdir=envs/$env apply -auto-approve
done
