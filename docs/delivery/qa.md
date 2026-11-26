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

## Release sign-off {#release-sign-off}

QA completes this on **staging** and posts it as a **comment** on the release PR, not in the PR body: release-please rewrites the body on every run, and ticked boxes there are lost. **An incomplete checklist is an automatic reject.**

The comment names the staging commit QA tested (the deploy alert and the health endpoint both show it). The release PR is merged only while `main` is still at that commit. If anything merged since, its flows are re-checked on staging and QA posts a new comment with the new SHA. See [Releases](/delivery/releases).

```markdown
**Signed off on staging at:** <commit SHA>

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
- [ ] Changed screens work at the narrowest supported width (<320 px, or your floor>)

**Environment**
- [ ] The staging ribbon is visible
- [ ] `main` is green in CI
- [ ] Production's environment is set for go-live: `APP_ENV=production` exactly, and each integration's send mode is `live`
```

Name the narrowest width you support (320 px is a common floor) instead of "phone-size", so the check has an answer.

## After a QA round {#after-a-qa-round}

QA's results live in QA's own system of record (a workbook, a test-management tool). Development answers each round in writing, in `qa/rounds/<round>.md` ([template](https://github.com/alilibx/agentic-development-workflow/blob/main/templates/docs/qa/rounds/_template.md)):

- **Every defect, mapped.** QA's defect ID, the tracker issue it became, and its status: fixed and ready to retest, still open, or won't fix (with the reason).
- **"Fixed, not browser-confirmed" is said out loud.** A fix proven only by tests is flagged, so QA knows to read before re-testing.
- **Severity re-rates and scope decisions,** with who decided.
- **A regression list for the next round:** the flows the fixes touched.

Then update **QA's system of record**, not a copy: the status and a one-line comment per defect, with the tracker link. If it's a file, upload a new version of the same file, so QA keeps one link and the history.

## After a release

Run a short manual smoke test on production: sign in, open the home screen, open one record of each main type. A failure means [rollback](/delivery/releases#rollback), not debugging live.
