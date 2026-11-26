#!/bin/bash
# Standalone harness for .githooks/pre-commit, .githooks/pre-merge-commit and
# .githooks/commit-msg --
# no test framework, just scratch git repos and plain assertions. Run
# directly: bash .githooks/pre-commit.test.sh
#
# Each scratch repo gets its own copy of the real hook scripts (copied from
# this directory, not reimplemented), activated the same way production
# activates them: committed .githooks/pre-commit + .githooks/pre-merge-commit
# plus a relative `core.hooksPath .githooks`, so these scenarios exercise the
# exact files that ship in the repo.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$HERE/pre-commit"
MERGE_HOOK_SRC="$HERE/pre-merge-commit"
MSG_HOOK_SRC="$HERE/commit-msg"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

pass=0
fail=0
check() {
  local desc="$1" ok="$2"
  if [ "$ok" = "1" ]; then
    echo "PASS: $desc"
    pass=$((pass + 1))
  else
    echo "FAIL: $desc"
    fail=$((fail + 1))
  fi
}

REPO="$SCRATCH/repo"
mkdir -p "$REPO/.githooks"
cp "$HOOK_SRC" "$REPO/.githooks/pre-commit"
cp "$MERGE_HOOK_SRC" "$REPO/.githooks/pre-merge-commit"
chmod +x "$REPO/.githooks/pre-commit" "$REPO/.githooks/pre-merge-commit"

(
  cd "$REPO" || exit 1
  git init -q
  git checkout -q -b main 2>/dev/null || git branch -m main
  git config user.email "test@example.com"
  git config user.name "Test"
  git add .githooks/pre-commit .githooks/pre-merge-commit
  git commit -q -m "seed: add pre-commit and pre-merge-commit hooks"
  git config core.hooksPath .githooks
)

echo "=== scenario 1: commit on main is rejected ==="
echo one > "$REPO/file.txt"
(cd "$REPO" && git add file.txt)
out=$(cd "$REPO" && git commit -m "should be rejected on main" 2>&1)
rc=$?
echo "--- hook output ---"
echo "$out"
echo "--- exit code: $rc ---"
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "no direct commits to main"; then ok=1; else ok=0; fi
check "commit on main is rejected with the policy message" "$ok"
count=$(cd "$REPO" && git log --oneline | wc -l | tr -d ' ')
[ "$count" = "1" ] && ok=1 || ok=0 # only the seed commit should exist
check "no additional commit landed on main" "$ok"
(cd "$REPO" && git reset -q --hard HEAD && git clean -qfd)
echo

echo "=== scenario 2: switch -c feature, then commit succeeds ==="
(cd "$REPO" && git switch -q -c feature)
echo two > "$REPO/file.txt"
(cd "$REPO" && git add file.txt)
out=$(cd "$REPO" && git commit -m "should succeed on feature" 2>&1)
rc=$?
echo "--- exit code: $rc ---"
[ "$rc" -eq 0 ] && ok=1 || ok=0
check "commit on a feature branch succeeds" "$ok"
count=$(cd "$REPO" && git log --oneline | wc -l | tr -d ' ')
[ "$count" = "2" ] && ok=1 || ok=0
check "commit landed on the feature branch" "$ok"
echo

echo "=== scenario 3: detached HEAD, commit succeeds ==="
sha=$(cd "$REPO" && git rev-parse HEAD)
(cd "$REPO" && git checkout -q "$sha")
branch_now=$(cd "$REPO" && git branch --show-current)
[ -z "$branch_now" ] && ok=1 || ok=0
check "HEAD is genuinely detached (empty branch name) before the commit" "$ok"
echo three > "$REPO/file.txt"
(cd "$REPO" && git add file.txt)
out=$(cd "$REPO" && git commit -m "should succeed detached" 2>&1)
rc=$?
echo "--- exit code: $rc ---"
[ "$rc" -eq 0 ] && ok=1 || ok=0
check "commit on detached HEAD succeeds" "$ok"
(cd "$REPO" && git switch -q feature)
echo

echo "=== scenario 4: a worktree of the repo, on a branch, commit succeeds ==="
(cd "$REPO" && git branch -q wtbranch)
WT="$SCRATCH/repo-wt"
(cd "$REPO" && git worktree add -q "$WT" wtbranch)
echo wt > "$WT/wtfile.txt"
(cd "$WT" && git add wtfile.txt)
out=$(cd "$WT" && git commit -m "should succeed in worktree" 2>&1)
rc=$?
echo "--- exit code: $rc ---"
[ "$rc" -eq 0 ] && ok=1 || ok=0
check "commit inside a non-main-branch worktree succeeds" "$ok"
echo

echo "=== scenario 5: git merge --no-ff into main is blocked; into a feature branch it succeeds ==="
(cd "$REPO" && git checkout -q main)
(cd "$REPO" && git checkout -q -b mergeable-branch)
echo mergeme > "$REPO/mergefile.txt"
(cd "$REPO" && git add mergefile.txt && git commit -q -m "commit to be merged")
(cd "$REPO" && git checkout -q main)

main_count_before=$(cd "$REPO" && git log --oneline main | wc -l | tr -d ' ')
out=$(cd "$REPO" && git merge --no-ff mergeable-branch -m "merge mergeable-branch into main" 2>&1)
rc=$?
echo "--- hook output ---"
echo "$out"
echo "--- exit code: $rc ---"
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "no direct commits to main"; then ok=1; else ok=0; fi
check "merge --no-ff into main is rejected with the policy message" "$ok"

# githooks(5): a denied pre-merge-commit does not silently unwind the merge --
# it leaves git mid-merge (MERGE_HEAD set, changes staged), same as an
# unresolved conflict would, and even a retried `git commit` there is caught
# again by pre-commit (verified separately). Confirm that state, then clean
# up the way a developer must: `git merge --abort`, not another commit
# attempt on main.
[ -f "$REPO/.git/MERGE_HEAD" ] && ok=1 || ok=0
check "denied merge leaves MERGE_HEAD (mid-merge, nothing silently landed)" "$ok"
main_count_after_deny=$(cd "$REPO" && git log --oneline main | wc -l | tr -d ' ')
[ "$main_count_after_deny" = "$main_count_before" ] && ok=1 || ok=0
check "no merge commit landed on main" "$ok"
(cd "$REPO" && git merge --abort)
[ -f "$REPO/.git/MERGE_HEAD" ] && ok=0 || ok=1
check "git merge --abort cleans up the blocked merge" "$ok"
echo

(cd "$REPO" && git checkout -q -b integration main)
out=$(cd "$REPO" && git merge --no-ff mergeable-branch -m "merge mergeable-branch into integration" 2>&1)
rc=$?
echo "--- exit code: $rc ---"
[ "$rc" -eq 0 ] && ok=1 || ok=0
check "merge --no-ff into a feature branch succeeds" "$ok"
integration_count=$(cd "$REPO" && git log --oneline integration | wc -l | tr -d ' ')
main_count_after=$(cd "$REPO" && git log --oneline main | wc -l | tr -d ' ')
[ "$integration_count" = "$((main_count_before + 2))" ] && ok=1 || ok=0
check "merge commit landed on the feature branch (base + merged commit + merge commit)" "$ok"
[ "$main_count_after" = "$main_count_before" ] && ok=1 || ok=0
check "main is still untouched after the feature-branch merge" "$ok"
echo

# A fresh repo with the hooks activated before the first commit, as adopt.sh
# leaves a brand-new project.
new_repo() {
  local dir="$1"
  mkdir -p "$dir/.githooks"
  cp "$HOOK_SRC" "$MERGE_HOOK_SRC" "$MSG_HOOK_SRC" "$dir/.githooks/"
  chmod +x "$dir/.githooks/"*
  (
    cd "$dir" || exit 1
    git init -q
    git checkout -q -b main 2>/dev/null || git branch -m main
    git config user.email "test@example.com"
    git config user.name "Test"
    git config core.hooksPath .githooks
  )
}

echo "=== scenario 6: the root commit of an empty repo is allowed on main; the next is not ==="
ROOT="$SCRATCH/root"
new_repo "$ROOT"
out=$(cd "$ROOT" && git add -A && git commit -m "chore: initial commit" 2>&1)
rc=$?
echo "--- exit code: $rc ---"
[ "$rc" -eq 0 ] && ok=1 || ok=0
check "root commit on main succeeds (nothing to protect yet)" "$ok"
echo second > "$ROOT/second.txt"
out=$(cd "$ROOT" && git add second.txt && git commit -m "should be rejected" 2>&1)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "no direct commits to main"; then ok=1; else ok=0; fi
check "second commit on main is rejected" "$ok"
echo

echo "=== scenario 7: PROTECTED_BRANCH moves the guard ==="
PB="$SCRATCH/protected"
new_repo "$PB"
(cd "$PB" && git add -A && git commit -q -m "chore: initial commit" && git branch -q -m trunk)
echo a > "$PB/a.txt"
out=$(cd "$PB" && git add a.txt && PROTECTED_BRANCH=trunk git commit -m "should be rejected on trunk" 2>&1)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "no direct commits to trunk"; then ok=1; else ok=0; fi
check "PROTECTED_BRANCH=trunk refuses a commit on trunk" "$ok"
(cd "$PB" && git switch -q -c main)
out=$(cd "$PB" && PROTECTED_BRANCH=trunk git commit -m "allowed on main when trunk is protected" 2>&1)
rc=$?
[ "$rc" -eq 0 ] && ok=1 || ok=0
check "PROTECTED_BRANCH=trunk allows a commit on a branch named main" "$ok"
echo

echo "=== scenario 8: commit-msg refuses AI attribution ==="
CM="$SCRATCH/commitmsg"
new_repo "$CM"
(cd "$CM" && git add -A && git commit -q -m "chore: initial commit" && git switch -q -c feature)
attempt() {
  echo "$RANDOM" >> "$CM/f.txt"
  (cd "$CM" && git add f.txt && git commit -q -F - 2>&1)
}
out=$(printf 'feat: x\n\nCo-authored-by: Claude <noreply@anthropic.com>\n' | attempt)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "Attribution policy"; then ok=1; else ok=0; fi
check "Co-authored-by Claude trailer is refused" "$ok"
out=$(printf 'feat: x\n\nco-authored-by: Some Bot <bot@anthropic.com>\n' | attempt)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "Attribution policy"; then ok=1; else ok=0; fi
check "lower-case co-authored-by naming anthropic is refused" "$ok"
out=$(printf 'feat: x\n\nClaude-Session: https://example.com/s/1\n' | attempt)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "Attribution policy"; then ok=1; else ok=0; fi
check "Claude-Session trailer is refused" "$ok"
out=$(printf 'feat: x\n\nGenerated with [Claude Code](https://claude.com/claude-code)\n' | attempt)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "Attribution policy"; then ok=1; else ok=0; fi
check "'Generated with Claude Code' line is refused" "$ok"
out=$(printf 'feat: x\n\nCo-authored-by: Jane Doe <jane@example.com>\n' | attempt)
[ $? -eq 0 ] && ok=1 || ok=0
check "a human co-author is allowed" "$ok"
out=$(printf 'docs: explain why we turned off Claude attribution\n' | attempt)
[ $? -eq 0 ] && ok=1 || ok=0
check "a subject that only mentions Claude is allowed" "$ok"
out=$(printf 'fix: x\n\nRemove the Generated with Claude Code footer from PR bodies\n' | attempt)
[ $? -eq 0 ] && ok=1 || ok=0
check "a body line that mentions the footer in prose is allowed" "$ok"
out=$(printf 'feat: x\n\n\360\237\244\226 Generated with [Claude Code](https://claude.com/claude-code)\n' | attempt)
rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "Attribution policy"; then ok=1; else ok=0; fi
check "the real footer line, with its emoji, is refused" "$ok"
# git commit -v: the diff below the scissors line is not part of the message,
# even when the change itself adds the footer to a file.
printf '#!/bin/sh\nprintf "docs: add the PR body template\\n" | cat - "$1" > "$1.new" && mv "$1.new" "$1"\n' > "$SCRATCH/editor.sh"
chmod +x "$SCRATCH/editor.sh"
printf '\360\237\244\226 Generated with [Claude Code](https://claude.com/claude-code)\n' >> "$CM/pr-body.md"
out=$(cd "$CM" && git add pr-body.md && GIT_EDITOR="$SCRATCH/editor.sh" git commit -q -v 2>&1)
rc=$?
subject=$(cd "$CM" && git log -1 --format=%s)
[ "$rc" -eq 0 ] && [ "$subject" = "docs: add the PR body template" ] && ok=1 || ok=0
check "git commit -v whose diff adds the footer is allowed (scissors honoured)" "$ok"
echo

echo "=== summary: $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
