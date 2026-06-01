#!/usr/bin/env bash
# Paste this ENTIRE script once in EC2 Instance Connect to install redeploy helpers.
# After this, frontend redeploy = one command:  ~/deploy-frontend.sh

set -euo pipefail

echo "==> Installing Cinebuzz deploy helpers on EC2..."

# Frontend repo (for git pull deploys)
if [[ ! -d "$HOME/cinebuzz-frontend/.git" ]]; then
  git clone https://github.com/Cinebuzz-MovieMania/cinebuzz-frontend.git "$HOME/cinebuzz-frontend"
else
  echo "    cinebuzz-frontend already cloned"
fi

# Infra repo (for deploy-frontend-on-ec2.sh)
if [[ ! -d "$HOME/cinebuzz-infra/.git" ]]; then
  git clone https://github.com/Cinebuzz-MovieMania/cinebuzz-infra.git "$HOME/cinebuzz-infra" || {
    echo "If cinebuzz-infra is private, clone manually with a GitHub token."
    exit 1
  }
else
  echo "    cinebuzz-infra already cloned"
fi

chmod +x "$HOME/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh"
ln -sf "$HOME/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh" "$HOME/deploy-frontend.sh"

echo ""
echo "==> One-time setup done."
echo "    Frontend redeploy from now on:"
echo "      ~/deploy-frontend.sh"
echo ""
echo "    (Push frontend changes to GitHub first, then run that on EC2.)"
