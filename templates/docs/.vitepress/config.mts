import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

// Every new page goes in the sidebar below. docs-auditor checks this.
export default withMermaid(defineConfig({
  title: '<Project> Docs',
  description: '<One line: what the product is>',
  // srcDir defaults to this folder (docs/). superpowers/ holds specs, plans and
  // runbooks; they are read in the repo, not published.
  srcExclude: ['superpowers/**', 'README.md'],
  lastUpdated: true,
  cleanUrls: true,
  mermaid: { theme: 'default' },
  mermaidPlugin: { class: 'mermaid-diagram' },
  themeConfig: {
    nav: [
      { text: 'Getting started', link: '/getting-started' },
      { text: 'Engineering', link: '/engineering/' },
      { text: 'QA', link: '/qa/' },
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Getting started', link: '/getting-started' },
        ],
      },
      {
        text: 'Engineering',
        items: [
          { text: 'Overview', link: '/engineering/' },
          { text: 'Task flow', link: '/engineering/task-flow' },
          { text: 'Branching and commits', link: '/engineering/branching' },
          { text: 'Code review', link: '/engineering/code-review' },
          { text: 'Environments', link: '/engineering/environments' },
          { text: 'CI/CD', link: '/engineering/ci-cd' },
          { text: 'Releases', link: '/engineering/release-process' },
          { text: 'Migrations', link: '/engineering/migrations' },
          { text: 'QA process', link: '/engineering/qa-process' },
        ],
      },
      {
        text: 'QA',
        items: [
          { text: 'QA home', link: '/qa/' },
          { text: 'Testing roadmap', link: '/qa/roadmap' },
          { text: 'Test case template', link: '/qa/test-cases/_template' },
          { text: 'QA round template', link: '/qa/rounds/_template' },
        ],
      },
      // Add: { text: 'API reference', items: [...] }, { text: 'Flows', items: [...] }
    ],
    search: { provider: 'local' },
    outline: [2, 3],
    footer: { message: '<Project>' },
  },
}))
