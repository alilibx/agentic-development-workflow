# Sub-agents

A sub-agent runs a task in its **own context** and returns only its conclusion. Use them for anything that reads more than it decides: searches, audits, reviews, multi-step research. The main session keeps its context for decisions and for talking with the developer.

## The rules

- **Delegate research, exploration and review.** Reading across many files belongs in a sub-agent.
- **Use direct tools for small lookups**, where the answer is one or two reads away. Spawning an agent for that wastes more than it saves.
- **Run independent agents in parallel**, in one message.
- **Brief them like a peer.** A sub-agent knows only its prompt: give it the goal, what you've ruled out, the files to read, and the scope. Ask for `file:line` evidence.
- **Don't hand it your conclusion.** An agent given a hypothesis tends to confirm it. To get a review that isn't anchored on your view, give it the code, not your verdict.
- **Check what comes back.** Its mistakes arrive in the same confident tone as its findings.

## The agents we use

Three are in the [templates](https://github.com/alilibx/manzilo-workflow/tree/main/templates/.claude/agents). `Explore` and `general-purpose` are built into Claude Code.

| Agent | When | Returns |
|---|---|---|
| `Explore` (built in) | Surface mapping: one per surface, in parallel | Where the change ripples, with `file:line` |
| `docs-auditor` | **Before** a task (what do the docs say?) and **after** it (what's now wrong?) | Stale sentences, quoted, with what's true now |
| `code-reviewer` | After an implementation step, at task boundaries, before pushing | Ranked findings with a concrete failure for each |
| `security-reviewer` | Before the PR on any trust-boundary change | Findings with a concrete attack for each |
| `general-purpose` (built in) | Multi-step research | A brief, often written to a file |

## Build, then review, in separate contexts

For larger work, one agent implements and the lead session reviews its result before anything moves on. The implementer's context is full of its own reasoning; the reviewer reads the diff fresh. **This lead review is mandatory**, and it isn't replaced by the review bot later. It's the cheapest place to catch a defect.

## When not to review

After `gh pr create`, don't send a reviewer at the PR diff; the review bot does that. See [Pull requests and review](/workflow/pull-requests#don-t-review-the-same-pr-twice).
