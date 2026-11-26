# Engineering standards

We are not optimizing for "ship it fast". We are optimizing for code that a senior engineer at a top-tier company would approve. Speed comes from getting the design right, not from skipping the design step.

These are the defaults for every task, for humans and agents alike. They live in `AGENTS.md`, so the agent loads them every session. Each one is phrased to override a habit that models, and people, fall into.

## Before writing code

- **Load the skill for the tech you're touching.** If a skill exists for your backend, UI kit or router and you skip it, you're guessing. See [Skills](/claude/skills).
- **Read the official docs for the pinned version.** When the API in your head doesn't match the version in your lockfile, the docs win, not memory, and not a similar library. Check the version, then check that the API exists in that version.
- **Use the documented pattern.** Data-fetching libraries, form libraries and backends all document how to do the common things. Match the documented pattern unless there's a specific, named reason not to.
- **Read before you create.** Before adding a function, read the module it belongs to: every file in the domain, not just the first search hit. Pick the right shape for this case: extend, split, rename, replace or add. There's no blanket "always extend" rule. If you add something new, say in the PR why the existing code didn't fit. This rule exists because duplicate functions got written when existing ones already did the job.

## While writing code

- **Fix root causes, not symptoms.** A bug at three call sites usually lives in the shared code they use. Fix it there, so the next caller doesn't hit it.
- **Don't copy the hacks you find.** Silent failures (`catch { return null }`), `as any`, unvalidated boundaries, and error states the UI never reads are debt. When you meet one, fix it properly instead of building on it.
- **Widen types the proper way.** When a framework type is too narrow, use module augmentation for an `interface`, or a narrow runtime check where you read the value. Never `as any` or `@ts-ignore`.
- **Comment the *why*, with a source.** When a choice would surprise a reader, leave one line with the reason and a link: "v5's `prepareSecondFactor`, because v6's `sendEmailCode` doesn't exist in our pinned version." That's the only kind of comment we want.
- **Name the incident.** Guards in workflows, hooks and code carry the issue or PR that made them necessary. A future reader who wants to delete the guard can read why it exists.

## Pre-production: no backward compatibility

Until real users depend on your data or API, backward-compatibility thinking only adds weight: duplicate functions, optional arguments kept for old callers, dead flags, renamed fields kept "just in case", and deprecation wrappers that never get removed.

- No shims, deprecation wrappers, feature flags or duplicate functions to preserve old behaviour.
- No optional arguments whose only job is to avoid touching existing callers. Update the callers.
- No aliases for renamed or removed fields. Delete them and update every reference.
- Make a breaking change cleanly, and update every call site in the same PR. **The compiler is your migration plan.**
- When you find existing cruft, fix it if the fix is safe and in scope. Flag it if the fix is large.

::: warning After launch
Delete this rule once you have real users. Stored data then needs [migrations](/delivery/migrations), and public APIs need versioning.
:::

## Before claiming done

- **Run the typecheck and the build.** Don't write "it should compile". If the type system can check it, check it.
- **Exercise UI changes** in a browser or on a device. A passing build is not a test plan.
- **Push back on wrong reviews** with the version, the docs link and the reason. Agreeing just to clear a comment is the same mistake whether the reviewer is a person or a bot.

## Honesty

The agent is told to be a senior peer, not a yes-man. The same goes for people.

- No praise without a technical reason. "Great idea" carries no information.
- Don't validate a decision because it was stated confidently.
- If a plan has a flaw, say so **before** building it. If there's a simpler way, say so unasked.
- Rate work honestly: bad is bad, mediocre is mediocre.
- Report outcomes as they are. Failing tests, skipped steps and unverified claims all get said out loud.

> **The test:** if a response would make the author feel better without making the code or product better, rewrite it.
