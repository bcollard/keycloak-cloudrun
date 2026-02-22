#!/bin/bash

# Quick test to list resources from a local state file
# when you have a remote backend configured

STATE_FILE="${1:-kc-glb.tfstate}"

if [ ! -f "$STATE_FILE" ]; then
  echo "Error: State file '$STATE_FILE' not found!"
  exit 1
fi

echo "Listing resources from $STATE_FILE..."
echo "=========================================="

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cp "$STATE_FILE" "$TEMP_DIR/"

cat > "$TEMP_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.42.0"
    }
  }
}
EOF

cd "$TEMP_DIR" || exit 1
terraform init -backend=false > /dev/null 2>&1

echo "Resources in $STATE_FILE:"
terraform state list -state="$STATE_FILE"
