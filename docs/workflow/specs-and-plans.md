# Specs and plans

Anything bigger than a fix starts as a written design that is committed to the repo, not discussed in chat and lost.

| Folder | File | What it is |
|---|---|---|
| `docs/superpowers/specs/` | `YYYY-MM-DD-<topic>-design.md` | The approved design: why, what, and what not |
| `docs/superpowers/plans/` | `YYYY-MM-DD-<feature>.md` | The implementation plan: tasks, files, tests |
| `docs/superpowers/research/` | `YYYY-MM-DD-<topic>-research.md` | Sourced research that feeds a spec (optional) |
| `docs/superpowers/runbooks/` | `<KEY-id>-<topic>.md` | The deploy steps for one change, when it needs manual steps, a strict order or a one-off migration |

The folder name comes from the [superpowers](https://github.com/obra/superpowers) Claude Code plugin. Its brainstorming skill writes specs there, and its writing-plans skill writes plans there. The format works without the plugin.

Specs are **living documents**. If a PR changes behaviour a spec describes, it updates the spec in the same PR. A spec that replaces part of another says so in its second paragraph.

## Spec

```markdown
# <Feature>: design

Date: 2026-11-18. Tracker: ABC-385. Status: approved to build (owner, 2026-11-18).

Decisions marked **(builder's call)** were made while writing this up and were not
asked of the owner; the owner can overturn any of them. Everything else was agreed.

## 1. Why
## 2. Goals, non-goals, anti-goals
## 3. Constraints and facts
## 4. Architecture
## 5. User flows
## 6. API and data (outline; the builder designs the details)
## 7. Testing
## 8. Open questions
```

Two conventions pay for themselves:

- **`(builder's call)`** marks a decision the agent or developer made without asking. The owner can see at a glance what to check.
- **Anti-goals** are outcomes that "would be a failure even if it technically works". For example: "a payment screen that needs more than one tap to confirm".

## Plan

```markdown
# <Feature> implementation plan

**Goal:** <one paragraph>
**Architecture:** <one paragraph>
**Tech stack:** <pinned versions>
**Spec:** `docs/superpowers/specs/2026-11-18-<topic>-design.md` (read it first).

## Global constraints
- <invariants every task must keep, e.g. "money is integer fils">
- Checks before claiming done: `<commands>`

## Review focus
1. **<edge case>** → <required outcome>. Tested in Task 2.

## File structure
<every file to create or change, by package, with the task that touches it>

### Task 1: <name>
- [ ] **Step 1:** write the failing test …
- [ ] **Step 2:** …
```

**Review focus** names the edge cases a reviewer must check, and ties each one to the test that covers it.

## Runbooks {#runbooks}

A change whose deploy isn't "merge and CI does the rest" gets a runbook: manual steps, an order that matters, a one-off migration, a vendor setting to flip. It is **read before the deploy, not during it**, and says:

- each step, in order, with the exact command;
- why the order matters;
- what fails if a step is skipped;
- how to check each step worked.

The PR's deploy notes link it. Delete it once the change has reached every environment; the PR keeps the history.

## Research notes

Every claim carries a URL. `UNKNOWN` marks anything that couldn't be checked against vendor docs or source. The spec links to the note rather than copying it.

## Architecture decisions

For a decision that shapes the whole system, add a page under `docs/engineering/` in ADR form: **Context, Decision, Rationale, Consequences, Migration**. Link it from `AGENTS.md`, and from the review bot's `path_instructions` if the bot should enforce it.
