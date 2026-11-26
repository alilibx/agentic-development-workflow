## What this changes

<!-- What changed and why. Link the tracker issue (ABC-123). -->

## How it was tested

<!-- Commands run and their result. Screenshots or a recording for UI. -->

## Checks

Tick what applies; explain anything you can't tick.

- [ ] The title follows Conventional Commits (`feat(scope): …`, `fix(scope): …`).
- [ ] The checks for every touched package pass (see AGENTS.md).
- [ ] New behaviour has tests.
- [ ] Every affected surface is updated, or its deferral is agreed in the issue.
- [ ] Docs, including QA test cases, describe the new behaviour.
- [ ] New outbound side effects are gated off outside production.
- [ ] No secrets or real people's data in code, tests or screenshots.
- [ ] Deploy notes: new env vars, secrets or manual steps are in `docs/engineering/`.
