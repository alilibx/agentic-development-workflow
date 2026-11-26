---
name: task
description: Tracker task flow. Pick what to work on next, claim it, and close it out. Use when a developer asks "what's next" or "what should I work on", wants to start an issue, or has finished one (PR merged). Modes - /task (recommend next), /task start ABC-123 (claim), /task done [ABC-123] (completion ritual and next pick).
---

# Task flow

This file is the executable source of truth for picking, claiming and closing tracker work. The human contract is `docs/engineering/task-flow.md`. Replace `ABC` with your issue key, `<team>` with your tracker team, and "the tracker owner" with the person who grooms the board.

## Data access

Use the tracker's MCP tools (Linear team `<team>`). If the MCP is unavailable, fall back to the tracker CLI. If neither works, say so and stop. Never answer "what's next" from memory, and never invent priorities.

"Me" is the developer in this session. Match them to a tracker user through `git config user.name` / `user.email`. If that is ambiguous, ask.

Priority order everywhere: Urgent (1), High (2), Medium (3), Low (4), None (0).

## Mode: `/task` (recommend; read-only, no tracker writes)

1. **WIP guard first.**
   - My issues **In Progress**: the answer is "resume <issue>", in cascade order. This is a hard guard: offer no new pick unless the developer overrides it. More than 2 issues in flight is a smell; say so.
   - My issues **In Review**: list them first with a "chase the review" nudge. This is a soft guard: continue to a new pick.
2. **Build the pickable set.** An issue qualifies only if all of these hold:
   - its project belongs to an initiative whose status is **Active**;
   - its project status is **started** or **planned** (started ranks first);
   - the issue state is **Todo** (Backlog is not ready);
   - it has no open "blocked by" relation;
   - it is assigned to me or unassigned, never someone else;
   - it was updated in the last 90 days;
   - it is not archived.
3. **Order the set.**
   1. Initiative priority, then the earlier initiative target date.
   2. Project status (started before planned), then project priority, then the nearest project target date.
   3. Issue priority, then due date, then the oldest creation date.
   4. At equal rank, issues assigned to me come before unassigned ones.
4. **Present.**
   - The top pick, with the path spelled out: "<initiative> is the top Active initiative, <project> is its highest-ranked project, and this is its highest-priority unblocked Todo."
   - Up to 2 runners-up, one line each.
   - A **triage footnote** for the tracker owner: in-scope issues untouched for more than 90 days, and Urgent or High issues with no project. Never recommend or change these.
   - If nothing qualifies, say so, show what sits just outside scope, and send the developer to the tracker owner. Never invent work.

## Mode: `/task start ABC-123` (claim)

1. **Re-read the issue now.** If it is no longer Todo, or someone else took it, say who and offer the runner-up.
2. Assign the developer, set **In Progress**, and add the issue to the current cycle if one is active.
3. Branch from a fresh `main`: `<prefix>/abc-<id>-<short-slug>`, with the prefix from `docs/engineering/branching.md` (`feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, `hotfix/`). The lower-case issue key in the branch name links the PR to the issue.
4. **Brief the developer before any code:** the description and acceptance criteria, linked docs and PRs, and the related QA test cases. Then follow the normal workflow in `CLAUDE.md` (surface mapping, skills, tests).

An explicit `/task start` can skip the cascade (an urgent interruption, a direct instruction). The claim steps are the same.

## Mode: `/task done [ABC-123]` (completion ritual)

Run it after the PR merges. A hook reminds you after `gh pr merge`; after a merge in the GitHub UI, run it by hand. Take the issue from the branch name when it isn't given.

1. Make sure the issue reached **In Review** when the PR opened.
2. Post this comment on the issue:

   ```
   ✅ Shipped: <one-line summary>
   PR: <link> (merged)
   Evidence: <typecheck, build and tests run; QA notes or screenshots>
   Docs: <pages updated | "no docs affected">
   Follow-ups: <proposed to the tracker owner | "none">
   ```

3. Set the issue to **Done**.
4. Propose follow-ups to the tracker owner, in the comment and in chat. Never create issues yourself.
5. Run `/task` right away and offer the next pick.

## Hard rules

- The writes listed under `start` and `done` are the only tracker writes this skill makes.
- Never reassign someone else's issue, change priorities, edit projects, initiatives or cycles, or close an issue outside the done ritual.
- When you open a PR for a claimed issue, move the issue to In Review.
