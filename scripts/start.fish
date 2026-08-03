#!/usr/bin/env fish

# start.fish - Reset worktree to main and create branch for a ticket
# Usage: start.fish <ticket-name>
# Must be run from within a git worktree

set ticket $argv[1]

if test -z "$ticket"
    echo "Usage: start.fish <ticket-name>"
    exit 1
end

# Check if we're in a worktree (git-dir differs from git-common-dir)
set git_dir (git rev-parse --git-dir 2>/dev/null)
set git_common (git rev-parse --git-common-dir 2>/dev/null)

if test "$git_dir" = "$git_common"
    echo "Error: Not in a worktree. Create one first with wt.fish"
    exit 1
end

# Check for uncommitted changes
if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
    echo "Error: Uncommitted changes in worktree. Commit or stash first."
    exit 1
end

# Check if branch already exists (local or remote)
if git show-ref --verify --quiet "refs/heads/$ticket" 2>/dev/null
    echo "Error: Branch '$ticket' already exists locally"
    exit 1
end
if git show-ref --verify --quiet "refs/remotes/origin/$ticket" 2>/dev/null
    echo "Error: Branch '$ticket' already exists on remote"
    exit 1
end

# Fetch latest and create branch from origin/main or local main
if git fetch origin main 2>/dev/null
    git checkout -b $ticket origin/main
else
    git checkout -b $ticket main
end
