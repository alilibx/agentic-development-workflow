import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

const repo = 'https://github.com/alilibx/agentic-development-workflow'

export default withMermaid(defineConfig({
  srcDir: 'docs',
  base: '/agentic-development-workflow/',
  title: 'Manzilo Workflow',
  description: 'How we take a change from a tracker issue to production, with Claude Code doing much of the work. A manual any project can adopt.',
  lang: 'en',
  cleanUrls: true,
  lastUpdated: true,
  head: [['meta', { name: 'theme-color', content: '#0f766e' }]],
  mermaid: {
    theme: 'default',
    themeVariables: { fontFamily: 'ui-sans-serif, system-ui, sans-serif' },
  },
  mermaidPlugin: { class: 'mermaid-diagram' },
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/' },
      { text: 'Workflow', link: '/workflow/task-loop' },
      { text: 'Delivery', link: '/delivery/environments' },
      { text: 'Claude Code', link: '/claude/' },
      { text: 'Templates', link: '/templates/' },
    ],
    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'What this is', link: '/guide/' },
          { text: 'Adopt it in a project', link: '/guide/adopt' },
          { text: 'Engineering standards', link: '/guide/standards' },
        ],
      },
      {
        text: 'Workflow',
        items: [
          { text: 'The task loop', link: '/workflow/task-loop' },
          { text: 'Branching and commits', link: '/workflow/branching' },
          { text: 'Pull requests and review', link: '/workflow/pull-requests' },
          { text: 'Surface mapping', link: '/workflow/surface-mapping' },
          { text: 'Specs and plans', link: '/workflow/specs-and-plans' },
        ],
      },
      {
        text: 'Delivery',
        items: [
          { text: 'Environments and side effects', link: '/delivery/environments' },
          { text: 'CI/CD', link: '/delivery/ci-cd' },
          { text: 'Releases', link: '/delivery/releases' },
          { text: 'Schema migrations', link: '/delivery/migrations' },
          { text: 'QA', link: '/delivery/qa' },
        ],
      },
      {
        text: 'Claude Code',
        items: [
          { text: 'Overview', link: '/claude/' },
          { text: 'CLAUDE.md and AGENTS.md', link: '/claude/claude-md' },
          { text: 'Skills', link: '/claude/skills' },
          { text: 'Sub-agents', link: '/claude/agents' },
          { text: 'Hooks', link: '/claude/hooks' },
        ],
      },
      {
        text: 'Documentation',
        items: [{ text: 'The docs site', link: '/docs-site/' }],
      },
      {
        text: 'Templates',
        items: [{ text: 'All templates', link: '/templates/' }],
      },
    ],
    socialLinks: [{ icon: 'github', link: repo }],
    editLink: { pattern: `${repo}/edit/main/docs/:path`, text: 'Edit this page' },
    search: { provider: 'local' },
    outline: [2, 3],
    footer: { message: 'Released under the MIT License.' },
  },
}))
