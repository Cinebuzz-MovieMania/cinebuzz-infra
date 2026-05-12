#!/usr/bin/env bash
set -euo pipefail
# Monorepo root is two levels up from cinebuzz-infra/scripts/
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/Backend/cinebuzz-backend"
chmod +x mvnw 2>/dev/null || true
./mvnw -DskipTests clean package
echo "Built: target/*.jar — upload with scp and restart cinebuzz on EC2"
