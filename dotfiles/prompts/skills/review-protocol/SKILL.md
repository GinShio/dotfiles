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

**1. Correctness** — does this do what it claims?

- Edge cases: empty inputs, overflow, underflow, null/None, zero-size allocations.
- Lifetimes: use-after-free, dangling references, invalidated iterators, moved-from objects.
- Ownership: who frees this? What happens on error paths? Are all resources released?
- Concurrency: data races, deadlocks, ordering guarantees, memory visibility.
- Integer widths: truncation, sign extension, overflow in arithmetic.
- Alignment: packed structs, unaligned access, padding assumptions.
- Error paths: are all return values checked? Resources cleaned up on failure?
- Spec compliance: does this match what the spec actually says, not what you wish it said?
- **Context-dependent correctness:** code that looks wrong may be correct because of external constraints (hardware intrinsics, spec-mandated sequences, IR invariants, translation rules from a higher-level spec, hardware errata). Before flagging such code as incorrect, check whether existing comments, surrounding code, project conventions, or clear spec/fact evidence explain the constraint. If a claim is explicitly spec-related or fact-dependent and the code is ambiguous or inconsistent with it, verify the claim before making a finding. If you cannot verify it from local evidence, ask for clarification or hand the research question to Puppet; do not turn uncertainty into a confident defect.

**2. Design** — is this well-structured?

- Interface stability: will this API survive evolution?
- Layering: does this respect module boundaries?
- Abstraction level: is it right, or too high (premature abstraction) or too low (leaked details)?
- Coupling: are dependencies justified and minimal?
- Extensibility: can this grow without rewriting?
- Naming: do names communicate intent?

**3. Maintainability** — can a future reader understand and modify this?

- Clarity: can a colleague follow the logic?
- Complexity: is the complexity justified by the problem?
- **Separation of concerns:** does the code mix responsibilities that should be separate? Example: a single loop that does both analysis and transform is harder to reason about, test, and modify than two passes — even if the fused loop is faster. Prefer separation unless profiling shows the cost matters.
- **Context preservation:** does context-dependent code carry a context-preserving comment? Code that looks strange, redundant, or unnecessarily complex to a reader without hidden context *must* have a comment that pins the constraint to a verifiable source (spec section, hardware errata number, intrinsic contract). A vague comment like "this is needed" does NOT count — the reader must be able to verify the claim. Missing or insufficient context-preserving comments are a legitimate finding.
- **Comment quality:** do comments explain *what* and *why*, not *how*? Inline comments that restate the code are noise. Comments that reference specific code names — variables, functions, or types — will silently drift after renames; flag these as maintainability concerns. Stable external names are allowed when they are the thing being documented: public APIs, spec sections, extension names, ABI/contracts, issue IDs, and hardware errata. API/interface comments should describe the contract thoroughly; sparse API docs are a finding.
- Test coverage: are the important paths tested?
- Error messages: do they help diagnose failures?

**4. Performance** — efficient enough for its context?

- Flag only: unnecessary copies in hot paths, hidden allocations, O(n²) where O(n) is feasible, cache-hostile access patterns.
- Never flag: premature optimizations, micro-optimizations without measurement, theoretical complexity differences that don't matter at the actual scale.
- **Never recommend sacrificing maintainability for speculative performance.** If a cleaner design is slightly slower, that's the right trade-off unless profiling proves otherwise.

**5. Style** — follows project conventions?

- Only flag deviations from the project's established patterns.
- Never impose external style preferences.

## Context-Dependent Code: How to Handle It

When you encounter code that looks wrong, strange, or unnecessarily complex, follow this protocol before flagging it:

1. **Check for existing context.** Read surrounding comments, the function/block documentation, nearby code that follows the same pattern. The explanation may already exist.
2. **Check for verifiable constraints.** Is this in a domain with external specs (Vulkan, SPIR-V, LLVM IR) or factual claims (hardware behavior, upstream API contracts, ABI requirements)? Look for spec references, intrinsic names, issue IDs, commit messages, or hardware-specific patterns. The constraint may be verifiable even if not commented.
3. **If context exists and explains the code:** the code is correct. Check whether the context-preserving comment is sufficient — would a new team member understand why this can't be simplified? If the comment is missing or vague, flag as a maintainability issue, not correctness.
4. **If the finding depends on a spec or fact you cannot verify locally:** ask for clarification or hand the question to Puppet. If the review must proceed without that answer, flag it as "needs clarification" with your reasoning: "This code appears to [X], which would be [problem]. However, in [domain], this may be required because [possible constraint]. Is this intentional?"
5. **If no plausible constraint explains the code:** flag as a correctness or design issue per normal review.

## Review Process

1. **Understand context:** read the design or intent, surrounding code, and project conventions.
2. **Read carefully:** first pass (understand what it does), second pass (correctness — including context-dependent correctness), third pass (design), fourth pass (maintainability — including context preservation).
3. **Structure findings:** group by severity, order by priority within each group.
4. **Self-calibrate:** would I actually block a merge on this? Am I flagging genuine issues or preferences? If you wouldn't block on it, it's not "Blocking."

## Domain-Specific Review Awareness

**Compiler code:** pass invariant preservation, IR construction correctness, metadata and debug info handling through transformations, compile-time impact of changes, missing analysis invalidation after mutations.

**Vulkan/driver code:** spec compliance (especially edge cases the spec is explicit about), synchronization barrier correctness and completeness, memory allocation and lifetime management, SPIR-V decoration and instruction correctness, cross-vendor assumption validity.

**C++ code:** lifetime issues (the #1 source of bugs), move semantics correctness, RAII completeness (every resource wrapped), template necessity (is this template actually needed?), exception safety guarantees.

**Rust code:** `unsafe` justification (every unsafe block should have a safety comment), lifetime minimization (are explicit lifetimes actually needed?), `Result`/`Option` handling (no unwraps without justification), trait design (is the abstraction well-bounded?).

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
