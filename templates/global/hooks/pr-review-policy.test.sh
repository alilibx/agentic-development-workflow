#!/bin/bash
# Standalone harness for ~/.claude/hooks/pr-review-policy.sh: scratch project
# folders, the JSON Claude Code sends after a Bash call, plain assertions.
# Run: bash templates/global/hooks/pr-review-policy.test.sh
#
# The command matcher itself (runs-gh-pr.sh) is covered case by case in
# templates/.claude/hooks/pr-lifecycle.test.sh. This file checks the global
# hook's own decisions, a few matcher shapes end to end, and that its copy of
# the matcher is identical to the repo-level one.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/pr-review-policy.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
pass=0
fail=0

# expect <bot|review|none> <description> <project dir> <command>
expect() {
  local want="$1" desc="$2" dir="$3" cmd="$4" out got
  out=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}' | CLAUDE_PROJECT_DIR="$dir" sh "$HOOK")
  case "$out" in
    *"CodeRabbit reviews the PR"*) got=bot ;;
    *"run /code-review on this PR"*) got=review ;;
    "") got=none ;;
    *) got=other ;;
  esac
  if [ "$got" = "$want" ]; then
    echo "PASS: $desc"
    pass=$((pass + 1))
  else
    echo "FAIL: $desc (expected $want, got $got)"
    fail=$((fail + 1))
  fi
}

plain="$SCRATCH/plain"; mkdir -p "$plain"
yaml="$SCRATCH/yaml"; mkdir -p "$yaml"; : > "$yaml/.coderabbit.yaml"
yml="$SCRATCH/yml"; mkdir -p "$yml"; : > "$yml/.coderabbit.yml"
own="$SCRATCH/own"; mkdir -p "$own/.claude"; : > "$own/.coderabbit.yaml"
printf '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"\\"$CLAUDE_PROJECT_DIR\\"/.claude/hooks/pr-lifecycle.sh"}]}]}}\n' > "$own/.claude/settings.json"
other="$SCRATCH/other"; mkdir -p "$other/.claude"
printf '{"permissions":{"allow":["Bash(git status)"]}}\n' > "$other/.claude/settings.json"

nl=$'\n'
expect review "no bot config: run /code-review" "$plain" 'gh pr create --fill'
expect bot    ".coderabbit.yaml: the bot reviews" "$yaml" 'gh pr create --fill'
expect bot    ".coderabbit.yml: the bot reviews" "$yml" 'gh pr create --fill'
expect none   "repo has its own PR hook (and a bot config): stand down" "$own" 'gh pr create --fill'
expect review "repo settings without a PR hook don't count" "$other" 'gh pr create --fill'
expect none   "not a PR command" "$plain" 'git status'
expect none   "gh pr merge is not create" "$plain" 'gh pr merge 12 --squash'
expect review "env var prefix" "$plain" 'GH_TOKEN=x gh pr create --fill'
expect review "gh -R owner/repo" "$plain" 'gh -R o/r pr create --fill'
expect review "after git push &&" "$plain" 'git push -u origin HEAD && gh pr create --fill'
expect review "\$(...) inside double quotes" "$plain" 'url="$(gh pr create --fill)"'
expect none   "commit message that mentions it" "$plain" 'git commit -m "docs: x; gh pr create later"'
expect none   "multi-line commit message that mentions it" "$plain" "git commit -m \"fix: hook${nl}${nl}It fired on prose (gh pr create in heredocs)\""
expect none   "heredoc body that mentions it" "$plain" "cat <<'EOF'${nl}gh pr create --fill${nl}EOF"

# The matcher ships twice (repo hook and global hook); the copies must match.
repo_copy="$HERE/../../.claude/hooks/runs-gh-pr.sh"
if [ -f "$repo_copy" ]; then
  if cmp -s "$HERE/runs-gh-pr.sh" "$repo_copy"; then
    echo "PASS: runs-gh-pr.sh is identical to templates/.claude/hooks/runs-gh-pr.sh"
    pass=$((pass + 1))
  else
    echo "FAIL: runs-gh-pr.sh differs from templates/.claude/hooks/runs-gh-pr.sh; change both together"
    fail=$((fail + 1))
  fi
else
  echo "note: no templates/.claude/hooks/runs-gh-pr.sh next to this copy (installed in ~/.claude?), identity check skipped"
fi

echo "=== summary: $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
