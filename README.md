# pre-flight

A [Claude Code](https://claude.ai/code) plugin that reviews your implementation plans with [Codex](https://openai.com/codex) before they reach you for approval.

Every plan gets a second pair of eyes — before you say yes.

## How it works

1. You ask Claude Code to plan something
2. Claude writes the plan and calls `ExitPlanMode`
3. **pre-flight intercepts** — sends the plan to Codex for review
4. Codex returns prioritized feedback (P1–P3)
5. Claude presents the review to you **before** the approval prompt
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

Restart Claude Code after installing — hooks load at session start.

## Updating

```bash
claude plugin marketplace update pre-flight
claude plugin update pre-flight@pre-flight
```

## Debugging

Run Claude Code with `claude --debug` to see hook execution logs. If no plan is found in the transcript, the hook exits silently.

## License

MIT
