# QA home

How we test, where test cases live, and how to report a bug.

| Layer | Where |
|---|---|
| Test-case library | `qa/test-cases/<module>.md`, IDs like `MOD-001` |
| Testing roadmap | `qa/roadmap.md` |
| Release sign-off | A checklist comment on the release PR, naming the staging commit tested |
| Answers to a QA round | `qa/rounds/<round>.md` |
| Bug reports | `<tracker team / project, or the QA workbook>` |

## Reporting a bug

Report bugs as you find them; don't batch them. Check the known limitations first. Give the test-case ID, the environment, the steps, the expected result (quote the case), what actually happened, and screenshots. Say whether it blocks a release.

## Known limitations: don't report these

| Limitation | Tracked in |
|---|---|
| `<limitation>` | `<issue>` |
