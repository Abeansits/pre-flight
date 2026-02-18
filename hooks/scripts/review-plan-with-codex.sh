#!/bin/bash
# Codex plan reviewer - fires on PreToolUse(ExitPlanMode)
# Extracts the plan from the transcript and passes it to codex for review.
# Non-blocking: injects review as a system message regardless of findings.

set -euo pipefail

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

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

        # Handle both direct tool_use entries and nested message entries
        if obj.get("type") == "tool_use" and obj.get("name") == "Write":
            last_write_content = obj.get("input", {}).get("content", "")
        elif obj.get("type") == "message":
            for block in obj.get("content", []):
                if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") == "Write":
                    last_write_content = block.get("input", {}).get("content", "")

print(last_write_content or "")
PYEOF
)

if [ -z "$plan_content" ]; then
  exit 0
fi

# Run codex non-interactively; uses ~/.codex/config.toml defaults (model, effort)
review_file=$(mktemp /tmp/codex-plan-review-XXXXXX.txt)
trap 'rm -f "$review_file"' EXIT

codex exec \
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
$plan_content" 2>/dev/null

review=$(cat "$review_file" 2>/dev/null || echo "")

if [ -z "$review" ]; then
  exit 0
fi

# Pass-through: inject review as system message visible to Claude and user
jq -n --arg review "$review" \
  '{"systemMessage": ("## Codex Plan Review\n\n" + $review)}'
