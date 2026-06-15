---
name: spec-author
description: >-
  Produces a prescriptive engineering spec for a Java / Spring Boot feature or change — fixing WHAT
  is being built and the key decisions, testably, while leaving HOW to the code. Consumes the shared
  lenses with generative intent ("what does this lens tell me to DECIDE, and what would
  architecture-review flag if I got it wrong?"). Use when writing or refining a spec or design
  before building. Defers reviewing existing code to java-pr-review and existing designs to
  architecture-review. Not for non-JVM work.
---

# spec-author

A construction workflow for Java / Spring Boot. It produces a prescriptive engineering spec — the
document that fixes WHAT a feature or change must do and the key decisions behind it, stated testably
— so the team builds the right thing once and can verify it. It is the construction-side sibling of
the review skills: where `java-pr-review` and `architecture-review` consume the shared lenses to
*judge* code and designs that already exist, this skill consumes the **same** lenses with the
opposite, generative intent — to *decide* what to build before it exists.

## Core stance

- **A spec fixes WHAT plus the key decisions, testably — not HOW.** The spec records the handful of
  decisions that are expensive to get wrong (boundaries, consistency, contracts, failure behavior)
  and the requirements as checkable statements. It leaves implementation latitude to the code.
- **The minimum to build the right thing and verify it.** Write the smallest spec that lets the team
  build correctly and check the result. A section that states neither a concrete criterion nor a
  reason is noise — cut it.
- **Consult the lenses GENERATIVELY.** The same knowledge the review skills use to find faults is
  used here to make decisions. For each area the change touches, ask: *what does this lens tell me to
  DECIDE, and what would `architecture-review` flag if I got this wrong?* — then record the decision.
- **Inspect the real system first.** Never assume a Java version, a Spring Boot version, a
  persistence stack, a broker, or a topology. Establish the system that actually exists before
  deciding anything; a spec built on an assumed stack is wrong by default.
- **Anti-over-specification.** A spec that dictates exact classes, method names, or code bodies is
  worse, not better — that belongs in code. Drop below the spec's altitude and the document goes
  stale the moment the code is written sensibly differently.
- **Scale to risk.** A one-paragraph spec for a small, reversible change is correct. The full section
  set is earned by changes that cross a consistency boundary, move data ownership, touch money or
  auth, or are hard to reverse.
- **A spec is not code.** It is the durable record of decisions, not a transcription of the
  implementation.

## How to write a spec

1. **Establish the actual system and stack.** Before deciding anything, inspect what really exists:
   the Java language level and Spring Boot version, the build tool, the persistence technology, the
   messaging/streaming technology (if any), the modules/contexts and how they are deployed, who owns
   which data, and the integration style between parts. Read the build files, configuration, and
   code, or ask. **Never assume a version, a library on the classpath, or a topology** — a decision
   built on an assumed system is the spec's first defect.

2. **State Goals and Non-Goals.** Write the goals so each is observable (you can tell whether it was
   met), and write the Non-Goals explicitly — what this change deliberately does not do, and why.
   Non-Goals are how the spec controls scope and stops it being graded against work it never promised.

3. **Derive testable Requirements.** Turn the goals into requirements stated as behaviors with
   observable outcomes, marking strength with the common **MUST / SHOULD / MAY** convention. Every
   requirement must be verifiable — if you cannot imagine the check that proves it met or unmet, it
   is not a requirement. State functional behavior and the non-functional qualities that actually
   apply (performance, scale, security, availability), each with a number *and* the reason it
   matters. Do not specify implementation here.

4. **Make and RECORD the key design decisions, consulting the lenses generatively.** Identify the
   decisions that, if made differently, would make this a different design, and record each with a
   one-line rationale (and what it trades away). Load **only** the lenses whose area the change
   actually touches — never a lens because a term appears in a name. For each, ask *what does this
   lens tell me to DECIDE, and what would `architecture-review` flag if I got it wrong?*:
   - [`../../lenses/ddd.md`](../../lenses/ddd.md) — where the boundaries fall, what each aggregate
     owns, and where the transactional **consistency boundary** is (one aggregate per transaction;
     eventual consistency across aggregates). Decide ownership and boundaries here so the reviewer
     does not have to infer them. *Wrong → a shared read-write model, a multi-aggregate transaction,
     an invariant enforced outside the aggregate.*
   - [`../../lenses/saga.md`](../../lenses/saga.md) — when a unit of work crosses more than one
     aggregate, store, or service: decide whether a saga is even warranted (often one local
     transaction suffices and is the right call), and if so, the steps, compensation, the pivot, the
     **outbox** for any state-change-plus-event, and **idempotency** under at-least-once delivery.
     *Wrong → a step with no compensation, a non-idempotent consumer, a dual write that loses an
     event.*
   - [`../../lenses/cqrs.md`](../../lenses/cqrs.md) — when separating a read (query) model from the
     write (command) model: decide whether the separation is warranted at all (a same-store
     projection often suffices), and if so, who owns the read model, its rebuild path, and how
     eventual consistency and read-your-own-writes are handled. *Wrong → a read model with no owner
     or rebuild path, eventual consistency assumed away.*
   - [`../../lenses/cdc.md`](../../lenses/cdc.md) — when a committed change must propagate to another
     system (a read model, index, cache, or another service): decide whether an intentional domain
     event suffices or a capture pipeline is warranted, and how deletes, ordering, idempotency, and
     lag are handled. *Wrong → capturing a raw table instead of an intentional outbox, ignoring
     ordering or deletes.*
   - [`../../lenses/design-patterns.md`](../../lenses/design-patterns.md) — the structural choices:
     a port/adapter at an integration edge, an event for genuine fan-out, a strategy for a real axis
     of variation. Decide structure that reduces real complexity, not ceremony. *Wrong → indirection
     that buys nothing, or a missing seam where a foreign model will leak inward.*
   - [`../../lenses/clean-code.md`](../../lenses/clean-code.md) and
     [`../../lenses/testing.md`](../../lenses/testing.md) — to shape acceptance and testability:
     decide what makes the change verifiable and what a test must be able to fail for the right
     reason. *Wrong → requirements no test can check, a critical path with no acceptance criterion.*

5. **Define Acceptance Criteria.** Using the testing lens generatively, write the concrete, checkable
   conditions that define done — each one something a person or a test can verify pass/fail, mapping
   back to the Requirements and the failure model. Write them so a test could fail for the right
   reason, not to chase a coverage number.

6. **Cover failure modes, observability, security, and rollout** — at the depth the risk warrants.
   Record the consistency and failure model (what is atomic, what is eventual, what is idempotent,
   what compensates, how a dual write is made safe) for any risk-bearing path; the signals and
   correlation id that make a cross-boundary flow diagnosable; the authz/data-classification
   requirements on any new surface; and the rollout, migration, and backout plan for anything hard
   to reverse. For a change that touches none of these, say so in a line rather than padding.

7. **Emit the spec** in the format of [`../../templates/spec.md`](../../templates/spec.md), filling
   only the sections this change actually needs and deleting the guidance comments. Scale the
   document to the risk — a subset for a small change, the full set for a cross-boundary one.

8. **Self-check against the rubric.** Grade the draft against
   [`../../rules/spec-rubric.md`](../../rules/spec-rubric.md): is every requirement testable, does
   every constraint name its reason, are the Non-Goals explicit, is the consistency/failure model
   stated on every risk-bearing path, does each published contract have a shape and a compatibility
   intent, does exactly one owner hold each written fact, and is the spec at the right altitude and
   size for the risk? Resolve every `BLOCKER` gap, or record it explicitly as an open question with
   an owner. A spec ships when it is `OK` overall with its `BLOCKER`s resolved or owned.

## Generative vs. evaluative — the same lenses, opposite direction

This skill and the review skills share one body of knowledge and use it in opposite directions. The
review skills read a lens **evaluatively** — *did this existing code/design get the boundary, the
consistency, the failure path right?* This skill reads the **same** lens **generatively** — *I am
deciding this now; what does the lens tell me to choose, and what would `architecture-review` flag
if I chose wrong?* A well-written spec is therefore one that the review skills would pass: every
decision recorded here is a decision they would otherwise have to find missing. The knowledge is not
duplicated into this skill — it consults the lenses by their paths above, so the construction side
and the review side never drift apart.

## Output

A filled engineering spec in the format of [`../../templates/spec.md`](../../templates/spec.md):
metadata and status, context and problem, goals and explicit non-goals, testable requirements
(MUST/SHOULD/MAY), the proposed design with its key decisions and rationale, the domain model and
boundaries, the contracts, the consistency and failure model, alternatives considered, concrete
acceptance criteria, and — at the depth the risk warrants — observability, security, and rollout.
Sized to the change: a subset for a small one, the full set for a risk-bearing one.

## Restraint rules

- **Do not over-specify.** Fix WHAT and the key decisions; leave HOW to the code. Exact classes,
  method names, and algorithm bodies do not belong in a spec — that detail is graded down, not up.
  Line-level style (formatting, naming-case, imports) is a linter's job and a code-review concern,
  never a spec's — mirroring the review side's "style belongs to tooling."
- **Leave implementation latitude.** State the decision and its reason, not the code that realizes it.
- **Mark open questions rather than inventing answers.** A recorded open question with an owner is
  worth more than a guess presented as a decision to make the spec look finished.
- **Scale the spec to the risk.** A one-paragraph spec for a small, reversible change is correct;
  reserve the full section set for changes that cross a boundary, move ownership, or are hard to undo.
- **Consult a lens only when the change touches its area** — never because a term appears in a name.
  Recommending *against* unnecessary machinery (no saga, no CQRS split, no CDC pipeline) is a valid
  and frequent decision, not an omission.
- **The spec fixes WHAT; code decides HOW.** When one local transaction over one aggregate does the
  job, say so plainly — the simplest design that satisfies the requirement is the goal.
- **Stay in your lane.** Reviewing an existing diff is `java-pr-review`'s job; reviewing an existing
  design is `architecture-review`'s. This skill produces the spec they will later be measured against.
