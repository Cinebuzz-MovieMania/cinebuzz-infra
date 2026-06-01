#!/usr/bin/env bash
# Push nginx/cinebuzz.conf to EC2 and reload (e.g. after client_max_body_size fix).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_ENV="$INFRA_ROOT/env/deploy.env"

if [[ ! -f "$DEPLOY_ENV" ]]; then
  echo "Missing $DEPLOY_ENV — copy env/deploy.env.example → env/deploy.env"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$DEPLOY_ENV"
set +a

: "${DEPLOY_HOST:?}"
: "${DEPLOY_KEY:?}"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"

if [[ ! -f "$DEPLOY_KEY" ]]; then
  echo "DEPLOY_KEY file not found: $DEPLOY_KEY"
  exit 1
fi

SSH_OPTS=(-i "$DEPLOY_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new)
REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"
CONF="$INFRA_ROOT/nginx/cinebuzz.conf"

echo "==> Uploading nginx config to $REMOTE"
scp "${SSH_OPTS[@]}" "$CONF" "$REMOTE:/tmp/cinebuzz.conf"

echo "==> Installing and reloading nginx"
ssh "${SSH_OPTS[@]}" "$REMOTE" bash -s <<'REMOTE_SCRIPT'
set -euo pipefail
sudo cp /tmp/cinebuzz.conf /etc/nginx/sites-available/cinebuzz
sudo nginx -t
sudo systemctl reload nginx
grep -n client_max_body_size /etc/nginx/sites-available/cinebuzz || true
echo "Nginx sync finished."
REMOTE_SCRIPT

echo "==> Done."
