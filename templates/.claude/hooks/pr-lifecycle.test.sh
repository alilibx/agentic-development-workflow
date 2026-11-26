#!/bin/bash
# Standalone harness for .claude/hooks/pr-lifecycle.sh: feed it the JSON
# Claude Code sends after a Bash call, and check whether it fires.
# Run: bash .claude/hooks/pr-lifecycle.test.sh
#
# Every case runs once per awk found on this machine (gawk, mawk, BusyBox awk,
# BSD awk), because the matcher must work with whichever one is `awk`.
set -u
HOOK="$(cd "$(dirname "$0")" && pwd)/pr-lifecycle.sh"
pass=0
fail=0

# expect <create|merge|both|none> <description> <command>
expect() {
  local want="$1" desc="$2" cmd="$3" out got
  out=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}' | AWK="$awk" sh "$HOOK")
  case "$out" in
    *"ran both gh pr create and gh pr merge"*) got=both ;;
    *"pull request was just created"*) got=create ;;
    *"PR merge command just ran"*) got=merge ;;
    "") got=none ;;
    *) got=other ;;
  esac
  if [ "$got" = "$want" ]; then
    echo "PASS [$awk]: $desc"
    pass=$((pass + 1))
  else
    echo "FAIL [$awk]: $desc (expected $want, got $got)"
    fail=$((fail + 1))
  fi
}

nl=$'\n'

run_cases() {
  expect create "plain gh pr create" 'gh pr create --fill'
  expect create "operator right after the verb" 'gh pr create; echo done'
  expect merge  "&& right after the verb" 'gh pr merge&&echo x'
  expect both   "create and merge in one command" 'gh -R o/r pr create --fill && gh pr merge --squash'
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
  # Quoted strings that span lines stay quoted on every line.
  expect none   "multi-line commit message mentions create" "git commit -m \"fix: hook${nl}${nl}It fired on prose (gh pr create in heredocs)\""
  expect none   "multi-line commit message mentions merge" "git commit -m \"docs: x${nl}gh pr merge 12 is how to land it\""
  expect none   "multi-line single-quoted string" "echo 'one${nl}gh pr create${nl}two'"
  expect create "real command after a multi-line quote closes" "git commit -m \"a${nl}gh pr merge 1\"${nl}gh pr create --fill"
  # Command substitutions run, even inside double quotes.
  expect create "\$(...) inside double quotes" 'url="$(gh pr create --fill)"'
  expect create "\$(...) unquoted" 'echo $(gh pr create --fill)'
  expect create "backticks" 'url=`gh pr create --fill`'
  expect create "backticks inside double quotes" 'echo "PR: `gh pr create --fill`"'
  expect none   "\$(...) inside single quotes is text" "echo '\$(gh pr create)'"
  expect create "after ; on line 3 of a plain script" "git add -A${nl}git commit -m \"feat: x\"${nl}git push; gh pr create --fill"
  expect merge  "only real command is on line 1, heredoc body mentions create" "gh pr merge 12 --squash --body \"\$(cat <<'EOF'${nl}## Notes${nl}gh pr create --fill${nl}EOF${nl})\""
  # Things that look like a heredoc but aren't, or delimiters that aren't plain.
  expect create "<< inside double quotes is not a heredoc" "echo \"use cat <<EOF here\"${nl}gh pr create --fill"
  expect create "<< inside single quotes is not a heredoc" "echo 'use cat <<EOF here'${nl}gh pr create --fill"
  expect create "hyphenated quoted delimiter" "cat <<'END-OF-NOTES' > n.md${nl}END${nl}gh pr create in notes${nl}END-OF-NOTES${nl}gh pr create --fill"
  expect none   "hyphenated delimiter: body text after a partial match stays body" "cat <<'END-OF-NOTES' > n.md${nl}END${nl}gh pr create --fill${nl}END-OF-NOTES"
  expect create "arithmetic shift is not a heredoc" "x=\$((1<<y))${nl}gh pr create --fill"
  expect create "(( )) shift is not a heredoc" "(( x = 1<<y ))${nl}gh pr create --fill"
  expect create "delimiter must match the whole line" "cat <<EOF${nl}EOF2${nl} EOF${nl}EOF${nl}gh pr create --fill"
  expect create "two heredocs on one line" "cat <<A <<B${nl}a${nl}A${nl}gh pr merge${nl}B${nl}gh pr create --fill"
  expect none   "comment that mentions it" '# then gh pr create'
  expect create "escaped quote doesn't open a string" "echo \\\"${nl}gh pr create --fill"
}

awks=()
for a in gawk mawk original-awk bwk-awk "busybox awk"; do
  command -v "${a%% *}" >/dev/null 2>&1 || continue
  if [ "${a%% *}" = busybox ] && ! busybox awk 'BEGIN{}' 2>/dev/null; then continue; fi
  awks+=("$a")
done
for awk in "${awks[@]}"; do
  echo "=== awk: $awk ==="
  run_cases
done
if [ "${#awks[@]}" -eq 0 ]; then awk=awk; run_cases; fi
for a in gawk mawk; do
  command -v "$a" >/dev/null 2>&1 || echo "note: $a is not installed, so its run was skipped"
done

echo "=== summary: $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
