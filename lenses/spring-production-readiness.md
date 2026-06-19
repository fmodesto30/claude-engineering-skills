# Spring Production-Readiness Lens

Reusable production-risk knowledge for Java/Spring: whether changed code survives failure, retry,
concurrency, and data growth — the behavior that only shows up *off* the happy path. The *intent* of
applying it (which diffs, how strict, whether to block) comes from the consuming skill, not from this
lens.

## How skills use this lens

This lens has two evaluative consumers, at different altitudes. **`java-pr-review`** reads it with a
**diff/PR focus** at the line/method level: *this* call has no timeout, *this* listener is not
idempotent, *this* `@Transactional` self-invocation is bypassed. **`architecture-review`** reads it at
**system altitude**: failure modes across an integration boundary, a hotspot or single writer under
load, consistency assumed atomic across services. `spec-author` may also read it **generatively** when
shaping a change's failure/observability model — *what resilience must this design decide up front?*

It overlaps two neighbors by design, and the framing keeps them distinct: where `design-patterns`
judges the *structure* (a singleton bean, a proxy/decorator), this lens judges the *runtime
consequence* (the data race, the advice silently skipped). Where `testing` asks whether a failure path
is *tested*, this lens asks whether the failure path is *handled*. Both can fire on one diff with
different findings. Load this lens only when the change actually touches a process/network boundary, a
transaction or concurrency boundary, a query, a resource, or the observability of a risk-bearing flow.

## Purpose

Help a skill judge whether a change is safe in production — under a slow dependency, a retried request,
concurrent load, and a growing dataset — and separate a real, nameable failure mode from speculative
hardening. Bias toward restraint: resilience machinery (a retry, a circuit breaker, a cache, a new
thread pool) is itself code, latency, and a failure surface, so it earns its place only where the
failure it guards is real. A few strong, consequence-backed findings beat a wall of "add a timeout
everywhere."

## When to Use

Engage this lens when the diff shows a *production-risk* trigger:

- A call crossing a process or network boundary — an HTTP/RPC client, a database query, a message
  broker, a cache, a third-party SDK.
- A state-changing operation reachable by retry or redelivery — an endpoint, a message listener, a
  scheduled job, anything a client or broker can deliver more than once.
- A transactional or async boundary added or moved — `@Transactional`, `@Async`, `@Cacheable`,
  `@EventListener`, `@Scheduled`, or a new propagation/isolation choice.
- Shared or instance state on a bean, a `static`, or an in-memory cache that request threads touch.
- A repository query — especially one inside a loop, or one returning an unbounded collection.
- Resource acquisition — a stream, a connection, a lock, an executor, a file handle.
- New (or conspicuously absent) logging/metrics/tracing on a flow that can fail in production.

Do **not** engage for pure in-process logic with no I/O, no shared state, and no transaction — there
is no production failure mode to name, and the lens has nothing to say.

## Core Principle

Production-readiness is about behavior **off the happy path**: what happens when a dependency is slow
or down, when a request arrives twice, when two threads race, when the table has grown 100×. A finding
is worth raising only when you can name the runtime failure mode — *what breaks in production, and how*
(a thread pool exhausts, a payment double-charges, state corrupts, a query times out). "This has no
retry" is not a finding; "this has no timeout, so one slow downstream call holds the request thread
until the pool exhausts and the whole service stops serving" is.

Resilience is a trade, never free. Every timeout, retry, circuit breaker, cache, or extra pool adds
latency, configuration, and a new way to fail (a retry storm, a stale cache, a tripped breaker that
never resets). Recommend it only against a real failure mode, and **inspect the stack first** — every
resilience facility named below is version- and dependency-gated (`spring-retry`, Resilience4j,
`RestClient`, virtual threads). A suggestion the project can't compile or hasn't wired is noise.

## Severity Calibration

Map findings to the consuming skill's severity rubric (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md)).
For production-readiness findings:

- **MUST** — a concrete production hazard *now*. An external call on a request path with **no
  timeout** (one slow dependency exhausts the thread/connection pool and takes the service down). A
  **retry or redelivery on a non-idempotent state change** (duplicate charges, double-shipped orders).
  A swallowed exception on a **write path** that loses data silently. **Mutable shared state** on a
  default singleton bean written by concurrent requests (data race, corrupted state). A resource that
  **leaks on the error path**. A `@Transactional`/`@Async`/`@Cacheable` method bypassed by
  self-invocation so the advice **silently does not run**.
- **SHOULD** — a real, nameable operability cost that is not a defect today. An external call with a
  timeout but **no retry/fallback** where a transient blip is expected and would surface to the user.
  An **N+1** or an **unbounded query** on a path that will grow. A critical flow with **no metric or
  correlation** to diagnose a failure. A `Propagation.REQUIRES_NEW` or after-commit side effect whose
  consistency implication is unhandled.
- **NIT** — a metric name, a log-message wording, a tunable constant with no behavioral consequence.
  Never blocks.
- **NO_COMMENT** — speculative hardening with no current failure mode: a circuit breaker on an
  in-process call, a retry on an idempotent read that never fails, a bulkhead for load that will not
  occur. Stay silent.

**Overriding rule:** every finding above NO_COMMENT names a concrete runtime failure mode — what
breaks in production and how. If you cannot, drop it. Demands for resilience "to be safe," with no
named failure, default to NO_COMMENT.

## Review Questions

- If this downstream call hangs, what is the blast radius — one request, or the whole pool / service?
- If this operation runs **twice** (client retry, broker redelivery, at-least-once), is the second run
  safe, or does it duplicate an effect?
- If this transaction fails **midway**, does state stay consistent, or is there a partial write / a
  lost event from a dual write?
- Does this `@Transactional` / `@Async` / `@Cacheable` advice actually run, or is it bypassed by a
  same-bean self-invocation?
- Does this query's cost grow with the data — an N+1 fan-out, an unbounded result set, a lock held too
  wide?
- If this shared field is written by two request threads at once, is it safe — or is it a race on a
  singleton bean?
- If this fails in production at 3am, is there enough in the logs/metrics (and a correlation id) to
  know *what* failed and *why*?

## Heuristics

### External calls — timeouts, retries, fallback

**What to look for:** A call to an HTTP client, a third-party SDK, a broker, or a remote service with
**no connect/read timeout**; a `RestTemplate`/`RestClient`/`WebClient` built without timeouts; a retry
with no cap or backoff; a hard dependency on a downstream with no fallback where degradation was an
option.

**Why it matters:** A call with no timeout can block its thread indefinitely. Under load, blocked
threads (and the connections they hold) exhaust the pool, and a service that is merely *slow* downstream
becomes a *down* service upstream — the classic cascading failure. An uncapped retry without backoff
turns a downstream blip into a retry storm that amplifies the outage.

**When NOT to comment:** An in-process call, or a downstream that is already wrapped (gateway, mesh
sidecar, configured `RestClient` bean) with timeouts you can see. Do not demand a circuit breaker on a
call that has no realistic failure mode, or a fallback where failing fast is the correct behavior.

**Modern Spring idiom:** Set explicit connect/read timeouts on the client (a `ClientHttpRequestFactory`
for `RestClient`/`RestTemplate`, `responseTimeout` for `WebClient`). For retries, prefer a library with
**capped attempts + backoff + jitter** over a hand-rolled loop — `spring-retry` (`@Retryable`, needs
`@EnableRetry`) or Resilience4j (`@Retry`, `@CircuitBreaker`, `@TimeLimiter`, `@Bulkhead`). All are
dependency-gated: confirm the starter is on the classpath and the version before recommending the
annotation.

**Key review questions:** If this dependency stops responding, does this thread ever get its stack
back? Does a retry here risk amplifying a downstream outage, and is it idempotent (see below)?

**Example review comment:**
> MUST: `paymentClient.capture(...)` is called with no read timeout, so if the gateway stalls the
> request thread blocks indefinitely; under load the pool exhausts and the service stops serving every
> route, not just payments. Could we set a read timeout on the client and fail fast (or fall back) when
> it's exceeded?

### Idempotency under retry & redelivery

**What to look for:** A state-changing operation — an HTTP endpoint, a `@KafkaListener`/JMS consumer, a
`@Scheduled` job, a saga step — that assumes it runs **exactly once**, while the transport gives
**at-least-once** (client retries on timeout, broker redelivery on no-ack, a retry added two lines up).
The tell is a non-idempotent effect (charge, ship, increment, append) with no dedup key, no unique
constraint, no "already processed" check.

**Why it matters:** Networks and brokers retry. If the second delivery repeats the effect, the customer
is charged twice, the order ships twice, the counter is wrong — and the bug is invisible in tests that
deliver once. This is the failure mode that pairs with retries above: adding a retry to a non-idempotent
call *creates* this defect.

**When NOT to comment:** The effect is naturally idempotent (a pure read, a `PUT` that sets an absolute
value, an upsert keyed by a stable id), or idempotency is already enforced (unique constraint,
idempotency-key store, dedup table). Do not demand an idempotency key for a read.

**Modern Spring idiom:** Enforce idempotency at a durable layer, not in memory: a unique constraint /
idempotency key persisted in the same transaction as the effect; an "inbox" / processed-message table
for consumers; an `INSERT … ON CONFLICT DO NOTHING` (or `@Version` optimistic check) rather than a
read-then-write race. For state-change-plus-publish, the outbox pattern (see the `saga`/`cdc` lenses at
architecture altitude) avoids the dual-write that loses an event.

**Key review questions:** What delivers this — and can it deliver twice? If it runs again with the same
input, what is the second effect?

**Example review comment:**
> MUST: this listener charges the `Order` on each message, but the broker is at-least-once, so a
> redelivery double-charges. Could we key the charge on a persisted idempotency token (or a unique
> constraint on `(orderId, attempt)`) so a duplicate delivery is a no-op?

### Transaction boundaries & consistency

**What to look for:** A `@Transactional` method **called from another method on the same bean**
(`this.save(...)`) — the proxy is bypassed and the transaction never starts; an effect that must be
atomic split across two transactions or two stores (a dual write); a long transaction holding a
connection across a remote call; a `@TransactionalEventListener(phase = AFTER_COMMIT)` doing the *only*
persistence of a critical effect; a `Propagation.REQUIRES_NEW` whose partial-commit implication is
unconsidered.

**Why it matters:** A bypassed `@Transactional` runs with no transaction, so a mid-method failure leaves
a **partial write** with no rollback. A dual write can commit one side and lose the other (the order
saves, the event never publishes). An after-commit listener runs *outside* the original transaction, so
its side effect **cannot roll the transaction back** — if it fails, the main work has already committed
and the effect is silently lost.

**When NOT to comment:** The boundary is correct — the `@Transactional` is invoked across a bean
boundary, the unit of work is one aggregate in one transaction, the after-commit listener is a genuinely
non-critical reaction (an audit log, a best-effort notification). Do not invent a saga where one local
transaction suffices (that judgment lives in the `saga` lens).

**Modern Spring idiom:** Keep `@Transactional` on the use-case boundary and invoke it across a bean
boundary so the proxy applies. Keep one aggregate per transaction; for cross-aggregate consistency use
an outbox + an event, not a dual write. Use `@TransactionalEventListener(AFTER_COMMIT)` only for effects
that may safely happen after commit and need no rollback; for an effect that must be atomic with the
work, use a synchronous listener in the same transaction or a direct call. Verify the Spring version for
listener-phase semantics.

**Key review questions:** Does this transactional advice actually apply, or is it self-invoked? If the
method fails halfway, what is left committed? Is this effect safe to lose if the after-commit step
fails?

**Example review comment:**
> MUST: `OrderService.place()` calls `this.persist()`, which is `@Transactional`, from within the same
> bean — the proxy is bypassed, so `persist` runs with no transaction and a failure after the first
> write leaves a partial `Order`. Could we move `persist` behind a separate bean (or put the boundary on
> `place`) so the advice actually runs?

### Concurrency & shared mutable state

**What to look for:** A mutable instance field on a default (singleton-scoped) Spring bean
(`@Service`/`@Component`) read and written across requests; a non-thread-safe collection or `SimpleDateFormat`
shared as a field; a check-then-act on shared state with no synchronization; a `static` mutable holder
used as a cache.

**Why it matters:** A default Spring bean is a single instance shared by every request thread. A mutable
field on it is a **data race**: concurrent requests interleave reads and writes and corrupt state, drop
updates, or throw (e.g. `ConcurrentModificationException`, `HashMap` infinite loop). It passes every
single-threaded test and fails only under concurrent load — in production.

**When NOT to comment:** The bean is stateless (the common, correct case), the state is confined to a
method-local variable, or the field is immutable / properly synchronized / an atomic / a thread-safe
structure, or the bean is request- or prototype-scoped on purpose. Do not flag a `final` immutable
collaborator.

**Modern Spring idiom:** Keep singleton beans stateless — carry per-request state in method-local
variables, a request-scoped bean, or pass it explicitly. Where shared state is genuinely needed, use the
right tool: an `AtomicX`, a `ConcurrentHashMap`, an immutable snapshot, or a properly synchronized owned
component — not a bare field. (The `design-patterns` lens covers the *singleton* structure; this lens is
the runtime race it causes.)

**Key review questions:** Is this field written by request threads on a shared bean? Would two
simultaneous requests corrupt it?

**Example review comment:**
> MUST: `currentTotal` is a mutable field on this singleton `@Service`, and `accumulate()` writes it per
> request. Two concurrent requests race and the total corrupts — and no single-threaded test will catch
> it. Could we make the running total method-local, or move it to a request-scoped holder?

### Database access cost — N+1, unbounded results, locks

**What to look for:** A query inside a loop (load a list, then a related entity per element) — the N+1;
a `findAll()` or an unbounded query on a table that grows, loaded fully into memory; a missing
`Pageable` on an endpoint that returns a collection; a pessimistic lock or a transaction held wide
enough to serialize throughput.

**Why it matters:** An N+1 turns one logical read into N+1 round-trips — fine on 10 rows in a test,
crippling on 10,000 in production. An unbounded `findAll()` on a growing table is a latent **OOM /
timeout** that ships green and detonates as data accumulates. A lock held too wide is a contention
hotspot that caps throughput.

**When NOT to comment:** The result set is bounded and small by construction (a lookup by unique key, a
fixed small reference table), the fetch strategy is already correct (`@EntityGraph`, a join fetch, a
projection), or pagination is already present. Do not micro-optimize a cold path or a query whose size
is provably tiny.

**Modern Spring idiom:** Fix N+1 with a `JOIN FETCH`, an `@EntityGraph`, or a batch/projection query
instead of lazy-loading per element. Page unbounded reads with `Pageable`/`Slice`. Scope locks
narrowly; prefer optimistic locking (`@Version`) over pessimistic where contention is rare, and a
`@Lock(PESSIMISTIC_WRITE)` only where a real write-write race exists. Verify the JPA/Hibernate and
Spring Data versions for the API you suggest.

**Key review questions:** Does this issue one query or N? Does the result set have an upper bound, or
does it grow with the table? How wide is the lock/transaction held?

**Example review comment:**
> SHOULD: `orders.forEach(o -> customerRepo.findById(o.customerId()))` runs one query per order — an
> N+1 that's fine in the test's 5 rows but will dominate latency at production volume. A single
> `findAllById(customerIds)` (or a join fetch) would collapse it to one round-trip.

### Error handling & failure visibility

**What to look for:** A `catch` that swallows (logs and continues, or returns a default) on a path where
the failure matters — especially a write/charge/publish; a `catch (Exception)` so broad it hides
distinct failures; an exception caught and rethrown **losing the original cause**; a critical flow with
**no log context or metric** to diagnose a production failure.

**Why it matters:** A swallowed exception on a write path is **silent data loss** — the operation
"succeeds," the data isn't there, and no one knows until a customer complains. A lost cause turns a
3-minute diagnosis into a 3-hour one. A critical flow with no correlation id or metric is a blind spot
when it fails at 3am.

**When NOT to comment:** The catch is deliberate and correct (a genuinely optional, best-effort step
that should not fail the request, with a comment saying so), the cause is chained, and the failure is
observable. Do not demand a log line on every branch, or treat *deep* security/PII-in-log concerns as
this lens's job — a secret or PII written to a log is a `MUST` under the severity rubric and the
`security` lens; here, only flag the *diagnosability* gap.

**Modern Spring idiom:** Let exceptions propagate to a single boundary handler (`@ControllerAdvice` /
`@ExceptionHandler`) rather than swallowing locally; preserve the cause (`throw new XException("...",
e)`); add a metric (Micrometer `@Timed` / `Counter`) and a correlation id (MDC / the Observation API on
Boot 3.x) on flows that page someone when they break. Verify Micrometer/observability is wired before
recommending the API.

**Key review questions:** If this `catch` fires in production, does anyone find out — and is any data
quietly lost? Is the original cause preserved? Could on-call diagnose this failure from what's logged?

**Example review comment:**
> MUST: `saveInvoice` wraps the persist in `catch (Exception e) { log.warn(...); }` and returns
> normally, so a failed write looks like success and the `Invoice` is silently dropped. Could we let it
> propagate (or rethrow with the cause) so the caller — and the metric — see the failure?

### Resource lifecycle

**What to look for:** A `Closeable` opened without `try-with-resources` — an `InputStream`, a JDBC
`Connection`/`Statement`/`ResultSet` acquired manually, a `Lock` acquired without a `finally unlock`, an
`ExecutorService` created per call and never shut down, a file handle on an error-prone path.

**Why it matters:** A resource closed only on the happy path **leaks on the error path** — and leaks
accumulate until the pool, the file descriptors, or memory run out, taking the service down well after
the offending code shipped. A lock not released in `finally` deadlocks under the first exception.

**When NOT to comment:** The framework owns the lifecycle (Spring Data / `JdbcTemplate` / a managed
`DataSource` already close their resources), or the resource is already in a try-with-resources / a
`finally`. Do not flag a Spring-managed connection as a leak.

**Modern Spring idiom:** `try (var stream = ...) { ... }` for anything `AutoCloseable`; acquire a lock
then `try { ... } finally { lock.unlock(); }`; reuse a managed/injected `ExecutorService` (or a virtual-
thread executor on Java 21+ — verify the version) rather than creating and abandoning one per call; lean
on the framework's resource management instead of hand-managing JDBC.

**Key review questions:** If the line after this acquisition throws, does the resource still close? Is
this created per call and never released?

**Example review comment:**
> MUST: this opens an `InputStream` and closes it only after the parse succeeds, so a parse failure
> leaks the handle; under load the descriptors exhaust. A `try (var in = ...)` closes it on every path.

## Anti-Patterns

- **Unbounded external call** — *Diff:* an HTTP/SDK call with no connect/read timeout on a request
  path. *Harm:* one slow dependency blocks threads, the pool exhausts, the whole service stops serving.
  *Fix:* explicit timeouts; fail fast or fall back.
- **Retry on a non-idempotent effect** — *Diff:* `@Retryable` (or a manual loop) added around a charge /
  ship / append. *Harm:* a retried or redelivered call repeats the effect — double charge, double ship.
  *Fix:* make the effect idempotent (durable dedup key / unique constraint) before retrying.
- **Retry storm** — *Diff:* an uncapped retry with no backoff/jitter. *Harm:* a downstream blip is
  amplified into a self-inflicted DDoS. *Fix:* cap attempts, exponential backoff with jitter, a circuit
  breaker.
- **`@Transactional` self-invocation** — *Diff:* a `@Transactional` (or `@Async`/`@Cacheable`) method
  called via `this.method()` in the same bean. *Harm:* the proxy is bypassed, the advice silently does
  not run, a mid-method failure leaves a partial write. *Fix:* invoke across a bean boundary, or move the
  annotation to the entry method.
- **Dual write** — *Diff:* save to the DB and publish to a broker in the same method, non-atomically.
  *Harm:* one side commits and the other is lost — the order persists, the event never fires. *Fix:* an
  outbox written in the same transaction, relayed afterwards.
- **Mutable singleton state** — *Diff:* a mutable field on a default-scoped `@Service` written per
  request. *Harm:* a data race under concurrent load; corrupted/lost state that no single-threaded test
  catches. *Fix:* keep the bean stateless; confine state to method-local / request scope / a thread-safe
  holder.
- **N+1 query** — *Diff:* a repository call inside a loop over a result set. *Harm:* N+1 round-trips;
  fine in tests, crippling at production volume. *Fix:* a join fetch / `@EntityGraph` / batch query.
- **Unbounded result set** — *Diff:* `findAll()` (or a query with no limit) on a growing table loaded
  into memory. *Harm:* a latent OOM/timeout that detonates as data accumulates. *Fix:* `Pageable` /
  `Slice` / a bounded query.
- **Swallowed exception on a write** — *Diff:* `catch (Exception) { log; }` then return normally on a
  persistence/charge path. *Harm:* silent data loss masquerading as success. *Fix:* propagate (or rethrow
  with the cause) so the failure surfaces and is observable.
- **Leaked resource** — *Diff:* a `Closeable`/lock closed only on the success path. *Harm:* leaks on
  error accumulate until the pool/FDs/memory exhaust. *Fix:* `try-with-resources` / `finally`.

## Modernization (Java/Spring production idioms)

Standing guidance: **inspect the target project's stack before recommending anything.** Resilience and
observability facilities are all version- and dependency-gated; a suggestion the project hasn't wired or
can't compile is worse than none. Frame each as *verify against the actual project*:

- **Client timeouts** — `RestClient`/`RestTemplate` via a configured `ClientHttpRequestFactory`,
  `WebClient` via `responseTimeout`. *Verify which client the project uses; `RestClient` is Spring
  Framework 6.1+/Boot 3.2+.*
- **`spring-retry`** — `@Retryable` + `@Recover`, requires the `spring-retry` dependency and
  `@EnableRetry`. *Verify both are present before suggesting the annotation.*
- **Resilience4j** — `@Retry`, `@CircuitBreaker`, `@TimeLimiter`, `@Bulkhead`, requires the Resilience4j
  Spring Boot starter. *Verify the starter and the Boot-compatible version.*
- **Idempotency / outbox** — a durable dedup key, a unique constraint, or an outbox table relayed by an
  event or CDC. *Architecture-level decisions; cross-reference the `saga`/`cdc` lenses, and verify the
  datastore supports the constraint.*
- **Transaction semantics** — `@Transactional` proxy rules, `propagation`, `readOnly`,
  `@TransactionalEventListener` phases. *Verify the Spring version for listener-phase behavior; the
  self-invocation caveat is version-independent.*
- **JPA fetch & paging** — `@EntityGraph`, `JOIN FETCH`, `Pageable`/`Slice`, `@Version` optimistic /
  `@Lock` pessimistic. *Verify the Spring Data / Hibernate version for the API.*
- **Virtual threads** — for high-concurrency blocking I/O, Java 21+ with
  `spring.threads.virtual.enabled` on Boot 3.2+. *Verify the Java version and that the workload is
  I/O-bound; beware pinning on `synchronized` and pooled-resource limits — virtual threads do not remove
  the need for downstream timeouts.*
- **Observability** — Micrometer metrics (`@Timed`, counters), the Observation API and tracing on Boot
  3.x, a correlation id via MDC. *Verify Micrometer/Actuator is on the classpath before recommending the
  API.* (Deep security/PII-in-log concerns are the severity rubric's and the `security` lens's
  job, not this one.)

When the simplest correct thing is *no* extra machinery — the call is in-process, the effect is
idempotent, the dataset is bounded — say so plainly. The deterministic, named failure mode is the
target, not maximal resilience.

## Suggested PR Comment Style

Respectful, consequence-first, severity-honest. Lead with the production failure mode, not the rule.
Make NITs explicitly optional, and endorse code that is already safe. Example openers:

- "This may take the service down under load because..." (names the blast radius)
- "If this is delivered twice..." (names the idempotency failure)
- "NIT (not a blocker): ..." (flags a tunable/name with no behavioral consequence)
- "This boundary looks right — timeout and fallback are both here, no change needed."

Short examples with neutral nouns:

- > MUST: `ledgerClient.post(...)` has no read timeout, so a stalled ledger blocks the request thread
  > and the pool exhausts under load. Could we set a timeout and fail fast?
- > SHOULD: the new `findAll()` on `AuditEntry` is unbounded; it's small today but grows forever, so this
  > becomes an OOM later. A `Pageable` query would bound it.
- > NIT (not a blocker): the retry count `5` could be a named constant so the intent is visible. Fine to
  > leave.

## Integration (java-pr-review and architecture-review)

- Apply with the consumer's altitude: `java-pr-review` reasons about the **changed lines** (this call,
  this listener, this field); `architecture-review` about **system failure modes** (this boundary, this
  hotspot, this cross-service consistency). Same lens, different grain.
- **Never raise a finding without a named runtime failure mode.** "No retry / no circuit breaker / no
  cache" is `NO_COMMENT` unless you can say what concretely breaks in production. Speculative hardening is
  not a finding.
- **Never block on speculative resilience.** Resilience machinery is a cost; demand it only against a
  real failure. A defensible "no extra machinery" is the correct, frequent outcome.
- **Always tag severity** — MUST / SHOULD / NIT — per the consuming skill's rubric, and always name the
  concrete consequence. NO_COMMENT is the silent fourth outcome.
- **Stay in your lane.** Pattern *structure* is the `design-patterns` lens; whether a path is *tested* is
  the `testing` lens; deep security/PII is the rubric and the `security` lens. This lens owns the
  runtime production consequence — the timeout, the idempotency, the race, the leak, the partial write.
- **Prefer a few strong findings over many weak ones.** One unguarded external call or one double-charge
  risk lands; ten "consider a timeout" notes bury it.
