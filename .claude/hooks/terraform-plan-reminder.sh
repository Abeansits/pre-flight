#!/bin/bash
# Post-tool hook: reminds Claude to run terraform plan after state-modifying operations.
# Triggered after Bash tool calls that match terraform state/import commands.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only act on terraform state-modifying commands
if ! echo "$COMMAND" | grep -qE "terraform (state rm|state mv|import)"; then
  exit 0
fi

# Inject a reminder into the conversation context
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "MANDATORY: You just ran a Terraform state-modifying command. You MUST now run `terraform plan` in the same workspace to validate the state change before considering this task complete."
  }
}
EOF
exit 0
