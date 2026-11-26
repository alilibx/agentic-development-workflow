# Releases

Versions are [SemVer](https://semver.org) tags, `vMAJOR.MINOR.PATCH`. They are cut by [release-please](https://github.com/googleapis/release-please) from the Conventional Commit titles on `main`, never by hand.

## How a change ships

1. **Pull request.** `ci.yml` runs the checks. Nothing is deployed.
2. **Merge to `main`.** `main.yml` runs the checks again and deploys the commit to **staging**. Then release-please opens or updates the release PR (`chore(main): release X.Y.Z`), which bumps the version and writes `CHANGELOG.md` from the commit titles since the last release.
3. **QA signs off on staging** using the [release checklist](/delivery/qa#release-sign-off).
4. **Merge the release PR.** release-please tags `vX.Y.Z` and publishes a GitHub release. The same `main.yml` run deploys that tag to **production**.
5. **Smoke-test production by hand:** sign in, open the main screens. A failure means rollback, not debugging in production.

**Never edit** `CHANGELOG.md`, `.release-please-manifest.json` or package versions by hand. Put this rule in `AGENTS.md`, because agents like to "help" with changelogs.

Before 1.0, `bump-minor-pre-major` makes a `feat` bump the minor version and a `fix` bump the patch. A breaking change also bumps the minor version, until 1.0.

### Setup notes

- Turn on **Settings → Actions → General → Allow GitHub Actions to create and approve pull requests**. release-please needs it to open the release PR.
- The release PR is opened with `GITHUB_TOKEN`, so GitHub doesn't run CI on it. That's fine: it only touches the version files and the changelog, and the code it releases already passed CI on `main`.
- Tags created with `GITHUB_TOKEN` don't start other workflows. That's why production deploys **in the same run** as the release job, not from a separate tag trigger.
- For a monorepo with several versioned packages, use `"release-type": "simple"` with `extra-files` that point at each `package.json`'s `$.version`, so all versions move together.
- If staging itself is broken (an expired key, a provider outage) and production needs a fix: push the tag by hand, run the Deploy workflow for production with that tag, then fix staging.

## Cadence

There's no schedule. Release small and often. Batching a week of changes turns QA sign-off into a rubber stamp and makes rollbacks bigger.

## Rollback

Rollback is always the first response. It's faster than a fix.

- **Frontends** on Vercel or Netlify: instant rollback to the previous deployment, in seconds.
- **Everything else:** run the Deploy workflow by hand for `production` with the **previous** tag.
- Then write a short incident note, and fix forward on a branch.

::: warning Schema changes can't always be rolled back
A release that changed stored data may not be safe to roll back. That's why [migrations](/delivery/migrations) are split into additive steps, and why releases stay small.
:::

## Hotfix

`main` is always releasable, so the fast path is the normal path, done quickly:

1. Branch `hotfix/abc-123-…` from `main`, with a minimal fix and a test.
2. PR. CI and the review bot still run; ask the reviewer for a fast review.
3. Merge, check it on staging, and merge the release PR straight away.

If `main` holds work that must not ship yet, **revert it on `main` first** (a normal revert PR), then hotfix. Don't tag a commit that isn't on `main`. release-please computes versions from `main`'s history, and a side-branch tag knocks it out of step.

### Break-glass

When production is down and the only reviewer can't be reached:

1. Open the hotfix PR as above. CI and the review bot still run.
2. An admin merges it without the human approval.
3. The PR description says what the incident is and why the reviewer couldn't be reached, and tags them for review after the fact.
4. Ship through the normal release.

The principle: **automated gates (CI, the review bot, smoke tests) are never skipped.** Only the human-availability gate is, and only during a logged emergency.

## Libraries

A library or CLI that publishes artifacts may prefer to cut releases by hand:

- A hand-written `CHANGELOG.md` with an `(unreleased)` section, plus a CI gate that fails a PR that changes shipped source without adding a changelog line (escape label: `skip-changelog`).
- A tag `vX.Y.Z` triggers `release.yml`. It checks the tag against every package version and a dated changelog section, builds, smoke-tests the artifact **without a source checkout**, publishes, then installs it the way users do.
- Pre-release tags (`vX.Y.Z-rc.N`) rehearse the whole pipeline.

Use release-please **or** a changelog gate, not both.
