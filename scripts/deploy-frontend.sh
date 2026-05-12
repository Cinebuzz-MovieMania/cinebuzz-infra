#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/Frontend/cinebuzz-frontend"
: "${VITE_API_BASE:?Set VITE_API_BASE e.g. http://IP/cinebuzz}"
npm ci
npm run build
echo "Built dist/ — scp to EC2 /tmp then mv to /var/www/cinebuzz-frontend"
