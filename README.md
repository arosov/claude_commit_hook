# Claude git commit linux HOOK

When 'commit' is used as prompt, use a hook to generate a commit with haiku
using Claude Code in non-interactive CLI mode.

Maybe this work on MacOS.

Adapting to Windows should be possible but I'm not doing it, feel free to
contribute.

## Hook ?

No context bloat.

Minimize token usage.

"Inspired" by Aider's approach to coding agent commit management.

But really, it's just a matter of using the LLM where it's actually relevant and
doing with a script what can be done with a script.

LLM is only used to generate a commit message from files diffs.


## Setup


### Common for global or local

Copy `commit-hook.sh` to `~/.local/share/claude-hook-handlers/`


### Global setup

Copy or extend your `~/.claude/settings.json` using this repository `settings.json`.

Copy `command-interceptor.sh` to `~/.claude/hooks/`


### Per repository (local) setup

Assuming `$REPO_ROOT` is your repository absolute path.

Copy / extend your `$REPO_ROOT/.claude/settings.json` using this repository `local-settings.json`.

Copy `command-interceptor.sh` to `$REPO_ROOT/.claude/hooks/`


## Why not a slash command

Slash Commands are fed to Claude Code SlashCommands internal tool.

As such, they increase the context usage:
* The slash command call itself is part of the context (I think ?)
* Due to extending the SlashCommand tool description
* Because the FrontMatter file is expanding in your current session context
  * And it would contain instruction for the LLM itself to forge and execute
  the `git commit` command.
* When used for git commit, since ClaudeCode doesn't provide access to modified
files tracking, files diff also increase your context usage (again).


## Hook limitations

Currently not designed for this kind of usage.

To not have 'commit' being added to the session context, using the 'block'
property of the UserPromptSubmit event JSON response.

The "UX" is not optimal.

Doesn't seem to allow interactions (like yes / no questions for untracked files
or modifying the message). At least, not without increasing the current session
context.

