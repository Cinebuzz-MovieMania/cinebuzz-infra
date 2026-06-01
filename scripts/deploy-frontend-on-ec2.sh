#!/usr/bin/env bash
# Run ON the EC2 instance (Instance Connect). No SSH from Mac required.
# One-time: clone cinebuzz-infra or symlink this script to ~/deploy-frontend.sh
#
# Usage on EC2:
#   bash ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh
#   # or after: ln -sf ~/cinebuzz-infra/scripts/deploy-frontend-on-ec2.sh ~/deploy-frontend
#   ~/deploy-frontend

set -euo pipefail

VITE_API_BASE="${VITE_API_BASE:-http://54.173.215.201/cinebuzz}"
FRONTEND_DIR="${FRONTEND_DIR:-$HOME/cinebuzz-frontend}"
WEB_ROOT="/var/www/cinebuzz-frontend"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-main}"

echo "==> Frontend deploy on EC2"
echo "    VITE_API_BASE=$VITE_API_BASE"
echo "    FRONTEND_DIR=$FRONTEND_DIR"

if [[ ! -d "$FRONTEND_DIR/.git" ]]; then
  echo "Missing $FRONTEND_DIR — clone first:"
  echo "  git clone https://github.com/Cinebuzz-MovieMania/cinebuzz-frontend.git $FRONTEND_DIR"
  exit 1
fi

cd "$FRONTEND_DIR"
echo "==> git pull $GIT_REMOTE $GIT_BRANCH"
git pull "$GIT_REMOTE" "$GIT_BRANCH"

echo "==> npm ci && npm run build"
export VITE_API_BASE
npm ci
npm run build

echo "==> Install to $WEB_ROOT"
sudo rm -rf "${WEB_ROOT:?}"/*
sudo cp -r dist/* "$WEB_ROOT/"
sudo chown -R www-data:www-data "$WEB_ROOT"

if sudo nginx -t 2>/dev/null; then
  sudo systemctl reload nginx
fi

echo "==> Verify"
curl -sI http://127.0.0.1/ | head -1
ls "$WEB_ROOT/assets/" 2>/dev/null | head -3 || true
echo "==> Done. Hard refresh http://54.173.215.201/ in your browser (Cmd+Shift+R)."
