#!/usr/bin/env fish

# Pre-commit hook: run the repository's `just check` against exactly what is
# staged, then put everything else back untouched.
#
# Unstaged edits and untracked files are moved aside with a keep-index stash
# so the checks see the index and nothing else. They come back from the
# stash's own trees, never through `git stash pop`: pop merges against HEAD,
# so a file that is staged as new and edited further shows up as added on
# both sides, and pop writes conflict stages into the index before failing.
# The commit then dies with "Error building trees" after the hook reported
# success. Restoring the worktree from the stash cannot conflict and never
# touches the index, and the hook checks the index is unchanged before it
# lets the commit proceed.

set -l index_tree (git write-tree)
set -l stash_before (git rev-parse -q --verify refs/stash)
set -l stashed 0

git diff --quiet
set -l unstaged $status
set -l untracked (git ls-files --others --exclude-standard)

if test $unstaged -ne 0; or test (count $untracked) -gt 0
    echo "📦 Setting unstaged changes aside..."
    git stash push --quiet --keep-index --include-untracked \
        --message "pre-commit hook stash"
    if test $status -ne 0
        echo "❌ Could not stash unstaged changes; nothing was changed"
        exit 1
    end
    if test (git rev-parse -q --verify refs/stash) != "$stash_before"
        set stashed 1
    end
end

set -l check_result 0
if test -f justfile
    echo "🔍 Running checks against the staged tree..."
    just check
    set check_result $status
end

if test $stashed -eq 1
    echo "📦 Restoring unstaged changes..."
    git restore --source=refs/stash --worktree -- .
    set -l restored $status
    # Untracked files ride in the stash's third parent, which exists even
    # when it is empty, so restore exactly the paths it lists and add nothing
    # to the index.
    if test $restored -eq 0; and git rev-parse -q --verify 'refs/stash^3' >/dev/null
        set -l untracked_paths (git ls-tree -r --name-only 'refs/stash^3')
        if test (count $untracked_paths) -gt 0
            git restore --source='refs/stash^3' --worktree --overlay -- $untracked_paths
            set restored $status
        end
    end
    if test $restored -ne 0
        echo "❌ Could not restore the unstaged changes; the stash is kept"
        echo "   Recover with: git restore --source=refs/stash --worktree -- ."
        echo "   and for untracked files: git restore --source='refs/stash^3' --worktree --overlay -- ."
        echo "   then: git stash drop"
        exit 1
    end
    if test (git write-tree) != "$index_tree"
        echo "❌ The index changed while restoring; the stash is kept"
        echo "   Put the index back with: git read-tree $index_tree"
        exit 1
    end
    git stash drop --quiet
end

if test $check_result -ne 0
    echo "❌ Pre-commit checks failed on the staged tree; unstaged changes are back in place"
    exit $check_result
end
echo "✅ Pre-commit checks passed"
