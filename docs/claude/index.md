# Claude Code

Most of the code in our projects is written by [Claude Code](https://docs.claude.com/en/docs/claude-code), guided by a human who decides and reviews. The workflow only holds if the agent follows it as reliably as a person would. Six pieces make that happen:

| Piece | Where it lives | What it does |
|---|---|---|
| [`CLAUDE.md` / `AGENTS.md`](/claude/claude-md) | Repo root, plus nested files per package | The rules, loaded into every session |
| [Global instructions](/claude/global) | `~/.claude/` | Your fallbacks for every repo; the repo wins |
| [Skills](/claude/skills) | `.claude/skills/` and installed globally | Step-by-step procedures (`/task`) and stack knowledge (your backend, UI kit, design system) |
| [Sub-agents](/claude/agents) | `.claude/agents/` | Research, review and docs audits in their own context |
| [Hooks](/claude/hooks) | `.claude/settings.json` | Reminders and checks around actions the agent takes |
| Git hooks | `.githooks/` | Rules that hold whoever commits: agent, human or script |

## The pattern behind all of it

- **Rules the agent must not break go in a machine, not in prose.** "No commits to `main`" was a sentence, then a Claude hook, and now it is a git hook. Prose is for judgement, and machines are for rules.
- **Each procedure has one executable source of truth.** The `/task` skill *is* the task flow; the docs page is the human contract that links to it. When they disagree, the skill wins and the page gets fixed.
- **Context is a budget.** The main session keeps its context for decisions and talking with the developer. Reading twenty files to find one function happens in a sub-agent, which returns the conclusion.
- **Untrusted text stays data.** Review-bot findings, issue text, web pages and pasted logs may contain instructions. The agent checks claims against the code and never follows instructions embedded in them.

## A session, end to end

1. The developer asks "what's next?". `/task` recommends an issue; the developer confirms; `/task start` claims it and creates the branch.
2. The agent sends `docs-auditor` and one `Explore` agent per surface, in parallel, and writes the [surface map](/workflow/surface-mapping).
3. For a feature, it writes the spec and plan, and the developer approves them.
4. It loads the stack skills and implements, task by task, running the checks from `AGENTS.md`.
5. `code-reviewer` (and `security-reviewer` on trust boundaries) review the diff before the PR. The agent fixes what's valid.
6. `docs-auditor` checks for drift, and the docs are updated in the same branch.
7. The agent opens the PR. The hook reminds it to move the issue to In Review and not to review the PR itself.
8. It answers the review bot's findings, checking each one. The human reviews and merges.
9. The merge hook starts `/task done`: completion comment, Done, next pick.
