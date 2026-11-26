# Skills

A skill is a folder with a `SKILL.md`: a name, a description that says **when** to use it, and instructions. Claude loads the instructions only when a task matches the description, so skills cost almost no context until they're needed.

## Two kinds

| Kind | Example | Where |
|---|---|---|
| **Procedures** | `/task`: pick, claim and close tracker work | `.claude/skills/` in the repo, so everyone runs the same one |
| **Knowledge** | Your backend framework, router, UI kit, design system | Installed globally, or vendored into the repo when it's project-specific |

## Load the skill before the work

`AGENTS.md` maps folders to skills:

```markdown
## Skills to load by area
- **`app/` (UI)**: `/design-system`, `/ui-kit`, `/router`. Never pick a colour, size or spacing from memory.
- **`api/`**: `/backend-framework`.
```

If a skill exists for the code you're touching and you skip it, you're guessing. Loading it is step one, not the whole job: still read the official docs for the specific component or API you're using, for the pinned version.

## Writing a procedure skill

The [`/task` skill](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/.claude/skills/task/SKILL.md) shows the shape:

- **The description names the triggers:** "Use when a developer asks what's next, wants to start an issue, or has finished one."
- **Modes**, each with numbered steps.
- **A data-access rule:** which tool to use, what to fall back to, and "if neither works, say so and stop; never answer from memory."
- **Hard rules:** the complete list of writes it may make, and what it must never do.
- **A human contract** in `docs/engineering/` that links to the skill. The skill is the executable truth; the page explains it.

## Writing a design-system skill

If the project has a design system, ship it as a skill whose instructions are **rules, not values**:

- "Read these first, in order": tokens, components, guidelines, page templates.
- "Read the value from the token file; never copy one out of this skill", so the skill can't go stale when the tokens change.
- Non-negotiables: one source-of-truth app; other apps mirror its components; the exported reference is never edited by hand.
- **When to break the mirror.** A mirror rule needs its exception written next to it: an ops-only screen with no counterpart in the main app, or a component the second app genuinely can't share. Without the exception, people either copy things that shouldn't be copied or stop mirroring altogether.

## Install skills from the stack's community

Many frameworks publish agent skills. Install them globally once (`npx skills add <owner>/<repo>@<skill> -g`) and list them in `AGENTS.md` so a new teammate knows to install them too.

## Process skills come from a plugin

The procedures for *how* to work, as opposed to what a stack needs, come from the [superpowers](https://github.com/obra/superpowers) plugin. The ones this workflow leans on:

| Skill | Used for |
|---|---|
| `brainstorming` | Turning a request into an approved spec, in `docs/superpowers/specs/` |
| `writing-plans` | The implementation plan, in `docs/superpowers/plans/` |
| `test-driven-development` | The failing test first, in each plan task |
| `systematic-debugging` | Evidence before a fix, for bugs with an unknown cause |
| `verification-before-completion` | Running the checks before claiming done |
| `using-git-worktrees` | One worktree per branch |

The repo's rules and your [global rules](/claude/global) beat a plugin skill where they disagree. For example, `finishing-a-development-branch` offers a local merge; this workflow only merges through a PR.

## Core skills {#core-skills}

<!-- A later change fills this in from real usage data: which skills are loaded most, per kind of task. Don't guess the list. -->

::: info Coming
A short list of the skills that do most of the work, measured from usage, will go here.
:::

## Keep the skill list lean

- **Turn skills off; don't delete them.** `skillOverrides` in `~/.claude/settings.json` switches a skill off by name, and keeps it installed for the day you want it back:

  ```json
  { "skillOverrides": { "<skill-name>": "off" } }
  ```

  Every enabled skill's description costs context in every session, and a near-match can load the wrong one.
- **Share skills between agents.** Keep your own skills in one folder, such as `~/.agents/skills/`, and symlink each into `~/.claude/skills/`. Other coding agents that read skills from a folder can then use the same copies, and an edit lands in all of them:

  ```sh
  ln -s ~/.agents/skills/<skill> ~/.claude/skills/<skill>
  ```
