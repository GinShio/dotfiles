---
name: wits-review
description: Use the local `wits review` workflow to review a numbered merge or pull request without checkout. Fetches into the local review store, reads pinned git objects, and writes a local `local.json` draft only. This skill is the complete source of truth for the wits review mechanics.
---

# Wits Review

Use this workflow for a numbered MR/PR reviewed through `wits review`. The output is a local review draft (`local.json`) and a report to the user. The user is the author of record and submits the review themselves; you only draft.

This file holds all `wits review` mechanics. The caller is the main session, which should follow it exactly rather than reinventing the steps. Review judgment itself comes from the `review-protocol` skill; this skill supplies mechanics only.

## Hard Boundaries

Absolute. No task prompt relaxes them. If one blocks the job, stop and say so.

- Never check out or materialize the code: no `wits review checkout`, `git checkout`, `git switch`, `git worktree`, `git reset`, or `git restore`. Nothing that moves `HEAD`. Read from pinned git objects.
- Never perform forge-visible actions: no `wits review submit`, `git push`, or `gh`/`glab` writes. The forge must never see that you were here.
- Never set a verdict of `approve` or `request-changes`, and never `resolve`/`unresolve` a thread. You only comment.
- Never write files except through the two permitted operations: `wits review fetch <mr>` may update the local review store, and `wits review draft <mr> -` may write that MR's `local.json`. Do not hand-edit the store, touch source, or write any other file.
- Never write the draft as a one-shot. `wits review draft` runs only after the findings have been discussed with the user and the user has explicitly approved writing. Fetching and reading are unattended; the `local.json` write is a gated step, not the default endpoint of a review.
- Never state a finding you cannot ground in code you actually read. An ungrounded worry is a question to the user or a `[needs-clarification]` comment, never a confident bug.

## Permitted Operations

- **Read from the forge (the only network call):** `wits review fetch <mr>` to acquire or refresh an MR. It pins objects and caches metadata in the local review store; this local store write is permitted and is not forge-visible.
- **Local reads:** `wits review show`/`diff`/`draft` (with `--json`; `diff --patch`), and `git show <sha>:<path>`, `git grep <sha>`, `git log`/`git diff` over the pinned SHAs, plus file reads and searches.
- **Local write (the deliverable):** `wits review draft <mr> -`, piping a JSON batch of actions into that MR's `local.json`. This is the only non-fetch write permitted.

## 1. Acquire

1. Run `wits review show <mr> --json`.
2. If the MR is not in the store, run `wits review fetch <mr>` and say so.
3. If the snapshot may be stale — an old `updated_at`, or the author just pushed — re-fetch so the review targets the current snapshot.
4. Read `wits review diff <mr> --json` for base/head SHAs, files, and commits.
5. Read `wits review diff <mr> --patch` for the full patch.
6. Note existing `threads`, `snapshots`, and `neighbors` from `show`.

## 2. Understand Without Checkout

Everything lives in the objects `fetch` pinned. Read whole files, not just hunks:

- `git show <head_sha>:<path>` for the new file, `git show <base_sha>:<path>` for the pre-image.
- `git grep -n <pattern> <head_sha>` to follow symbols off the diff and judge blast radius and internal consistency.
- `git log <base_sha>..<head_sha>` and `git show <sha>` for the author's intent.

Prefer pinned-object access over reading the clone's working tree, which may sit at a different commit. If `neighbors` shows a stack, understand the MRs this one sits on before judging.

## 3. Judge

Apply the `review-protocol` skill for all review judgment: its priority order (correctness > design > maintainability > performance > style), its context-dependent-code protocol, and its severity calibration. This skill supplies mechanics only and adds no review criteria of its own.

An MR with nothing wrong earns a short "looks good" — an empty finding list is a valid review.

## 4. Ask When Context Is Missing

The moment a conclusion rests on something you can't see or verify, stop and ask the user rather than guessing. Common triggers:

- A symbol the change needs is absent from the snapshot and not found by `git grep <head_sha>`.
- Correctness hinges on unobservable behavior: a caller's invariant, a spec/hardware contract, or an upstream IR invariant.
- The snapshot looks outdated.
- A referenced spec, issue, or errata you cannot reach is load-bearing.
- The author's intent is genuinely ambiguous.

Say what is unclear, why it matters, and what you need. If it cannot be answered, record it as a `[needs-clarification]` comment — a question to the author, not a defect. Don't ask what the code already answers.

## 5. Discuss Before Writing

Present the findings to the user first (use the report format in the last section) and review them together over as many rounds as needed: the user may push back, add context, drop or reframe findings, or ask you to re-examine. Do NOT write the draft yet.

Write to `local.json` only when the user has explicitly approved doing so, and only after discussion has settled. If the user hasn't asked for the draft to be written, stop at the report — a discussion-only review that never touches `local.json` is a valid outcome. Treat "review this MR" as a request to read and report, not an instruction to write the draft.

## 6. Deposit Into `local.json`

Only after step 5's approval. Translate each agreed finding into a `comment` action, plus one `summary` action for the overall assessment, and append with `wits review draft <mr> -`.

**Anchor.** `file` + `line` is a line comment, `file` alone is file-level, neither is an MR-level note. Take line numbers from the patch or `git show <head_sha>:<path>`. `side` is `new` for added/context lines, `old` for a deleted line; a span uses `start_line`/`start_side`. You needn't set `commit` — `draft` stamps the current snapshot at ingest.

**Body.** Lead with a severity tag — `[blocking]` / `[important]` / `[suggestion]` / `[nit]` / `[needs-clarification]` / `[praise]` — then Problem / Impact / Direction (a direction, never a patch), or the question itself. Reference other code with a `[[path:line]]` token, which `submit` turns into a forge permalink.

**Disclose AI authorship on every body.** End each `comment`, `reply`, and `summary` body with one trailer line:

```markdown
**Generated-by:** <tool> (<model>) <!-- this comment is submitted by wits-review -->
```

`<tool>` is the coding tool (e.g. `Claude Code`) and `<model>` is the active model, both supplied by the adapter. The HTML comment is a fixed provenance marker that renders invisibly on both forges. Keep it to one line, and never claim a human has verified what you only drafted.

**Verdict and threads.** Leave `verdict` unset (or `comment`). `reply` may add to an existing thread; `resolve` and the `approve`/`request-changes` verdicts are off-limits.

**IDs and append-only edits.** Every action is addressed by an `id` (`wits:<uuid>`; `draft` assigns one when you omit it). The draft is append-only: to revise a finding, append another action with the same `id`; to withdraw one, append `{ "action": "drop", "id": … }`. On a re-review, read `wits review draft <mr> --json` for the live actions and their ids and `wits review show <mr> --json` for what is already posted, then supersede or drop by id instead of re-appending.

```json
{
  "schema": 1,
  "actions": [
    { "action": "summary",
      "body": "Two blockers around lock ordering; the rest is solid.\n\n**Generated-by:** <tool> (<model>) <!-- this comment is submitted by wits-review -->" },
    { "action": "comment", "file": "src/lock.c", "line": 42,
      "body": "[blocking] Problem: the error path on line 44 returns before the unlock, double-unlocking the mutex.\nImpact: undefined behavior on any failure here.\nDirection: unlock once in a single cleanup epilogue.\n\n**Generated-by:** <tool> (<model>) <!-- this comment is submitted by wits-review -->" }
  ]
}
```

## 7. Report

Use the output format below for the findings in step 5, and again after any write in step 6. When you have written the draft, add one line on what you wrote (how many actions; anything superseded or dropped) and any open questions. Remind the user once that they submit — you did not.

```markdown
## Review: MR <n> — <title>

### Summary
[1-2 sentences: ready, or what needs attention? Note that no verdict was set.]

### Blocking Issues
1. **[file:line]** — [title]
   - **Problem:** ...
   - **Impact:** ...
   - **Direction:** ...

### Important Issues
### Suggestions
### Nits
### What's Good
### Needs Clarification
- [what you couldn't verify, and what you need from the user]

### Draft written
- N action(s) in MR <n>'s `local.json` (verdict unset). Review with `wits review draft <n>`; submit is yours.
```
