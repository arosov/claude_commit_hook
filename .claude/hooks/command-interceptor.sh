#!/bin/bash

# Hook Command Interceptor
# Intercepts specific pseudo-commands and routes them to appropriate handlers
# Usage: This script is called by user-prompt-submit hook with the user's prompt as argument

INPUT="$(cat)"
PROMPT=$(echo "$INPUT" | jq -r '.prompt')
STRIPPED_PROMPT="${PROMPT%\"}"
STRIPPED_PROMPT="${STRIPPED_PROMPT#\"}"
SCRIPT_DIR="$HOME/dev/claude_commit_hook/"

# Check if prompt matches any intercepted commands
case "$STRIPPED_PROMPT" in
    commit)
        # Run handler and capture exit code (stderr goes to hook logs)
        "$SCRIPT_DIR/handle-commit.sh" 2>&1
        EXIT_CODE=$?

        # Block the original prompt and report result
        if [ $EXIT_CODE -eq 0 ]; then
            jq -n '{
                "decision": "block",
                "reason": "Commit created successfully",
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit"
                }
            }'
        else
            jq -n --arg code "$EXIT_CODE" '{
                "decision": "block",
                "reason": ("Commit failed (exit code: " + $code + ")"),
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit"
                }
            }'
        fi
        ;;
    *)
        # For non-intercepted prompts, output nothing to allow normal processing
        ;;
esac
