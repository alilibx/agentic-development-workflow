# Adopt it in a project

This takes about an afternoon. Each step links to the page that explains it.

**You need:** `git`, `bash`, [`bun`](https://bun.sh), the GitHub CLI (`gh`), and `jq`. The PR-lifecycle hook reads its input with `jq`; without it, the hook warns once per PR command and does nothing else.

## 1. Copy the templates {#copy-the-templates}

```sh
git clone https://github.com/alilibx/agentic-development-workflow
agentic-development-workflow/scripts/adopt.sh /path/to/your-project
```

The script copies everything under [`templates/`](https://github.com/alilibx/agentic-development-workflow/tree/main/templates) into your project and sets `core.hooksPath` to `.githooks`. **It never overwrites a file.** Files you already have are listed at the end, for you to merge by hand. It skips `templates/global/`, which is for your home directory, not the repo (see [Global and repo instructions](/claude/global)).

It refuses, and tells you why, when enforcement would silently be off:

- **The path isn't the repository root.** `core.hooksPath` is resolved from the root, so hooks copied into a subfolder never run. Run it on the root.
- **`core.hooksPath` already points somewhere else** (husky, lefthook). Overwriting it would switch your existing hooks off. Call `.githooks/pre-commit` from your hook manager's pre-commit, and `.githooks/pre-merge-commit` from its pre-merge-commit, then re-run with `--keep-hooks-path`.

It also warns when `.gitignore` would hide a copied file. A common pattern, `.claude/*`, hides the hook script and the agents while the committed `settings.json` still points at the hook, so every teammate gets a hook error. The warning prints the `!` lines to add; see [Hooks](/claude/hooks#settings-files).

If you already had a `CLAUDE.md`, the script kept it. Add `@AGENTS.md` as its first line, so Claude loads the rules.

From then on, the hook blocks commits on `main`, so do the rest on a branch:

```sh
git switch -c chore/adopt-workflow
```

::: tip Brand-new repository
The hook lets the root commit of an empty repo through, since there is no `main` to protect yet. Every commit after that needs a branch.
:::

## 2. Switch the hook on for everyone {#switch-the-hook-on}

`adopt.sh` set `core.hooksPath` for your clone only. Make it automatic for every clone and worktree:

::: code-group
```json [bun / pnpm]
{
  "scripts": {
    "postinstall": "git config core.hooksPath .githooks || true"
  }
}
```
```json [npm]
{
  "scripts": {
    "prepare": "git config core.hooksPath .githooks || true"
  }
}
```
```md [other stacks]
<!-- README.md, under "Set up" -->
Run once after cloning: `git config core.hooksPath .githooks`
```
:::

The `|| true` keeps installs outside a git checkout (a Docker build, a tarball) from failing. See [Branching and commits](/workflow/branching).

## 3. Fill in the placeholders {#fill-in-the-placeholders}

```sh
grep -rn '<[a-zA-Z][^>]*>' AGENTS.md .coderabbit.yaml .github release-please-config.json docs
```

| File | What to fill in | Page |
|---|---|---|
| `AGENTS.md` | Project summary, package table and check commands, domain invariants, surfaces table, skills by area | [CLAUDE.md and AGENTS.md](/claude/claude-md) |
| `.claude/hooks/pr-lifecycle.sh` | `ISSUE_KEY` (your tracker's issue prefix) | [Hooks](/claude/hooks) |
| `.claude/skills/task/SKILL.md` | Issue key, tracker team, who owns the board | [The task loop](/workflow/task-loop) |
| `.coderabbit.yaml` | One `path_instructions` block per package | [Pull requests and review](/workflow/pull-requests) |
| `.github/CODEOWNERS` | The maintainer's GitHub handle | |
| `.github/workflows/*.yml` | Real check, codegen, deploy and migration commands; `HEALTH_URL` | [CI/CD](/delivery/ci-cd) |
| `release-please-config.json` | `package-name`, and `release-type` (`node` for one `package.json`) | [Releases](/delivery/releases) |
| `docs/` | Project name, getting-started commands | [The docs site](/docs-site/) |

Then install the docs site and commit its lockfile, or `ci.yml`'s docs job (`--frozen-lockfile`) fails on the adopting PR:

```sh
cd docs && bun install && git add bun.lock
```

The engineering pages in `docs/engineering/` start as stubs. Each one names the manual page it adapts, and until you adapt it, the agent follows that page as written:

| Stub | Adapts |
|---|---|
| `task-flow.md` | [The task loop](/workflow/task-loop) |
| `branching.md` | [Branching and commits](/workflow/branching) |
| `code-review.md` | [Pull requests and review](/workflow/pull-requests) |
| `environments.md` | [Environments and side effects](/delivery/environments) |
| `ci-cd.md` | [CI/CD](/delivery/ci-cd) |
| `release-process.md` | [Releases](/delivery/releases) |
| `migrations.md` | [Schema migrations](/delivery/migrations) |
| `qa-process.md` | [QA](/delivery/qa) |

If you don't deploy yet, delete `main.yml`, `deploy.yml` and `smoke.yml` in this PR, or fill in their commands. Left as placeholders, the first merge to `main` goes red. See [CI/CD](/delivery/ci-cd).

## 4. Set up the services

- [ ] **Tracker.** A Linear team for the project, with statuses Todo, In Progress, In Review, Done. Connect the Linear MCP server to Claude Code. Connect Linear's GitHub integration so a branch named `abc-123-…` links its PR.
- [ ] **Review bot.** Install the CodeRabbit GitHub app on the repo. It reads `.coderabbit.yaml`.
- [ ] **GitHub settings.** Turn on *Settings → Actions → General → Allow GitHub Actions to create and approve pull requests*; release-please needs it. Turn on squash merging only.
- [ ] **Secrets and variables, per tier.** Repository secrets `DEPLOY_TOKEN_STAGING`, `DEPLOY_TOKEN_PRODUCTION` and `NOTIFY_TOPIC`; repository variables `HEALTH_URL_STAGING`, `HEALTH_URL_PRODUCTION`, `APP_URL_STAGING` and `APP_URL_PRODUCTION`. This works on every plan. GitHub environments (and a required reviewer on production) depend on your plan for private repos; see [Secrets per tier](/delivery/ci-cd#secrets-per-tier) for the upgrade path.
- [ ] **Pager.** Run the **Pager test** workflow and check every priority arrives on a phone.
- [ ] **Branch protection**, if your plan allows it, on `main`:
  - require a pull request, with one approval from someone other than the author;
  - require the `CI` checks **and the review bot's check** to pass, with the branch up to date;
  - require conversation resolution, so an unanswered bot finding blocks the merge;
  - require linear history, and block force-pushes and deletion;
  - leave *Do not allow bypassing the above settings* unchecked, so an admin can [break glass](/delivery/releases#break-glass) and the override lands in the audit log.

  Without it, the git hook is your only guard, and the hook can be skipped with `--no-verify`.
- [ ] **Docs site.** Deploy `docs/` to GitHub Pages, Vercel or Netlify. See [The docs site](/docs-site/).
- [ ] **Health endpoint.** Your service reports the commit it runs (`{"revision": "<sha>"}`), so the deploy can check it. See [CI/CD](/delivery/ci-cd#verify-what-is-live).

## 5. Install the skills your stack needs

List them in `AGENTS.md` under "Skills to load by area". See [Skills](/claude/skills).

## 6. Open the PR

Commit with `chore: adopt the agentic development workflow` and open a PR. Because it is mostly markdown, the review bot will skip most of it, so ask for a human review. That's the first rule of [Pull requests and review](/workflow/pull-requests) in action.

## What to leave out

Adopt the whole loop, but drop what doesn't apply:

- **No backward compatibility** is a pre-production rule. Delete that block from `AGENTS.md` once real users depend on your API or data.
- **release-please** fits apps that deploy from `main`. A library that publishes on tags may prefer a changelog gate in CI instead. See [Releases](/delivery/releases#libraries).
- **Mobile apps** need one extra rule in `AGENTS.md`: say whether a change ships as an over-the-air patch or needs a store release.
