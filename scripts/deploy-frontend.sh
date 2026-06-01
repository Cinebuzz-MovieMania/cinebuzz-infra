#!/usr/bin/env bash
# Smart frontend deploy from Mac: tries SSH script; if SSH fails, tells you the one EC2 command.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$INFRA_ROOT/.." && pwd)"

EC2_CMD='bash ~/deploy-frontend.sh'
# If helper not installed yet:
EC2_SETUP="git clone https://github.com/Cinebuzz-MovieMania/cinebuzz-infra.git ~/cinebuzz-infra 2>/dev/null || true; chmod +x ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh; ln -sf ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh ~/deploy-frontend.sh"

echo "==> Trying deploy via SSH (Mac → EC2)..."
set +e
"$SCRIPT_DIR/deploy-frontend-ec2.sh"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "==> Deploy finished. Hard refresh http://54.173.215.201/ (Cmd+Shift+R)."
  exit 0
fi

echo ""
echo "SSH deploy failed (often office network blocks port 22)."
echo ""
echo "ONE-TIME on EC2 (Instance Connect), paste:"
echo "  $EC2_SETUP"
echo ""
echo "EVERY redeploy on EC2, paste only:"
echo "  $EC2_CMD"
echo ""
echo "Or push to GitHub first, then on EC2:"
echo "  bash ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh"
exit 1
