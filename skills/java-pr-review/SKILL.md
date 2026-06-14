---
name: java-pr-review
description: >-
  Reviews Java / Spring Boot pull requests for design, correctness, and production risk,
  returning severity-tagged (MUST / SHOULD / NIT) findings with concrete consequences. Use when
  reviewing a Java or Spring diff or PR, or when checking a Java/Spring change before requesting
  review. Defers pure style (formatting, `final var`, `this.`, import order) to linters and
  prefers modern Java/Spring idioms over classic pattern ceremony. Not for non-JVM code.
---

# java-pr-review

A review orchestrator for Java / Spring Boot pull requests. It applies consistent engineering
judgment so findings are calibrated, consequence-driven, and free of style nitpicks — and it
knows when to stay silent.

## Core stance

- **A rule is a tool, not a goal.** Flag something only when you can name the concrete
  consequence. If you can't, it's `NO_COMMENT`.
- **Style is the linter's job.** Never raise formatting, `final var`, `this.` qualification,
  import order, or "useless comment" findings — those belong to Checkstyle/Spotless/PMD/Sonar.
- **Modern-first.** Prefer current Java/Spring idioms over classic ceremony, and inspect the
  *target* project's actual stack before recommending anything.
- **Few strong findings beat many weak ones.**

## How to run a review

1. **Establish the target stack.** Inspect the repository before judging: Java version, Spring
   Boot version, build tool, DI style, libraries on the classpath, coding conventions, and
   architecture style. Recommendations must fit the project that exists, not a template. Never
   assume a version or an available API.
2. **Get the diff.** Review the PR diff (changed files plus enough surrounding context to judge
   correctness and intent).
3. **Apply the severity rubric.** Classify every finding `MUST` / `SHOULD` / `NIT` /
   `NO_COMMENT` per [references/severity-rubric.md](references/severity-rubric.md), and obey the
   overriding rule: every finding names a concrete consequence.
4. **Consult the relevant lenses** for the structural areas the diff touches:
   - [references/design-patterns-lens.md](references/design-patterns-lens.md) — when the diff
     adds/removes abstractions, inheritance, type/state branching, creation logic, integration
     boundaries, cross-cutting behavior, or eventing.
   - *(More lenses — concurrency/transactions, testing, security, Spring production-readiness —
     are added here as they are written.)*
5. **Prioritize reasoning-heavy concerns** the linter cannot catch: correctness, transaction
   boundaries, idempotency, concurrency, error handling, security, observability, and
   production risk.
6. **Emit the review.** Severity-tagged findings, each with file:line, the problem, the concrete
   consequence, and a suggested alternative. Close with a verdict (approve / approve with
   comments / request changes) and a per-severity count.

## Output format

```
[MUST|SHOULD|NIT] <file>:<line> — <problem>
  Consequence: <what concretely breaks / gets harder / improves>
  Suggestion: <the alternative, not just the objection>
```

For a design-pattern recommendation, use the per-pattern block defined in the design-patterns
lens (Current Problem / Classic Approach / Modern Alternative / Recommendation / Why / Severity).

## Restraint rules

- Do not comment because a pattern is absent — only because its absence has a named consequence.
- Never block a PR on preference. Preferences are `NIT` at most.
- Drop weak suggestions to `NO_COMMENT` rather than padding the review.
- Keep comments respectful and ready-to-paste; offer the alternative, not just the objection.
