---
name: architecture-review
description: >-
  Reviews the design and architecture of Java / Spring Boot systems — context boundaries,
  coupling, consistency, data ownership, failure modes, evolvability, and integration — returning
  severity-tagged (MUST / SHOULD / NIT) findings with concrete consequences. Use when reviewing a
  design doc, an architectural change, or a sizeable PR at system/design altitude, or when checking
  such a change before requesting review. Defers line-level review (correctness of changed lines,
  local readability, individual test quality) to java-pr-review and pure style (formatting, naming-case,
  import order) to linters. Not for non-JVM systems and not for line-by-line diff review.
---

# architecture-review

A review orchestrator for Java / Spring Boot **systems and designs**. It applies consistent
engineering judgment at design/system altitude — how a change sits within bounded contexts,
who owns which data, where consistency is transactional vs. eventual, how the system behaves when
an integration point fails, and what the next likely change will cost — so findings are calibrated,
consequence-driven, and free of style or line-level nitpicks. It knows when to stay silent, and it
defers line-by-line concerns to `java-pr-review`.

## Core stance

- **A concept or pattern is a tool, not a goal.** A bounded context, an event, a saga, a separate
  service — none earns its place by being named. Flag something only when you can name the concrete
  consequence: what breaks, what gets harder, what risk lands, what concretely improves. If you
  can't, it's `NO_COMMENT`.
- **Line-level and style belong elsewhere.** Correctness of a changed line, local readability, an
  individual test's assertion → `java-pr-review`. Formatting, naming-case, import order, `this.`,
  whitespace → linters. This skill spends its attention on what neither can judge: the shape of the
  system.
- **Modern-first.** Prefer current Java/Spring idioms and architectural facilities the platform
  already gives you over hand-rolled ceremony, and inspect the *target* system's actual stack
  (services, versions, persistence, messaging) before recommending anything.
- **Inspect the actual system before judging.** Architecture findings are wrong by default if they
  assume a topology. Establish the real modules, contexts, ownership, and integration style first.
- **Few strong findings beat many weak ones.** One well-justified boundary or consistency `MUST`
  beats a wall of structural preferences.

## How to run a review

1. **Establish the actual system context.** Before judging anything, map the system as it really is:
   the modules/services and how they are deployed (monolith, modular monolith, services); the
   bounded contexts and where their boundaries fall; who owns which data and which store is the
   single source of truth; the integration style between parts (synchronous HTTP/RPC, messaging,
   shared database, batch); and the real Java/Spring stack and versions, the persistence technology,
   and the messaging/streaming technology actually in use. **Never assume a topology, a version, or
   an integration style** — read the build files, configuration, and code, or ask. An architecture
   finding built on an assumed system is noise.
2. **Get the design or change under review.** The unit is a design document, an architectural change
   (a new service, a moved boundary, a new integration, a data-ownership shift), or a sizeable PR
   whose impact is structural rather than line-level. Read enough to judge intent and blast radius.
3. **Apply the severity rubric.** Classify every finding `MUST` / `SHOULD` / `NIT` / `NO_COMMENT`
   per [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md), and obey the overriding
   rule: every finding names a concrete consequence.
4. **Consult the lenses this skill uses**, loading only the ones whose area the change actually
   touches (never just because a concept name appears):
   - [`../../lenses/ddd.md`](../../lenses/ddd.md) — when the change touches domain modeling,
     bounded-context boundaries, aggregate design and consistency, domain events, or integration
     with a foreign/legacy model. Use it to judge whether boundaries and the ubiquitous language
     hold, where the consistency seams fall, and whether a foreign model is being translated at the
     edge or leaking inward.
   - [`../../lenses/design-patterns.md`](../../lenses/design-patterns.md) — applied here at **DESIGN
     altitude**, not line-level: does the structural choice (a port/adapter at an integration
     boundary, an event for fan-out, a facade over a subsystem, a strategy for a real axis of
     variation) reduce real complexity and risk, or is it ceremony that adds indirection without
     buying anything? Judge the structure against the problem the design actually has.
   - [`../../lenses/saga.md`](../../lenses/saga.md) — when the change maintains consistency across
     more than one aggregate, datastore, or service without a distributed transaction: a multi-step
     workflow whose steps can each fail, compensation/rollback, choreography vs. orchestration,
     idempotency under at-least-once delivery, or the dual-write/outbox problem. Use it to judge
     whether a saga is even warranted (often one local transaction suffices) and whether
     compensation, idempotency, and lost isolation are handled.
   - [`../../lenses/cqrs.md`](../../lenses/cqrs.md) — when the change separates the write (command)
     model from the read (query) model: a denormalized read model or projection, a separate read
     store/replica, or distinct read views. Use it to judge whether the separation is warranted at
     all (a same-store read-only projection often suffices), whether the read model has an owner and
     a rebuild path, and whether eventual consistency and read-your-own-writes are handled.
   - [`../../lenses/cdc.md`](../../lenses/cdc.md) — when a committed change in one datastore must be
     captured and streamed to another system (a read model, search index, cache, warehouse, or
     another service), or an outbox is relayed by change data capture. Use it to judge whether a CDC
     pipeline is warranted at all (an intentional domain event often suffices when you own the
     source), whether the capture point is a raw table or an intentional outbox, and whether deletes,
     ordering, idempotency, and lag are handled.
   - [`../../lenses/spring-production-readiness.md`](../../lenses/spring-production-readiness.md) —
     when the change affects how the system behaves under failure, retry, concurrency, or load at a
     boundary: timeouts/retries/fallback and failure isolation across an integration point,
     idempotency under at-least-once delivery, a hotspot / single writer / N+1 fan-out that won't hold
     under load, or a consistency seam assumed atomic across services. Use it at **system altitude** to
     judge whether the design's failure modes are handled — not the line-level call (that is
     `java-pr-review`).
   - [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md) — always; classify every
     finding `MUST` / `SHOULD` / `NIT` / `NO_COMMENT`.
   - *(One more shared lens — event-driven — is added here as it lands in `lenses/`.)*
5. **Prioritize architecture-level concerns** the line reviewer cannot judge:
   - **Context boundaries & coupling** — does the change respect bounded-context boundaries, or does
     it couple contexts that should evolve independently (shared mutable model, a context reaching
     into another's internals, a cyclic dependency between modules/services)?
   - **Data ownership & single source of truth** — does exactly one context own each piece of data,
     or is the same fact now written from two places, leaving no authoritative source?
   - **Transactional vs. eventual consistency** — is a single transaction being assumed across a
     boundary it can't span (two services, two stores, an after-commit event)? Where consistency is
     eventual, is that acknowledged and handled, or silently assumed atomic?
   - **Failure modes & resilience across integration points** — what happens when a downstream call
     times out, fails, or returns partially? Are timeouts, retries with idempotency, fallbacks, and
     failure isolation present at each boundary, or does one slow dependency take the system down?
   - **Scalability & contention** — does the design introduce a hotspot, a shared lock, a single
     writer, or an N+1 fan-out across a boundary that will not hold under load?
   - **Evolvability & the cost of likely near-term change** — given the changes the roadmap actually
     implies, does this structure make the next one cheap or expensive? Flag rigidity that will bite
     soon, not hypothetical futures.
   - **Observability at boundaries** — when a cross-context or cross-service flow fails, can it be
     traced and diagnosed (correlation across the boundary, the failure surfaced rather than
     swallowed), or is the integration a blind spot?
6. **Emit the review.** Severity-tagged findings, each with a location, the problem, the concrete
   consequence, and a suggested alternative (see Output format). Close with a verdict and a
   per-severity count.

## Output format

```
[MUST|SHOULD|NIT] <location> — <problem>
  Consequence: <what concretely breaks / gets harder / improves at the system level>
  Suggestion: <the alternative, not just the objection>
```

`<location>` may be a component, module, service, bounded context, or integration boundary
(e.g. `Billing ↔ Notification boundary`, `OrderContext aggregate`, `payment-service → ledger-service`)
— not only `file:line`. Use a file:line anchor when one exists and helps, but a design finding
often lives at a seam, not a line.

For a design-pattern recommendation made at this altitude, use the per-pattern block defined in the
design-patterns lens (Current Problem / Classic Approach / Modern Alternative / Recommendation /
Why / Severity).

Close with a verdict (approve / approve with comments / request changes) and a count per severity.

## Restraint rules

- Do not comment because a pattern, context boundary, event, or other concept is *absent* — only
  because its absence has a named, concrete consequence. A missing abstraction the system does not
  need yet is `NO_COMMENT`.
- Never block on preference. A structural choice that is merely not how you'd draw the diagram is a
  `NIT` at most, and usually `NO_COMMENT`. Speculative generality (a service split, an event bus, a
  CQRS read model "to be ready") with no current driver is `NO_COMMENT`.
- Drop weak suggestions to `NO_COMMENT` rather than padding the review. Three consequence-backed
  findings at system altitude land; fifteen diagram preferences bury the one that mattered.
- Stay in your altitude: a line-level correctness bug or a local readability tangle is
  `java-pr-review`'s finding, not this skill's — note it as out of scope rather than restating it.
- Keep findings respectful, ready-to-paste, and anchored to the trade-off — name what the design
  buys and gives up, and offer the alternative, not just the objection.
