---
layout: home
hero:
  name: Manzilo Workflow
  text: From tracker issue to production, with Claude Code
  tagline: The engineering process behind Manzilo, written so any project can adopt it in an afternoon.
  actions:
    - theme: brand
      text: Adopt it
      link: /guide/adopt
    - theme: alt
      text: What this is
      link: /guide/
    - theme: alt
      text: Templates
      link: /templates/
features:
  - title: One loop for every change
    details: Pick an issue, claim it, branch, open a PR, get it reviewed, merge, close it. A /task skill runs the tracker side.
    link: /workflow/task-loop
  - title: Rules a machine enforces
    details: A git hook refuses commits to main. CI does every deploy. Production takes only release tags that ran on staging first.
    link: /workflow/branching
  - title: Claude Code as a teammate
    details: A CLAUDE.md that states the rules, skills for the stack, sub-agents for research and review, and hooks around the PR lifecycle.
    link: /claude/
  - title: Nothing reaches real people by accident
    details: Outbound side effects are off outside production. Destructive operations fail closed when the environment is unset.
    link: /delivery/environments
  - title: Docs that stay true
    details: A VitePress site per project, updated in the same PR as the code, with QA test cases that keep their IDs.
    link: /docs-site/
  - title: Copy, don't retype
    details: Hooks, settings, the /task skill, agents, workflows, PR template, release-please and a docs starter, plus a script that installs them.
    link: /templates/
---
