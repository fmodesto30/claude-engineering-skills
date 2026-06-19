---
name: skill-author
description: >-
  Scaffolds a new skill — or, just as often, decides one is not warranted and the addition belongs in a
  lens, a rule, or nowhere. Use when extending this repository: adding a new mode of work, when asked to
  "create a skill", "add a lens", "scaffold a skill", "how do I add X here", or when a recurring kind of
  task has no home skill yet. Decides skill vs. lens vs. rule (a skill is one *type of work*, never one
  pattern, topic, or book), writes the artifact to the house conventions (a trigger-surface
  `description`, consequence-driven findings, the shared severity rubric, lenses referenced by relative
  path, synthetic neutral examples), keeps the indexes in sync (the structure map, the README tree,
  CHANGELOG/VERSION, the consuming-skill wiring), and verifies it will actually trigger and pass the
  sanitization gate. Proposes the artifact and writes on approval. Not for authoring application code,
  and not for one-off or speculative additions — only a genuinely new, recurring mode of work earns a
  skill.
---

# skill-author

A meta/ops skill whose subject is *this repository itself*: it adds a new capability — a skill, a lens,
or a rule — without breaking the model that keeps the library coherent. It is the executable form of the
*Architecture model* and *Adding to this repo* sections of [`../../CLAUDE.md`](../../CLAUDE.md), and the
sibling of [`../claude-setup-audit/SKILL.md`](../claude-setup-audit/SKILL.md) (which audits a consuming
`.claude/` setup) and [`../retrospective/SKILL.md`](../retrospective/SKILL.md) (which turns a lesson into
durable config): those maintain a *consuming* environment, this one maintains *this library*. Its first
job is restraint — most "we should add a skill for X" ideas are really a lens, a rule, or nothing.

## Core stance

- **A skill is a *type of work*, never a pattern, a topic, or a book.** `java-pr-review` (review a diff)
  and `spec-author` (write a spec) are modes of work; "the Observer pattern" or "Kafka" is *knowledge*
  and belongs in a lens. The first question is always *which artifact* — get it wrong and the library
  accretes a skill per concept and collapses into noise.
- **skill vs. lens vs. rule.** A **skill** is a workflow with a trigger and an output contract
  (`skills/<name>/SKILL.md`). A **lens** is reusable specialized knowledge a skill loads on demand
  (`lenses/<topic>.md`), shared across skills and read *evaluatively* by one and *generatively* by
  another. A **rule** is a global rubric every skill obeys (`rules/<name>.md`). Knowledge shared by two
  skills is a lens; a one-skill concern stays in the skill; a cross-cutting rubric is a rule.
- **Add only on real, recurring need.** A lens is added when a real consumer needs it; a skill when a
  recurring mode of work has no home. Speculative additions — "we might review Rust someday" — are the
  `NO_COMMENT` of this skill. Do not scaffold ahead of need.
- **The `description` is the trigger surface — it *is* the skill.** A skill fires (or fails to) entirely
  on its frontmatter `description`. It must say *when to fire* and, just as importantly, *when not to* —
  an over-broad description fires on everything and trains the user to ignore it; a thin one never fires.
  Write it as carefully as the body, in the words the user is likely to use.
- **Inherit the house contract, don't reinvent it.** Every skill emits consequence-driven findings
  classified by the shared [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md), references
  lenses/rules by relative path, and stays sanitized (synthetic neutral nouns — `Order`, `Payment`,
  `Invoice` — no corporate or copyrighted material). A new skill that invents its own severity
  vocabulary, or inlines real identifiers, fractures the library's coherence.
- **A skill that isn't indexed and can't be absorbed doesn't exist.** Adding the file is half the job;
  the structure map, the README tree, the CHANGELOG entry, the VERSION bump, and any consuming-skill
  wiring or pending-lens note must move *with* it — or the next session reads a stale map and never loads
  the new capability.

## When to run

- Adding a **new skill, lens, or rule** to this repository.
- The user asks to **"create a skill", "add a lens", "scaffold a skill", "how do I add X here"**.
- A **recurring mode of work** keeps coming up with no home skill — the trigger to *consider* one, then
  apply the restraint test before building.

Do **not** run it to author application code (not this repo's job), or to add a skill for a one-off task,
or for knowledge an existing lens already covers (extend the lens instead).

## How to run

1. **Decide the artifact — skill, lens, or rule — first.** Is this a new *type of work* (skill),
   reusable *knowledge* a skill consumes (lens), or a *global rubric* (rule)? If it is a pattern or a
   topic, it is almost certainly a lens, not a skill. If no real consumer needs it yet, stop —
   `NO_COMMENT`.
2. **Check it doesn't already exist.** Read the structure map in [`../../CLAUDE.md`](../../CLAUDE.md): a
   new skill must be a mode of work no existing skill covers; a new lens, a subject no existing lens
   owns. Overlap → extend the existing artifact and carve the boundary explicitly (as the lenses do),
   never add a near-duplicate.
3. **Draft the trigger surface.** Write the frontmatter `name` and `description` first — the description
   states when it fires *and when it does not*, in the user's likely words. This is the
   highest-leverage part: a skill mis-triggers entirely on a weak description.
4. **Write the body to the house shape, mirroring an exemplar.** For a **skill**: a short intro placing
   it in a track and against its siblings, a core stance, when/how to run, an output format, restraint
   rules, and a `Severity` section binding to [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md)
   (model it on a meta skill like `retrospective`, or a review skill like `java-pr-review`). For a
   **lens**: the section structure the existing lenses share — *How skills use this lens, Purpose, When
   to Use, Core Principle, Severity Calibration, Review Questions, Heuristics, Anti-Patterns,
   Modernization, Integration* — and an explicit boundary carve against any neighbor it could overlap.
   Copy an existing artifact's shape rather than inventing a layout.
5. **Wire the indexes in the same change.** Update the [`../../CLAUDE.md`](../../CLAUDE.md) structure map
   (and the skill count), the README tree and roadmap, add a [`../../CHANGELOG.md`](../../CHANGELOG.md)
   entry, bump [`../../VERSION`](../../VERSION), and — for a lens — add it to every consuming skill's
   declared list (and clear its "pending lens" note). A user-visible change is tagged `vX.Y.Z` on merge.
6. **Verify it triggers and is clean.** Confirm the `description` would fire on the intended request and
   *not* on the unintended one; run the sanitization gate (`scripts/sanitization-check.sh --staged`)
   before committing; for a lens, confirm its severity calibration and that its boundary carve names the
   neighbor it defers to.

## Output format

```
Artifact: <skill | lens | rule>  —  <name>
  Warranted: <why this is a real, recurring need — not speculative, not an existing artifact>
  Decision:  skill (a type of work) | lens (shared knowledge) | rule (global rubric) — <why this one>
  Trigger:   <the description's fire / don't-fire surface, in the user's words>     [skills only]
  Consumers: <which skills load it, evaluatively / generatively>                    [lenses only]
  Indexes:   <structure map · README tree · CHANGELOG · VERSION · consuming-skill wiring — each moved>
  Verified:  <triggers as intended · sanitization gate green · severity calibrated>
```

Close with the exact files created or changed (after approval).

## Restraint rules

- **Don't scaffold a skill for a pattern, a topic, or a one-off.** A pattern is a lens, a topic is a
  lens, a one-off is nothing. Per *type of work*, on real recurring need.
- **Don't add speculatively.** No "just in case" skill or lens with no current consumer — that is
  `NO_COMMENT`.
- **Never invent a parallel severity vocabulary or output contract.** Inherit the shared rubric; a new
  private scale fragments the library.
- **Never break sanitization.** Synthetic neutral nouns only; no real identifiers, secrets, or
  copyrighted text — the gate is the floor, not the ceiling.
- **Never land an artifact without moving the indexes with it.** A file the structure map doesn't list
  is invisible to the next session's absorption.
- **Checkpoint before writing.** Propose the artifact and the index changes; write on approval, exactly
  as the other meta skills do.

## Severity

Classify any finding about a proposed addition `MUST` / `SHOULD` / `NIT` / `NO_COMMENT` per
[`../../rules/severity-rubric.md`](../../rules/severity-rubric.md); every finding names a concrete
consequence.

- **MUST** — an addition that breaks the model: a "skill" that is really a pattern/topic (the library
  starts accreting a skill per concept), a duplicate of an existing artifact, a private severity
  vocabulary, real corporate/secret material, or a skill landed with **no** index/CHANGELOG/VERSION
  update (invisible and unabsorbable). Name the breakage.
- **SHOULD** — a real weakness short of breakage: a `description` too broad or too thin to trigger
  correctly, a lens with no boundary carve against an overlapping neighbor, a missing consuming-skill
  wiring, an absent worked example where the output contract is non-obvious.
- **NIT** — file placement, naming, ordering in the tree.
- **NO_COMMENT** — a genuinely warranted, well-formed addition; **or** a proposed addition that should
  simply not be made (speculative, one-off, already covered by a lens). Saying "don't add this, here is
  why" is the correct, frequent outcome.
