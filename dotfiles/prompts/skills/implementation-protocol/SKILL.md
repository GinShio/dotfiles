---
name: implementation-protocol
description: Guide main-session implementation work for features, bug fixes, refactors, and tests. Use when the user asks to implement, fix, add support, refactor according to an approved plan, or write code.
---

# Implementation Protocol

Use this in the main session. Do not delegate normal implementation to a subagent; implementation depends on the active conversation, current edits, user corrections, and HITL decisions. You implement approved designs — you are not designing through implementation. The user reviews everything; make that review cheap by writing clear, correct, well-scoped code.

## Understand Gate

Before writing code:

1. Read the existing code — understand what's there and the conventions used.
2. Read neighboring tests — testing patterns and coverage expectations.
3. Identify the scope and blast radius — what files change.
4. **Build and test: check project context first, then ask.** Look for build/test/lint instructions in the project-level AGENTS.md/CLAUDE.md, README, or CONTRIBUTING. If found, follow them. If not found, ask the user — C/C++ build systems are too varied to guess reliably from config files alone. Only investigate build files on your own if the user explicitly tells you to.

Ask when the task is ambiguous about scope or intent, or you don't know how to build/test. Don't ask what you can determine by reading existing code patterns (build-system config excepted — that's too unreliable to infer).

## Design Gate

Work from an approved design. This is non-negotiable for non-trivial changes.

- If no design exists: say "this needs a design discussion before I implement" rather than designing through code.
- Implementation-level decisions (algorithm choice within a function, variable naming): make the call and note it in your output.
- Architectural decisions (new module, interface change, new dependency, data format, build/config change, security/concurrency-sensitive behavior): STOP and confirm first — these are design decisions disguised as implementation details.

## While Writing Code

1. **Match conventions** — use the project's style, idioms, and patterns. Read the neighbors before introducing a new pattern.
2. **Prefer modern idioms only where allowed** — functional style, ranges, metaprogramming, newer features — but ONLY where the project's standard and house style admit them. When unsure, match neighbors and propose the modern option rather than introducing it silently.
3. **Handle errors properly** — no silent failures, no swallowed errors, no missing cleanup. Every error path releases resources.
4. **Think about ownership** — who owns this memory, what's the lifetime, what happens on error paths.
5. **Consider concurrency** — is this thread-safe, are there synchronization points to consider.
6. **Keep changes focused** — one logical change per unit. Don't mix refactoring with feature work. Present large changes in reviewable chunks, not one 500-line diff.

**The 2-3 failure rule:** after 2-3 failed attempts at the same obstacle, STOP. Don't force through with an ugly workaround. Re-question the design: "I've tried X, Y, Z and they all fail because [root cause]. The design may need adjustment."

Verify APIs, dependencies, and command assumptions actually exist before treating them as real.

## Domain-Specific Implementation Awareness

The core skill is understanding the relationship between high-level specifications and hardware reality. Code lives at the intersection: it must satisfy abstract contracts while working on concrete hardware.

**Compiler work (LLVM/MLIR):** understand how high-level semantics map to IR constructs, and how IR transforms must preserve the invariants downstream passes depend on. Use builder APIs correctly. Preserve debug info and metadata through transformations — losing debug info is a silent correctness bug. Consider compile-time cost. Test with multiple optimization levels. Use the project's range/iterator APIs when they express intent clearly (e.g. LLVM's `make_filter_range`).

**Vulkan/driver work:** translate the Vulkan spec (an abstract state machine) into hardware operations (command buffers, register writes, memory barriers). Follow the spec precisely — implement what it says, not what you think it means. Handle all valid input states. Consider cross-vendor implications. Respect the explicit synchronization model — don't hide barriers behind abstractions that obscure what the hardware actually needs.

## Comments

Default: don't write comments — rely on self-documenting names and structure. If a comment feels necessary for simple code, first ask whether the code can be renamed or restructured to make it redundant. Code is the source of truth; comments that duplicate it will drift.

**The three tiers of comments:**

1. **Inline comments** (within a function): explain *what* and *why*, never *how*. For simple code, "how" IS the code — restating it is noise. Inline comments exist for context the code can't express: spec requirements, hardware constraints, non-obvious invariants. Pin to a verifiable source.
2. **Summary comments** (function headers, block-level): may describe *how* when the logic is genuinely complex — a multi-step algorithm, a state machine, a pass with non-trivial invariants. These orient the reader before they dive in.
3. **API / interface comments** (public headers, docstrings, trait docs): documentation for *consumers*, not readers of the implementation. Describe the contract thoroughly: what it does, preconditions, postconditions, invariants, error behavior, thread-safety, lifetime requirements, and edge cases. A missing behavioral detail here causes bugs in callers.

**Never reference specific code names in comments — variables, functions, or types.** Code is dynamic: names get renamed and refactored, and a comment that names them will silently lie. Describe intent at the right level of abstraction instead. Stable external names are allowed when they are the thing being documented: public APIs, spec sections, extension names, ABI/contracts, issue IDs, and hardware errata.

**When you MUST add a context-preserving comment (inline tier):** code that a reader without hidden context would find strange. Common triggers:

- A spec-mandated ordering, sequence, or value that isn't obvious from the code alone.
- A hardware intrinsic or intrinsic sequence that looks arbitrary.
- A translation from a higher-level spec (e.g. GLSL → SPIR-V, NIR → ACO) where the mapping is non-obvious.
- A hardware errata workaround.
- An IR invariant that constrains what transformations are legal at this point.
- A seemingly redundant operation (barrier, fence, flush) that exists for a non-obvious reason.

**Inline comment quality — pin to a verifiable source:**

- Good: `// Vulkan spec §7.4: pipeline barrier must precede the first draw accessing this image.`
- Good: `// OpControlBarrier semantics require execution + memory dependency here.`
- Good: `// Navi2x hardware bug: depth decompress must precede color resolve (mesa!12345).`
- Bad: `// This is needed.` (says nothing)
- Bad: `// Hardware requirement.` (which hardware? which requirement?)
- Bad: `// Increment buf_count.` (restates the code, will drift)
- Bad: `// Don't remove this.` (why not? what breaks?)

A reader should be able to verify the claim and understand why the code can't be simplified or reordered — without needing to know any specific variable or function name.

## Self-review

Before handing work back, check against the quality bar:

- **Correctness:** edge cases, lifetimes, ownership, error paths, concurrency, integer widths, alignment. For context-dependent code, is the constraint verifiable?
- **Context preservation:** scan for anything that would make a reviewer ask "why is this here?" If the answer requires knowledge outside the file, add a context-preserving comment.
- **Maintainability:** could a colleague follow this? Is the complexity justified and placed in the right module?
- **Extensibility:** are interfaces stable and layering clean?
- **Performance:** efficient enough for its context — no unnecessary copies or hidden allocations in hot paths, no speculative speedups at the cost of clarity.

Then verify what you can (build, test, lint if a recipe exists) and state plainly what you couldn't verify and why.

## Commit Attribution

When asked to commit, attach an AI attribution trailer using `git interpret-trailers`. Never append trailers by manual string concatenation — let Git handle placement, formatting, and deduplication.

Trailer keys (open-source community convention):

- `Assisted-by` — you contributed to decisions or generated parts of the code, but the user directed the design and significant portions.
- `Generated-by` — you generated almost all of the code in the commit.

Usage:

```bash
git commit --trailer "Assisted-by: Claude Code (Sonnet)"
```

The value format is `<TOOL> (<MODEL>)`. `<TOOL>` is the AI coding tool in use (e.g. `Claude Code`); `<MODEL>` is the active model. Omit the model parenthetical if it can't be determined. When in doubt, default to `Assisted-by` — it covers the common case where implementation is a collaboration between an approved design and your code.

## Output

```markdown
## Changes Made

**Scope:** [what was changed and why]

**Files modified:**
- `path/to/file.cpp` — [what changed and why]

**Implementation decisions:**
- [decision made and why — things you chose that could have gone differently]

**What to review:**
- [areas deserving careful attention — where bugs are most likely]

**Verified:** [what was tested, built, or checked]
**Not verified:** [what couldn't be checked and why]
```
