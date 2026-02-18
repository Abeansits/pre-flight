# Claude Code Hooks

## review-plan-with-codex.sh

Auto-reviews Claude Code plans with Codex before they reach you for approval.

### How it works

- Fires as a `PreToolUse` hook on `ExitPlanMode`
- Extracts the plan content from the session transcript (last `Write` tool call)
- Passes it to `codex exec` non-interactively using your `~/.codex/config.toml` defaults
- Injects the Codex review as a system message (pass-through — never blocks)

### Setup

```bash
# Copy hook to global Claude hooks dir
mkdir -p ~/.claude/hooks
cp .claude/hooks/review-plan-with-codex.sh ~/.claude/hooks/

# Add to ~/.claude/settings.json:
# "hooks": {
#   "PreToolUse": [{
#     "matcher": "ExitPlanMode",
#     "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/review-plan-with-codex.sh", "timeout": 120}]
#   }]
# }
```

### Requirements

- `codex` CLI installed (`brew install codex` or via npm)
- `~/.codex/config.toml` configured with your preferred model
- `python3` and `jq` available in PATH

### Debugging

```bash
# Test the script manually with a fake transcript
echo '{"transcript_path": "/path/to/transcript.jsonl", "cwd": "/your/project"}' | \
  bash ~/.claude/hooks/review-plan-with-codex.sh

# Or run Claude Code with debug mode to see hook execution:
claude --debug
```
