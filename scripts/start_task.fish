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

cd $repo_path

# Check if worktree is registered but directory is missing
if git worktree list | grep -q "$worktree_path"
    if not test -d $worktree_path
        echo "Worktree is registered but directory missing. Pruning..."
        git worktree prune
    else
        echo "Error: Worktree '$worktree_path' already exists"
        return 1
    end
end

# Check if branch exists
if git show-ref --verify --quiet refs/heads/$branch_name
    echo "Branch '$branch_name' already exists, checking it out in worktree..."
    git worktree add ../$worktree_name $branch_name
else
    echo "Creating new branch '$branch_name' in worktree '$worktree_name'..."
    git worktree add ../$worktree_name -b $branch_name
end

or begin
    echo "Failed to create worktree"
    return 1
end

echo "Entering worktree directory..."
cd ../$worktree_name
