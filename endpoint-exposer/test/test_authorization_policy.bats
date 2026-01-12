#!/usr/bin/env bats

load helpers

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export OUTPUT_DIR="$TEST_TEMP_DIR/output"
  mkdir -p "$OUTPUT_DIR"
  export SERVICE_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  # Load assert functions
  load_bats_support_libraries

  export K8S_NAMESPACE="test-namespace"

  # Mock gomplate
  cat > "$TEST_TEMP_DIR/gomplate" << 'EOF'
#!/bin/bash
TEMPLATE_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -f) TEMPLATE_FILE="$2"; shift 2 ;;
    -o) OUTPUT_FILE="$2"; shift 2 ;;
    -c) shift 2 ;;
    *) shift ;;
  esac
done

if [[ -n "$TEMPLATE_FILE" ]] && [[ -n "$OUTPUT_FILE" ]]; then
  cat > "$OUTPUT_FILE" << YAML
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ${SERVICE_SLUG}-${SERVICE_ID}-authz-test
  namespace: gateways
spec:
  action: CUSTOM
YAML
fi
EOF
  chmod +x "$TEST_TEMP_DIR/gomplate"
  export PATH="$TEST_TEMP_DIR:$PATH"
}

@test "authorization_policy: generates policies when enabled" {
  export CONTEXT=$(load_fixture "public-and-private-routes")
  source "$SERVICE_PATH/scripts/istio/build_context"

  run bash "$SERVICE_PATH/plugins/authorization-policy/generate"

  assert_success
  assert_file_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-public.yaml"
  assert_file_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-private.yaml"
}

@test "authorization_policy: creates marker files when disabled" {
  export CONTEXT=$(load_fixture "authorization-disabled")
  source "$SERVICE_PATH/scripts/istio/build_context"

  run bash "$SERVICE_PATH/plugins/authorization-policy/generate"

  assert_success
  assert_file_not_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-public.yaml"
  assert_file_not_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-private.yaml"
  assert_file_exists "$OUTPUT_DIR/.authz-public-deleted"
  assert_file_exists "$OUTPUT_DIR/.authz-private-deleted"
}

@test "authorization_policy: creates marker for public when no public routes" {
  export CONTEXT=$(load_fixture "no-public-routes")
  # Enable authorization
  export CONTEXT=$(echo "$CONTEXT" | jq '.parameters.authorization.enabled = true')
  source "$SERVICE_PATH/scripts/istio/build_context"

  run bash "$SERVICE_PATH/plugins/authorization-policy/generate"

  assert_success
  assert_file_exists "$OUTPUT_DIR/.authz-public-deleted"
  assert_file_not_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-public.yaml"
}

@test "authorization_policy: creates marker for private when no private routes" {
  export CONTEXT=$(load_fixture "simple-public-routes")
  # Enable authorization
  export CONTEXT=$(echo "$CONTEXT" | jq '.parameters.authorization.enabled = true')
  source "$SERVICE_PATH/scripts/istio/build_context"

  run bash "$SERVICE_PATH/plugins/authorization-policy/generate"

  assert_success
  assert_file_exists "$OUTPUT_DIR/.authz-private-deleted"
  assert_file_not_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-private.yaml"
}

@test "authorization_policy: creates marker when no domain" {
  export CONTEXT='{
    "service": {"id": "test-id", "slug": "test"},
    "parameters": {
      "publicDomain": "",
      "privateDomain": "",
      "authorization": {"enabled": true}
    },
    "routes": [{"path": "/test", "method": "GET", "scope": "test", "visibility": "public"}]
  }'
  source "$SERVICE_PATH/scripts/istio/build_context"

  run bash "$SERVICE_PATH/plugins/authorization-policy/generate"

  assert_success
  assert_file_exists "$OUTPUT_DIR/.authz-public-deleted"
  assert_file_exists "$OUTPUT_DIR/.authz-private-deleted"
}

@test "authorization_policy: builds rules correctly" {
  export CONTEXT=$(load_fixture "public-and-private-routes")
  source "$SERVICE_PATH/scripts/istio/build_context"

  run bash "$SERVICE_PATH/plugins/authorization-policy/generate"

  assert_success

  # Both files should be created
  assert_file_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-public.yaml"
  assert_file_exists "$OUTPUT_DIR/authorization-policy-fbcf7a60-8ca8-4bf2-b1b5-5c59bb5bc4fd-private.yaml"
}
