#!/bin/bash

# Define the state files
export SOURCE_STATE="kc-glb.tfstate"
export TARGET_STATE="kc-cloudrun.tfstate"

# 1. Safety checks
if [ ! -f "$SOURCE_STATE" ]; then
  echo "Error: Source state file '$SOURCE_STATE' not found!"
  exit 1
fi

if [ ! -f "$TARGET_STATE" ]; then
  echo "Error: Target state file '$TARGET_STATE' not found!"
  exit 1
fi

# IMPORTANT: When using a remote backend (GCS, S3, etc.), the -state flag is ignored.
# We need to work in a temporary directory without backend configuration.
echo "Creating temporary workspace for state manipulation..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "TMP DIR: " $TEMP_DIR

# Copy state files to temp directory
cp "$SOURCE_STATE" "$TEMP_DIR/"
cp "$TARGET_STATE" "$TEMP_DIR/"

# Create minimal terraform config without backend
cat > "$TEMP_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.42.0"
    }
  }
  # No backend configuration - using local state
}
EOF

# Initialize terraform in temp directory
cd "$TEMP_DIR" || exit 1
terraform init -backend=false

# 2. Get the list of resources from the source state
# Using grep -v '^data\.' to exclude data sources
RESOURCES=$(terraform state list -state="$SOURCE_STATE" | grep -v '^data\.')

if [ -z "$RESOURCES" ]; then
  echo "No resources found to move in $SOURCE_STATE (or only data sources remain)."
  exit 0
fi


echo "Starting migration from $SOURCE_STATE to $TARGET_STATE..."
echo "--------------------------------------------------------"

# 3. Loop through each resource and move it
for RESOURCE in $RESOURCES; do
  echo "Moving: $RESOURCE"
  terraform state mv -state="$SOURCE_STATE" -state-out="$TARGET_STATE" "$RESOURCE" "$RESOURCE"
  
  # Check if the move command was successful
  if [ $? -ne 0 ]; then
    echo "--------------------------------------------------------"
    echo "ERROR: Failed to move $RESOURCE."
    echo "Stopping the script to prevent state corruption."
    exit 1
  fi
done

echo "--------------------------------------------------------"
echo "Migration complete! All resources moved to $TARGET_STATE."

# Copy merged state back to original location
cd - > /dev/null || exit 1
cp "$TEMP_DIR/$TARGET_STATE" "./$TARGET_STATE"
echo "Merged state file saved to ./$TARGET_STATE"
echo "Original states remain in backup/ directory if you created backups."
