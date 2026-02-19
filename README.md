# pre-flight 📝 ✈️

#### Love the speed and developer experience of using Claude Code but feel like you have to babysit it so it doesn't over-engineer, or worse, miss some important detail? By injecting Codex into the planning process you can now have both!

A [Claude Code](https://claude.ai/code) plugin that reviews your implementation plans with the [Codex](https://github.com/openai/codex) CLI before they reach you for approval. 

Your implementation plans, cleared for takeoff. ✈️

## How it works

1. You ask Claude Code to plan something
2. Claude writes the plan and calls `ExitPlanMode`
3. **NEW** **pre-flight intercepts** — sends the plan to Codex for review
4. **NEW** Codex returns prioritized feedback (P1–P3)
5. **NEW** Claude receives the feedback and decides whether to incorporate or ignore it
6. You approve, revise, or reject with the review in hand

If the plan changes after feedback, it gets re-reviewed automatically.

## 🚀 Demo

[![Pre-flight in action](https://img.youtube.com/vi/sMixXHXpbFc/maxresdefault.jpg)](https://youtu.be/sMixXHXpbFc)

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

## Uninstall

```bash
claude plugin remove pre-flight
claude plugin marketplace remove pre-flight
```

Restart Claude Code after uninstalling.

## Debugging

Run Claude Code with `claude --debug` to see hook execution logs. If no plan is found in the transcript, the hook exits silently.

<details>
<summary><strong>Technical details</strong></summary>

### Hook event

pre-flight registers a `PreToolUse:ExitPlanMode` hook. This fires every time Claude calls `ExitPlanMode` (i.e., right before presenting a plan for approval) — *before* the tool actually executes.

### Deny-then-retry pattern

The hook uses a two-pass approach:

1. **First call** — extracts the plan from the transcript, sends it to Codex, and **denies** `ExitPlanMode`. The denial reason contains the Codex review, which Claude surfaces to the user in conversation.
2. **Second call** — Claude retries `ExitPlanMode` after incorporating the feedback. The hook detects the plan was already reviewed and **passes through**, allowing the tool to execute normally.

### Content hashing & loop prevention

A SHA-256 hash of the plan content is written to a marker file in `/tmp` (`pre-flight-<session-hash>.marker`). On each invocation the hook compares the current plan hash to the stored one:

- **Same hash** → plan unchanged, pass through (second call after deny)
- **Different hash** → plan was revised, trigger a fresh Codex review
- Marker files older than 24 hours are automatically cleaned up

### Transcript parsing

The hook reads Claude Code's session transcript (JSONL format) and extracts the most recent `Write` tool call — this is the plan file Claude writes just before calling `ExitPlanMode`. It handles both `type: "assistant"` entries (tool calls nested in `obj.message.content[]`) and `type: "message"` entries (content directly in `obj.content`).

</details>

## License

MIT
