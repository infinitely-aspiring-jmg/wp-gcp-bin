#!/bin/bash

# --- Configuration ---
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <REMOTE_IP> [REMOTE_USER]"
  exit 1
fi

REMOTE_IP="$1"
REMOTE_USER="${2:-john}"                                     # Default to 'john' if not provided
REMOTE_DIR="/var/www/"                                       # Trailing slash ensures we get the contents of /www/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(bash "$SCRIPT_DIR/get-parent-git-dir.sh")"
LOCAL_DIR="$ROOT_DIR/.deployed/"                             # Store pulled files at the repository root

mkdir -p "$LOCAL_DIR"

echo "Starting sync-back from $REMOTE_IP..."

# --- The Rsync Command ---
# -a : Archive mode (preserves permissions, ownership, symlinks, and timestamps)
# -v : Verbose (shows you what is being copied)
# --rsync-path="sudo rsync" : Runs rsync as root on the server to bypass read restrictions
# --delete : (Optional - uncomment the line below if you want to delete local files that were removed on the server)

rsync -av -e ssh \
  --rsync-path="sudo rsync" \
  "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR" \
  "$LOCAL_DIR"

echo "Sync complete! Files are located in $LOCAL_DIR"
