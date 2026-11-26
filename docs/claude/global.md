# Global and repo instructions

Claude Code reads instructions from two layers: **yours**, in `~/.claude/`, which apply in every repo you open, and **the repo's**, which apply to everyone who works in it. The rest of this manual is about the repo layer. This page is about the global one, and how the two fit together.

## The two layers

| | Global (you, every repo) | Repo (everyone, this repo) |
|---|---|---|
| Rules | `~/.claude/CLAUDE.md` | `AGENTS.md`, imported by `CLAUDE.md`; nested `CLAUDE.md` per package; `docs/engineering/` |
| Settings and hooks | `~/.claude/settings.json` | `.claude/settings.json` (committed), `.claude/settings.local.json` (yours, ignored) |
| Skills | `~/.claude/skills/`, plugins | `.claude/skills/` |
| Agents | `~/.claude/agents/` | `.claude/agents/` |

Claude Code loads both rule files into every session; neither replaces the other. For settings, the repo's values override yours. For the rule files, precedence is whatever the files themselves say, so **say it, in the global file:**

1. **The repo's SDLC docs** (`docs/engineering/`) win.
2. Then the repo's **`AGENTS.md` / `CLAUDE.md`**.
3. Then **your global `CLAUDE.md`**.
4. **Plugin skills come last.** A skill is general advice; the rules above are this team's decisions. For example, the superpowers plugin's `finishing-a-development-branch` skill offers to merge locally into the default branch, and `using-git-worktrees` may pick a folder other than `.claude/worktrees/`. Where a skill offers something the rules forbid, follow the rules.

## What goes where

| Belongs in the global file | Belongs in the repo |
|---|---|
| Habits you want in every repo: branch first, clean up after merges, worktree discipline | The team's workflow, with links to `docs/engineering/` |
| How you work with your tracker, when a repo doesn't say | The tracker team, issue key and board owner |
| Sub-agent safety | Domain rules and the tests that enforce them |
| How the agent writes to you | The surfaces table, skills by folder, check commands |
| Fallbacks: "if the repo doesn't say, do X" | Anything a teammate also needs |

If a teammate would need the rule too, it belongs in the repo. Keep machine-specific setup (local tools, paths, accounts) out of the global rules file; put it in your own notes.

## Rules worth having globally

The [starter `~/.claude/CLAUDE.md`](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/global/CLAUDE.md) holds all of these. Each is a fallback for repos that don't say otherwise.

### No commits to the default branch

Cut a branch first, with the repo's documented prefixes, or `feat/`, `fix/` and `chore/` when it has none. In repos that adopted this workflow the [git hook](/workflow/branching#the-pre-commit-hook) enforces it; the global rule covers every other repo.

### Clean up after a merge

A merged PR leaves nothing behind:

1. **Confirm the merge.** `gh pr view <n> --json state,mergeCommit`, and check the merge commit contains the branch's latest commit. A PR is sometimes merged on GitHub before a later push lands, and that push would be lost with the branch.
2. **Remove the worktree** from the main checkout, never from inside it: `git -C <repo> worktree remove <path>`, then `git worktree prune`.
3. **Delete the local branch** with `git branch -D`; squash merges defeat `-d`.
4. **Prune and check the remote.** `git fetch --prune`, then `git ls-remote --heads origin <branch>`. If the branch still exists on the remote, say so and delete it.
5. **Report** what was deleted.

Never touch the branch of a PR that is still open.

### Worktree discipline

- One worktree per branch, under `.claude/worktrees/<name>/`, which is git-ignored.
- Use `git -C <path>` instead of `cd`-ing between checkouts.
- A worktree lives exactly as long as its PR. Stale worktrees pin branches: git refuses to delete a branch that is checked out somewhere.
- Never a bare `git stash`: the stash is shared by every worktree, so a `pop` in one can apply another's changes. Prefer a WIP commit.

### The tracker, beyond `/task`

[The task loop](/workflow/task-loop) covers picking, claiming and closing an issue. The global file adds what happens around it:

- **After a feature merges,** post a project status update (what shipped, what's next, risks, health) and update the project's status and its "shipped" list.
- **Human-only steps become issues assigned to that person,** with clear steps and a `blocks` relation to the work they unblock: account signups, DNS, API keys, legal or content decisions, production data. Engineering issues are still pulled, not assigned.
- **If the tracker tools aren't authenticated, say so.** Never skip the "is there an issue?" check silently.
- **Repos may opt out.** An open-source or personal repo can keep its plan in a `FEATURES.md` or progress file. It says so in its `AGENTS.md`, and the global rule steps aside.

### Sub-agent safety

- **Every brief forbids `pkill`, `killall` and `kill`.** A broad pattern such as `pkill -f cat` matches far more than the agent meant, including the user's other apps.
- **Sub-agents never run CLIs that write to shared deployments,** even in a "dry run" mode that still touches them. The lead session runs those, one at a time.
- **Re-read shared config before writing it,** and report whether you created or updated it. Other people edit staging at the same time, and many vendor settings have no history.

### Quality habits

- **Docs and copy change in the same PR as the behaviour.** Check user-facing copy against what the code really does.
- **Runnable tests from the first task** of a new project or slice, not "once it settles".
- **A bot review that ran once is stale after a new push.** Some bots review a PR once and never again. Check the review covers the head commit before trusting its verdict.

## Review after `gh pr create`

The manual's default, for repos that adopt it: **the review bot reviews PRs with code, and the agent doesn't run a second local review after `gh pr create`.** A local review happens on request, for docs-only PRs the bot skips, or when no bot review appears. See [Pull requests and review](/workflow/pull-requests#no-second-review).

Your other repos may have no bot at all. So the global rule is a fallback: **if the repo has a review bot or its own review policy, follow the repo; otherwise run a local review right after `gh pr create`,** report the findings, and fix what's confirmed before handing the PR over.

### A global hook that defers to the repo

The [starter `settings.json`](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/global/settings.json) carries that fallback as a `PostToolUse` hook on `Bash`, which runs [`~/.claude/hooks/pr-review-policy.sh`](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/global/hooks/pr-review-policy.sh):

```json
{
  "type": "command",
  "command": "\"$HOME\"/.claude/hooks/pr-review-policy.sh",
  "statusMessage": "PR review policy check"
}
```

After the agent runs `gh pr create`, the script decides in this order:

1. **The repo has its own PR hook:** its `.claude/settings.json` mentions `gh pr create` or `pr-lifecycle`. The global hook exits, and the repo's [PR-lifecycle hook](/claude/hooks#the-pr-lifecycle-hook) speaks.
2. **The repo has a CodeRabbit config** (`.coderabbit.yaml` or `.coderabbit.yml`). The bot reviews the PR, so the agent doesn't run a second local review. If the PR is docs-only, or no review appears, it says so and offers one.
3. **Otherwise,** the agent runs `/code-review` on the PR, reports the findings, and fixes confirmed issues before handing it over.

It detects the command with [`runs-gh-pr.sh`](/claude/hooks#match-the-command-not-the-text), an identical copy of the matcher the repo hook uses. So a commit message or heredoc that only mentions `gh pr create` doesn't trigger it, and `GH_TOKEN=x gh pr create` or `gh -R owner/repo pr create` does. [`pr-review-policy.test.sh`](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/global/hooks/pr-review-policy.test.sh) checks each decision above, and that the two copies of the matcher are still identical.

The pattern works for any global default you want a repo to be able to override: check for the repo's version first, and step aside.

::: danger Never put a token in a hook command
`settings.json` is read by tools, backed up, synced between machines, and pasted into issues and dotfiles repos. A token in a hook command (`curl -H 'Authorization: Bearer …'`) leaks with it. Read it from an environment variable or the OS keychain (`security find-generic-password -w` on macOS, `secret-tool lookup` on Linux).
:::

## The writing voice {#plain-voice}

The [`plain-voice` skill](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/global/skills/plain-voice/SKILL.md) applies the [Google developer documentation style guide](https://developers.google.com/style) to every reply: answer first, active voice, no filler, no em-dashes. Its description makes Claude load it for every response. The honesty rules in the repo win where the two conflict. See [How the agent writes](/guide/standards#how-the-agent-writes).

## Install the starter {#install-the-starter}

`adopt.sh` installs only the repo layer. It never touches your home directory. Copy the global files by hand, without overwriting what you have:

```sh
cp -n  templates/global/CLAUDE.md      ~/.claude/CLAUDE.md
cp -n  templates/global/settings.json  ~/.claude/settings.json
mkdir -p ~/.claude/hooks ~/.claude/skills
cp -n  templates/global/hooks/pr-review-policy.sh templates/global/hooks/runs-gh-pr.sh ~/.claude/hooks/
cp -Rn templates/global/skills/plain-voice ~/.claude/skills/
```

The hook needs `jq`. Keep `runs-gh-pr.sh` next to `pr-review-policy.sh`; when you update one copy of the matcher, update both.

If you already have a `~/.claude/CLAUDE.md` or `settings.json`, merge by hand. Claude Code reads `~/.claude/settings.json` as one JSON object, so add the hook under your existing `hooks.PostToolUse` rather than appending a second file.
