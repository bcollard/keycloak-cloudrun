#!/usr/bin/env bash
set -euo pipefail

if ! command -v gum >/dev/null 2>&1; then
  echo "gum is required. Install with: brew install gum" >&2
  exit 1
fi

current_version=""
if [[ -f KEYCLOAK_VERSION ]]; then
  current_version=$(tr -d ' \t\r\n' < KEYCLOAK_VERSION)
fi

prompt_label="Keycloak version"
if [[ -n "$current_version" ]]; then
  prompt_label="Keycloak version (current: $current_version)"
fi

version=$(gum input --prompt "$prompt_label: " --placeholder "26.5.4")
if [[ -z "$version" ]]; then
  echo "Version is required." >&2
  exit 1
fi

if ! gum confirm "Use Keycloak version $version?"; then
  echo "Canceled." >&2
  exit 1
fi

echo "$version" > KEYCLOAK_VERSION

gum style --border rounded --padding "1 2" "Updated KEYCLOAK_VERSION to $version"