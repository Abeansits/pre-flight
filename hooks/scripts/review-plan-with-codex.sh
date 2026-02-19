#!/bin/bash
# Codex plan reviewer - fires on PreToolUse(ExitPlanMode)
#
# First call:  extracts the plan, sends it to Codex, and DENIES ExitPlanMode
#              so Claude presents the review to the user in conversation.
# Second call: detects the plan was already reviewed (via content hash in marker
#              file) and passes through, allowing ExitPlanMode to proceed.
#
# If the plan changes between calls (user asks for revisions), the hash won't
# match and a fresh review is triggered.

set -euo pipefail

log() { echo "[pre-flight] $*" >&2; }

# Clean up marker files older than 24h to prevent /tmp accumulation
find /tmp -maxdepth 1 -name 'pre-flight-*.marker' -mtime +1 -delete 2>/dev/null || true

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  log "no transcript found, skipping"
  exit 0
fi

# Derive a per-session marker file path from the transcript path
marker_file="/tmp/pre-flight-$(echo "$transcript_path" | shasum -a 256 | cut -c1-16).marker"

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

# Hash the plan content to detect changes between calls
plan_hash=$(echo "$plan_content" | shasum -a 256 | cut -c1-64)

# If the marker file exists and contains the same hash, this plan was already
# reviewed — let ExitPlanMode through (this is the retry after a deny).
if [ -f "$marker_file" ]; then
  stored_hash=$(cat "$marker_file" 2>/dev/null || echo "")
  if [ "$stored_hash" = "$plan_hash" ]; then
    log "plan already reviewed (hash match), passing through"
    exit 0
  fi
  log "plan changed since last review (hash mismatch), re-reviewing"
fi

log "plan extracted (${#plan_content} chars), sending to codex..."

# Run codex non-interactively
review_file=$(mktemp /tmp/codex-plan-review-XXXXXX.txt)
trap 'rm -f "$review_file"' EXIT

if ! codex exec \
  --model "gpt-5.3-codex" \
  -c 'model_reasoning_effort="high"' \
  --full-auto \
  --ephemeral \
  --skip-git-repo-check \
  -o "$review_file" \
  "You are a senior engineer reviewing an implementation plan before it goes to the developer for approval. Be direct and concise — bullet points only, grouped by priority.

Prioritize findings:
- P1 (must fix): correctness issues, wrong assumptions, missing critical steps, security risks
- P2 (should fix): gaps in error handling, missing edge cases, unclear ownership of steps
- P3 (nice to have): scope creep, over-engineering, minor improvements

Only include priority levels that have findings. If the plan looks solid, say so in one line.

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

log "review received (${#review} chars), denying ExitPlanMode to surface review first"

# Store the plan hash so the retry (same plan) passes through
echo "$plan_hash" > "$marker_file"

# Deny ExitPlanMode — Claude sees permissionDecisionReason and presents the review
# to the user before retrying ExitPlanMode (which passes through on second call).
jq -n --arg review "$review" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": ("Codex Plan Review\n\nPresent this review to the user and address any concerns before finalizing the plan.\n\n" + $review)
    }
  }'
