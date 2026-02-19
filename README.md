# pre-flight

Love the speed and developer experience of using Claude Code but want to have the thorough review of Codex? Now you can have both!

A [Claude Code](https://claude.ai/code) plugin that reviews your implementation plans with the [Codex](https://openai.com/codex) CLI before they reach you for approval. 

Your implementation plans, cleared for takeoff. ✈️

## How it works

1. You ask Claude Code to plan something
2. Claude writes the plan and calls `ExitPlanMode`
3. **NEW** **pre-flight intercepts** — sends the plan to Codex for review
4. **NEW** Codex returns prioritized feedback (P1–P3)
5. **NEW** Claude chooses to incorporate or ignore the feedback
6. You approve, revise, or reject with the review in hand

If the plan changes after feedback, it gets re-reviewed automatically.

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- [Codex CLI](https://github.com/openai/codex) installed and authenticated
- `python3` and `jq` in your PATH

## Install

```bash
claude plugin marketplace add Abeansits/pre-flight
claude plugin install pre-flight@pre-flight
```

Restart Claude Code after installing - hooks load at session start

## Config

Create `~/.config/pre-flight/config` to override defaults:

```
model=gpt-5.3-codex
reasoning_effort=high
```

| Setting             | Default          | Description                    |
|---------------------|------------------|--------------------------------|
| `model`             | `gpt-5.3-codex`  | Codex model to use for reviews |
| `reasoning_effort`  | `high`            | Reasoning effort (low/medium/high) |

## Updating

```bash
claude plugin marketplace update pre-flight
claude plugin update pre-flight@pre-flight
```

## Debugging

Run Claude Code with `claude --debug` to see hook execution logs. If no plan is found in the transcript, the hook exits silently.

## License

MIT
