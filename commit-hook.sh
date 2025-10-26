#!/bin/bash

# Commit Handler Script
# Generates git diffs, stages untracked files, and uses Claude CLI to create commit messages
# This script is called by the command interceptor when /commit is detected

TEMP_DIR=$(mktemp -d)
DIFF_FILE="$TEMP_DIR/changes.diff"
COMMIT_MSG_FILE="$TEMP_DIR/commit_msg.txt"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Check for any changes (staged, unstaged, or untracked)
if git diff --quiet HEAD && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "No changes to commit" >&2
    exit 1
fi

# Stage all untracked files so they're included in the diff
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)
if [ -n "$UNTRACKED_FILES" ]; then
    echo "$UNTRACKED_FILES" | xargs git add
fi

# Stage all modifications
git add -u

# Generate comprehensive diff of all staged changes
git diff --cached > "$DIFF_FILE"

# Check if diff is too large (Claude has token limits)
DIFF_SIZE=$(wc -c < "$DIFF_FILE")
if [ "$DIFF_SIZE" -gt 100000 ]; then
    echo "Warning: Diff is very large ($DIFF_SIZE bytes). Using summary instead..." >&2
    git diff --cached --stat > "$DIFF_FILE"
fi

# Create prompt for Claude CLI
CLAUDE_PROMPT="Based on the following git diff, generate a commit message following conventional commits format.

The commit message should have:
- First line: concise title summarizing the change (50-72 characters)
- Second line: empty
- Following lines: detailed description explaining WHY the changes were made

Here's the diff:

\`\`\`diff
$(cat "$DIFF_FILE")
\`\`\`

Generate only the commit message, no additional commentary."

# Use Claude CLI in non-interactive mode to generate commit message
echo "Generating commit message with Claude Haiku ..." >&2
echo "$CLAUDE_PROMPT" | claude --model haiku > "$COMMIT_MSG_FILE.raw"

# Strip markdown code fences if present (Claude often wraps responses in ```)
sed -e 's/^```.*$//' -e '/^[[:space:]]*$/d' "$COMMIT_MSG_FILE.raw" | \
    sed '1{/^[[:space:]]*$/d;}' > "$COMMIT_MSG_FILE"

# Re-add proper spacing after first line
awk 'NR==1{print; print ""; next} 1' "$COMMIT_MSG_FILE" > "$COMMIT_MSG_FILE.formatted"
mv "$COMMIT_MSG_FILE.formatted" "$COMMIT_MSG_FILE"

# Commit automatically (non-interactive)
if COMMIT_OUTPUT=$(git commit -F "$COMMIT_MSG_FILE" 2>&1); then
    # Output the full commit message to stdout for the hook to capture
    cat "$COMMIT_MSG_FILE"
    echo "" # Separator
    echo "$COMMIT_OUTPUT" >&2
    exit 0
else
    echo "Error: git commit failed" >&2
    echo "$COMMIT_OUTPUT" >&2
    exit 2
fi
