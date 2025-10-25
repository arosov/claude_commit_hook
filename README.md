# Claude Code Commit Automation

Automate git commit messages using Claude AI through Claude Code hooks. Simply type `commit` in Claude Code, and it will automatically stage your changes, generate a conventional commit message, and create the commit.

## Features

- Automatically stages all changes (tracked and untracked files)
- Generates commit messages using Claude AI based on git diffs
- Follows conventional commits format
- Works within Claude Code without interrupting your workflow
- Can be installed locally (per-repository) or globally (all repositories)

## Prerequisites

- [Claude Code](https://docs.claude.com/claude-code) installed and configured
- `claude` CLI available in your PATH
- `git` installed
- `jq` installed (for JSON processing)

## Installation

You can install this system either locally (for a single repository) or globally (for all repositories where you use Claude Code).

### Option 1: Local Installation (Single Repository)

This installs the commit automation in a specific repository only.

1. **Copy the scripts to your repository:**
   ```bash
   # From this repository
   mkdir -p .claude/hooks
   cp handle-commit.sh .claude/hooks/
   cp .claude/hooks/command-interceptor.sh .claude/hooks/
   ```

2. **Update the path in command-interceptor.sh:**

   Edit `.claude/hooks/command-interceptor.sh` and update line 11:
   ```bash
   SCRIPT_DIR="$(dirname "$0")/"  # Or use absolute path to your repo
   ```

3. **Create local settings:**

   Create `.claude/settings.json`:
   ```json
   {
     "description": "Commit with minimal LLM usage",
     "hooks": {
       "UserPromptSubmit": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "./.claude/hooks/command-interceptor.sh"
             }
           ]
         }
       ]
     }
   }
   ```

4. **Make scripts executable:**
   ```bash
   chmod +x .claude/hooks/command-interceptor.sh
   chmod +x handle-commit.sh
   ```

### Option 2: Global Installation (All Repositories)

This installs the commit automation globally, making it available in all repositories where you use Claude Code.

1. **Create global directories:**
   ```bash
   mkdir -p ~/.local/share/claude-commit-hook/
   mkdir -p ~/.config/claude/hooks/
   ```

2. **Copy scripts to global locations:**
   ```bash
   # From this repository's global/ directory
   cp global/handle-commit.sh ~/.local/share/claude-commit-hook/
   cp global/command-interceptor.sh ~/.config/claude/hooks/
   ```

3. **Make scripts executable:**
   ```bash
   chmod +x ~/.local/share/claude-commit-hook/handle-commit.sh
   chmod +x ~/.config/claude/hooks/command-interceptor.sh
   ```

4. **Create global Claude Code settings:**

   Create or update `~/.config/claude/settings.json`:
   ```json
   {
     "description": "Global Claude Code settings - Commit automation with Claude",
     "hooks": {
       "UserPromptSubmit": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "~/.config/claude/hooks/command-interceptor.sh"
             }
           ]
         }
       ]
     }
   }
   ```

## Usage

1. Make changes to your code in any repository (if using global install) or this repository (if using local install)
2. Open Claude Code in that repository
3. Simply type: `commit`
4. Claude will:
   - Stage all your changes
   - Generate a git diff
   - Use Claude AI to create a conventional commit message
   - Create the commit
   - Display the commit message and result

## How It Works

### Architecture

```
User types "commit" in Claude Code
         ↓
UserPromptSubmit hook triggers
         ↓
command-interceptor.sh intercepts the "commit" command
         ↓
handle-commit.sh executes:
  - Stages all changes (git add)
  - Generates diff (git diff --cached)
  - Calls Claude CLI to generate commit message
  - Creates commit (git commit)
         ↓
Result displayed to user
```

### Components

1. **command-interceptor.sh**: Intercepts user prompts in Claude Code and routes specific commands (like "commit") to handlers
   - Uses Claude Code's `UserPromptSubmit` hook
   - Blocks the original prompt when intercepting
   - Returns formatted responses to the user

2. **handle-commit.sh**: The main commit automation script
   - Stages all changes (untracked and modified files)
   - Generates git diff
   - Calls `claude` CLI with a prompt to generate commit message
   - Cleans up Claude's response (removes markdown fences)
   - Creates the commit with the generated message

3. **settings.json**: Claude Code configuration
   - Registers the `UserPromptSubmit` hook
   - Points to the command-interceptor script

## Directory Structure

### Local Installation
```
your-repo/
├── .claude/
│   ├── settings.json              # Local Claude Code config
│   └── hooks/
│       └── command-interceptor.sh # Command router
└── handle-commit.sh               # Commit handler
```

### Global Installation
```
~/.config/claude/
├── settings.json                  # Global Claude Code config
└── hooks/
    └── command-interceptor.sh     # Command router

~/.local/share/claude-commit-hook/
└── handle-commit.sh               # Commit handler
```

## Extending the System

The command interceptor is designed to be easily extensible. To add new commands:

1. **Edit command-interceptor.sh:**

   Add a new case to the switch statement:
   ```bash
   case "$STRIPPED_PROMPT" in
       commit)
           # ... existing commit handler ...
           ;;
       push)
           # New handler for "push" command
           HANDLER_OUTPUT=$("$SCRIPT_DIR/handle-push.sh" 2>&1)
           # ... handle response ...
           ;;
       *)
           # Default: allow normal processing
           ;;
   esac
   ```

2. **Create the handler script:**

   Create a new script (e.g., `handle-push.sh`) that performs the desired action

3. **Make it executable:**
   ```bash
   chmod +x handle-push.sh
   ```

## Troubleshooting

### "Command not found: jq"
Install jq:
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# Arch Linux
sudo pacman -S jq
```

### "Command not found: claude"
Make sure Claude CLI is installed and in your PATH. See [Claude Code documentation](https://docs.claude.com/claude-code).

### Hook not triggering
1. Verify settings.json is in the correct location
2. Check that scripts have execute permissions
3. Ensure paths in command-interceptor.sh are correct
4. Restart Claude Code

### "Not in a git repository"
Make sure you're running the command from within a git repository.

### Diff too large warning
If your changes are very large (>100KB), the script automatically uses `git diff --stat` instead to avoid Claude's token limits.

## Configuration

### Customizing the Commit Message Format

Edit `handle-commit.sh` and modify the `CLAUDE_PROMPT` variable (around line 48) to change how Claude generates commit messages.

### Changing the Diff Size Limit

Edit `handle-commit.sh` line 42 to adjust the maximum diff size:
```bash
if [ "$DIFF_SIZE" -gt 100000 ]; then  # Change 100000 to your preferred limit
```

## License

This project is provided as-is for use with Claude Code.

## Contributing

Feel free to extend this system with additional commands and handlers. The interceptor pattern makes it easy to add new automation workflows.
