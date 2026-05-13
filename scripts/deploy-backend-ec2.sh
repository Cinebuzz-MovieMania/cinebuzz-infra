#!/usr/bin/env bash
# One-command backend deploy: Maven package → upload → restart on EC2.
# Uses env/deploy.env for DEPLOY_* (VITE_API_BASE not required).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$INFRA_ROOT/.." && pwd)"
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

BE="$REPO_ROOT/Backend/cinebuzz-backend"
if [[ ! -d "$BE" ]]; then
  echo "Backend folder not found: $BE"
  exit 1
fi

SSH_OPTS=(-i "$DEPLOY_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new)
REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"

echo "==> Building JAR"
cd "$BE"
chmod +x mvnw 2>/dev/null || true
./mvnw -DskipTests clean package
cp target/cinebuzz-0.0.1-SNAPSHOT.jar /tmp/cinebuzz-release.jar

echo "==> Uploading to $REMOTE"
scp "${SSH_OPTS[@]}" /tmp/cinebuzz-release.jar "$REMOTE:/tmp/cinebuzz-release.jar"
rm -f /tmp/cinebuzz-release.jar

echo "==> Installing JAR and restarting"
ssh "${SSH_OPTS[@]}" "$REMOTE" bash -s <<'REMOTE_SCRIPT'
set -euo pipefail
sudo mv /tmp/cinebuzz-release.jar /home/ubuntu/app.jar
sudo systemctl restart cinebuzz
sudo systemctl is-active cinebuzz
echo "Backend deploy finished."
REMOTE_SCRIPT

echo "==> Done."
