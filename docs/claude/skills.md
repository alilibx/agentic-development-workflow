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

We measured this from four months of our own sessions, across more than twenty repos. A handful of skills do almost all the work:

| Rank | Skill | Kind | What it does in the loop |
|---|---|---|---|
| 1 | `/code-review` | Built in | Reviews a diff, branch or PR at a chosen effort level; `--fix` applies the findings. The most-used skill by far. |
| 2 | superpowers: `brainstorming` → `writing-plans` → `subagent-driven-development` (or `executing-plans`) | Plugin | Spec, then plan, then execution by sub-agents with a review after each task. Together, the backbone of feature work. |
| 3 | superpowers: `systematic-debugging`, `test-driven-development`, `finishing-a-development-branch`, `using-git-worktrees` | Plugin | Bugs, tests first, wrapping up a branch, one worktree per branch. |
| 4 | Repo procedure and design-system skills, such as `/task` and a design-system skill | Repo | The team's own loop and UI rules. They're the heaviest skills by token use, because they run on every task in their area. |
| 5 | Stack skills: backend framework, UI kit, API SDK | Global or repo | Loaded before touching that part of the code. |
| 6 | The tracker skill (`linear` for us) | Global | Issue work outside `/task`. |

Two rules came out of the data:

- **Give one clear rule for when `/code-review` runs.** Most of our review calls came from a global rule that fired after every `gh pr create`, including in repos where a review bot already reviewed the PR. See [Don't review the same PR twice](/workflow/pull-requests#no-second-review) and [the global rule](/claude/global).
- **Write skill names exactly.** The model sometimes called names that don't exist: a plugin skill without its `plugin:` prefix, a name with the wrong case, or a retired command. Name skills in `AGENTS.md` exactly as `/skills` lists them.

A personal style skill, such as one that sets how the agent writes replies, is often among the most-used skills. It belongs in your global setup, not in a repo. [`plain-voice`](https://github.com/alilibx/agentic-development-workflow/tree/main/templates/global/skills/plain-voice) is an example.

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

## Check your setup {#check-your-setup}

Skills, plugins and permissions pile up. Two built-in commands show what you have:

| Command | Runs | Shows |
|---|---|---|
| `/doctor` | Interactively only; `claude doctor` works in a terminal | Install and update problems, sign-in, and permission rules that are broken or broader than they look |
| `/skill-doctor` | Interactively, or headless with `claude -p "/skill-doctor"` | Skills loaded but never used, each skill's token cost, and plugins whose skills you don't use |

What a first run usually finds, and what to do:

- **Skills you never use.** Turn them off with `skillOverrides`. A plugin's skills can't be turned off one by one, so a plugin with many skills you don't use should be disabled outside the work that needs it.
- **The same skill installed twice**, for example in your skills folder and in a plugin. Keep one, or the model picks between near-identical descriptions.
- **Allow rules wider than intended.** A one-off approval such as `Bash(grep -rn "foo.*bar" src)` saves a `*`, which then acts as a wildcard. Prune old one-off rules from `.claude/settings.local.json`.
- **Synced skills.** Skills synced from your claude.ai account come back after a local delete; turn them off in the account instead.
