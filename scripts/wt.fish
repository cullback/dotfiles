#!/usr/bin/env fish

# wt.fish - git worktrees beside the repository, kept the way Podium keeps them
#
# Worktrees live at <repo-parent>/.worktrees/<repo-name>/<name>, outside the
# checkout, so nothing inside the repo needs gitignoring and Podium lists and
# manages the same tree. A new worktree gets a branch of its own from the
# remote trunk and copies of the untracked files a checkout needs. It gets no
# port: `free-port` picks one when a server starts.
#
# git config (per repo or global):
#   wt.seed   glob for an untracked file to copy in; repeatable.
#             Default: .env and *.sqlite3

function abort
    set_color red
    echo "✗ $argv" >&2
    set_color normal
    exit 1
end

function warn
    set_color yellow
    echo "! $argv" >&2
    set_color normal
end

function note
    echo "$argv" >&2
end

function show_help
    echo "Usage: wt [OPTIONS] [name]"
    echo ""
    echo "Create a git worktree at <repo-parent>/.worktrees/<repo>/<name>"
    echo "on a branch of the same name, from origin/<trunk> when there is a"
    echo "remote and <trunk> otherwise. An existing branch is checked out"
    echo "instead of created. With no name, a random two-word name is used."
    echo ""
    echo "Options:"
    echo "  -d, --delete      Delete the worktree, then its branch"
    echo "  -l, --list        List worktrees"
    echo "  -p, --prune       Prune stale worktree entries only"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  wt                     # new worktree, e.g. quiet-lantern"
    echo "  wt fix-login           # new worktree on branch fix-login"
    echo "  wt --delete fix-login  # remove worktree and branch"
end

argparse --name=wt -x 'l,p,d' h/help d/delete l/list p/prune -- $argv
or exit 1

if set -ql _flag_help
    show_help
    exit 0
end

git rev-parse --git-dir >/dev/null 2>&1
or abort "Not a git repository"

# The main checkout is the first entry, wherever this is run from.
set main_path (git worktree list --porcelain | string replace -rf '^worktree ' '' | head -n1)
test -n "$main_path"
or abort "Failed to find the main checkout"
set repo_name (path basename $main_path)
set repos_dir (path dirname $main_path)
set root $repos_dir/.worktrees/$repo_name
# Where worktrees used to go; still accepted for deletion.
set legacy_root $main_path/.worktrees

git -C $main_path worktree prune
or abort "Failed to prune worktrees"

# --- git helpers -------------------------------------------------------------

function branch_exists --argument-names name
    git -C $main_path rev-parse --verify -q refs/heads/$name >/dev/null
end

function remote_branch_exists --argument-names name
    git -C $main_path rev-parse --verify -q refs/remotes/origin/$name >/dev/null
end

# The branch checked out at a registered worktree path, "detached", or
# failure when the path is not a worktree of this repo.
function worktree_branch --argument-names wanted
    set -l current
    for line in (git -C $main_path worktree list --porcelain)
        if string match -q 'worktree *' -- $line
            set current (string replace -r '^worktree ' '' -- $line)
        else if test "$current" = "$wanted"
            if string match -q 'branch refs/heads/*' -- $line
                string replace -r '^branch refs/heads/' '' -- $line
                return 0
            else if test "$line" = detached
                echo detached
                return 0
            end
        end
    end
    return 1
end

# The trunk: origin/HEAD when a remote names one, else the main checkout's
# own branch, else main.
function trunk
    set -l head (git -C $main_path symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
    set -l branch (string replace -r '^[^/]+/' '' -- $head)
    if test -n "$branch"
        echo $branch
        return
    end
    set -l own (worktree_branch $main_path)
    if test -n "$own" -a "$own" != detached
        echo $own
        return
    end
    echo main
end

function valid_name --argument-names name
    string match -qr '^[A-Za-z0-9_-][A-Za-z0-9._-]*$' -- $name
    and git check-ref-format --branch $name >/dev/null 2>&1
end

function unusable_name --argument-names name
    abort "$name is not a usable worktree name — letters, digits, dot, dash and underscore only"
end

# --- ports -------------------------------------------------------------------
# A main checkout may keep a PORT in its `.env` as the number it prefers, and
# seeding copies the file whole. The line goes, so the worktree does not ask
# for the same port; `free-port` gives its server one when it starts.

set port_line '^\s*(export\s+)?PORT='

function clear_port --argument-names dir
    set -l file $dir/.env
    test -f $file
    or return
    set -l kept (string match -rv $port_line <$file)
    if test -z (string join '' -- $kept | string trim)
        rm $file
    else
        printf '%s\n' $kept >$file
    end
end

# --- seeding -----------------------------------------------------------------

# Copies the files a checkout needs but git does not track. What could not be
# copied is reported: an unseeded worktree still beats no worktree.
function seed --argument-names dir
    set -l patterns (git config --get-all wt.seed)
    test -n "$patterns"
    or set patterns .env '*.sqlite3'
    for file in (find $main_path -mindepth 1 -maxdepth 1 -type f)
        set -l base (path basename $file)
        for pattern in $patterns
            if string match -q -- $pattern $base
                cp $file $dir/$base
                or warn "$base was not copied into the worktree"
                break
            end
        end
    end
end

# --- random names ------------------------------------------------------------

set adjectives amber bold brave bright calm clever cosmic crisp deft eager \
    fleet fond gentle glad keen late lucid mellow night pale \
    plain proud quiet rapid rough spare still swift tidy vivid warm wild
set nouns anchor basin beacon birch canyon cedar comet coral crane \
    delta ember fjord garnet harbor heron island juniper lantern \
    meadow onyx orchard otter pebble pine prairie quartz raven \
    reef sparrow summit thicket willow

function random_name
    echo $adjectives[(random 1 (count $adjectives))]-$nouns[(random 1 (count $nouns))]
end

# --- list / prune ------------------------------------------------------------

if set -ql _flag_list
    git -C $main_path worktree list
    exit 0
end

if set -ql _flag_prune
    exit 0
end

# --- delete ------------------------------------------------------------------

if set -ql _flag_delete
    test (count $argv) -ge 1
    or abort "Missing required argument: name"
    set name $argv[1]
    valid_name $name
    or unusable_name $name

    set wt_path
    for candidate in $root/$name $legacy_root/$name
        if test -d $candidate
            set wt_path $candidate
            break
        end
    end
    test -n "$wt_path"
    or abort "No worktree named $name under $root"
    set branch (worktree_branch $wt_path)
    or abort "$wt_path is not a registered worktree of $repo_name"

    # The shell that asked is about to lose its directory; the wrapper cds
    # into the last line of output when it is one.
    set inside (string match -q "$wt_path*" -- (pwd -P); and echo yes)

    git -C $main_path worktree remove --force $wt_path
    or abort "Failed to remove worktree"
    if test "$branch" != detached
        git -C $main_path branch -D $branch >&2
        or warn "The worktree is gone, but branch $branch remains"
    end
    test -n "$inside"; and echo $main_path
    exit 0
end

# --- create ------------------------------------------------------------------

set requested $argv[1]
if test -n "$requested"
    valid_name $requested
    or unusable_name $requested
    set name $requested
else
    for i in (seq 64)
        set candidate (random_name)
        if not test -e $root/$candidate; and not branch_exists $candidate
            set name $candidate
            break
        end
    end
    test -n "$name"
    or abort "Could not find a free worktree name"
end

set wt_path $root/$name
test -e $wt_path
and abort "Something is already at $wt_path"
mkdir -p $root
or abort "Failed to create $root"

set trunk (trunk)
if remote_branch_exists $trunk
    set base origin/$trunk
else
    set base $trunk
end

if branch_exists $name
    git -C $main_path worktree add $wt_path $name >&2
    or abort "Failed to create worktree"
    note "Checked out existing branch $name"
else if remote_branch_exists $name
    git -C $main_path worktree add --track -b $name $wt_path origin/$name >&2
    or abort "Failed to create worktree"
    note "Checked out origin/$name as $name"
else
    git -C $main_path worktree add --no-track -b $name $wt_path $base >&2
    or abort "Failed to create worktree"
    note "Created branch $name from $base"
end

seed $wt_path
# After seeding, never before: `.env` is a seed file, and what was just copied
# in may hold the main checkout's port.
clear_port $wt_path

echo $wt_path
