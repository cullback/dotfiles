#!/usr/bin/env fish

# Check git status for a single repository
function check_repo
    set -l dir $argv[1]
    pushd $dir >/dev/null

    set -l statuses

    # Check for uncommitted changes
    if not git diff-index --quiet HEAD -- 2>/dev/null
        set -a statuses "$dir,Uncommitted changes"
    end

    # Check for unpushed commits
    if git log @{u}.. --oneline 2>/dev/null | grep -q .
        set -a statuses "$dir,Unpushed commits"
    end

    # Check for unpulled commits
    if git log ..@{u} --oneline 2>/dev/null | grep -q .
        set -a statuses "$dir,Unpulled commits"
    end

    # Check for untracked files
    if test -n "$(git ls-files --others --exclude-standard)"
        set -a statuses "$dir,Untracked files"
    end

    # If everything is clean
    if test (count $statuses) -eq 0
        set -a statuses "$dir,Clean"
    end

    popd >/dev/null

    # Return statuses
    printf '%s\n' $statuses
end

# Build up the entire output string
set -l output "repo_name,status"

# Check git status for all repos in current directory
for dir in */
    if test -d "$dir/.git"
        set -l repo_statuses (check_repo $dir)
        for stat in $repo_statuses
            set -a output $stat
        end
    end
end

# Print everything at once
printf '%s\n' $output | qsv table
