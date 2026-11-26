#!/bin/bash
# Standalone harness for .githooks/pre-commit and .githooks/pre-merge-commit --
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

echo "=== summary: $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
