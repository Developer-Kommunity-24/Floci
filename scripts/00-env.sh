#!/usr/bin/env zsh
# scripts/00-env.sh
# Source this before every demo: `source scripts/00-env.sh`

set -euo pipefail

echo "🔧 Configuring environment for Floci..."

export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "✅ AWS_ENDPOINT_URL  = $AWS_ENDPOINT_URL"
echo "✅ AWS_DEFAULT_REGION = $AWS_DEFAULT_REGION"

# Verify Floci is running
if curl -sf "$AWS_ENDPOINT_URL/_floci/health" > /dev/null 2>&1; then
  echo "✅ Floci is running at $AWS_ENDPOINT_URL"
else
  echo "❌ Floci is NOT reachable at $AWS_ENDPOINT_URL"
  echo "   Run: floci start"
  return 1 2>/dev/null || exit 1
fi
