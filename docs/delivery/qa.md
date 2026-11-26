# QA

Every change is tested twice: once on its own (on the PR preview, or locally), and once together with everything else on **staging** before a release. Production is tagged only after sign-off.

## The QA section of the docs site

QA works from the project's docs site, so the docs are load-bearing: **a stale page means QA tests the wrong thing, which is worse than no page.**

| Page | What it holds |
|---|---|
| `qa/index.md` | Environments, test equipment, how to report a bug, known limitations ("don't report these"), cadence and owners |
| `qa/roadmap.md` | Testing tiers: 0 prerequisites (re-run after every data wipe), 1 the launch gate (ordered flows, each linked to an issue, with exit criteria), 2 hardening, 3 later. Plus a table tracing each flow to its issue and module pages. |
| `qa/test-cases/<module>.md` | One page per module, with test cases that have permanent IDs |

## Test cases

Each module page starts with the routes or screens it covers, its related tracker flow and its prerequisites. Then come numbered sections (`§4.1 Team list`), each with a table:

| ID | Test case | Steps | Expected result |
|----|-----------|-------|-----------------|
| TEAM-001 | View team | Open `/team` | The roster shows admins and managers, then technicians. Each row has a role badge and a status badge (Active / Pending invite). |
| TEAM-031 | (retired by ABC-437) | | Replaced by TEAM-029 and TEAM-030 |

- **IDs are `<MODULE>-<NNN>`**, zero-padded, and **permanent.** Add new ones at the end; never renumber. A retired case keeps its row and says what replaced it. Bug reports and stand-ups quote these IDs.
- **Expected results quote the exact UI copy,** so a wording change shows up as a test change.
- **A PR that changes a user-facing flow updates its test cases in the same PR.** `docs-auditor` checks this.

## Reporting a bug

Report bugs as you find them; don't batch them. Check the known-limitations list first. Include the test-case ID, the environment, the steps, the expected result (quoted from the case), what actually happened, and screenshots. Say whether it blocks a release.

## Release sign-off

QA completes this on **staging**, as a checklist in the release PR. **An incomplete checklist is an automatic reject.**

```markdown
**Core flows** (from the testing roadmap)
- [ ] Sign-up and onboarding
- [ ] <core flow>
- [ ] <core flow>
- [ ] Outbound messages reach only the test recipients; every other send shows as Suppressed
- [ ] Admin panel

**This release**
- [ ] Every PR merged since the last release has had its flow re-checked on staging
- [ ] Every bug fixed since the last release is confirmed fixed here

**Everywhere**
- [ ] No console errors on the main flows
- [ ] Right-to-left and every language render correctly on changed screens
- [ ] Sign-in, sign-out and switching accounts work
- [ ] Phone-size layout on changed screens

**Environment**
- [ ] The staging ribbon is visible
- [ ] `main` is green in CI
```

## After a release

Run a short manual smoke test on production: sign in, open the home screen, open one record of each main type. A failure means [rollback](/delivery/releases#rollback), not debugging live.
