# Spec Rubric

The quality bar for an engineering spec, and the construction-side sibling of
[`severity-rubric.md`](severity-rubric.md). Where the severity rubric keeps *reviews* useful by
separating the findings that matter from the noise, this rubric keeps *specs* useful by separating
the few things that must be pinned down from the ceremony that buries them. A spec is good when it
is enough to build the right thing and verify it — and no more. A spec graded against this rubric
is judged on whether it does that concrete work, never on whether it filled in every section.

## What a spec is for

A spec fixes **WHAT** is being built and the **key decisions** behind it, testably, and leaves
**HOW** to the code. Its value is the handful of decisions and constraints that are expensive to
get wrong — boundaries, consistency, contracts, failure behavior — stated so they can be verified.
Everything that does not do that work is weight. The rubric below grades the *gaps* in a spec the
same way the severity rubric grades the *findings* in a review.

## The four levels (spec gaps)

- **BLOCKER** — The team cannot build the right thing, or cannot verify it, without resolving this.
  A core requirement is ambiguous or contradictory so two readers would build different things; a
  requirement has no way to be checked (no acceptance criterion, nothing testable); the
  consistency/failure model on a risk-bearing path is undefined (a unit of work crosses a boundary
  with no statement of what is atomic, what is eventual, what compensates, or how a dual write is
  made safe); a published contract is unspecified; data ownership is unstated where two parties
  could write the same fact. A `BLOCKER` must be resolved before building, or explicitly recorded
  as an open question with an owner. It names *what* cannot be built or verified and *why*.

- **SHOULD** — A real gap that will cause rework or avoidable cost, but not one that stops the build.
  A non-functional target stated without a number (or a number without a reason); a non-goal left
  implicit so scope will be argued later; an alternative silently dropped so the decision looks like
  a default; observability missing on a flow whose failure would otherwise be a blind spot. A
  `SHOULD` is raised but does not block; it names the concrete rework or cost it will cause.

- **NIT** — A cosmetic or organizational gap with no consequence for what gets built: a section out
  of order, a missing link that is easily found, slightly wordy guidance left in. Worth a brief
  note (`nit:`), never a reason to withhold approval. When in doubt between `SHOULD` and `NIT`, it
  is a `NIT`.

- **OK** — The spec states what it needs to and no more. This is the silent, frequent, correct
  outcome — including the case where a small change is covered by a one-paragraph spec and most
  sections are legitimately absent. A short spec that pins the right things is `OK`, not incomplete.
  Saying "this is enough" is a valid and common verdict.

## The overriding rule

**Every requirement must be testable, and every constraint must name its reason. If neither can be
stated, cut the line.** A requirement you cannot imagine a check for is not a requirement; a
constraint with no reason is someone's preference wearing a MUST. This is the spec-side mirror of
the review rubric's "every finding must name a concrete consequence." "The system should be
scalable" states neither a test nor a reason and is noise; "MUST sustain 500 `Order` placements/sec
at p99 < 200 ms, because that is measured peak plus headroom" states both. When a line can carry
neither a test nor a reason, deleting it makes the spec stronger, not weaker.

Use the common **MUST / SHOULD / MAY** requirement-strength convention to mark how hard each
requirement is — MUST is a hard requirement whose absence is a defect, SHOULD is a strong default
that may be traded with a stated reason, MAY is genuinely optional. Apply the keywords only where
the strength is load-bearing; sprinkling them on every sentence drains them of meaning.

## Anti-over-specification

A spec that dictates implementation detail is graded **DOWN, not up.** Exact class and method names,
variable names, the body of an algorithm, every field of an internal type, a prescribed code
structure — these pin down decisions that belong to the implementer and the code review, and they
make the spec brittle (it goes stale the moment the code is written differently for a good reason).
The spec fixes WHAT and the key decisions; it leaves implementation latitude. A spec that reads like
source code in prose has dropped below its altitude and is *worse* for it.

Equally, **scale the spec to the risk and complexity.** Not every change needs a full spec:

- A small, low-risk, easily-reversed change is correctly served by a one-paragraph spec — context,
  goal, and how you will know it works. Demanding the full section set for it is the same mistake as
  over-specifying implementation: ceremony that costs effort and protects nothing.
- A change that crosses a consistency boundary, moves data ownership, touches money or auth, or is
  hard to reverse earns the full treatment — especially an explicit consistency and failure model.
- The right size is the smallest spec that lets the team build the right thing and verify it. A
  missing section on a trivial change is `OK`; the same omission on a risk-bearing change is a
  `BLOCKER`. Grade the gap against the risk, not against the template.

A spec is not code, not a design diagram for its own sake, and not a contract to be padded for
appearance. It is the minimum durable record of the decisions that are expensive to get wrong.

## Calibration examples

**BLOCKER**
- A unit of work updates the `Order`, the `Payment`, and the `Shipment` across services, and the
  spec says nothing about what is atomic, what compensates on partial failure, or where the point of
  no return is → the team cannot build a correct failure path from this.
- "The system handles duplicate requests correctly" with no statement of the idempotency key or what
  "correctly" means → not verifiable; two implementers will diverge.
- An `OrderPlaced` event is published to other contexts but its schema and versioning intent are
  unspecified → consumers cannot be built or evolved safely.

**SHOULD**
- "Must be highly available" with no statement of acceptable degraded behavior when a dependency is
  down → real gap; the resilience design will be guessed and reworked.
- The `Report` read model is introduced with no owner and no rebuild path stated → will bite during
  the first reprojection.
- A serious alternative (a single shared `Customer` model vs. per-context models) was clearly weighed
  but is not recorded, so the decision reads as accidental.
- A non-backward-compatible `Invoice` schema migration with no stated backout → the rollback will be
  improvised under pressure; escalate to `BLOCKER` if the migration is irreversible and its risk is
  unowned.

**NIT**
- Acceptance criteria listed before the design rather than after.
- A reference link omitted that a reader can find in one search.

**OK**
- A one-paragraph spec for adding a nullable field to an internal DTO: context, the one functional
  requirement, and the acceptance check. Most sections absent — correctly.
- A change explicitly stating "single local transaction over the `Order` aggregate; no cross-service
  consistency involved" instead of a full saga design — that one line is a complete failure model.

## Review questions before calling a spec ready

A spec author or reviewer should be able to answer each of these before the spec is built from:

- Is every requirement testable — can you name the check that proves it met or unmet?
- Does every constraint name its reason, and every non-functional target carry a number *and* a why?
- Are the Non-Goals explicit, so scope cannot be argued later?
- For any risk-bearing path: is the consistency and failure model stated — what is atomic, what is
  eventual, what is idempotent, what compensates, how a dual write is made safe — or is it stated
  plainly that one local transaction suffices?
- For a hard-to-reverse change (a non-backward-compatible migration, an irreversible data move): is
  the backout/rollback plan stated, or is the change explicitly noted as irreversible with its risk
  owned?
- Does each published contract (API, event, persisted shape) have a defined shape and a compatibility
  intent?
- Does exactly one owner hold each piece of data the change writes?
- Are the acceptance criteria concrete enough that "done" is not arguable?
- Is the spec at the right altitude — does it fix WHAT and the key decisions without dictating HOW?
- Is it the right size for the risk — not a full spec for a trivial change, not a one-liner for a
  cross-boundary one?
- Is every open question marked as open, rather than answered with a guess to look finished?

## Verdict

Close a spec review the way the severity rubric closes a code review: a short verdict (ready to
build / ready with `SHOULD`s to address / not ready — `BLOCKER`s outstanding) and a count per level.
Prefer a few real gaps named precisely over a long list of section-by-section observations — drop
weak notes to `OK` rather than padding the review. A spec that is `OK` overall, with its `BLOCKER`s
resolved or recorded as owned open questions, is ready to build from.
