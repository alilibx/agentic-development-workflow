#!/usr/bin/env bash
# Copy the workflow templates into a project. Existing files are never
# overwritten; they are listed so you can merge them by hand.
#
#   scripts/adopt.sh /path/to/project
set -euo pipefail

src="$(cd "$(dirname "$0")/../templates" && pwd)"
dest="${1:?usage: scripts/adopt.sh /path/to/project}"
dest="$(cd "$dest" && pwd)"

git -C "$dest" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "error: $dest is not a git repository" >&2
  exit 1
}

copied=0
skipped=()
while IFS= read -r -d '' file; do
  rel="${file#"$src"/}"
  target="$dest/$rel"
  if [ -e "$target" ]; then
    skipped+=("$rel")
    continue
  fi
  mkdir -p "$(dirname "$target")"
  cp -p "$file" "$target"
  copied=$((copied + 1))
done < <(find "$src" -type f -print0 | sort -z)

git -C "$dest" config core.hooksPath .githooks

echo "Copied $copied files into $dest and set core.hooksPath to .githooks."
if [ "${#skipped[@]}" -gt 0 ]; then
  echo
  echo "Already there, left untouched (merge these by hand):"
  printf '  %s\n' "${skipped[@]}"
fi
cat <<'EOT'

Next:
  1. Fill in every <placeholder>:  grep -rn '<[a-zA-Z][^>]*>' AGENTS.md .coderabbit.yaml .github release-please-config.json docs
  2. Make the hook activation automatic: add "postinstall" (bun, pnpm) or "prepare" (npm)
     running "git config core.hooksPath .githooks || true" to the root package.json,
     or document the one git config command in the README for other stacks.
  3. Set ISSUE_KEY in .claude/hooks/pr-lifecycle.sh, and the issue key in .claude/skills/task/SKILL.md.
  4. cd docs && bun install, and commit docs/bun.lock (CI installs with --frozen-lockfile).
  5. Commit everything on a branch (the hook now blocks commits to main) and open a PR.
EOT
