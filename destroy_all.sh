#!/usr/bin/env bash
set -euo pipefail
for env in prod staging dev; do
  echo ">>> Destroying $env"
  terraform -chdir=envs/$env destroy -auto-approve || true
done
