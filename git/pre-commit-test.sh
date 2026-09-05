#!/usr/bin/env bash
set -u
# Exercises git/pre-commit.fish in a throwaway repository: each scenario
# commits with a particular mix of staged, unstaged, and untracked state and
# checks the commit, the worktree, and the index afterwards.
HERE=$(cd "$(dirname "$0")" && pwd); HOOK=$HERE/pre-commit.fish; S=$(mktemp -d)
fail=0
setup() {
  rm -rf "$S/hookrepo"; mkdir -p "$S/hookrepo"; cd "$S/hookrepo"
  git init -q; git config user.email t@t; git config user.name t
  mkdir .githooks; cp "$HOOK" .githooks/pre-commit; git config core.hooksPath .githooks
  printf 'check:\n\ttest ! -e FAIL\n\t@echo checked\n' > justfile
  printf 'one\n' > tracked; printf 'x\n' > gone
  git add -A; git commit -qm base >/dev/null 2>&1
}
expect() { if ! eval "$2"; then echo "FAIL [$1]: $2"; fail=1; else echo "ok   [$1]"; fi; }
clean_index() { [ -z "$(git status --short | grep -v '^ \|^??')" ]; }

setup  # A: file staged as new, then edited further (the Error building trees case)
printf 'a\n' > new; git add new; printf 'b\n' >> new
git commit -qm A >/dev/null 2>&1; expect A-commit "git log --oneline | grep -q A"
expect A-committed-index "[ \"$(git show HEAD:new)\" = a ]"
expect A-worktree "[ \"$(cat new)\" = \"$(printf 'a\nb')\" ]"
expect A-clean "[ \"$(git status --short)\" = ' M new' ]"
expect A-nostash "[ -z \"$(git stash list)\" ]"

setup  # E: staged rename plus further edit
git mv tracked moved; printf 'more\n' >> moved
git commit -qm E >/dev/null 2>&1; expect E-commit "git log --oneline | grep -q E"
expect E-worktree "[ \"$(cat moved)\" = \"$(printf 'one\nmore')\" ]"
expect E-status "[ \"$(git status --short)\" = ' M moved' ]"

setup  # B: staged deletion while the file stays in the worktree
git rm -q --cached gone
git commit -qm B >/dev/null 2>&1; expect B-commit "git log --oneline | grep -q B"
expect B-file-kept "[ -f gone ] && [ \"$(git status --short)\" = '?? gone' ]"

setup  # C: an untracked file and no unstaged edits
printf 'u\n' > untracked; printf 'two\n' > tracked; git add tracked
git commit -qm C >/dev/null 2>&1; expect C-commit "git log --oneline | grep -q C"
expect C-untracked-kept "[ -f untracked ] && [ \"$(git status --short)\" = '?? untracked' ]"

setup  # D: unstaged deletion of a tracked file
rm gone; printf 'two\n' > tracked; git add tracked
git commit -qm D >/dev/null 2>&1; expect D-commit "git log --oneline | grep -q D"
expect D-still-deleted "[ ! -e gone ] && [ \"$(git status --short)\" = ' D gone' ]"

setup  # F: the check fails on the staged tree; everything must come back
printf 'x\n' > FAIL; git add FAIL; printf 'edit\n' >> tracked; printf 'u\n' > untracked
git commit -qm F >/dev/null 2>&1; expect F-refused "! git log --oneline | grep -q F"
expect F-index-kept "git diff --cached --name-only | grep -q FAIL"
expect F-worktree "[ \"$(cat tracked)\" = \"$(printf 'one\nedit')\" ] && [ -f untracked ]"
expect F-nostash "[ -z \"$(git stash list)\" ]"

setup  # G: nothing unstaged at all
printf 'two\n' > tracked; git add tracked
git commit -qm G >/dev/null 2>&1; expect G-commit "git log --oneline | grep -q G"
expect G-clean "[ -z \"$(git status --short)\" ]"
exit $fail
