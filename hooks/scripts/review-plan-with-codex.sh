#!/bin/bash
# Codex plan reviewer - fires on PreToolUse(ExitPlanMode)
# Extracts the plan from the transcript and passes it to codex for review.
# Non-blocking: injects review as a system message regardless of findings.

set -euo pipefail

log() { echo "[pre-flight] $*" >&2; }

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  log "no transcript found, skipping"
  exit 0
fi

log "extracting plan from transcript..."

# Extract the content of the most recent Write tool call from the transcript.
# Plans are written to a file just before ExitPlanMode is called.
plan_content=$(python3 - "$transcript_path" <<'PYEOF'
import json, sys

transcript_path = sys.argv[1]
last_write_content = None

with open(transcript_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue

        # Search for Write tool_use blocks in all known transcript formats
        content_blocks = []
        if obj.get("type") in ("message", "assistant"):
            # "assistant" type nests content in obj.message.content
            # "message" type nests content directly in obj.content
            msg = obj.get("message", obj)
            content_blocks = msg.get("content", [])
        elif obj.get("type") == "tool_use" and obj.get("name") == "Write":
            last_write_content = obj.get("input", {}).get("content", "")

        for block in content_blocks:
            if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") == "Write":
                last_write_content = block.get("input", {}).get("content", "")

print(last_write_content or "")
PYEOF
)

if [ -z "$plan_content" ]; then
  log "no plan content found in transcript, skipping"
  exit 0
fi

log "plan extracted (${#plan_content} chars), sending to codex..."

# Run codex non-interactively; uses ~/.codex/config.toml defaults (model, effort)
review_file=$(mktemp /tmp/codex-plan-review-XXXXXX.txt)
trap 'rm -f "$review_file"' EXIT

if ! codex exec \
  --full-auto \
  --ephemeral \
  --skip-git-repo-check \
  -o "$review_file" \
  "You are a senior engineer reviewing an implementation plan before it goes to the developer for approval. Be direct and concise — bullet points only.

Flag any of the following if present:
- Missing steps or gaps in the approach
- Wrong technical assumptions
- Scope creep or over-engineering
- Risks that aren't called out

If the plan looks solid, say so briefly.

Plan:
$plan_content" 2>&1 | while IFS= read -r line; do log "codex: $line"; done; then
  log "codex exec failed"
  exit 0
fi

review=$(cat "$review_file" 2>/dev/null || echo "")

if [ -z "$review" ]; then
  log "codex returned empty review, skipping"
  exit 0
fi

log "review received (${#review} chars), injecting system message"

# Pass-through: inject review as system message visible to Claude and user
jq -n --arg review "$review" \
  '{"systemMessage": ("## Codex Plan Review\n\n" + $review)}'
