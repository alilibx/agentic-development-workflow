# Manzilo Workflow

How we take a change from a tracker issue to production, with [Claude Code](https://docs.claude.com/en/docs/claude-code) doing much of the work. It is written as a manual that any project can adopt, with templates you can copy.

**Read it:** https://alilibx.github.io/manzilo-workflow/

## What's here

| Path | What it is |
|---|---|
| `docs/` | The manual (VitePress) |
| `templates/` | Files to copy into a project: `AGENTS.md`, `.claude/` (settings, hook, `/task` skill, agents), `.githooks/`, GitHub workflows and templates, release-please, CodeRabbit, a docs-site starter |
| `scripts/adopt.sh` | Copies `templates/` into a project without overwriting anything |

## Adopt it

```sh
git clone https://github.com/alilibx/manzilo-workflow
manzilo-workflow/scripts/adopt.sh /path/to/your-project
```

Then follow [Adopt it in a project](https://alilibx.github.io/manzilo-workflow/guide/adopt).

## Work on the manual

```sh
bun install
bun run dev          # http://localhost:5173/manzilo-workflow/
bun run build
bash templates/.githooks/pre-commit.test.sh
```

Changes go through a branch and a PR, like everything else this manual describes.

## License

[MIT](LICENSE)
