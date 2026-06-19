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
   `NO_COMMENT` per [../../rules/severity-rubric.md](../../rules/severity-rubric.md), and obey the
   overriding rule: every finding names a concrete consequence.
4. **Consult the lenses this skill uses**, loading only the ones whose structural area the diff
   actually touches (never just because a pattern name appears):
   - [`../../lenses/design-patterns.md`](../../lenses/design-patterns.md) — when the diff
     adds/removes abstractions, inheritance, type/state branching, creation logic, integration
     boundaries, cross-cutting behavior, or eventing. Apply it with a **diff/PR focus** — *does
     this pattern in the diff make the code simpler and safer, or is it ceremony/overengineering?*
     — **not** as a broad architectural review (that is a separate skill's job).
   - [`../../lenses/clean-code.md`](../../lenses/clean-code.md) — when the diff touches a long or
     growing method/class, new names, comments, duplicated logic, tangled control flow, confused
     responsibility, or a small in-scope refactor. Apply it with a **diff/PR focus** on the changed
     lines, defer pure style to linters, and bias toward restraint (most readability observations
     are `NIT` or `NO_COMMENT`).
   - [`../../lenses/testing.md`](../../lenses/testing.md) — when the diff adds or changes tests, or
     changes risk-bearing production code (payment, auth, persistence, money math) that should be
     tested. Apply it with a **diff/PR focus** on the changed tests and the code under change: judge
     whether a test can fail for the right reason, never demand coverage numbers, and defer test
     style to linters.
   - [`../../lenses/spring-production-readiness.md`](../../lenses/spring-production-readiness.md) —
     when the diff touches a process/network boundary (HTTP client, DB query, broker, cache), a state
     change reachable by retry/redelivery, a transaction or `@Async`/`@Cacheable`/`@Scheduled`
     boundary, shared mutable state on a bean, a query in a loop or an unbounded result set, or a
     resource (stream, connection, lock). Apply it with a **diff/PR focus** at the line/method level —
     name the runtime failure mode (pool exhaustion, double effect, data race, leak, partial write) —
     and stay silent on speculative hardening with no named failure.
   - [`../../lenses/security.md`](../../lenses/security.md) — when the diff touches a trust boundary
     (untrusted input reaching a query/command/path/URL/deserializer), an authorization check, a
     secret/credential, sensitive data (PII/token) heading to a log/response/URL, or a crypto
     operation. Apply it with a **diff/PR focus** at the line/method level — name the exploit (SQL
     injection, IDOR, a logged token, a weak password hash) — and delegate dependency-version CVEs to
     SCA tooling. This lens owns the secret/PII-in-log `MUST` that `spring-production-readiness` defers.
   - [`../../lenses/observability.md`](../../lenses/observability.md) — when the diff adds/changes a
     log line, a metric (especially a tag whose value comes from request data), a trace/MDC boundary
     (`@Async`, an executor, a consumer), or the diagnosability of a risk-bearing flow. Apply it with a
     **diff/PR focus** on instrumentation *quality* — a structured, queryable log; a low-cardinality
     metric label; a trace context that survives the hop — not whether visibility merely exists (that
     gap is `spring-production-readiness`'s).
   - [`../../lenses/solid.md`](../../lenses/solid.md) — when the diff moves a responsibility boundary
     (a class/method taking a second reason to change), a type hierarchy or `instanceof`/`switch`
     dispatch that must stay substitutable, an interface's shape, or the direction of a dependency
     (high-level policy reaching for a concrete/infra detail). Apply it with a **diff/PR focus** and
     **heavy restraint** — most SOLID observations are `NO_COMMENT`; raise one only when a principle's
     violation has a named consequence (a change forces editing unrelated code, a polymorphic caller
     breaks, a needed test seam is blocked), never because a layer or interface is "missing".
   - [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md) — always; classify every
     finding `MUST` / `SHOULD` / `NIT` / `NO_COMMENT`.
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
