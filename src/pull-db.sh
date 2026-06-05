#!/bin/bash
set -euo pipefail

# Get the script's directory and the root of the git repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(bash "$SCRIPT_DIR/get-parent-git-dir.sh")"

# Source environment variables from .env and .env.local
source "$SCRIPT_DIR/source-env.sh"

# Generate a timestamp (e.g., 2026-06-04_13-15-56)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOCAL_FILE="gigis_db_$TIMESTAMP.sql"

echo "📦 Exporting database on the remote server..."
# We use -t to allow the sudo password prompt if needed.
# We export to /tmp and change ownership so your user can download it via scp.
ssh -i "$SSH_KEY_PATH" -t "$REMOTE_USER@$REMOTE_IP" "cd /var/www/html && \
    sudo wp db export /tmp/db_export.sql --allow-root && \
    sudo chown $REMOTE_USER:$REMOTE_USER /tmp/db_export.sql"

echo "⬇️ Downloading database to local machine..."
scp -i "$SSH_KEY_PATH" "$REMOTE_USER@$REMOTE_IP:/tmp/db_export.sql" "$ROOT_DIR/.tmp/$LOCAL_FILE"

echo "🧹 Cleaning up temporary files on server..."
ssh -i "$SSH_KEY_PATH" -t "$REMOTE_USER@$REMOTE_IP" "rm /tmp/db_export.sql"

echo "✅ Success! Database saved locally as: $LOCAL_FILE"
