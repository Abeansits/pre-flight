# pre-flight ✈️

A [Claude Code](https://claude.ai/code) hook that automatically reviews your implementation plans with [Codex](https://openai.com/codex) before they reach you for approval.

Every plan gets a second pair of eyes — before you say yes.

## How it works

1. You ask Claude Code to plan something
2. Claude writes the plan and calls `ExitPlanMode`
3. **pre-flight intercepts** — passes the plan to `codex exec` for review
4. Codex flags risks, gaps, and wrong assumptions
5. The review appears as a system message before you approve or revise

Non-blocking by design: the review is informational. You stay in control.

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- [Codex CLI](https://github.com/openai/codex) with `~/.codex/config.toml` configured
- `python3` and `jq` in your PATH

## Setup

### 1. Copy the hook script

```bash
mkdir -p ~/.claude/hooks
cp .claude/hooks/review-plan-with-codex.sh ~/.claude/hooks/
```

### 2. Add the hook to `~/.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/review-plan-with-codex.sh",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

### 3. Restart Claude Code

Hooks are loaded at session start — exit and relaunch for the hook to take effect.

## Configuration

The hook uses your `~/.codex/config.toml` defaults — no flags needed. Example config:

```toml
model = "gpt-5.3-codex-spark"
model_reasoning_effort = "xhigh"
```

Adjust `timeout` in `settings.json` if reviews are timing out (default: 120s).

## Debugging

```bash
# Test the script manually
echo '{"transcript_path": "/path/to/transcript.jsonl", "cwd": "/your/project"}' | \
  bash ~/.claude/hooks/review-plan-with-codex.sh

# Or run Claude Code in debug mode to see hook execution logs
claude --debug
```

If no plan is extracted from the transcript, the hook exits silently — it won't break anything.

## How it extracts the plan

The hook reads the Claude Code session transcript (JSONL) and finds the content of the most recent `Write` tool call — which is where Claude writes the plan file just before calling `ExitPlanMode`.

## License

MIT
