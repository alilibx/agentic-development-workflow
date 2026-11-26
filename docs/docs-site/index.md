# The docs site

Every project has a [VitePress](https://vitepress.dev) site in `docs/`, deployed on every merge. It is where the team, QA, and the agent go to learn how the product works, so it has to be true.

## Layout

```
docs/
├─ .vitepress/
│  ├─ config.mts          # nav, sidebar, Mermaid, local search
│  └─ theme/              # default theme + brand colours
├─ index.md               # home: hero + links into each section
├─ getting-started.md     # clone, install, run, check
├─ engineering/           # the SDLC: this manual, adapted to the project
│  ├─ index.md            # lifecycle diagram + guiding principles
│  ├─ task-flow.md  branching.md  code-review.md
│  ├─ environments.md  ci-cd.md  release-process.md  migrations.md
├─ api/<module>.md        # per-module API reference: functions, args, returns
├─ flows/                 # business flows as Mermaid diagrams
├─ modules/               # module overviews: data, architecture
├─ qa/                    # QA home, roadmap, test-cases/<module>.md
└─ superpowers/           # specs, plans, research (excluded from the build)
```

The [starter](https://github.com/alilibx/manzilo-workflow/tree/main/templates/docs) has the config, theme, home page, engineering stubs, QA home and a test-case template.

```sh
cd docs
bun install
bun run dev      # local preview
bun run build    # what CI runs
```

## Writing conventions

- **Diagrams in Mermaid,** in the page, next to the text they explain: `flowchart` for flows and pipelines, `sequenceDiagram` for integrations, `gitGraph` for branching, `stateDiagram` for statuses.
- **Be honest about what isn't built yet.** Any page that describes something unbuilt (a per-PR backend, branch protection, an approval gate) carries a callout:

  ```markdown
  ::: warning Not built yet
  Previews share the staging backend until ABC-212 lands.
  :::
  ```

- **The workflow file is the source of truth for CI.** Its comments give the reason for each step; the page describes what it does and links to the file.
- **Give headings that other pages link to an explicit anchor**, `## Rollback {#rollback}`, so the link survives a heading rename.
- **Every page is in the sidebar.** A page missing from the sidebar effectively doesn't exist.
- **No secrets, real people's details, or client data,** including in examples and screenshots. Use obvious placeholders (`+971500000001`).

## Keeping it true

- **Docs change in the same PR as the code.** A PR that changes behaviour updates the API reference, the flow, and the QA test cases for that behaviour.
- **`docs-auditor` runs before a task** (to learn what the docs claim) **and after it** (to find what's now wrong). See [Sub-agents](/claude/agents).
- **QA test-case IDs never change.** Add new ones; retire old ones in place.
- **CI builds the site on every PR,** so a broken page fails before it merges.
- **Remember the review-bot gap.** If the bot skips markdown, a docs-only PR needs a human or local review.

## Deploying

::: code-group
```yaml [GitHub Pages]
# .github/workflows/docs.yml: build on PRs, deploy on main
on:
  push: { branches: [main], paths: ['docs/**'] }
  pull_request: { paths: ['docs/**'] }
permissions: { contents: read, pages: write, id-token: write }
jobs:
  build:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: docs } }
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
      - run: bun install --frozen-lockfile
      - run: bun run build
      - uses: actions/upload-pages-artifact@v3
        if: github.event_name != 'pull_request'
        with: { path: docs/.vitepress/dist }
  deploy:
    if: github.event_name != 'pull_request'
    needs: build
    runs-on: ubuntu-latest
    environment: { name: github-pages }
    steps:
      - uses: actions/deploy-pages@v4
```
```json [Vercel (docs/vercel.json)]
{
  "buildCommand": "vitepress build",
  "outputDirectory": ".vitepress/dist"
}
```
:::

For GitHub Pages, set `base: '/<repo>/'` in `config.mts`. For private projects, put the site behind your host's authentication rather than relying on an unguessable URL.
