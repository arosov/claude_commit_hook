#!/bin/bash

# Hook Command Interceptor
# Intercepts specific pseudo-commands and routes them to appropriate handlers
# Usage: This script is called by user-prompt-submit hook with the user's prompt as argument

INPUT="cat"
PROMPT=$(echo "$input" | jq -r '.prompt')
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Entered command interceptor with prompt \"$PROMPT\""
# Check if prompt matches any intercepted commands
case "$PROMPT" in
    commit)
        # Execute the commit handler script
        exec "$SCRIPT_DIR/handle-commit.sh"
        ;;
    *)
        # Not an intercepted command, pass through to Claude
        echo "$PROMPT"
        ;;
esac
