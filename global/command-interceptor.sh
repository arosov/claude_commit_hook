#!/bin/bash

# Hook Command Interceptor
# Intercepts specific pseudo-commands and routes them to appropriate handlers
# Usage: This script is called by user-prompt-submit hook with the user's prompt as argument

INPUT="$(cat)"
PROMPT=$(echo "$INPUT" | jq -r '.prompt')
STRIPPED_PROMPT="${PROMPT%\"}"
STRIPPED_PROMPT="${STRIPPED_PROMPT#\"}"
SCRIPT_DIR="$HOME/.local/share/claude-commit-hook/"

# Check if prompt matches any intercepted commands
case "$STRIPPED_PROMPT" in
    commit)
        # Run handler and capture output and exit code
        HANDLER_OUTPUT=$("$SCRIPT_DIR/handle-commit.sh" 2>&1)
        EXIT_CODE=$?

        # Block the original prompt and report result with full commit message
        if [ $EXIT_CODE -eq 0 ]; then
            jq -n --arg output "$HANDLER_OUTPUT" '{
                "decision": "block",
                "reason": ("Commit created successfully:\n\n" + $output),
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit"
                }
            }'
        else
            jq -n --arg code "$EXIT_CODE" --arg output "$HANDLER_OUTPUT" '{
                "decision": "block",
                "reason": ("Commit failed (exit code: " + $code + "):\n\n" + $output),
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
