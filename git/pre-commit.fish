#!/usr/bin/env fish

# Git pre-commit hook using fish shell
# Save this file as .git/hooks/pre-commit and make it executable with:
# chmod +x .git/hooks/pre-commit

# Check if there are any unstaged changes
set -l has_unstaged (git diff --quiet; echo $status)

# If there are unstaged changes, stash them
if test "$has_unstaged" -ne 0
    echo "📦 Stashing unstaged changes..."
    git stash push --keep-index --include-untracked --message "pre-commit hook stash"
    set -l stash_created $status

    if test "$stash_created" -ne 0
        echo "❌ Failed to stash changes"
        exit 1
    end
end

# Run the check command
set -l check_result 0
if test -f justfile
    echo "🔍 Running checks..."
    just check
    set check_result $status
end

# If we stashed changes, restore them
if test "$has_unstaged" -ne 0
    echo "📦 Restoring stashed changes..."
    git stash pop --quiet 2>/dev/null

    if test $status -ne 0
        # stash pop can fail when staged deletions conflict with stashed
        # worktree files. Reset the failed merge state, re-apply with
        # checkout, then drop the stash entry.
        git checkout stash -- . 2>/dev/null
        git stash drop --quiet 2>/dev/null

        if test $status -ne 0
            echo "❌ Warning: Failed to restore stashed changes automatically"
            echo "   Run 'git stash pop' manually to restore your changes"
        end
    end
end

# Exit with the result of the check command
if test "$check_result" -ne 0
    echo "❌ Pre-commit checks failed"
    exit $check_result
else
    echo "✅ Pre-commit checks passed"
    exit 0
end
