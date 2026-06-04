#!/bin/bash

# Get the script's directory and the root of the git repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(bash "$SCRIPT_DIR/get-parent-git-dir.sh")"

# Collect environment variables from .env and .env.local, then export them for use in the current shell session.
ENV_FILES=("$ROOT_DIR/.env" "$ROOT_DIR/.env.local")

set -a
for env_file in "${ENV_FILES[@]}"; do
  if [ -f "$env_file" ]; then
    source "$env_file"
  fi
done
set +a
