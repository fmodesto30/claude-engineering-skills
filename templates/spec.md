# Engineering Spec

<!--
This is a fill-in skeleton for an engineering spec. A spec fixes WHAT is being built and the
key decisions behind it — testably — and leaves HOW to the code.

Scale it to the risk. A small, low-risk change needs only a subset of these sections (often just
Context, Goals/Non-Goals, a short Requirements list, and Acceptance Criteria); writing all of
them for a one-line fix is the over-specification this repo argues against. A change that crosses
a consistency boundary, moves data ownership, touches money/auth, or is hard to reverse earns the
full set — especially the Consistency and Failure Model.

Delete the sections you do not need and delete every guidance comment before sharing. If a section
would only restate the obvious or cannot state a concrete criterion or reason, cut it — empty
ceremony erodes trust in the document.

Requirement-strength keywords below use the common MUST / SHOULD / MAY convention: MUST is a hard
requirement whose absence is a defect; SHOULD is a strong default that may be traded away with a
stated reason; MAY is genuinely optional. Use them only where the strength is load-bearing.
-->

## Metadata

<!--
One compact block, not prose. Include: status (Draft / In Review / Approved); owner (a person, not
a team); date and last-updated; links that let a reader verify context (the issue/ticket, the
parent design if any, the target repository/module). Status is load-bearing — a reader must know
whether this is a sketch or a decision the team has committed to.
-->

- Status: Draft | In Review | Approved
- Owner:
- Date / last updated:
- Related: <!-- issue, parent design, target repo/module, prior art -->

## Context and Problem

<!--
State the problem this change exists to solve and the situation as it actually is today — not the
solution. A reader who knows nothing about the work should finish this section understanding why
the change is needed and what breaks or is missing without it. Name the real system you inspected
(stack, versions, the modules/contexts touched) rather than assuming a topology. Keep it to a few
paragraphs; if it runs long, the problem is probably not yet understood. No solution detail here.
-->

## Goals

<!--
What this change must achieve, stated so each goal is observable — you can tell whether it was met.
"Reduce p99 latency of order placement below 200 ms" is a goal; "make it faster" is not. A short
ranked list. If you cannot say how you would know a goal was achieved, it is not a goal yet.
-->

## Non-Goals

<!--
STRONGLY DEFAULT — the one section worth keeping even in a minimal spec. The things this change
deliberately does NOT do, and (briefly) why. Non-goals are how a spec controls scope and stops a
reviewer from grading it against work it never promised. Naming what is out of scope is as
load-bearing as naming what is in scope — an unstated non-goal becomes an argument later.
"Multi-currency pricing is out of scope; all Money is assumed single-currency for this change" is a
non-goal that prevents a whole class of review noise. For a truly trivial change, a single inline
non-goal sentence in Context can stand in for this section.
-->

## Requirements

<!--
The testable heart of the spec. Every requirement must be verifiable — a reader must be able to
imagine the check that proves it met or unmet. Use MUST / SHOULD / MAY to mark strength, and state
each as a behavior, not an implementation. Do NOT specify exact classes, method names, or code
shapes here; that is the code's job and pins down decisions the implementer should own.
-->

### Functional

<!--
What the system must DO, as testable statements. Each line names a behavior and an observable
outcome.
Examples (neutral):
- The system MUST reject an `Order` submitted with zero `LineItem`s and return a validation error.
- A `Payment` capture request MUST be idempotent under retry: the same idempotency key MUST capture
  at most once.
- The system SHOULD surface a `Report` generation failure to the requester rather than silently
  retrying indefinitely.
If a line cannot be phrased as something you could test, it is not a requirement — cut it or move it
to Context.
-->

### Non-Functional

<!--
The qualities the change must hold, each with a concrete, checkable target and the reason it matters
— a number without a reason is noise, and a reason without a number is not testable. Cover only the
dimensions this change actually touches:
- Performance / latency / throughput — a target tied to a measurement point.
- Scale — the volume the design must hold (peak rate, data growth) and why that figure.
- Security & privacy — authn/authz, data classification, what must not leak (expand in Security
  below if substantial).
- Availability / resilience — what degraded behavior is acceptable when a dependency is down.
Example: "MUST sustain 500 `Order` placements/sec at p99 < 200 ms, because that is the measured peak
plus headroom." Omit a dimension entirely rather than writing a vague placeholder for it.
-->

## Proposed Design

<!--
The approach, at the altitude of decisions and boundaries — not a code walkthrough. Enough that a
competent implementer can build the right thing and a reviewer can judge it, without dictating the
implementation. If you find yourself writing method bodies or naming every variable, you have
dropped below the spec's altitude; pull back up.
-->

### Key Decisions

<!--
The handful of decisions that, if made differently, would make this a different design. State each
as a decision plus a one-line rationale (and, where it matters, what it trades away). This is where
the spec earns its keep: it records WHY, so a future reader does not relitigate a settled choice or
silently undo it. Keep it to the decisions that are actually load-bearing — not every minor choice.
Example:
- Decision: keep `Order` placement and `Invoice` issuance as separate transactions, propagated by a
  domain event. Rationale: they are separate aggregates; one transaction across both would widen
  lock scope and risk a torn write. Trade-off: invoicing becomes eventually consistent.
-->

### Domain Model and Boundaries

<!--
The domain concepts this change introduces or touches, and where the boundaries fall: which
aggregate/context owns which data, what the consistency boundary is, and how a foreign or external
model is kept from leaking inward. State who owns each piece of data (single source of truth). This
is the generative use of the DDD lens — record the boundary and ownership decisions here so a
reviewer can see them, rather than leaving them implicit. Keep it to the boundaries that matter for
this change; do not draw a full context map for a one-context change.
-->

### Contracts

<!--
The shapes at the edges that other code or systems depend on: API request/response shapes, event
schemas, persisted data shapes, message formats. Specify these because they are the parts that are
expensive to change later (they bind other parties). State versioning/compatibility intent for
anything published (an event or external API is a contract — changing its shape breaks consumers).
Do NOT specify internal-only types here; those are implementation latitude.
-->

### Consistency and Failure Model

<!--
The most important section for any risk-bearing change, and the one a reviewer will check hardest.
State, concretely:
- Transactions: what is atomic, and what is the consistency boundary (one aggregate, one store?).
- Where consistency is EVENTUAL rather than transactional, say so explicitly and say how the
  in-between state is handled — silent assumption of atomicity across a boundary that cannot span
  one transaction is the classic defect architecture-review flags.
- Idempotency: which operations can be retried or redelivered, and what makes the effect happen at
  most once (at-least-once delivery is the norm; name the dedup key).
- Cross-aggregate / cross-service consistency: if a unit of work spans more than one aggregate,
  store, or service, name the steps, what fails, what compensates, and where the point of no return
  is (the saga "pivot") — or state plainly that one local transaction suffices and no saga is needed.
- Dual writes: if a state change must also publish an event, say how the two are made atomic (e.g.
  an outbox) so a crash cannot lose or phantom the event.
- Failure behavior at each integration point: timeout, retry, fallback, and what the caller sees.
This is where the DDD, saga, cqrs, and cdc decisions are RECORDED. If this change touches none of
the above — a single local transaction over one aggregate — say exactly that in one line; that is a
complete and correct answer, not a gap.
-->

## Alternatives Considered

<!--
The serious options you did not take, each with a one-line reason for rejection. This proves the
chosen design was a decision, not a default, and saves the next person from re-proposing a dead end.
Keep it to genuine alternatives that were really on the table; do not invent strawmen. For a small
change with one obvious approach, a single line ("considered doing X inline; rejected because Y") or
omission is fine.
-->

## Acceptance Criteria

<!--
The concrete, checkable conditions that define DONE — the bridge from the testable Requirements to
"we can ship this." Each criterion is something a person or a test can verify pass/fail, phrased so
there is no argument about whether it was met. These should map back to the Requirements and the
failure model. This is the generative use of the testing lens: write the criteria that a test could
fail for the right reason. (Requirement testability itself is the baseline overriding rule, applied
to every requirement; the testing lens is consulted here to shape the concrete acceptance checks.)
Example:
- A duplicate `Payment` capture with the same idempotency key results in exactly one captured
  payment, verified by an integration test that submits the request twice.
- When the downstream `Notification` service is unavailable, `Order` placement still succeeds and
  the notification is retried, verified by a test that stubs the dependency as down.
-->

## Observability and Operability

<!--
How an operator will know this works in production and diagnose it when it does not. Name the
concrete signals: the logs/metrics/traces that matter, the correlation id that ties a multi-step or
cross-service flow together, the alert that fires on the failure mode this change introduces. For a
cross-boundary flow, say how a failed run is traced end to end. Scale to risk — a trivial change may
need nothing here; a new integration or a saga needs this section to not be a blind spot.
-->

## Security and Privacy

<!--
What this change must protect and how, stated as requirements with reasons. Cover only what applies:
authentication/authorization on new surfaces; data classification of anything stored or logged (and
what MUST NOT be logged — secrets, tokens, personal data); input validation at trust boundaries; and
any new data flow that crosses a trust boundary. If the change touches no sensitive data and adds no
new surface, say so in one line rather than padding.
-->

## Rollout, Migration, and Backout

<!--
How the change reaches production safely and how it is undone if it goes wrong. Cover what applies:
the rollout sequence (flag, phased, all-at-once) and why; any data migration and whether it is
backward-compatible (can old and new code run against the same data during rollout?); and the
backout plan — how to revert, and whether the migration is reversible. A change that is hard to
reverse MUST say how it is backed out; that is the whole point of this section. Trivial,
flag-guarded changes may need only a line.
-->

## Risks and Open Questions

<!--
The honest list of what could go wrong and what is not yet decided. Mark genuine open questions as
open — do NOT invent an answer to look finished; an unresolved question recorded here is worth more
than a guess presented as a decision. A spec author or reviewer turns each blocking open question
into something to resolve before building. State the risk and, where known, the mitigation.
-->

## References

<!--
Links a reader needs to verify or extend the spec: the parent design, related specs, the relevant
review lenses consulted (e.g. the DDD or saga lens), external standards. Keep it to what is actually
referenced — a reference list is a tool for the reader, not a bibliography for show.
-->
