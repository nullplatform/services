#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_PATH="$(dirname "$SCRIPT_DIR")"

# Load test context
CONTEXT_FILE="${1:-$SCRIPT_DIR/test-context.json}"

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "Error: Context file not found: $CONTEXT_FILE"
  exit 1
fi

echo "=== FULL TEST ==="
echo "Context file: $CONTEXT_FILE"
echo ""

# Set up environment like entrypoint does
export CONTEXT=$(cat "$CONTEXT_FILE" | jq '.notification')
export SERVICE_PATH

echo "=== 1. Running build_context ==="
source "$SERVICE_PATH/scripts/azure/build_context"

echo "Database:     $DATABASE_NAME"
echo "Account:      $ACCOUNT_NAME"
echo "RG:           $RESOURCE_GROUP"
echo "Containers:   $(echo "$CONTAINERS_JSON" | jq -r '[.[].container_name] | join(", ")')"
echo ""

echo "=== 2. Running tofu apply ==="
export TOFU_ACTION="apply"
source "$SERVICE_PATH/scripts/azure/do_tofu"

echo ""
echo "=== FULL TEST COMPLETE ==="
