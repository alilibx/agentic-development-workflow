#!/bin/bash
# Standalone harness for .claude/hooks/pr-lifecycle.sh: feed it the JSON
# Claude Code sends after a Bash call, and check whether it fires.
# Run: bash .claude/hooks/pr-lifecycle.test.sh
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/pr-lifecycle.sh"
pass=0
fail=0

# expect <create|merge|none> <description> <command>
expect() {
  local want="$1" desc="$2" cmd="$3" out got
  out=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}' | sh "$HOOK")
  case "$out" in
    *"pull request was just created"*) got=create ;;
    *"PR merge command just ran"*) got=merge ;;
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

nl=$'\n'
expect create "plain gh pr create" 'gh pr create --fill'
expect create "after git push &&" 'git push -u origin HEAD && gh pr create --fill'
expect create "after a semicolon" 'git push; gh pr create --fill'
expect create "inside a subshell" '(cd app && gh pr create --fill)'
expect create "env var prefix" 'GH_TOKEN=x gh pr create --fill'
expect create "two env var prefixes" 'GH_TOKEN=x GH_HOST=github.com gh pr create'
expect create "gh -R owner/repo" 'gh -R owner/repo pr create --fill'
expect create "gh --repo=owner/repo" 'gh --repo=owner/repo pr create --fill'
expect create "second line of a two-line command" "git push -u origin HEAD${nl}gh pr create --fill"
expect create "body from a heredoc" "gh pr create --title \"feat: x\" --body \"\$(cat <<'EOF'${nl}## Summary${nl}gh pr merge is mentioned here${nl}EOF${nl})\""
expect create "real command after a heredoc ends" "cat > notes.md <<'EOF'${nl}text${nl}EOF${nl}gh pr create --fill"
expect merge  "gh pr merge" 'gh pr merge 12 --squash'
expect merge  "gh pr merge with -R" 'gh -R owner/repo pr merge 12 --squash --delete-branch'
expect none   "echo that mentions it" 'echo "remember gh pr create"'
expect none   "single-quoted mention" "echo 'then gh pr create'"
expect none   "commit message with a separator inside quotes" 'git commit -m "docs: x; gh pr create later"'
expect none   "heredoc body only mentions it" "cat <<'EOF'${nl}gh pr create --fill${nl}EOF"
expect none   "heredoc body with echo of it" "cat > a.sh <<EOF${nl}echo \"gh pr create\"${nl}gh pr create${nl}EOF"
expect none   "tab-stripped heredoc body" "cat <<-EOF${nl}	gh pr create${nl}	EOF"
expect none   "here-string is not a heredoc, and mentions nothing" 'grep x <<< "gh pr create"'
expect none   "gh pr view" 'gh pr view 12'
expect none   "gh pr create-like word" 'gh pr created'
expect none   "a different tool" 'mygh pr create'

echo "=== summary: $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
