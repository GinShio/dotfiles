# Prompt Delegation Policy

This is the portable policy for choosing between the main session, skills, and agents. Tool-specific adapters may add command names, file paths, or agent rosters, but must not loosen these boundaries.

## Main Session

Use the main session for work that depends on continuity:

- collaborative design and architecture discussion
- implementation, refactoring, and test writing
- tasks that depend on active edits, user corrections, or unresolved HITL decisions
- final integration of research, reviews, and implementation choices

The main session owns context, user alignment, edits, and accountability. Do not move implementation into an agent just to give it a persona.

## Skills

Use skills to teach the main session a workflow without moving the work out of the conversation.

Good skill candidates:

- design protocols
- implementation protocols
- review mechanics
- project or tool workflows
- output formats and checklists

Skills preserve the main session's context while adding reusable procedure. They are the right place for design behavior, implementation discipline, review judgment, and shared `wits review` mechanics.

## Agents

Use agents for bounded work that can be delegated with a clear input and returned as a report.

Good agent candidates:

- independent research
- parallel investigation where a fresh context helps
- a one-shot, clean-context pass on work the main session did not produce, when independence matters more than back-and-forth

Note: conversational, iterative work is a poor fit for an agent (turn-based delegation, isolated context). Review here is deliberately a main-session skill, not an agent, because the workflow is dominantly conversational and often happens right after writing the code.

Agents must have clear boundaries, a defined output, and enough context in their prompt to succeed without guessing. Prefer read-only or tightly constrained tools unless the agent's whole purpose is an explicitly approved operational workflow.

## Handoffs

When delegating to an agent, include:

- the exact scope
- relevant prior decisions and assumptions
- what evidence to inspect
- what output format is expected
- what must be treated as an open question

The main session integrates the result. Agents can inform decisions, but they do not silently make user-owned design choices or perform hidden implementation work.

## Current Shape

- Puppet is the only agent (research). It runs in isolation and returns a report.
- Everything else is a main-session skill:
  - `design-protocol` — design and architecture.
  - `implementation-protocol` — features, fixes, refactors, tests.
  - `review-protocol` — the review quality bar and method; use for conversational, iterative review and review right after writing code.
  - `wits-review` — mechanics-only for reviewing a numbered forge MR/PR; defers to `review-protocol` for judgment. The `local.json` draft write is gated: discuss findings over as many rounds as needed and write only after the user explicitly approves — never as a one-shot.
