#!/usr/bin/env bash
# One-command frontend deploy: build → upload → install on EC2.
# Requires env/deploy.env (see env/deploy.env.example). Run from anywhere.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$INFRA_ROOT/.." && pwd)"
DEPLOY_ENV="$INFRA_ROOT/env/deploy.env"

if [[ ! -f "$DEPLOY_ENV" ]]; then
  echo "Missing $DEPLOY_ENV"
  echo "Copy env/deploy.env.example → env/deploy.env and fill DEPLOY_HOST, DEPLOY_KEY, VITE_API_BASE."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$DEPLOY_ENV"
set +a

: "${DEPLOY_HOST:?Set DEPLOY_HOST in env/deploy.env}"
: "${DEPLOY_KEY:?Set DEPLOY_KEY in env/deploy.env}"
: "${VITE_API_BASE:?Set VITE_API_BASE in env/deploy.env}"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"

if [[ ! -f "$DEPLOY_KEY" ]]; then
  echo "DEPLOY_KEY file not found: $DEPLOY_KEY"
  exit 1
fi

FE="$REPO_ROOT/Frontend/cinebuzz-frontend"
if [[ ! -d "$FE" ]]; then
  echo "Frontend folder not found: $FE (run from monorepo with cinebuzz-infra at repo/cinebuzz-infra)"
  exit 1
fi

SSH_OPTS=(-i "$DEPLOY_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new)
REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"
ARCHIVE="/tmp/cinebuzz-frontend-dist-$$.tar.gz"

echo "==> Building frontend (VITE_API_BASE=$VITE_API_BASE)"
cd "$FE"
export VITE_API_BASE
npm ci
npm run build
tar -czf "$ARCHIVE" -C dist .

echo "==> Uploading to $REMOTE"
scp "${SSH_OPTS[@]}" "$ARCHIVE" "$REMOTE:/tmp/cinebuzz-frontend-dist.tar.gz"
rm -f "$ARCHIVE"

echo "==> Installing on server"
ssh "${SSH_OPTS[@]}" "$REMOTE" bash -s <<'REMOTE_SCRIPT'
set -euo pipefail
sudo rm -rf /var/www/cinebuzz-frontend
sudo mkdir -p /var/www/cinebuzz-frontend
sudo tar -xzf /tmp/cinebuzz-frontend-dist.tar.gz -C /var/www/cinebuzz-frontend
sudo chown -R www-data:www-data /var/www/cinebuzz-frontend
sudo nginx -t && sudo systemctl reload nginx
echo "Frontend deploy finished."
REMOTE_SCRIPT

echo "==> Done. Open http://$DEPLOY_HOST/ (hard refresh: Cmd+Shift+R)"
