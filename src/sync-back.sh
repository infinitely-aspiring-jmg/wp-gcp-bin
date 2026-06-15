#!/bin/bash
set -euo pipefail

# Get the script's directory and the root of the git repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(bash "$SCRIPT_DIR/get-parent-git-dir.sh")"

# Source environment variables from .env and .env.local
source "$SCRIPT_DIR/source-env.sh"

# If REMOTE_IP is not set in the environment, try to get it from the first command-line argument.
# Fall back to the GCP deployment host so the script matches the deployment workflow env.
if [ -z "${REMOTE_IP:-}" ]; then
  REMOTE_IP="${GCP_SSH_HOST:-}"
fi

if [ -z "${REMOTE_IP:-}" ]; then
  if [ -z "$1" ]; then
    echo "Error: REMOTE_IP is not set in the environment and no IP address was provided as an argument." >&2
    echo "Usage: $0 <REMOTE_IP> [REMOTE_USER]" >&2
    exit 1
  else
    REMOTE_IP="$1"
  fi
fi

# If REMOTE_USER is not set in the environment, try to get it from the deployment env or the second CLI argument.
if [ -z "${REMOTE_USER:-}" ]; then
  REMOTE_USER="${GCP_SSH_USER:-${2:-john}}"
fi

REMOTE_DIR="/var/www/"

REMOTE_PORT="${REMOTE_PORT:-${GCP_SSH_PORT:-22}}"

REMOTE_KEY_PATH="${REMOTE_KEY_PATH:-${GCP_SSH_PRIVATE_KEY_PATH:-~/.ssh/gcp_ggss_id_ed25519}}"
case "$REMOTE_KEY_PATH" in
  "~/"*) REMOTE_KEY_PATH="$HOME/${REMOTE_KEY_PATH#~/}" ;;
  "~") REMOTE_KEY_PATH="$HOME" ;;
esac

if [ ! -f "$REMOTE_KEY_PATH" ]; then
  echo "Error: SSH private key not found at $REMOTE_KEY_PATH" >&2
  exit 1
fi

# Generate a timestamp (e.g., 2026-06-04_13-15-56)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

LOCAL_DIR="$ROOT_DIR/.deployed/" # Store pulled files at the repository root

mkdir -p "$LOCAL_DIR"

echo "Starting sync-back from $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR..."

# --- The Rsync Command ---
# -a : Archive mode (preserves permissions, ownership, symlinks, and timestamps)
# -v : Verbose (shows you what is being copied)
# --rsync-path="sudo rsync" : Runs rsync as root on the server to bypass read restrictions
# --delete : (Optional - uncomment the line below if you want to delete local files that were removed on the server)
#
# Example:
# - rsync -av -e "ssh -i ~/.ssh/gcp_ggss_id_ed25519 -p 22 -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes" --rsync-path="sudo rsync" john@34.172.75.225:/var/www/ ./.deployed/ 2>&1 | tee ""./.tmp/sync-back-$(date +"%Y-%m-%d_%H-%M-%S").log"
#
rsync -av -e "ssh -i $REMOTE_KEY_PATH -p $REMOTE_PORT -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes" \
  --rsync-path="sudo rsync" \
  "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR" \
  "$LOCAL_DIR" \
  2>&1 | tee "$ROOT_DIR/.tmp/sync-back-$TIMESTAMP.log"

echo "Sync complete! Files are located in $LOCAL_DIR"
