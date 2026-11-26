# Templates

Everything under [`templates/`](https://github.com/alilibx/manzilo-workflow/tree/main/templates) can be copied into a project with:

```sh
scripts/adopt.sh /path/to/your-project
```

It never overwrites existing files. See [Adopt it in a project](/guide/adopt) for what to fill in afterwards.

## Agent instructions

| File | What it is | Page |
|---|---|---|
| [`AGENTS.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/AGENTS.md) | The rules for humans and agents, with placeholders | [CLAUDE.md and AGENTS.md](/claude/claude-md) |
| [`CLAUDE.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/CLAUDE.md) | `@AGENTS.md`: one line | |

## Claude Code

| File | What it is | Page |
|---|---|---|
| [`.claude/settings.json`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.claude/settings.json) | Attribution off, plus the PR-lifecycle hook | [Hooks](/claude/hooks) |
| [`.claude/hooks/pr-lifecycle.sh`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.claude/hooks/pr-lifecycle.sh) | Review policy after `gh pr create`; `/task done` after `gh pr merge` | [Hooks](/claude/hooks) |
| [`.claude/skills/task/SKILL.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.claude/skills/task/SKILL.md) | `/task`, `/task start`, `/task done` | [The task loop](/workflow/task-loop) |
| [`.claude/agents/docs-auditor.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.claude/agents/docs-auditor.md) | Docs drift, before and after a task | [Sub-agents](/claude/agents) |
| [`.claude/agents/code-reviewer.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.claude/agents/code-reviewer.md) | Review before the PR | [Sub-agents](/claude/agents) |
| [`.claude/agents/security-reviewer.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.claude/agents/security-reviewer.md) | Trust-boundary review | [Sub-agents](/claude/agents) |

## Git

| File | What it is | Page |
|---|---|---|
| [`.githooks/pre-commit`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.githooks/pre-commit) | Refuses commits on `main` | [Branching](/workflow/branching#the-pre-commit-hook) |
| [`.githooks/pre-merge-commit`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.githooks/pre-merge-commit) | The same check for `git merge` | |
| [`.githooks/pre-commit.test.sh`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.githooks/pre-commit.test.sh) | 14 checks against scratch repos: `bash .githooks/pre-commit.test.sh` | |

## GitHub

| File | What it is | Page |
|---|---|---|
| [`.github/workflows/ci.yml`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.github/workflows/ci.yml) | PR gate: checks, fresh generated code, docs build | [CI/CD](/delivery/ci-cd) |
| [`.github/workflows/main.yml`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.github/workflows/main.yml) | CI → staging → release-please → production | [CI/CD](/delivery/ci-cd) |
| [`.github/workflows/deploy.yml`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.github/workflows/deploy.yml) | Deploy, migrate, verify the revision; production takes tags only | [CI/CD](/delivery/ci-cd#verify-what-is-live) |
| [`.github/pull_request_template.md`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.github/pull_request_template.md) | The rules as checkboxes | [Pull requests](/workflow/pull-requests) |
| [`.github/CODEOWNERS`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.github/CODEOWNERS) | A maintainer reviews everything | |
| [`.github/dependabot.yml`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.github/dependabot.yml) | Monthly updates for GitHub Actions only | |
| [`.coderabbit.yaml`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.coderabbit.yaml) | Strict review bot with per-folder rules | [Pull requests](/workflow/pull-requests#the-review-bot) |
| [`release-please-config.json`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/release-please-config.json), [`.release-please-manifest.json`](https://github.com/alilibx/manzilo-workflow/blob/main/templates/.release-please-manifest.json) | Versions and changelog from commit titles | [Releases](/delivery/releases) |

## Docs site

| Folder | What it is | Page |
|---|---|---|
| [`docs/`](https://github.com/alilibx/manzilo-workflow/tree/main/templates/docs) | VitePress starter: config, theme, home, engineering stubs, QA home, test-case template, `superpowers/` folders | [The docs site](/docs-site/) |
