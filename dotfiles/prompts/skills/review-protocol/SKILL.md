---
name: review-protocol
description: The quality bar and method for reviewing code and designs. Use when reviewing changes, a diff, a design, or a subsystem for correctness, design, maintainability, performance, and style — including conversational, back-and-forth review and review right after writing code. This skill is the single source of truth for review judgment.
---

# Review Protocol

Review against the quality bar, not personal taste. Distinguish blocking issues from nits. Respect the author's design decisions while challenging execution. Output is findings, not patches: suggest the direction of a fix, not the exact code — the author writes the fix.

This skill holds the review judgment. It loads into the current session, so review can be fully conversational: share findings, take the user's pushback, re-examine, and refine over multiple rounds. Workflow-specific mechanics (for example the local `wits review` flow) live in their own skill and defer to this one for judgment.

## Asking During Review

- Ask only when you need the intent behind a non-obvious choice — "is this intentional or an oversight?" — and only when reading the surrounding code doesn't answer it.
- Never ask "would you like me to review this?" — if you were asked to review, review it.
- Never ask "should I also look at the tests?" — if tests are in scope, look.

## Anti-pattern: Style Policing and Over-reporting

Do not:

- Flag style issues a formatter handles (indentation, brace placement, spacing).
- Suggest rewrites that are "just different" without being clearly better.
- Impose personal taste as quality concerns.
- Find problems for the sake of finding problems — an empty review is a valid review.
- Flag premature optimization concerns in code that isn't on a hot path.

Do:

- Focus on correctness first, always.
- Explain WHY something is a problem, not just THAT it is.
- Suggest the direction of a fix, not exact code.
- Acknowledge good design when you see it — positive signal matters.
- Calibrate severity honestly — not everything is a blocker.

## Review Priority (strict ordering)

Review in this order. A correctness bug always trumps a design concern, which always trumps a style nit.

**1. Correctness** — does this do what it claims? Reason about edge cases, lifetimes, ownership, concurrency, and error paths. Code that looks wrong may be correct due to external constraints — follow the Context-Dependent Code protocol before flagging.

**2. Design** — is this well-structured? Assess interface stability, layering, abstraction level, coupling, extensibility, and naming.

**3. Maintainability** — can a future reader understand and modify this?

- **Separation of concerns:** does the code mix responsibilities that should be separate? A single loop that does both analysis and transform is harder to reason about, test, and modify than two passes — prefer separation unless profiling shows the cost matters.
- **Context preservation:** does context-dependent code carry a comment that pins the constraint to a verifiable source? A vague comment like "this is needed" does NOT count — the reader must be able to verify the claim. Missing or insufficient context-preserving comments are a finding.
- **Comment quality:** do comments explain *what* and *why*, not *how*? Comments that reference specific code names will silently drift after renames — flag these. Stable external names are allowed: public APIs, spec sections, extension names, ABI/contracts, issue IDs, hardware errata. Sparse API docs are a finding.

**4. Performance** — efficient enough for its context? Never sacrifice maintainability for speculative performance. If a cleaner design is slightly slower, that's the right trade-off unless profiling proves otherwise.

**5. Style** — follows project conventions? Only flag deviations from the project's established patterns. Never impose external style preferences.

## Spec / Requirements Compliance

Spec compliance is a distinct axis, not a correctness sub-item. A change can be correct (no bugs) yet fail to implement what was asked for. Skip this axis when the author had no spec.

### What to check

For every requirement in the spec, ask three questions:

| Question | What it catches |
|---|---|
| **Missing:** did the spec ask for this? | Requirements that weren't implemented |
| **Creep:** did the spec not ask for this? | Scope creep — code that implements something the spec didn't request |
| **Wrong:** does the implementation match what the spec says? | Requirements that look implemented but the implementation contradicts the spec |

Quote the spec line for each finding. Treat spec ambiguity as the spec author's responsibility, not the implementer's — if the spec is ambiguous, flag the ambiguity as a finding, don't blame the implementation.

### Relationship to correctness

Spec violations are correctness issues — they go in **Blocking Issues**. But report them with a `[Spec]` tag so they are traceable back to this axis. Example: `[Spec] Missing: the spec requires rate limiting on line 42, but no rate limiter is wired up.`

## Context-Dependent Code: How to Handle It

When you encounter code that looks wrong, strange, or unnecessarily complex, follow this protocol before flagging it:

1. **Check for existing context.** Read surrounding comments, the function/block documentation, nearby code that follows the same pattern. The explanation may already exist.
2. **Check for verifiable constraints.** Is this in a domain with external specs (Vulkan, SPIR-V, LLVM IR) or factual claims (hardware behavior, upstream API contracts, ABI requirements)? Look for spec references, intrinsic names, issue IDs, commit messages, or hardware-specific patterns. The constraint may be verifiable even if not commented.
3. **If context exists and explains the code:** the code is correct. Check whether the context-preserving comment is sufficient — would a new team member understand why this can't be simplified? If the comment is missing or vague, flag as a maintainability issue, not correctness.
4. **If the finding depends on a spec or fact you cannot verify locally:** ask for clarification or hand the question to Puppet. If the review must proceed without that answer, flag it as "needs clarification" with your reasoning: "This code appears to [X], which would be [problem]. However, in [domain], this may be required because [possible constraint]. Is this intentional?"
5. **If no plausible constraint explains the code:** flag as a correctness or design issue per normal review.

## Review Process

1. **Understand context:** read the design or intent, surrounding code, and project conventions. Identify the spec source for the change (if any) — see Spec Compliance below.
2. **Read holistically:** assess the change against the review priority in order — correctness (including context-dependent correctness) first, then design, maintainability, performance, and style last. You don't need separate passes; a single careful read suffices.
3. **Structure findings:** group by severity, order by priority within each group.
4. **Self-calibrate:** would I actually block a merge on this? Am I flagging genuine issues or preferences? If you wouldn't block on it, it's not "Blocking."

## Output Format

```markdown
## Review: [scope — what was reviewed]

### Summary
[1-2 sentence overall assessment: is this ready, or what needs attention?]

### Blocking Issues
[Must fix before merge. Each issue includes: location, problem, impact, fix direction.]

1. **[file:line]** — [brief issue title]
   - **Problem:** [what's wrong]
   - **Impact:** [why it matters — correctness/safety/spec consequence]
   - **Direction:** [how to fix — suggest direction, not exact code]

### Important Issues
[Should fix. Design problems, significant maintainability concerns.]

### Suggestions
[Could improve. Worth mentioning but won't block.]

### Nits
[Trivial. Fix if convenient, ignore if not.]

### What's Good
[Acknowledge well-done aspects. Positive signal matters.]
```

## Severity Calibration

Reflects the quality bar: correctness > maintainability > extensibility > performance.

- **Blocking:** Would refuse to merge. Correctness bugs, safety issues, spec violations, data loss risks.
- **Important:** Would strongly push back. Design problems, maintainability issues (mixed concerns that should be separated, missing context-preserving comments on non-obvious code, unnecessary complexity, missing tests for important paths). Maintainability defects are NOT casual suggestions — they compound over time and make the code unchangeable.
- **Suggestion:** Could improve. Naming that doesn't communicate intent, minor structural improvements, additional tests for edge cases. These won't cause pain immediately but would help future readers.
- **Nit:** Truly trivial. Less than 30 seconds to fix. Not worth arguing about.
