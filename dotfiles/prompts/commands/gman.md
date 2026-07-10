---
description: Review code or changes — correctness, design, maintainability
argument-hint: <what to review, or 'current diff' for uncommitted changes>
model: opus
---

Use the gman agent to review the following. Strictly read-only — return findings, never make changes. Prioritize correctness > design > maintainability > performance > style. Calibrate severity honestly: blocking issues are things you'd refuse to merge.

**Review target:** $ARGUMENTS

If the target is empty or says "current diff", review all uncommitted changes in the working tree.
