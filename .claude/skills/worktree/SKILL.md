---
name: worktree
description: Manage git worktrees for parallel development. Create, list, switch between, and clean up isolated working directories for running multiple Claude sessions simultaneously.
allowed-tools: Bash
---

# Git Worktree Management

Manage git worktrees for parallel development workflows. Worktrees allow multiple branches to be checked out simultaneously in separate directories, enabling parallel Claude Code sessions without conflicts.

## Overview

Git worktrees create isolated working directories that share the same git history. This enables:

- **Parallel Development**: Run multiple Claude sessions on different features
- **Context Isolation**: Keep work-in-progress separate from other tasks
- **Quick Context Switching**: Jump between branches without stashing
- **PR Reviews**: Review PRs in isolation while continuing development

## Commands

All commands use `pnpm wt <command>`:

| Command                   | Description                                    |
| ------------------------- | ---------------------------------------------- |
| `pnpm wt list`            | List all managed worktrees                     |
| `pnpm wt list --all`      | Include external worktrees                     |
| `pnpm wt new [branch]`    | Create new worktree (interactive if no branch) |
| `pnpm wt go <branch>`     | Enter existing worktree shell                  |
| `pnpm wt main`            | Return to main repo                            |
| `pnpm wt which`           | Show current worktree info                     |
| `pnpm wt remove <branch>` | Remove worktree and optionally delete branch   |
| `pnpm wt prune`           | Clean up stale worktree references             |

## Workflow Examples

### Create a New Feature Worktree

```bash
# Interactive creation (prompts for branch type and name)
pnpm wt new

# Or specify branch directly
pnpm wt new feature/user-auth
```

### Switch Between Worktrees

```bash
# List available worktrees
pnpm wt list

# Enter a specific worktree
pnpm wt go feature/user-auth

# Return to main repo
pnpm wt main
```

### Clean Up When Done

```bash
# Remove a specific worktree
pnpm wt remove feature/user-auth

# Clean stale references
pnpm wt prune
```

## Parallel Claude Sessions

To run multiple Claude Code sessions in parallel:

1. Create worktrees for each task:

   ```bash
   pnpm wt new feature/auth
   pnpm wt new fix/login-bug
   ```

2. Open separate terminal windows/panes

3. In each terminal, navigate to a different worktree:

   ```bash
   # Terminal 1
   cd ../monorepo-feature-auth
   claude

   # Terminal 2
   cd ../monorepo-fix-login-bug
   claude
   ```

4. Each Claude session works independently on its own branch

## Directory Structure

Worktrees are created as sibling directories:

```
~/projects/
├── monorepo/                      # Main repo (main branch)
├── monorepo-feature-auth/         # Worktree for feature/auth
├── monorepo-fix-login-bug/        # Worktree for fix/login-bug
└── monorepo-scratch-happy-fox/    # Scratch worktree
```

## Branch Types

When creating interactively, select from:

1. **feature/** - New functionality
2. **fix/** - Bug fixes
3. **chore/** - Maintenance, dependencies
4. **refactor/** - Code restructuring
5. **docs/** - Documentation
6. **test/** - Test coverage
7. **scratch/** - Quick exploration (auto-named with random words)

## Tips

- Run `pnpm install` in new worktrees to set up dependencies
- Exit worktree shells with `Ctrl+D` or `exit`
- Scratch branches get random names like `scratch/happy-penguin-a1b2`
- Use `pnpm wt which` to check your current location
