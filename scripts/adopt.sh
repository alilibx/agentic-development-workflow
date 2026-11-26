#!/usr/bin/env bash
# Copy the workflow templates into a project. Existing files are never
# overwritten; they are listed so you can merge them by hand.
#
#   scripts/adopt.sh [--keep-hooks-path] /path/to/project
#
# It refuses when enforcement would silently be off: a path that isn't the
# repository root, or a core.hooksPath that already points at another hook
# manager. templates/global/ is for ~/.claude and is never copied.
set -euo pipefail

usage() { echo "usage: scripts/adopt.sh [--keep-hooks-path] /path/to/project" >&2; exit 2; }

keep_hooks_path=0
dest=""
for arg in "$@"; do
  case "$arg" in
    --keep-hooks-path) keep_hooks_path=1 ;;
    -h|--help) usage ;;
    -*) echo "error: unknown option $arg" >&2; usage ;;
    *) [ -z "$dest" ] || usage; dest="$arg" ;;
  esac
done
[ -n "$dest" ] || usage

src="$(cd "$(dirname "$0")/../templates" && pwd)"
dest="$(cd "$dest" && pwd -P)"

top="$(git -C "$dest" rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error: $dest is not a git repository" >&2
  exit 1
}
top="$(cd "$top" && pwd -P)"

# core.hooksPath=.githooks is resolved from the root of the work tree. Hooks
# copied into a subfolder would never run, and commits to main would pass.
if [ "$dest" != "$top" ]; then
  echo "error: $dest is inside the repository $top, not its root." >&2
  echo "Git resolves core.hooksPath from the root, so hooks copied here would never run." >&2
  echo "Run: scripts/adopt.sh $top" >&2
  exit 1
fi

# Don't silently switch off another hook manager (husky, lefthook, ...).
current_hooks_path="$(git -C "$dest" config --get core.hooksPath || true)"
if [ -n "$current_hooks_path" ] && [ "$current_hooks_path" != ".githooks" ] && [ "$keep_hooks_path" -eq 0 ]; then
  cat >&2 <<EOT
error: core.hooksPath is already set to "$current_hooks_path".
Pointing it at .githooks would switch those hooks off. Instead, chain ours:
  1. In your hook manager's pre-commit hook, run:        .githooks/pre-commit
  2. In its pre-merge-commit hook (create it), run:      .githooks/pre-merge-commit
  3. Optionally, in its commit-msg hook, run:            .githooks/commit-msg "\$1"
Then re-run with --keep-hooks-path; core.hooksPath stays "$current_hooks_path".
EOT
  exit 1
fi

copied=()
skipped=()
while IFS= read -r -d '' file; do
  rel="${file#"$src"/}"
  case "$rel" in global/*) continue ;; esac   # for ~/.claude, copied by hand
  target="$dest/$rel"
  if [ -e "$target" ]; then
    skipped+=("$rel")
    continue
  fi
  mkdir -p "$(dirname "$target")"
  cp -p "$file" "$target"
  copied+=("$rel")
done < <(find "$src" -type f -print0 | sort -z)

if [ "$keep_hooks_path" -eq 1 ] && [ -n "$current_hooks_path" ] && [ "$current_hooks_path" != ".githooks" ]; then
  hooks_msg="left core.hooksPath at \"$current_hooks_path\" (chain .githooks/ from it)"
else
  git -C "$dest" config core.hooksPath .githooks
  hooks_msg="set core.hooksPath to .githooks"
fi

echo "Copied ${#copied[@]} files into $dest and $hooks_msg."
if [ "${#skipped[@]}" -gt 0 ]; then
  echo
  echo "Already there, left untouched (merge these by hand):"
  printf '  %s\n' "${skipped[@]}"
fi

# A .gitignore pattern such as .claude/* hides the hook script and agents while
# the committed settings.json still points at the hook.
ignored=()
if [ "${#copied[@]}" -gt 0 ]; then
  while IFS= read -r path; do
    [ -n "$path" ] && ignored+=("$path")
  done < <(git -C "$dest" check-ignore --no-index -- "${copied[@]}" 2>/dev/null || true)
fi
if [ "${#ignored[@]}" -gt 0 ]; then
  echo
  echo "warning: .gitignore hides these copied files, so they would never be committed:"
  printf '  %s\n' "${ignored[@]}"
  echo "Add exceptions after the pattern that hides them, for example:"
  printf '%s\n' "${ignored[@]}" | awk -F/ '{ d = (NF > 2) ? $1 "/" $2 "/" : $0; print "  !" d }' | sort -u
fi

if [ -f "$dest/CLAUDE.md" ] && ! grep -q '@AGENTS.md' "$dest/CLAUDE.md"; then
  echo
  echo "note: your existing CLAUDE.md doesn't import AGENTS.md. Add '@AGENTS.md' as its first line."
fi

cat <<'EOT'

Next:
  1. Fill in every <placeholder>:  grep -rn '<[a-zA-Z][^>]*>' AGENTS.md .coderabbit.yaml .github release-please-config.json docs
  2. Make the hook activation automatic: add "postinstall" (bun, pnpm) or "prepare" (npm)
     running "git config core.hooksPath .githooks || true" to the root package.json,
     or document the one git config command in the README for other stacks.
  3. Set ISSUE_KEY in .claude/hooks/pr-lifecycle.sh, and the issue key in .claude/skills/task/SKILL.md.
  4. cd docs && bun install, and commit docs/bun.lock (CI installs with --frozen-lockfile).
  5. Not deploying yet? Delete .github/workflows/{main,deploy,smoke}.yml, or fill in their commands.
  6. Commit everything on a branch (the hook now blocks commits to main) and open a PR.
EOT
