---
name: effort-budget
description: >-
  Right-sizes the model, thinking effort, context window, and multi-agent fan-out for a task, and
  flags when the session is provisioned above the work. Use when starting under a stated token or
  cost budget, when asked whether a task needs the top model or high reasoning effort, when a
  cheaper tier clearly suffices for routine work, or when a heavy multi-agent fan-out is planned
  for a small job. Proposes a tier change as a checkpoint — current tier to recommended tier, the
  reason, and the concrete saving — and proceeds on the user's choice. Never switches silently,
  never downgrades genuinely hard work (false economy), and never cuts the explanation the user
  needs. Read-only and advisory; defers code review to the review skills. Not for every task —
  only budget signals, an explicit ask, or clear over-provisioning.
---

# effort-budget

A meta/ops skill that matches session capability to task difficulty — model, thinking effort,
context window, and multi-agent fan-out — and flags over- or under-provisioning under a token or
cost budget, proposing any change as a checkpoint and proceeding on the user's choice. It is
distinct from the review track (`java-pr-review`, `architecture-review`) and the construction track
(`spec-author`, `report`): its subject is the **session's provisioning**, not application code. Its
job is to spend the right amount of capability on the work, not the most.

## Core stance

- **Match capability to difficulty.** A simple, well-scoped task on a cheap tier is a complete,
  correct setup; a hard, ambiguous, high-stakes task earns the strong model and high effort. The
  goal is fit, not a maximal or minimal default — and difficulty is judged by the *hidden
  correctness surface*, not the task's surface label.
- **Minimize total cost-to-correct, not per-turn cost.** A cheaper tier that needs a re-do or
  misses a bug costs more than the right tier once. Optimize the cost of *reaching a correct
  result*, never the sticker price of a single turn.
- **Warn, do not nag.** Surface a mismatch once, concretely, then move on. Repeating the nudge
  every turn is the anti-pattern this skill exists to avoid.
- **The user's explicit choice wins.** A deliberate choice of the top tier or high effort is
  `NO_COMMENT` — do not second-guess a stated preference.
- **Never downgrade genuinely hard work.** Recommending a weaker tier for a task that needs the
  strong one is false economy: a small token saving for a wrong or incomplete result that costs
  far more to fix.
- **Explaining clearly is never the cut.** Reasoning the user needs to see, a thorough answer, or
  context a correct result depends on is not waste — never trim the explanation to save tokens.

## How to run

1. **Assess the task's real difficulty.** Judge what the work actually requires: scope, ambiguity,
   stakes, breadth of context, whether it is mechanical or genuinely novel — and whether an
   easy-looking task (CRUD, "follow the pattern") hides an idempotency, concurrency, transactional,
   or security surface that makes it hard. This is the anchor; everything else is measured against it.
2. **Read the current provisioning.** Note what the session is running: the **model** tier, the
   **thinking-effort** level, the **context window** in use, and whether a **multi-agent fan-out**
   is planned (and how wide). Note any **stated budget** — a token cap or a cost ceiling.
3. **Judge the mismatch with the lens.** Compare difficulty against provisioning using
   [`../../lenses/model-and-effort-economy.md`](../../lenses/model-and-effort-economy.md) — tier
   fit, effort fit, window fit, and fan-out fit, and how each reads under a stated budget. Load the
   lens; do not re-derive its rules from memory.
4. **Surface ONE concrete recommendation as a checkpoint.** If there is a real mismatch, state it
   once: the **current tier → recommended tier**, the **reason** tied to the task's difficulty, and
   the **concrete saving** (tokens, cost, or fan-out width avoided). Present it as a checkpoint, not
   a switch.
5. **Proceed on the user's choice.** Apply the change only if the user takes it; otherwise continue
   as provisioned. **Never auto-switch** the model, effort, or fan-out yourself — this skill is
   advisory.

When right-sizing alone cannot fit the budget and the task genuinely needs the strong tier, do not
silently downgrade. Surface the conflict explicitly — cut scope, split the work, or raise the
budget — so the user resolves it. This skill re-allocates spend honestly; it does not pretend a
hard task can be done correctly under a budget that cannot cover it.

## Output format

A single-line nudge plus a verdict. Keep it to one surfacing, not a recurring banner:

```
[over-provisioned | under-provisioned] <current tier/effort/fan-out> -> <recommended> — <reason tied to task difficulty>
  Saving: <concrete tokens / cost / fan-out width avoided>
  Verdict: matched | over-provisioned | under-provisioned
```

Concrete example:

```
over-provisioned: top model + high effort -> mid model, medium effort — single-file rename, shallow
correctness surface, tests already green; nothing here needs frontier reasoning.
  Saving: a large fraction of per-turn token cost; no multi-agent fan-out needed.
  Verdict: over-provisioned
```

When provisioning fits the work, say so in one line and stop:

```
Verdict: matched — difficulty and provisioning line up; no change.
```

## Restraint rules

- **Do not nag every task.** Surface a mismatch once. Most tasks are correctly provisioned and the
  right outcome is silence (`NO_COMMENT`) — the common case, not a failure to find something.
- **The user's explicit top-tier choice is `NO_COMMENT`.** Respect a stated preference; do not
  re-litigate it each turn.
- **Never cut the explanation the user needs.** A cheaper-but-wrong or cheaper-but-opaque result is
  not a saving.
- **Never downgrade hard work.** If the task genuinely needs the strong tier or high effort, do not
  recommend a weaker one — the false economy costs more than it saves.
- **Defer code review.** Correctness, design, and architecture of the code belong to
  `java-pr-review` / `architecture-review`, not here. This skill sizes the session, not the code.

## Durable adoption note

A skill fires only when triggered, so this nudge will not fire on a session it was never invoked
in. For **always-on** right-sizing, recommend a one-line operating principle in the consuming
environment's `CLAUDE.md`, for example:

> Right-size model and effort to the task; flag an over-provisioned session **once** with the
> cheaper tier and the concrete saving (per the `effort-budget` skill), then proceed on the user's
> choice — never switch silently, never downgrade genuinely hard work.

Writing that durable line is itself a `retrospective`-style change (turning a standing preference
into config that fires every session); this skill carries the detailed judgment when the work
actually touches provisioning, while `retrospective` owns the mechanics of persisting the rule.

## Severity

Classify every finding `MUST` / `SHOULD` / `NIT` (or stay silent, `NO_COMMENT`) per
[`../../rules/severity-rubric.md`](../../rules/severity-rubric.md), and obey the overriding rule:
every finding names a concrete consequence. Mirror the lens's asymmetry — false economy is the
`MUST`; overspend is a `SHOULD`-or-softer nudge.

- **MUST** — the provisioning will cause a *wrong or incomplete result*: a hard, high-stakes task
  on a tier too weak to get it right, where the likely-wrong answer carries a real cost (a redo, a
  missed bug, eroded trust) whether or not a later gate catches it. Name the failure mode.
- **SHOULD** — it works, but a specific change clearly saves cost with no risk to correctness: a
  routine, shallow-surface task on the top tier and high effort a mid tier finishes correctly; a
  wide multi-agent fan-out for a job one agent handles; a 1M-token window on work that fits the
  default. State the concrete saving.
- **NIT** — a marginal effort/tier tweak with negligible cost impact and no correctness effect. A
  brief note, never a blocker.
- **NO_COMMENT** — provisioning already fits the work, or the user explicitly chose the current
  tier. Stay silent. For a correctly provisioned session this is the most common, correct outcome.
