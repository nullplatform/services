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

echo "=== DRY RUN TEST ==="
echo "Context file: $CONTEXT_FILE"
echo ""

# Set up environment like entrypoint does
export CONTEXT=$(cat "$CONTEXT_FILE" | jq '.notification')
export SERVICE_PATH

echo "=== 1. CONTEXT (notification) ==="
echo "$CONTEXT" | jq '{
  action_id: .id,
  action_type: .type,
  service_id: .service.id,
  service_slug: .service.slug
}'
echo ""

echo "=== 2. Running build_context ==="
source "$SERVICE_PATH/scripts/azure/build_context"
echo ""

echo "=== 3. Variables extracted ==="
echo "SERVICE_ID:        $SERVICE_ID"
echo "SERVICE_SLUG:      $SERVICE_SLUG"
echo "ACTION_ID:         $ACTION_ID"
echo "RESOURCE_GROUP:    $RESOURCE_GROUP"
echo "ACCOUNT_NAME:      $ACCOUNT_NAME"
echo "DATABASE_NAME:     $DATABASE_NAME"
echo "ENDPOINT:          $ENDPOINT"
echo "SUBSCRIPTION_ID:   $SUBSCRIPTION_ID"
echo ""

echo "=== 4. CONTAINERS_JSON ==="
echo "$CONTAINERS_JSON" | jq .
echo ""

echo "=== 5. TOFU_VARIABLES (terraform.tfvars.json) ==="
echo "$TOFU_VARIABLES" | jq .
echo ""

echo "=== 6. TOFU_MODULE_DIR ==="
echo "$TOFU_MODULE_DIR"
echo ""

echo "=== 7. Validating Terraform ==="
if command -v tofu &> /dev/null; then
  # Write tfvars to temp file
  TEMP_TFVARS=$(mktemp)
  echo "$TOFU_VARIABLES" > "$TEMP_TFVARS"

  cd "$TOFU_MODULE_DIR"
  tofu init -backend=false > /dev/null 2>&1 || true

  if tofu validate; then
    echo "Terraform validation: OK"
  else
    echo "Terraform validation: FAILED"
  fi

  rm -f "$TEMP_TFVARS"
else
  echo "tofu not found, skipping validation"
fi

echo ""
echo "=== DRY RUN COMPLETE ==="
