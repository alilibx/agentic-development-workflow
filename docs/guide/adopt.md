# Adopt it in a project

This takes about an afternoon. Each step links to the page that explains it.

## 1. Copy the templates

```sh
git clone https://github.com/alilibx/manzilo-workflow
manzilo-workflow/scripts/adopt.sh /path/to/your-project
```

The script copies everything under [`templates/`](https://github.com/alilibx/manzilo-workflow/tree/main/templates) into your project and sets `core.hooksPath` to `.githooks`. **It never overwrites a file.** Files you already have are listed at the end, for you to merge by hand.

From then on, the hook blocks commits on `main`, so do the rest on a branch:

```sh
git switch -c chore/adopt-workflow
```

::: tip Brand-new repository
The hook lets the root commit of an empty repo through, since there is no `main` to protect yet. Every commit after that needs a branch.
:::

## 2. Switch the hook on for everyone

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

## 3. Fill in the placeholders

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

## 4. Set up the services

- [ ] **Tracker.** A Linear team for the project, with statuses Todo, In Progress, In Review, Done. Connect the Linear MCP server to Claude Code. Connect Linear's GitHub integration so a branch named `abc-123-…` links its PR.
- [ ] **Review bot.** Install the CodeRabbit GitHub app on the repo. It reads `.coderabbit.yaml`.
- [ ] **GitHub settings.** Turn on *Settings → Actions → General → Allow GitHub Actions to create and approve pull requests*; release-please needs it. Create `staging` and `production` environments with their secrets and a `HEALTH_URL` variable. Turn on squash merging only.
- [ ] **Branch protection**, if your plan allows it: require a PR, one approval, the `CI` checks, linear history, and no force-pushes. Without it, the git hook is your only guard, and the hook can be skipped with `--no-verify`.
- [ ] **Docs site.** Deploy `docs/` to GitHub Pages, Vercel or Netlify. See [The docs site](/docs-site/).
- [ ] **Health endpoint.** Your service reports the commit it runs (`{"revision": "<sha>"}`), so the deploy can check it. See [CI/CD](/delivery/ci-cd#verify-what-is-live).

## 5. Install the skills your stack needs

List them in `AGENTS.md` under "Skills to load by area". See [Skills](/claude/skills).

## 6. Open the PR

Commit with `chore: adopt the Manzilo workflow` and open a PR. Because it is mostly markdown, the review bot will skip most of it, so ask for a human review. That's the first rule of [Pull requests and review](/workflow/pull-requests) in action.

## What to leave out

Adopt the whole loop, but drop what doesn't apply:

- **No backward compatibility** is a pre-production rule. Delete that block from `AGENTS.md` once real users depend on your API or data.
- **release-please** fits apps that deploy from `main`. A library that publishes on tags may prefer a changelog gate in CI instead. See [Releases](/delivery/releases#libraries).
- **Mobile apps** need one extra rule in `AGENTS.md`: say whether a change ships as an over-the-air patch or needs a store release.
