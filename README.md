# pre-flight 📝 ✈️

#### Love the speed and developer experience of using Claude Code but feel like you have to babysit it so it doesn't over-engineer, or worse, miss some important detail? By injecting a second opinion into the planning process you can now have both!

A [Claude Code](https://claude.ai/code) plugin that reviews your implementation plans with the [Codex](https://github.com/openai/codex) or [Gemini](https://github.com/google-gemini/gemini-cli) CLI before they reach you for approval.

Your implementation plans, cleared for takeoff. ✈️

## How it works

1. You ask Claude Code to plan something
2. Claude writes the plan and calls `ExitPlanMode`
3. **NEW** **pre-flight intercepts** — sends the plan to your configured provider for review
4. **NEW** The provider returns prioritized feedback (P1–P3)
5. **NEW** Claude receives the feedback and decides whether to incorporate or ignore it
6. You approve, revise, or reject with the review in hand

If the plan changes after feedback, it gets re-reviewed automatically.

## 🚀 Demo

[![Pre-flight in action](https://img.youtube.com/vi/sMixXHXpbFc/hqdefault.jpg)](https://youtu.be/sMixXHXpbFc)

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- One of the following review providers:
  - [Codex CLI](https://github.com/openai/codex) installed and authenticated (default)
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated (free tier: 1000 req/day, 1M token context)
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
provider=codex
codex_model=gpt-5.3-codex
codex_reasoning_effort=high
gemini_model=gemini-2.5-pro
```

| Setting                  | Default          | Description                         |
|--------------------------|------------------|-------------------------------------|
| `provider`               | `codex`          | Review provider (`codex` or `gemini`) |
| `codex_model`            | `gpt-5.3-codex`  | Codex model to use for reviews      |
| `codex_reasoning_effort` | `high`           | Reasoning effort (low/medium/high)  |
| `gemini_model`           | `gemini-2.5-pro` | Gemini model to use for reviews     |

**Backwards compatibility:** Existing configs using `model=` and `reasoning_effort=` (without prefix) continue to work and map to `codex_model` and `codex_reasoning_effort` respectively.

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

1. **First call** — extracts the plan from the transcript, sends it to the configured provider (Codex or Gemini), and **denies** `ExitPlanMode`. The denial reason contains the review, which Claude surfaces to the user in conversation.
2. **Second call** — Claude retries `ExitPlanMode` after incorporating the feedback. The hook detects the plan was already reviewed and **passes through**, allowing the tool to execute normally.

### Content hashing & loop prevention

A SHA-256 hash of the plan content is written to a marker file in `/tmp` (`pre-flight-<session-hash>.marker`). On each invocation the hook compares the current plan hash to the stored one:

- **Same hash** → plan unchanged, pass through (second call after deny)
- **Different hash** → plan was revised, trigger a fresh review
- Marker files older than 24 hours are automatically cleaned up

### Provider abstraction

The review logic is split into provider-specific functions (`review_with_codex`, `review_with_gemini`) behind a shared prompt builder. A `case` statement routes to the configured provider. Adding a new provider requires only a new function and case branch — everything else (plan extraction, hashing, deny/retry flow) is shared.

### Transcript parsing

The hook reads Claude Code's session transcript (JSONL format) and extracts the most recent `Write` tool call — this is the plan file Claude writes just before calling `ExitPlanMode`. It handles both `type: "assistant"` entries (tool calls nested in `obj.message.content[]`) and `type: "message"` entries (content directly in `obj.content`).

</details>

## License

MIT
