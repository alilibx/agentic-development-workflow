# CLAUDE.md and AGENTS.md

`CLAUDE.md` is loaded into every Claude Code session in the repo. It is the one place to tell the agent how this project works.

## Write it once, for every agent

Put the rules in **`AGENTS.md`**, and make `CLAUDE.md` one line that imports it:

```markdown
@AGENTS.md
```

Codex, Cursor and other agents read `AGENTS.md` directly, and Claude reads it through the import, so there's one file to keep current. (A symlink works too, but the import also survives Windows checkouts.)

## The layers

| File | Scope | Holds |
|---|---|---|
| `~/.claude/CLAUDE.md` | You, in every project | Personal preferences: how you like answers, your shell, tools you always use. **No project rules.** |
| `<repo>/AGENTS.md` (via `CLAUDE.md`) | Everyone in this repo | The workflow, standards, surfaces, skills by area |
| `<repo>/<package>/CLAUDE.md` | Work inside that package | Gotchas specific to that package |
| `.claude/settings.local.json` | You, in this repo | Personal permission allows. **Gitignored.** |

Nested files are for **"gotchas that bit us twice"**: run the UI-kit CLI from inside the app folder, not the root; `bun test` strips types, so run `tsc` too; mutations must use the shared builder, and a test enforces it. If something is true for the whole repo, it belongs in the root file.

## What goes in the root file

The [template](https://github.com/alilibx/manzilo-workflow/blob/main/templates/AGENTS.md) has these sections, in this order:

1. **Project at a glance.** One paragraph, plus a table of packages with the commands that check each one. The commands are the most important line in the file: they define "works".
2. **Domain rules that must never break.** Money is integer minor units. Only one service writes ledger rows. "Is this allowed?" is answered in exactly one place.
3. **Workflow.** Tracker, branching, Conventional Commits, one change per PR, review, CI-only deploys, specs. Each point links to the full page in `docs/engineering/`.
4. **Surface mapping.** The table of surfaces and the three-step process.
5. **Engineering standards.** Before, while and after writing code; no backward compatibility (pre-production); side-effect gating; migrations.
6. **Docs stay in sync.**
7. **Skills and agents.** Which skill to load for which folder.
8. **Honesty.**
9. **Attribution.**

## Writing rules that hold

- **Phrase rules as overrides of a habit.** "Do NOT add optional arguments whose only purpose is to avoid breaking existing callers. Just update the callers." works better than "keep the API clean", because it names the exact thing the model would otherwise do.
- **Give the reason.** "No co-author trailers: the host rejects deploys from unknown git authors." A rule with a reason gets applied to cases the rule didn't list.
- **Point to the source of truth instead of copying it.** "Branching: see `docs/engineering/branching.md`" stays correct when the page changes; a pasted copy goes stale.
- **Keep it short.** Every line costs context in every session. If a section grows past a screen, move the detail into a doc page or a skill and link to it.
- **Fence vendor-managed blocks.** If a tool writes into your `CLAUDE.md` (`<!-- vendor-start --> … <!-- vendor-end -->`), leave its block alone and write your rules outside it.
- **State precedence when files conflict.** If a nested file says "only touch this app" and the root says "every affected surface is in scope", say which one wins.

## Attribution

Pick one policy, and set it in both the settings file and `AGENTS.md`. Ours: commits and PRs carry no AI co-author trailer and no "generated with" footer. Some hosts reject deploys from git authors they don't recognise, and the human who merges owns the change.

```json
{ "attribution": { "commit": "", "pr": "", "sessionUrl": false } }
```

Squash merges copy `Co-authored-by` trailers from branch commits, so keep them out of the branch commits too.
