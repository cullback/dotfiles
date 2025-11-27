#!/usr/bin/env fish
# <https://mskelton.dev/bytes/20230906143340>

if test "$argv[1]" = 0000000000000000000000000000000000000000
    # Get the main worktree path (first entry from git worktree list)
    set basePath (git worktree list | head -n1 | awk '{print $1}')

    # Copy .env if it exists
    if test -f "$basePath/.env"
        cp "$basePath/.env" (pwd)/.env
    end

    # Copy all .sqlite3 files if they exist
    for file in $basePath/*.sqlite3
        if test -f $file
            cp $file (pwd)/(basename $file)
        end
    end

end
