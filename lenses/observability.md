# Observability Lens

Reusable instrumentation knowledge for Java/Spring: whether a changed flow can be **operated and
diagnosed in production** — read from its logs, measured by its metrics, traced across its
boundaries, watched by its health checks, and alerted on when it actually breaks. Not *whether* a
risk-bearing flow has some visibility (that gap is named elsewhere) but whether the visibility it has
is **good** — structured, correlated, low-cardinality, and tied to a signal someone can act on. The
*intent* of applying it — which diffs, how strict, whether to block — comes from the consuming skill,
not from this lens.

## How skills use this lens

This lens has three consumers, at different altitudes and with different intents.

- **`java-pr-review`** reads it with a **diff/PR focus** at the line/method level: *this* log line
  concatenates a string instead of carrying key-value fields, *this* `Counter` tags a metric with an
  `orderId`, *this* `@Async` boundary drops the trace context, *this* exception is logged at `DEBUG`
  on a write path. It is the line-level companion to the production-readiness lens — where that lens
  asks *is the failure handled*, this lens asks *is the instrumentation around it diagnosable*.
- **`architecture-review`** reads it at **system altitude**: does a request keep one correlation id as
  it crosses three services; what does this integration *measure* (the RED signals on the boundary,
  the saturation of the pool behind it); does the design name what **pages someone** versus what is
  noise; is a money-movement flow observable enough that an operator learns it is failing *before* a
  customer does. The architecture-review skill already lists **"Observability at boundaries — when a
  cross-context or cross-service flow fails, can it be traced and diagnosed … or is the integration a
  blind spot?"** as a system concern; this lens is the depth behind that bullet.
- **`spec-author`** reads it **generatively** when shaping a change's observability model. The
  spec-author skill is told to record *"the signals and correlation id that make a cross-boundary flow
  diagnosable"* for any risk-bearing path; this lens supplies the *decisions* behind that line — what
  to instrument, which metric type, what label is safe to attach, what threshold pages, what stays at
  `INFO`.

That shared use — evaluative for the two review skills, generative for `spec-author` — is exactly why
this knowledge lives in `lenses/` rather than inside one skill: each consumer brings its own intent,
the lens brings the knowledge. Load it only when the change actually touches logging, metrics,
tracing, health/readiness, or the diagnosability of a flow that can fail — never because the word
"metric," "trace," or "log" appears in a name.

## Purpose

Help a skill judge whether a change can be **run and diagnosed in production**, and separate a real,
nameable operability defect from instrumentation dogma. The bias is toward restraint: every log line,
every metric series, and every span is itself cost — disk, ingestion bill, query latency, and noise
that buries the one signal that matters. Instrumentation earns its place only where it answers a
question an operator will actually ask at 3am, or guards against a concrete operability hazard (a
cardinality explosion, a trace that dies at a boundary, a flow that fails silently with nothing to
alert on). A few strong, consequence-backed findings beat a wall of "add a metric here" and "log this
too."

This lens is deliberately the *deep* instrumentation layer. The production-readiness lens flags that a
visibility **gap exists** ("this critical flow has no metric or correlation id") as a `SHOULD`, as part
of error handling. This lens owns the **quality of the instrumentation that is there**: whether the log
is structured and queryable, whether a metric's labels will detonate the time-series database, whether
the trace context actually survives the async hop, whether the alert fires on a symptom a human can
act on. The two fire on the same diff with different findings, and the carve below keeps them distinct.

## When to Use

Engage this lens when the diff or design shows an *observability* trigger:

- A **log statement** added or changed on a flow that matters — especially string concatenation where
  key-value fields belong, a level that misrepresents severity, or a log on a hot path.
- A **metric** registered or emitted — a Micrometer `Counter`, `Timer`, `Gauge`, `@Timed`,
  `DistributionSummary` — *especially one whose tag/label value is derived from request data*
  (an id, an email, a path with an embedded id, a free-text reason).
- A **trace / correlation boundary** — a new `@Async`, an `ExecutorService` submit, a `@Scheduled`
  job, a `@KafkaListener`/JMS consumer, a `CompletableFuture`, a manual thread, a reactive operator —
  anywhere the request context must be carried across a thread or a message and might be dropped.
- **MDC** usage — a key put into the logging context, and (the usual bug) not cleared, or not
  propagated to a worker thread.
- A **risk-bearing flow** (money movement, `Payment` capture, `Account` mutation, an irreversible
  side effect) reachable in production where the question is *would an operator know it is failing*.
- **Health / readiness** wiring — an Actuator `HealthIndicator`, a readiness/liveness probe, a
  dependency added to a health group.
- An **alert / threshold** defined or implied — what condition is meant to page someone, and whether
  it fires on a symptom or on noise.

Do **NOT** engage when the change is pure in-process logic with no failure mode worth watching, a cold
administrative path no one diagnoses under pressure, or a trivial CRUD endpoint whose existing
framework instrumentation already covers it. There is no operability question to answer, and the lens
has nothing to say. **And do NOT engage merely because the words appear** — a class named
`MetricsConfig`, a package called `telemetry`, or an injected `MeterRegistry` is not itself a trigger;
the trigger is instrumentation whose *quality* has a consequence.

## Core Principle

Observability is the ability to **answer questions about production you did not know you would need to
ask** — from the outside, without attaching a debugger or shipping new code. The three signals serve
distinct questions: **logs** answer *what happened in this specific case* (and must be queryable to be
worth keeping); **metrics** answer *how often / how slow / how saturated, in aggregate* (and must be
bounded in cardinality to be affordable); **traces** answer *where in the path of one request the time
went or the failure occurred* (and must keep one identity across every hop to be reconstructable). A
finding is worth raising only when you can name what an operator **cannot do** because the
instrumentation is wrong — *what question goes unanswerable, what cost detonates, what failure stays
invisible*. "This should log more" is not a finding; "this logs the failure by concatenating the
`Order` id into the message, so on-call cannot filter the 4am spike by anything and the one failing
tenant is unfindable in 50k lines" is.

Instrumentation is a trade, never free. A metric is a time series that costs storage and query time
*per unique label combination*; a label drawn from unbounded request data (a `userId`, an `orderId`, a
raw URL) multiplies the series count without bound and can take the metrics backend down or run up the
bill — the **cardinality explosion**, the single most expensive observability mistake. A log line on a
hot path is I/O and ingestion volume that drowns the signal. A span on every trivial call is trace
overhead with no diagnostic payoff. Recommend instrumentation only against a real operability
question, and **inspect the stack first** — every facility named below (Micrometer, the Observation
API, Micrometer Tracing, Actuator, a structured-logging encoder, the tracing backend) is
version- and dependency-gated. A suggestion the project hasn't wired or can't compile is noise.

## Severity Calibration

Map findings to the consuming skill's severity rubric (see
[`../rules/severity-rubric.md`](../rules/severity-rubric.md)). For observability findings:

- **MUST** — a concrete operability hazard *now*.
  - A **metric label of unbounded cardinality** — a `userId`, `orderId`, `email`, raw request path, or
    free-text value attached as a tag (`Counter … .tag("orderId", id)`). The series count grows with
    traffic without bound; the time-series database OOMs or the metrics bill explodes, and the metric
    becomes unusable or takes the backend down with it. This is the cardinality explosion.
  - A **trace/correlation context dropped at an async or messaging boundary** — work handed to an
    executor, a `@Async` method, a `CompletableFuture`, or a broker consumer that does not propagate
    the context, so the downstream work has *no* correlation id and a production incident in that path
    is undiagnosable (the failing request cannot be tied to anything upstream).
  - A **money-movement / irreversible flow with no alertable failure signal at all** — a `Payment`
    capture, a `Transfer`, a `Ledger` post whose failure increments nothing and logs nothing an alert
    can match, so the system is **blind to its own failure**: it fails and no one is paged until a
    customer complains. (This is the observability *angle* — "blind to alert on" — carved against the
    production-readiness lens's "no metric on a critical flow"; see the carve below.)
  - A **secret, token, or PII written to a log** is a `MUST`, but it is the **`security` lens's and the
    rubric's** `MUST`, not this lens's — defer it (see "stay in your lane").
- **SHOULD** — a real, nameable operability cost that is not a defect today.
  - A **string-concatenated log on a diagnosable flow** (`log.info("processed order " + id + " for "
    + amount)`) where structured key-value fields belong — the line is not machine-queryable, so
    filtering/aggregating by `orderId` or `amount` across a spike is impossible.
  - A **multi-service flow with no correlation id** threaded through it, so a failed run is a scatter of
    unrelated log lines across services with nothing tying them together. (When the flow is a
    *multi-step saga*, this is the [`./saga.md`](./saga.md) lens's correlation concern; here it is a
    general cross-service request.)
  - A **log level that misrepresents severity** — a genuine error on a write path logged at `DEBUG`
    (invisible in production where `DEBUG` is off) or routine flow logged at `ERROR` (alert fatigue
    that trains on-call to ignore the channel).
  - An **alert defined on a cause, not a symptom** — paging on CPU% rather than on user-visible error
    rate or latency, so the page does not correlate with anything broken and on-call learns to mute it.
- **NIT** — a metric *name* (`orders_processed` vs `order.processed.count`), the wording of a log
  message, a tag *key* spelling, a tunable threshold constant with no behavioral consequence. Worth a
  brief labeled note, never a blocker.
- **NO_COMMENT** — speculative or low-value instrumentation: a dashboard or a custom metric for a
  trivial, never-diagnosed path; a span on an in-process call that adds trace overhead with no
  question to answer; "add logging" on a flow that already fails loudly and is already covered;
  instrumenting a cold administrative path no one watches under pressure. Stay silent.

**Overriding rule:** every finding above NO_COMMENT names a concrete operability consequence — what an
operator cannot do, what cost detonates, what failure stays invisible, what page fires falsely. "This
isn't observable enough" / "add a metric" / "use structured logging everywhere" with no named
consequence is **NO_COMMENT**, no matter how far the code is from a textbook observability shape.
Demands for instrumentation "for completeness," with no question it answers, default to NO_COMMENT.

## Review Questions

- If this fails at 3am, what does on-call **see** — a queryable structured event with the ids needed to
  scope the blast radius, or a string they cannot filter?
- Does any **metric label here take a value drawn from request data** (an id, an email, a raw path)? If
  so, how many distinct series does that create over a day — bounded, or unbounded with traffic?
- When this work crosses a **thread, async, or message boundary**, does the trace/correlation context
  go with it — or does the downstream side start with no identity tying it to the request that caused
  it?
- Is the **log level honest** — does an `ERROR` here mean someone should look, and would a real failure
  on this path be visible at the level production actually runs?
- For this risk-bearing flow, is there a signal an **alert can match on its failure** — and does that
  alert fire on a **symptom a human acts on** (error rate, latency, a stuck queue) rather than a cause
  that may be benign (a CPU blip, a GC pause)?
- Does this **MDC** key get **cleared** after the request (or is it set on a pooled thread that will
  carry it into the next, unrelated request)?
- Does this **health/readiness** check actually reflect the thing it gates — does readiness fail when a
  required dependency is down, and does liveness *not* fail for a transient downstream blip?
- Is this instrumentation **on the hot path**, and is its volume/cardinality worth the signal — or does
  it drown the signal it is meant to provide?

## Heuristics

### Structured, queryable, right-level logging

**What to look for:** A log statement built by **string concatenation or interpolation**
(`log.info("charged " + amount + " to " + accountId)`) where the variable parts should be **key-value
fields**; a **level that misrepresents severity** (a swallowed real error at `DEBUG`/`TRACE` so it is
invisible in production; routine success at `WARN`/`ERROR` so the alert channel is noise); a log **on a
hot path** emitted per element of a large loop; a message that records *that* something happened but
not the **ids needed to scope it** (no `orderId`, no tenant, no correlation id).

**Why it matters:** Logs are only worth their cost if you can **query** them. A concatenated message is
opaque to the log backend — you cannot filter "all failures for `Account` 42" or aggregate by tenant,
so during an incident on-call greps free text across tens of thousands of lines instead of filtering a
field. A wrong level is a different failure: an error logged at `DEBUG` is *invisible* in production
(where `DEBUG` is off), so the failure happens silently; routine traffic at `ERROR` floods the alert
channel until on-call learns to ignore it, and then misses the real one. A per-element log on a hot path
is volume that buries the signal and runs up the ingestion bill.

**When NOT to comment:** The logging is already structured (an MDC/argument-based logger, a JSON
encoder) and the level matches severity; a one-off concatenation on a genuinely cold path that no one
queries under pressure; a debug log that is correctly at `DEBUG` and off in production. Do not demand
structured logging on a throwaway admin command, and do not rewrite a log line purely for wording —
**message text is a NIT at most.** Do not treat a secret/PII appearing in the log as *this* lens's
finding — that is the `security` lens's `MUST` (defer it; flag only the structure/level here).

**Modern Java/Spring idiom:** Pass the variable parts as **arguments / key-value fields**, not
concatenated into the message — SLF4J placeholders (`log.info("charged {} to account {}", amount,
accountId)`) at minimum, and a **structured (JSON) encoder** or a fluent/structured logging API so the
fields are first-class and queryable; Spring Boot 3.4+ has built-in structured logging
(`logging.structured.format`) — *verify the Boot version before recommending it.* Put stable
request-scoped identifiers in **MDC** once so every line inherits them rather than threading them by
hand. Reserve `ERROR` for "a human should look," `WARN` for "degraded but handled," `INFO` for
business-meaningful milestones, `DEBUG` for diagnosis that is off in production.

**Key review questions:** Could on-call filter these logs by the id that scopes the incident, or only
grep free text? Is a real failure on this path visible at the level production runs? Does this fire once
per request, or once per row in a large loop?

**Example review comment:**
> SHOULD: `log.info("settlement failed for " + transferId + ": " + reason)` concatenates the ids into
> the message, so when settlements spike at 4am on-call can't filter by `transferId` or group by
> `reason` — they're grepping free text across the whole stream. Could we pass them as fields
> (`log.warn("settlement failed", kv("transferId", transferId), kv("reason", reason))`) so the failure
> is queryable? (Also note this is a handled failure, not a crash — `WARN` reads truer than `INFO`.)

### Metric type and RED/USE — measuring the right thing

**What to look for:** A new metric and whether its **type fits the question**: a `Counter` for a
monotonic count of events (requests, errors, retries), a `Timer`/`@Timed` for latency *and* throughput
of an operation, a `Gauge` for a current level that goes up and down (queue depth, pool in-use, cache
size), a `DistributionSummary` for a non-time distribution. The tells of a mismatch: a `Gauge` used to
count events (it samples, it loses counts), a `Counter` read as if it were a rate without a rate
function, latency tracked as a `Gauge` of "last duration" (no percentiles), or a hand-rolled timing
block where a `Timer` belongs. At system altitude: does a request-serving boundary expose the **RED**
signals (Rate, Errors, Duration) and a resource expose the **USE** signals (Utilization, Saturation,
Errors), or is the thing that will page someone simply not measured?

**Why it matters:** The wrong metric type answers the wrong question or answers none. A `Gauge`
incremented per event under-counts under concurrency and on scrape gaps — you cannot trust the total. A
latency captured as "last value" hides the tail: the p99 that is timing out is invisible behind a
healthy mean. If a request boundary measures neither error rate nor latency, the operator has no symptom
to alert on and learns of an outage from customers. RED/USE are not ceremony; they are the minimum that
lets someone answer "is this endpoint healthy, and if not, is it erroring or just slow?"

**When NOT to comment:** The metric type already fits (a `Timer` on the operation, a `Counter` on the
events, a `Gauge` on the level) and the boundary's RED signals are present (often free via the
framework's HTTP/server metrics — do not re-add what Actuator already emits). A cold path that no
dashboard or alert consumes does not need RED instrumentation — **NO_COMMENT.** Do not demand a custom
metric where the auto-configured one already answers the question.

**Modern Java/Spring idiom:** **Micrometer** as the facade — `MeterRegistry` to register, `@Timed` or a
`Timer` for operation latency+rate, `Counter.builder(...)` for event counts, `Gauge.builder(...)` (with
a weak reference to the measured object) for levels, `DistributionSummary` for sizes. Enable client-side
percentiles/histograms on a `Timer` only where the backend needs them. Lean on Spring Boot Actuator's
auto-configured HTTP-server, datasource, and executor metrics for RED/USE at the standard boundaries
rather than hand-rolling them. *Verify Micrometer and the Actuator metrics starter are on the classpath,
and which registry (the monitoring backend) is wired, before recommending an API or a percentile
config.*

**Key review questions:** Does this metric's type match what's being asked — a count, a
rate+latency, or a current level? Does this boundary expose rate, errors, and duration, or only one?
Is anything here already emitted by Actuator?

**Example review comment:**
> SHOULD: `processingLatencyGauge.set(elapsedMillis)` records only the *last* duration, so the p99 that
> matters during a slowdown is invisible — the gauge shows whatever the most recent call happened to
> be. A `Timer` (or `@Timed` on the method) records the distribution and the count together, so you get
> latency percentiles and throughput from one meter. Verify Micrometer's registry is wired to the
> backend first.

### Cardinality control — the label that detonates the backend

**What to look for:** A metric tag/label whose **value is drawn from unbounded request data** — a
`userId`, `orderId`, `accountId`, `email`, a session id, a raw URL with an embedded id, an exception
*message* (often unique), or a free-text `reason`. The signal is any `.tag(key, x)` /
`Tags.of(...)` / `@Timed(extraTags = ...)` where `x` is per-request rather than from a small fixed set.
At system altitude: a metric whose label space is the product of several such dimensions (tenant ×
endpoint × status × user), which multiplies into an explosion even if each looks bounded.

**Why it matters:** A time-series database stores **one series per unique combination of label
values**. A label drawn from request data has effectively unbounded distinct values, so the series
count grows with traffic without limit — millions of dead, one-sample series. This is the **cardinality
explosion**: it OOMs the metrics backend, blows up the storage/ingestion bill, and slows every query
(including the dashboards you need *during* the incident the explosion may be causing). It is the single
most expensive and most common observability mistake, and it ships green because in a test with three
users the cardinality looks fine. The high-cardinality identifier belongs on a **trace or a log line**
(where per-request detail is the point), never on a metric label (where aggregation is the point).

**When NOT to comment:** The labels are all from a **small, bounded, known set** — an HTTP method, a
status-code *class* (`2xx`/`4xx`/`5xx`, not the raw code per path), an endpoint *template*
(`/orders/{id}`, not `/orders/12345`), a fixed enum of outcomes. A per-request id placed on a **span or
a log field** (not a metric tag) is correct — do not flag that. Do not invent a cardinality problem for
a label whose value set is provably tiny.

**Modern Java/Spring idiom:** Keep metric tags to a **bounded, low-cardinality** set; put the
high-cardinality identifier on the **trace** (a span attribute / baggage) or a **structured log field**
instead. Use the **route template**, not the concrete URL, as the tag (Spring's `uri` tag already does
this via `WebMvcTags`/`ServerHttpObservation` — *verify the Boot version*). For exceptions, tag with the
exception **class**, not the (often unique) message. If a per-entity breakdown is genuinely needed, that
is a logging/tracing or analytics query, not a metric dimension. *Verify the registry and the backend's
cardinality limits before relying on any tag.*

**Key review questions:** What is the value set of this tag — bounded enum, or unbounded request data?
How many series does (this tag × the others) produce over a day at production traffic? Does the
identifier belong on a metric at all, or on a trace/log?

**Example review comment:**
> MUST: `Counter.builder("payment.attempt").tag("accountId", accountId).register(registry)` puts the
> `accountId` on a metric label, so every distinct account creates its own time series — millions of
> one-sample series that OOM the metrics backend and run up the bill, and the counter stops being
> usable. Drop `accountId` from the tag (keep a bounded one like the `status` class), and if you need
> per-account detail put it on the trace span or a structured log field where per-request cardinality
> is the point.

### Trace & correlation propagation across boundaries

**What to look for:** Work that crosses a **thread, async, or message boundary** where the
trace/correlation context must be carried and might be dropped: a task handed to a raw
`ExecutorService`/`ThreadPoolTaskExecutor`, a `@Async` method, a `CompletableFuture.supplyAsync`, a
manually started thread, a reactive operator chain, or a `@KafkaListener`/JMS handler that does not
extract the incoming trace context. The tell is an MDC value or a trace id that is present on the
request thread and **absent** on the worker — log lines from the async work carry no correlation id, and
the trace shows a gap (a new, unlinked trace) at the hop.

**Why it matters:** A trace/correlation id is the thread that ties a request's work together across
threads and services. If it is **dropped at a boundary**, the downstream work becomes an orphan: its
logs have no correlation id, its span is a fresh disconnected trace, and when *that* part fails in
production the incident is **undiagnosable** — there is no way to tie the failing async work back to the
request that caused it or to the user-visible symptom. This is the failure that pairs with the async
boundaries the production-readiness lens watches: adding a `@Async` or an executor without propagating
context *creates* this blind spot. MDC is especially treacherous because it is `ThreadLocal` — it does
**not** cross to a worker thread by default, and a value left in a **pooled** thread leaks into the next,
unrelated request (wrong correlation id, or worse, the previous request's user attached to this one's
logs).

**When NOT to comment:** The context propagation is already handled — a context-propagating task
decorator on the executor, Micrometer's context propagation wired, the broker's trace headers
extracted, MDC explicitly captured-and-restored around the hop and **cleared** in a `finally`. The work
does not cross a thread/service boundary at all (a plain in-process call keeps the same thread and the
same context). Do not demand trace plumbing for synchronous in-thread work that already has it.

**Modern Java/Spring idiom:** On Spring Boot 3.x, prefer the **Observation API** (`ObservationRegistry`,
`@Observed`) with **Micrometer Tracing** so the context is a first-class thing that the framework
propagates; wrap executors with the framework's **context-propagating decorator** (e.g.
`ContextSnapshot`/`TaskDecorator` integration) so the trace and MDC cross to worker threads; rely on the
auto-instrumented broker integrations to carry trace headers on messages. Where you set MDC by hand,
**capture and restore** it around the async hop and **clear it in `finally`** so a pooled thread does not
leak it. *Verify the Boot version, that Micrometer Tracing and a tracer bridge are on the classpath, and
which propagation format the system uses, before recommending the API.* (Correlation across a *multi-step
saga* specifically is the [`./saga.md`](./saga.md) lens's concern — this heuristic is general request
context across any thread/async/message boundary.)

**Key review questions:** Does the trace/correlation id cross this boundary, or does the worker start
with none? Is this MDC value cleared after the request, or will the pooled thread carry it into the next
one? If the async part fails in production, can you tie it back to the request that triggered it?

**Example review comment:**
> MUST: `executor.submit(() -> reconcile(batch))` runs on a pool thread that doesn't inherit the
> request's MDC or trace context, so the reconcile logs carry no correlation id and show up as an
> unlinked trace — when reconciliation fails in production there's nothing tying it back to the request
> that scheduled it. Wrap the executor with the framework's context-propagating decorator (and clear
> MDC in `finally` so the pooled thread doesn't leak it) so the trace survives the hop.

### Alertable signals — what pages a human

**What to look for:** Whether a **risk-bearing flow has a signal an alert can fire on**, and whether
that alert fires on a **symptom** (something the user feels) rather than a **cause** (something that may
be benign). The triggers: a money-movement or irreversible flow whose failure increments nothing and
logs nothing matchable; an alert (or a metric clearly intended for one) defined on CPU%, memory, GC
pauses, or thread count — internal causes that do not by themselves mean anything is broken; an alert
with no actionable response; an `ERROR` log used as a de-facto alert on a path that errors routinely.

**Why it matters:** The point of instrumentation on a risk-bearing flow is that **a human is paged when
it actually breaks**, before a customer notices. A flow that fails silently — no error counter, no
matchable log — is **blind to alert on**: it can be failing for hours and no one is told. That is the
observability angle on a critical flow, distinct from "is the failure *handled*" (production-readiness)
and "is the failure path *tested*" (testing). Equally damaging is the alert that pages on the wrong
thing: paging on high CPU produces a page that does not correlate with any user impact (CPU is often
high when healthy), so on-call burns out and mutes the channel — and then misses the real
symptom-based page. **Symptom-based alerting** (error rate, latency SLO burn, a stuck/growing queue,
failed money movements) pages when users are actually hurt; cause-based alerting pages on noise.

**When NOT to comment:** The flow already has a symptom signal an alert matches (an error counter, a
latency SLO, a failure log with a stable matchable shape) and the alerting fires on user-visible impact.
A non-critical, easily-retried, fully-recovered path does not need a page — **NO_COMMENT.** Do not demand
an alert on every branch, and do not flag a *cause* metric that exists only as a diagnostic dashboard
(not wired to a page) — diagnostics and alerts are different jobs.

**Modern Java/Spring idiom:** Emit a **bounded-cardinality error/outcome metric** on the risk-bearing
flow (a `Counter` tagged with a small `outcome`/`status`-class set) so an alert can fire on the failure
*rate* or *ratio*, and a latency `Timer` so an SLO-burn alert can fire on slowness — alert on the
**symptom**, define the threshold against a target (an SLO), and keep cause metrics (CPU, GC, pool
saturation) as **diagnostic** signals you pivot to *after* a symptom page, not as the pager itself.
*The alert rules themselves usually live in the monitoring backend, not the Java code — verify where
they are defined; this lens judges whether the code emits a signal an alert can use.*

**Key review questions:** If this flow fails in production, what fires a page — and does that signal
exist? Does the alert fire on something a user feels, or on an internal cause that may be benign? Is
there an action on-call takes when it fires, or is it noise?

**Example review comment:**
> MUST: the `Transfer` capture path catches and retries internally but emits no failure metric and no
> matchable failure log, so when captures start failing in production nothing pages anyone — the system
> is blind to its own failure on a money-movement path until a customer reports it. Emit a
> bounded-cardinality outcome counter (`transfer.capture` tagged `outcome=success|failed`) so an alert
> can fire on the failure ratio. (The retry handling itself is the production-readiness lens's concern;
> this is about being able to *alert* on the failure.)

### Health, readiness & liveness

**What to look for:** Health/readiness/liveness wiring and whether each check **reflects what it
gates**: a readiness probe that does *not* fail when a **required** dependency (the database, a
must-have downstream) is down — so the instance keeps receiving traffic it cannot serve; a liveness
probe that fails on a **transient** downstream blip — so the orchestrator kills and restarts a healthy
pod in a crash loop; a custom `HealthIndicator` that does expensive work on every probe; a health check
that **leaks** internal detail (versions, dependency hostnames) on an unauthenticated endpoint.

**Why it matters:** Readiness and liveness drive **orchestration decisions**, so getting them wrong has
a concrete operational cost. A readiness check that ignores a down required dependency keeps routing
traffic to an instance that will only error — the load balancer sends users to a broken pod. The mirror
mistake — liveness that fails on a transient downstream blip — makes the orchestrator **restart** the
instance (liveness failure = "kill me"), turning a brief downstream hiccup into a self-inflicted crash
loop across the fleet. A heavyweight check run on every probe adds load precisely when the system is
already stressed. (A health endpoint that exposes secrets/internals is primarily the `security` lens's
concern; flag here only the operational-correctness of what the check gates.)

**When NOT to comment:** The probes already separate **liveness** (am I alive — restart me if not) from
**readiness** (can I serve traffic right now — route around me if not) correctly, required dependencies
are in the readiness group and optional ones are not, and the checks are cheap. Do not demand a custom
`HealthIndicator` for a dependency whose absence does not actually make the instance unable to serve, and
do not put a *non-required* dependency in readiness (a brief blip there should not pull the whole
instance out of rotation).

**Modern Java/Spring idiom:** Spring Boot Actuator's **liveness and readiness** probes
(`management.endpoint.health.probes.enabled`, the `/actuator/health/liveness` and `/readiness` groups)
distinguish the two; a custom `HealthIndicator` contributes a dependency's status to a group — put a
**required** dependency in **readiness** so the instance is pulled from rotation (not killed) when it is
down, and keep **liveness** reflecting only the process's own health so a downstream blip does not
trigger a restart. Keep indicators cheap. *Verify the Actuator version and which probe groups are
configured before recommending the property.*

**Key review questions:** Does readiness fail when a required dependency is down (route around me) and
liveness *not* fail for a transient blip (don't restart me)? Is the right dependency in the right group?
Is this check cheap enough to run on every probe?

**Example review comment:**
> SHOULD: the new `HealthIndicator` puts the downstream `Notification` service into the **liveness**
> group, but `Notification` is non-critical and flaky — when it blips, liveness fails and the
> orchestrator restarts otherwise-healthy pods, amplifying a minor outage into a crash loop. A
> non-required dependency shouldn't gate liveness; if it gates anything it's readiness, and a flaky
> optional dependency probably gates neither. Verify which probe groups are enabled.

## Anti-Patterns

- **High-cardinality metric label** — *Diff:* a `Counter`/`Timer` tagged with a `userId`, `orderId`,
  `email`, raw URL, or exception message. *Harm:* one time series per distinct value; the series count
  grows unbounded with traffic, OOMs the metrics backend / explodes the bill, and slows every query —
  the metric becomes unusable, sometimes mid-incident. *Fix:* tag only bounded sets (status class,
  route template, outcome enum); put the high-cardinality id on a trace span or a structured log field.

- **Dropped trace/correlation context at an async boundary** — *Diff:* work submitted to an executor /
  `@Async` / `CompletableFuture` / broker consumer with no context propagation. *Harm:* the downstream
  work has no correlation id and a fresh unlinked trace, so a failure there is undiagnosable — nothing
  ties it to the request that caused it. *Fix:* a context-propagating task decorator / the Observation
  API + Micrometer Tracing; extract trace headers on consumers; capture-and-restore MDC around the hop.

- **Leaked MDC on a pooled thread** — *Diff:* `MDC.put(...)` with no `MDC.clear()`/remove in a
  `finally`, on a thread that returns to a pool. *Harm:* the value carries into the next, unrelated
  request — wrong correlation id, or one request's user attached to another's logs (a correctness *and*
  a privacy problem). *Fix:* set MDC in a filter/interceptor that **clears it in `finally`**, or use a
  scoped/propagated context the framework manages.

- **String-concatenated log** — *Diff:* `log.info("processed " + id + " at " + amount)`. *Harm:* the
  line is not machine-queryable, so on-call cannot filter/aggregate by `id` or `amount` during an
  incident — they grep free text. *Fix:* key-value fields / SLF4J placeholders / a structured (JSON)
  encoder so the fields are first-class.

- **Wrong log level** — *Diff:* a real write-path error at `DEBUG`, or routine success at `ERROR`.
  *Harm:* the error is invisible in production (DEBUG off) so the failure is silent; or the alert channel
  floods until on-call mutes it and misses the real one. *Fix:* `ERROR` = a human should look; `WARN` =
  degraded but handled; `INFO` = business milestone; `DEBUG` = off-in-prod diagnosis.

- **Wrong metric type** — *Diff:* a `Gauge` counting events, or latency stored as a "last duration"
  gauge. *Harm:* the gauge under-counts under concurrency / on scrape gaps (untrustworthy total), and
  the latency tail (p99) is invisible behind the mean. *Fix:* `Counter` for counts, `Timer`/`@Timed`
  for latency+rate with percentiles where the backend needs them, `Gauge` only for a current level.

- **Cause-based alert** — *Diff:* an alert (or a metric clearly meant for one) on CPU%, memory, or GC
  pauses. *Harm:* it pages when nothing is user-visibly broken (high CPU is often healthy), so on-call
  mutes the channel and then misses the symptom-based page that mattered. *Fix:* alert on symptoms
  (error rate, latency SLO burn, a stuck queue, failed money movement); keep cause metrics as
  post-page diagnostics.

- **Blind risk-bearing flow** — *Diff:* a money-movement / irreversible path whose failure increments no
  metric and logs nothing matchable. *Harm:* the system is blind to alert on its own failure — it can
  fail for hours before a customer reports it. *Fix:* a bounded-cardinality outcome counter (and a
  latency timer) so an alert can fire on the failure ratio. (Carve: the *handling* of that failure is
  the production-readiness lens; this is being able to *alert* on it.)

- **Readiness/liveness inversion** — *Diff:* a required dependency missing from readiness (or a
  non-required one gating liveness). *Harm:* traffic routed to an instance that can't serve (down
  dependency, ready=true), or a healthy pod restarted on a transient blip (liveness=kill-me) into a
  crash loop. *Fix:* required dependency → readiness (route around me); liveness → only the process's
  own health.

## Modernization (Java/Spring observability idioms)

Standing guidance: **inspect the target project's stack before recommending anything.** Every facility
below is version- and dependency-gated, and the alert/dashboard half usually lives in the monitoring
backend, not the Java code. A suggestion the project hasn't wired (no Micrometer registry, no tracer
bridge, no structured-logging encoder) or can't compile is worse than none. Frame each as *verify
against the actual project; never assume a version, a registry, a backend, or a library is present.*

- **Metrics facade** — **Micrometer** (`MeterRegistry`, `Counter`, `Timer`, `Gauge`,
  `DistributionSummary`, `@Timed`). *Verify Micrometer and the specific registry/bridge for the
  monitoring backend in use are on the classpath; the backend determines what percentile/histogram
  config is even meaningful.*
- **Auto-configured metrics** — Spring Boot Actuator emits HTTP-server (RED), datasource, executor,
  JVM, and logging metrics out of the box. *Verify the Actuator metrics starter is present; do not
  re-add what it already emits.*
- **Tracing & context** — on Boot 3.x, the **Observation API** (`ObservationRegistry`, `@Observed`)
  plus **Micrometer Tracing** with a tracer bridge; context propagation across threads/executors via
  the framework's context-propagation integration; broker auto-instrumentation for trace headers on
  messages. *Verify the Boot version, the tracer bridge, and the propagation format; on Boot 2.x the
  equivalent was Spring Cloud Sleuth — confirm which the project uses.*
- **Structured logging** — Spring Boot 3.4+ has built-in structured (JSON) logging
  (`logging.structured.format`); otherwise a JSON encoder (e.g. a Logback/Log4j2 layout) or a fluent
  key-value logging API. *Verify the Boot version and the logging backend before recommending the
  property or an encoder.*
- **Correlation in logs** — **MDC** for request-scoped ids that every line inherits; on Boot 3.x the
  tracing integration can put trace/span ids into the MDC automatically. *Verify the tracing stack is
  wired; if MDC is set by hand, it must be cleared in a `finally`.*
- **Health & probes** — Actuator **liveness/readiness** groups and custom `HealthIndicator`s.
  *Verify the Actuator version and which probe groups are enabled before recommending the properties;
  required dependency → readiness, process health → liveness.*
- **PII/secret in logs** — out of scope here: that is a `MUST` under the
  [`../rules/severity-rubric.md`](../rules/severity-rubric.md) and the (planned) `security` lens. This
  lens owns the **structure, level, and queryability** of the log, not whether its *content* is a
  secret. (Cross-reference, do not duplicate.)

When the simplest correct thing is *less* instrumentation — the path is cold, the metric already
auto-configured, the id belongs on a trace not a label — say so plainly. The named, answerable
operability question is the target, not maximal telemetry.

## Suggested Comment Style

Respectful, consequence-first, severity-honest. Lead with **what an operator cannot do** (or what cost
detonates), not with the rule. Make NITs explicitly optional, and endorse instrumentation that is
already good. Example openers:

- "When this fails at 3am, on-call can't filter by..." (names the diagnosis gap)
- "This tag's value is per-request, so the series count grows without bound and..." (names the
  cardinality explosion)
- "The trace context doesn't cross this boundary, so the async failure can't be tied back to..." (names
  the undiagnosable hop)
- "NIT (not a blocker): the metric name could read..." (flags a name with no behavioral consequence)
- "This boundary already emits rate/errors/duration and the id is on the span, not the label — looks
  right, no change needed."

Short examples with neutral nouns:

- > MUST: `Timer.builder("invoice.render").tag("invoiceId", id)` puts a per-invoice id on a metric
  > label — unbounded series that OOM the metrics backend. Drop the id from the tag; put it on the trace
  > span where per-request detail belongs.
- > SHOULD: this multi-service `Order` flow carries no correlation id across `order-service →
  > payment-service → shipping-service`, so a failed run is three unrelated log scatters. Threading one
  > id through the calls and into MDC would make a failed run traceable end to end. (If this is a
  > multi-step saga, see the saga lens's correlation guidance.)
- > NIT (not a blocker): `orders_done` could read `order.completed` to match the registry's naming
  > convention. Fine to leave.

## Integration (java-pr-review, architecture-review, and spec-author)

- **Apply with the consumer's altitude and intent.** `java-pr-review` reasons about the **changed
  lines** (this log, this tag, this async hop, this level); `architecture-review` about **system
  signals** (RED/USE on a boundary, correlation across services, what pages someone, an SLO);
  `spec-author` reads it **generatively** to *decide* the observability model — what to instrument,
  which metric type, what label is safe, what threshold pages — recording exactly the *"signals and
  correlation id that make a cross-boundary flow diagnosable"* the spec-author skill asks for. Same
  lens, different grain and direction.
- **Never raise a finding without a named operability consequence.** "Add a metric" / "log more" / "use
  structured logging everywhere" is `NO_COMMENT` unless you can say what question goes unanswerable,
  what cost detonates, or what failure stays invisible. Speculative telemetry is not a finding, and
  NO_COMMENT is the frequent, correct outcome (a cold path, an over-instrumented trivial call).
- **Never block on speculative instrumentation.** A dashboard for a path no one diagnoses, a span on a
  trivial in-process call, a custom metric Actuator already emits — these are cost, not signal. Endorse
  "no extra instrumentation" when the path is cold or already covered.
- **Always tag severity** — MUST / SHOULD / NIT — per [`../rules/severity-rubric.md`](../rules/severity-rubric.md),
  and always name the concrete consequence. NO_COMMENT is the silent fourth outcome.
- **Stay in your lane — this lens is the *depth* of instrumentation, and three neighbors own adjacent
  ground:**
  - **[`./spring-production-readiness.md`](./spring-production-readiness.md)** flags that a visibility
    *gap exists* — "this critical flow has no metric or correlation id" is its `SHOULD`, raised as part
    of *Error handling & failure visibility*, and it explicitly defers the deep instrumentation to here.
    This lens owns the **quality**: the log is structured and queryable, the metric is
    low-cardinality, the trace context survives the boundary, the alert fires on a symptom. Carve:
    production-readiness = "the failure is *handled* and there is *some* visibility"; observability =
    "the instrumentation is *good* — structured, correlated, bounded, diagnosable, alertable." Both can
    fire on one diff with different findings.
  - **[`./saga.md`](./saga.md)** owns **correlation and observability across a multi-step,
    cross-boundary workflow** (a saga id threaded through every step and message, a metric on
    compensation, a stuck-saga sweep). This lens owns **general instrumentation** — request context
    across any thread/async/message boundary, metric type and cardinality, log structure — not the
    saga's end-to-end story. When the flow is a saga, defer the workflow-correlation finding to the saga
    lens; keep the line-level "this tag is unbounded" / "this hop drops MDC" finding here.
  - **`security`** (planned) and the **[`../rules/severity-rubric.md`](../rules/severity-rubric.md)**
    own **PII/secret in a log** — that is *their* `MUST`. This lens owns the **level, structure, and
    queryability** of the log, and defers its *content*-safety. Flag the structure here, the secret
    there.
- **Prefer a few strong findings over many weak ones.** One unbounded metric label or one dropped trace
  context lands; ten "consider logging this" notes bury it. Drop the weak ones to NO_COMMENT.
