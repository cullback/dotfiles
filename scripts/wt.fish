#!/usr/bin/env fish

# wt.fish - Manage git worktrees in a .worktrees directory

function abort
    set_color red
    echo "✗ $argv" >&2
    set_color normal
    exit 1
end

function show_help
    echo "Usage: wt [OPTIONS] <name>"
    echo ""
    echo "Create git worktrees in project-root/.worktrees/"
    echo "Worktrees are created in detached HEAD state from origin/main (or main if no remote)"
    echo ""
    echo "Arguments:"
    echo "  name              Name for the worktree directory"
    echo ""
    echo "Options:"
    echo "  -d, --delete      Delete worktree"
    echo "  -l, --list        List all current worktrees"
    echo "  -p, --prune       Prune stale worktrees only (no create)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  wt session-1          # Create worktree in detached HEAD"
    echo "  wt --delete session-1 # Remove worktree"
    echo "  wt --list             # List all worktrees"
end

# Parse arguments
argparse --name='wt' \
    -x 'l,p,d' \
    h/help \
    d/delete \
    l/list \
    p/prune \
    -- $argv
or exit 1

# Handle --help
if set -ql _flag_help
    show_help
    exit 0
end

# Ensure we're in a git repository
if not git rev-parse --git-dir >/dev/null 2>&1
    abort "Not a git repository"
end

# Get project root
set project_root (git rev-parse --show-toplevel)
or abort "Failed to determine project root"

set worktrees_dir "$project_root/.worktrees"

# Create .worktrees directory if it doesn't exist
if not test -d "$worktrees_dir"
    mkdir -p "$worktrees_dir"
    or abort "Failed to create .worktrees directory"
end

# Check if .worktrees is gitignored
if not git check-ignore -q "$worktrees_dir" 2>/dev/null
    abort ".worktrees is NOT gitignored. Please add '.worktrees' to your .gitignore."
end

# Prune stale worktrees (silent unless error)
git worktree prune 2>&1
or abort "Failed to prune worktrees"

# Handle --list
if set -ql _flag_list
    git worktree list
    exit 0
end

# Handle --prune (prune only, already done above)
if set -ql _flag_prune
    exit 0
end

# Handle --delete
if set -ql _flag_delete
    if test (count $argv) -lt 1
        abort "Missing required argument: name"
    end

    set name $argv[1]
    set worktree_path "$worktrees_dir/$name"

    # Remove worktree (force to handle modified/untracked files)
    if test -d "$worktree_path"
        git worktree remove --force "$worktree_path"
        or abort "Failed to remove worktree"
    else
        abort "Worktree does not exist: $worktree_path"
    end

    exit 0
end

# Require name for worktree creation
if test (count $argv) -lt 1
    abort "Missing required argument: name"
end

set name $argv[1]
set worktree_path "$worktrees_dir/$name"

# Check for duplicate worktree path
if test -d "$worktree_path"
    abort "Worktree directory already exists: $worktree_path"
end

# Create parent directories
mkdir -p (dirname "$worktree_path")
or abort "Failed to create parent directories"

# Create worktree in detached HEAD from origin/main or main
if git rev-parse --verify origin/main >/dev/null 2>&1
    git worktree add --detach "$worktree_path" origin/main
    or abort "Failed to create worktree"
else
    git worktree add --detach "$worktree_path" main
    or abort "Failed to create worktree"
end

echo "$worktree_path"
