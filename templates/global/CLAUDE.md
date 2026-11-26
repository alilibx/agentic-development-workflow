# Global engineering rules (all repos)

<!-- A starter for ~/.claude/CLAUDE.md. Copy it by hand; adopt.sh doesn't install it.
     Keep it repo-agnostic: no project names, no machine setup, no secrets. -->

## Precedence

- **The repo wins.** A repo's own SDLC docs (for example `docs/engineering/`), and its `CLAUDE.md` / `AGENTS.md`, take precedence over this file. Read them before any branch, PR, deploy or release action.
- **Repo and global rules beat plugin skills.** If a skill offers something these rules forbid (a local merge into the default branch, a worktree somewhere else), follow the rules, not the skill.

## Git and pull requests

- **Never commit to the default branch** (`main` or `master`). Cut a short-lived branch first: use the repo's documented prefixes, or `feat/`, `fix/`, `chore/` if it has none. Conventional Commits for commit messages and PR titles, with no emoji before the type.
- **Review after `gh pr create`.** If the repo names a review bot or its own review policy, follow the repo. Otherwise, right after creating the PR, run a local review of it (a code-review skill, or a reviewer sub-agent), report the findings, and fix confirmed issues on the PR branch before handing it over. Never call a PR ready when nothing has reviewed it.
- **A bot review that ran before your latest push is stale.** Check that it covers the head commit before trusting it; if not, ask it to review again.
- **Attribution:** follow the repo's policy. Where it has none, add no AI co-author trailers or "generated with" lines to commits, PRs, comments or release notes.
- **A merged PR leaves nothing behind.** After a merge, in this order:
  1. Confirm it merged: `gh pr view <n> --json state,mergeCommit`, and check the merge commit contains the branch's latest commit (a PR can be merged on GitHub before a later push lands). Never assume.
  2. If the branch has a worktree, remove it from the main checkout, never from inside it: `git -C <repo> worktree remove <path>`, then `git -C <repo> worktree prune`.
  3. Delete the local branch with `git branch -D` (squash merges defeat `-d`).
  4. `git fetch --prune`, then `git ls-remote --heads origin <branch>`. If the remote branch still exists, say so and delete it: `git push origin --delete <branch>`.
  5. Report what you deleted.

  Never delete a branch whose PR is still open, and never touch the main checkout's current branch.

## Worktrees

- One worktree per branch, under the repo's `.claude/worktrees/<name>/`, which is git-ignored.
- Run commands against another checkout with `git -C <path>`; don't `cd` from a worktree into the main checkout.
- A worktree lives exactly as long as its PR: create it with the branch, delete it in the merged-PR cleanup. Stale worktrees pin branches.
- Scratch state in a worktree dies with it. Anything worth keeping goes in a commit or a memory file.
- The stash is shared by every worktree: never a bare `git stash` / `git stash pop`. Prefer a WIP commit.

## Tracker

<!-- Written for Linear. Swap the tool names for your tracker. -->

- **Everything goes through the tracker**, unless the repo opts out in its `AGENTS.md` (for example, it keeps a `FEATURES.md` or progress file instead). Before starting, check for a matching issue. If none exists, ask where it belongs and what to create. Never start work or create an issue silently.
- **Link the PR to its issue,** and move the issue to done when the PR merges.
- **After a feature merges, update its project:** post a project status update (what shipped, with PR and issue keys; what's next; risks; health), and update the project's status and any "shipped" list or roadmap in its description.
- **Human-only steps become issues assigned to that person:** account signups, dashboard settings, DNS, API keys, legal or content decisions, production data entry. Give clear steps and a `blocks` relation to the work it unblocks. Don't leave them only in chat.
- **Engineering issues are pulled, not pushed.** Don't bulk-assign unowned issues; keep the priority order right instead.
- **If the tracker tools aren't authenticated,** say so and ask the user to connect them. Never skip the check silently.

## Sub-agents

- Every sub-agent brief forbids `pkill`, `killall` and `kill`. A broad pattern kills the user's other apps.
- Sub-agents never run CLIs that write to shared deployments or shared environments, including "dry-run" modes that still touch them. The lead session runs those, one at a time.
- Before writing shared config (a staging setting, a vendor template), re-read it, and report whether you created or updated it. Other people edit shared environments too.

## Quality

- **Docs and copy change in the same PR as the behaviour,** or in a linked follow-up. Check user-facing copy against what the code really does.
- **Runnable tests from the first task** of any new project or slice.
- **Run tests locally or on staging.** Use production only when told to.

## Secrets

- Never put a token in a `settings.json` hook command or any committed file. Read it from an environment variable or the OS keychain.

## Writing

- Replies, PRs and docs follow the `plain-voice` skill. When it conflicts with an honest verdict, honesty wins.
