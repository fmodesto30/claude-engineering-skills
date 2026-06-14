# Severity Rubric

The shared severity vocabulary for every `java-pr-review` lens. Its job is to keep reviews
*useful*: to separate the handful of findings that matter from the noise that erodes trust in
automated review. Every lens classifies its findings with these four levels and obeys the
overriding rule below.

## The four levels

- **MUST** — A concrete defect or serious hazard. The change (or its absence) causes a bug,
  data loss, a security hole, a broken contract, inconsistent/corrupted state, a
  transactional/consistency error, a resource leak, or makes a required near-term change unsafe.
  A `MUST` blocks the PR and must explain the failure mode — *what* breaks and *how*.

- **SHOULD** — A real, nameable improvement that is not a defect today. A specific change would
  measurably improve maintainability, testability, extensibility, or operability, and you can
  state the concrete benefit. A `SHOULD` is raised but does not block.

- **NIT** — A cosmetic or organizational preference with no behavioral consequence. Worth a
  brief, explicitly-labeled note (`nit:`), **never** a blocker. When in doubt between `SHOULD`
  and `NIT`, it's a `NIT`.

- **NO_COMMENT** — The observation would be pure taste, or speculative overengineering (an
  abstraction for a variation that doesn't exist, a "just in case" change). Stay silent. Saying
  nothing is a valid, frequent, and correct outcome.

## The overriding rule

**Every finding must name a concrete consequence** — what breaks, what gets harder, what risk
materializes, or what concretely improves. If no concrete consequence can be articulated, the
finding is `NO_COMMENT`, no matter how strongly the code diverges from a convention or a
preferred shape. "This violates principle X" is not a finding; "this violates X, so changing
the tax rule will force editing the unrelated notification path" is.

## Style belongs to tooling, not review

Do **not** spend review attention — or model tokens — on anything a deterministic tool enforces
better and for free:

- `final var` usage, `this.` qualification, import ordering, whitespace, brace style, line
  length → **formatter/linter** (Spotless, google-java-format, Checkstyle).
- "Useless comment" removal, naming conventions, unused imports, simple smells → **static
  analysis** (PMD, SonarQube, Error Prone).

If a rule can be automated, it is not a review finding. A review's value is the judgment a
linter cannot make: correctness, design, transactions, idempotency, concurrency, security,
observability, and production risk.

## Java/Spring calibration examples

**MUST**
- Mutable instance fields on a default singleton-scoped Spring bean read/written across request
  threads → data race and state corruption.
- A `@Transactional` (or `@Cacheable`, `@Async`) method invoked from another method on the same
  bean (`this.method()`) → the proxy is bypassed and the advice silently does not run.
- A non-idempotent state-changing endpoint exposed to client/broker retries → duplicate effects.
- A secret, token, or credential hard-coded or written to a log.
- A resource (stream, connection, lock) opened on a path that can leak it on error.

**SHOULD**
- The same `switch (status)` duplicated across several methods, each needing a new branch
  together → extract to polymorphism / a sealed type so a new status touches one place.
- A critical path (payment capture, money movement) with no test or no observability.
- An external call with no timeout / retry / fallback.

**NIT**
- A builder that would read slightly better than a long constructor.
- Package placement or a clearer method name.

**NO_COMMENT**
- An interface extracted for a single implementation "to be safe," with no second case in sight.
- A naming choice that is merely not your preference.

## Output convention

Each finding is rendered as:

```
[MUST|SHOULD|NIT] <file>:<line> — <problem>
  Consequence: <what concretely breaks / gets harder / improves>
  Suggestion: <the alternative, not just the objection>
```

Close every review with a short verdict (approve / approve with comments / request changes) and
a count per severity. Prefer a few strong, specific findings over many generic ones — drop weak
suggestions to `NO_COMMENT` rather than padding the review.
