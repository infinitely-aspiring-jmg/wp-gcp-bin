#!/bin/bash

# Print the nearest parent directory that contains a real .git directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$SCRIPT_DIR"

while [ "$CURRENT_DIR" != "/" ]; do
  if [ -d "$CURRENT_DIR/.git" ]; then
    echo "$CURRENT_DIR"
    exit 0
  fi

  CURRENT_DIR="$(dirname "$CURRENT_DIR")"
done

echo "Error: No parent directory containing .git was found." >&2
exit 1
