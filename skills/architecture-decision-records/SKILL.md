---
name: architecture-decision-records
description: >-
  Captures an architecturally-significant decision as a durable, immutable record — its context and
  forces, the decision itself, the alternatives genuinely considered and why each was rejected, and
  the consequences (the costs accepted, not only the upside). Use when a hard-to-reverse or
  cross-cutting choice is being made or has just been made (a boundary, a datastore, a consistency
  model, an auth model, an integration contract, a framework commitment), when asked to "write an
  ADR", "record this decision", "document why we chose X", or when a past decision is changing and a
  new record must supersede the old one. Authors and maintains the record and its status lifecycle;
  it never edits an accepted record in place. Records only significant decisions — a reversible,
  local choice is NO_COMMENT, not an ADR. Not for specs (spec-author) or for judging whether the
  design is good (architecture-review).
---

# architecture-decision-records

A construction skill that records *why* an architecturally-significant decision was made, so the
reasoning outlives the people who were in the room. It is the sibling of
[`../spec-author/SKILL.md`](../spec-author/SKILL.md) — which says *what to build* — and the
counterpart of [`../architecture-review/SKILL.md`](../architecture-review/SKILL.md), which judges a
design that exists: an ADR captures the decision and the rejected alternatives that a spec assumes
and a review later evaluates. Its subject is the **decision and its trade-offs**, not the
implementation and not whether the decision was wise.

## Core stance

- **Record the significant, skip the rest.** An ADR is for a decision that is costly to reverse or
  cuts across the system — a service boundary, a datastore, a consistency model, an auth model, an
  integration contract, a framework commitment. A choice you can change cheaply next week is
  `NO_COMMENT`, not a record. A repo full of ADRs for trivia is as useless as none — it buries the
  three that mattered.
- **The *why* and the rejected alternatives are the asset.** Anyone can read the code to see *what*
  was chosen. The record's value is the **forces** that constrained the choice and the options that
  were genuinely weighed and rejected — exactly what a future maintainer cannot reconstruct from the
  code and will otherwise undo by accident.
- **Every real decision has a cost — name it.** An ADR whose consequences are all upside is a sales
  pitch, not a decision record. State what you give up, what gets harder, and what risk you accept.
  A decision with no nameable trade-off was probably not significant, or was not thought through.
- **Immutable; supersede, never rewrite.** An accepted ADR is a historical fact about *why we
  decided then*. When the decision changes, write a **new** record that supersedes it and mark the
  old one superseded — do not edit the old one to match today's reality, or you erase the exact trail
  the ADR existed to preserve.
- **One decision per record.** Bundling several decisions into one ADR makes none of them findable,
  supersedable, or citable on its own.
- **Status is load-bearing.** `proposed → accepted → (superseded by ADR-NNN | deprecated)`. The
  status and the supersede links are what keep the set a true map of *current* decisions instead of
  an archaeological dig where stale and live records look identical.

## When to run

- A decision that is **hard to reverse or cross-cutting** is being made, or has just been made.
- A **past decision is changing** — write the superseding record (and mark the old one superseded).
- The user asks to **"write an ADR", "record this decision", "document why we chose X"**.
- **Onboarding / back-fill** — reconstructing the *why* behind a significant existing decision, the
  record clearly dated and labelled as back-filled.

Do **not** run it for a reversible, local implementation choice — that is a code comment, or nothing.

## How to run

1. **Confirm the decision is ADR-worthy.** Significant = expensive to reverse, cross-cutting, or it
   constrains future change. If it is local and cheap to change, stop — `NO_COMMENT`. Most choices
   are not ADRs.
2. **Capture the context and forces first.** The constraints and pressures that make this a real
   decision — load, consistency needs, failure modes, team skills, deadlines, regulatory limits.
   Reason about them *generatively* with the architecture lenses, loading only what the decision
   touches: [`../../lenses/ddd.md`](../../lenses/ddd.md) for boundaries and consistency,
   [`../../lenses/saga.md`](../../lenses/saga.md) / [`../../lenses/cqrs.md`](../../lenses/cqrs.md) /
   [`../../lenses/cdc.md`](../../lenses/cdc.md) for distributed-consistency choices, and
   [`../../lenses/spring-production-readiness.md`](../../lenses/spring-production-readiness.md) for
   the operational forces (timeouts, idempotency, retries).
3. **State the decision in one sentence, active voice.** "We will use a single relational store with
   the transactional-outbox pattern for `Order` events," not "options for event storage."
4. **Record the alternatives genuinely considered.** For each real option, one line on why it was
   rejected. An ADR with no rejected alternatives weighed nothing and proves nothing.
5. **Name the consequences — both signs.** What this buys *and* what it costs, makes harder, or risks.
   This is the part a future reader needs most.
6. **Set the status and the links.** `proposed`/`accepted`; if it replaces an earlier decision, link
   both ways (`supersedes ADR-NNN` / the old one's `superseded by ADR-MMM`).

## Output format

```
# ADR-NNN: <decision as a short noun phrase>

Status: <proposed | accepted | superseded by ADR-MMM | deprecated>
Date:   <YYYY-MM-DD>

## Context
<the forces and constraints that make this a real decision — not project background prose>

## Decision
<one sentence, active voice: what we will do>

## Alternatives considered
- <option> — rejected because <reason>
- <option> — rejected because <reason>

## Consequences
- Positive: <what this buys>
- Negative / accepted cost: <what gets harder, what we give up, the risk we take on>
```

The canonical form of this output is [`../../templates/adr.md`](../../templates/adr.md) — emit a record
that matches it. Keep it to one screen. An ADR is a decision record, not a design doc — depth goes into the forces and
the trade-off, never into prose. When **evaluating an existing ADR** (or a missing one) rather than
writing one, emit severity-tagged findings per the rubric below.

## Restraint rules

- **Don't record the trivial.** A reversible, local choice is `NO_COMMENT`. The set is valuable only
  because every entry earned its place.
- **Never edit an accepted record to fit a new decision — supersede it.** Rewriting history is the
  single thing this skill exists to prevent.
- **No all-upside ADRs.** If you cannot name a cost, either the decision is not significant or it
  hasn't been thought through — say which, rather than inventing a tidy record.
- **One decision per record.**
- **Stay in your lane.** Whether the decision is *good* is `architecture-review`'s call; whether the
  spec is right is `spec-author`'s. This skill makes the decision and its trade-offs durable and
  findable — it does not bless the design.

## Severity

Classify every finding `MUST` / `SHOULD` / `NIT` / `NO_COMMENT` per
[`../../rules/severity-rubric.md`](../../rules/severity-rubric.md), and obey the overriding rule:
every finding names a concrete consequence.

- **MUST** — a significant, hard-to-reverse decision shipped with **no record**; an accepted ADR
  **edited in place** to rewrite history (the trail is now false); or a costly commitment justified
  by an ADR with **no named negative consequence** (false confidence). Name what is lost: a later
  maintainer reverses a deliberate decision because the *why* was never written down.
- **SHOULD** — alternatives not recorded (the weighing is invisible and unrepeatable); status /
  supersede links missing, so the set no longer maps current decisions; several decisions bundled
  into one record so none can be superseded independently.
- **NIT** — numbering, file placement, or formatting of the record.
- **NO_COMMENT** — a reversible, local choice that does not warrant a record. Do not manufacture
  ADRs for routine implementation; an empty ADR log on a small, stable system is correct, not a gap.
