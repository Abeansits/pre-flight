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

## Install

```bash
claude plugin install pre-flight
```

Then restart Claude Code — hooks are loaded at session start.

## Configuration

The hook uses your `~/.codex/config.toml` defaults — no flags needed. Example config:

```toml
model = "gpt-5.3-codex-spark"
model_reasoning_effort = "xhigh"
```

The default review timeout is 120 seconds. If reviews are timing out, you can adjust this in the plugin's `hooks/hooks.json`.

## Debugging

```bash
# Run Claude Code in debug mode to see hook execution logs
claude --debug
```

If no plan is extracted from the transcript, the hook exits silently — it won't break anything.

## How it extracts the plan

The hook reads the Claude Code session transcript (JSONL) and finds the content of the most recent `Write` tool call — which is where Claude writes the plan file just before calling `ExitPlanMode`.

## License

MIT
