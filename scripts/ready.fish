#!/usr/bin/env fish

# ready.fish - Show tickets ready to start (no existing branch)
# Filters tk ready output by excluding tickets that already have local or remote branches

set tickets (tk ready)

if test -z "$tickets"
    exit 0
end

for ticket in $tickets
    # Check if local branch exists
    if git show-ref --verify --quiet "refs/heads/$ticket" 2>/dev/null
        continue
    end
    # Check if remote branch exists
    if git show-ref --verify --quiet "refs/remotes/origin/$ticket" 2>/dev/null
        continue
    end
    echo $ticket
end
