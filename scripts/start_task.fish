#!/usr/bin/env fish

if test (count $argv) -ne 2
    echo "Usage: start_task <repo_name> <branch_name>"
    return 1
end
set repo_root $HOME/repos

set repo_name $argv[1]
set branch_name $argv[2]

set repo_path $repo_root/$repo_name
set worktree_name "$repo_name-$branch_name"
set worktree_path $repo_root/$worktree_name

if not test -d $repo_path
    echo "Error: Repository '$repo_path' does not exist"
    return 1
end

if test -d $worktree_path
    echo "Error: Worktree '$worktree_path' already exists"
    return 1
end

echo "Creating worktree '$worktree_name' from repo '$repo_name' with branch '$branch_name'..."
cd $repo_path
git worktree add ../$worktree_name -b $branch_name
or begin
    echo "Failed to create worktree"
    return 1
end

echo "Entering worktree directory..."
cd ../$worktree_name

echo "Running nix develop..."
nix develop

echo "Creating zellij session '$session_name'..."
zellij attach --create $session_name
