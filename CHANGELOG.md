# Changelog

All notable changes to this repository are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and every release is a git tag (`vX.Y.Z`) plus the
[`VERSION`](VERSION) marker. A newer tag / `VERSION` than the one a CLI last absorbed is the signal
that **a new patch is available**.

> **Absorbing a patch:** an agent that has already learned an earlier version should read **only** the
> entries below that are newer than the version it recorded — and open just the lenses/skills those
> entries name — rather than re-reading the whole repo. See the *patch update path* in
> [`CLAUDE.md`](CLAUDE.md#staying-current--patches).

## [0.7.0] — 2026-06-19

### Added
- **Skill `skill-author`** — a meta/ops skill for extending the library itself: it decides whether an
  addition is a **skill** (a type of work), a **lens** (shared knowledge), a **rule** (a global rubric),
  or nothing, then scaffolds it to the house conventions — a trigger-surface `description`,
  consequence-driven findings on the shared severity rubric, lenses referenced by relative path,
  synthetic neutral examples — and keeps the indexes in sync (structure map, README tree,
  CHANGELOG/VERSION, consuming-skill wiring), verifying the artifact triggers and passes the
  sanitization gate. Restraint-first: most "add a skill for X" ideas are really a lens, a rule, or
  nothing, and "don't add this, here is why" is a frequent correct outcome. Consults `agent-skills`.

## [0.6.0] — 2026-06-19

### Added
- **Lens `security`** — application-security review for Java/Spring at line/method and system altitude:
  injection (SQL/JPQL/command/LDAP/path), authorization & broken-object-level-access (IDOR), secret &
  credential handling, sensitive-data/PII exposure, cryptography & randomness misuse, insecure
  deserialization / XXE / SSRF, mass assignment, CSRF/CORS. It **owns the secret/PII-in-log `MUST`**
  that `spring-production-readiness` explicitly delegates, names the *exploit* (not the OWASP category)
  for every finding, and delegates dependency-version CVEs to SCA tooling rather than acting as a
  scanner. Consumed by `java-pr-review`, `architecture-review`, and `spec-author`.
- **Lens `observability`** — whether a changed flow can be operated and diagnosed in production:
  structured/queryable logging and honest levels, metric type and **cardinality control** (the label
  that detonates the time-series backend), trace/correlation propagation across async & messaging
  boundaries (and MDC leakage on pooled threads), health/readiness/liveness correctness, and
  symptom-based alertable signals. Carved against `spring-production-readiness` (which flags that a
  visibility *gap* exists; this lens owns instrumentation *quality*) and `saga` (cross-step
  correlation), and defers PII/secret-in-log to `security`. Consumed by `java-pr-review`,
  `architecture-review`, and `spec-author`.
- **Lens `event-driven`** — the event-driven architectural *style* at system/design altitude: the
  decision to be event-driven at all (vs. a synchronous call), event design (notification vs.
  event-carried state transfer vs. event sourcing), domain-vs-integration events, producer/consumer &
  temporal coupling, **event-schema evolution** (the silent cross-boundary contract break),
  ordering/partitioning, and topology (pub/sub vs. point-to-point, the coupling/visibility facet of
  choreography vs. orchestration). Carves explicitly against `saga` (workflow consistency/compensation),
  `ddd` (aggregate boundary & domain events), `cqrs` (read/write split), `cdc` (capture mechanics), and
  `spring-production-readiness` (line-level runtime/idempotency mechanics). Consumed by
  `architecture-review` (per the roadmap) and `spec-author`.
- **Wiring** — `java-pr-review` now consumes `security` and `observability`; `architecture-review` now
  consumes `security`, `observability`, and `event-driven`. The structure map, lens tree, and roadmap
  are updated accordingly.

## [0.5.0] — 2026-06-19

### Added
- **Skill `architecture-decision-records`** — a construction skill that records *why* an
  architecturally-significant decision was made: its context and forces, the decision, the
  alternatives genuinely considered and why each was rejected, and the consequences (the costs
  accepted, not only the upside). Records **only** significant, hard-to-reverse, cross-cutting
  decisions — a reversible local choice is `NO_COMMENT`, not an ADR — and treats an accepted record
  as immutable: a changed decision is **superseded** by a new record, never edited in place, so the
  decision trail stays true. Reads the architecture lenses (`ddd`, `saga`, `cqrs`, `cdc`,
  `spring-production-readiness`) generatively. The `MUST` is a significant decision shipped with no
  record, or history rewritten by editing an accepted one.
- **Skill `eval-harness`** — a meta/quality skill that brings measurement to non-deterministic
  outputs (an LLM feature, agent, classifier, ranker) where a pass/fail unit test does not fit. It
  defines the success criteria and a versioned dataset (representative + edge + adversarial, with a
  held-out slice), picks the strongest grader the criterion allows (deterministic > reference metric >
  validated LLM-as-judge), pins and records the run config (model, prompt, temperature, seed), and
  compares against a baseline with **n and variance** — never claiming a win inside the noise — while
  tracking cost and latency next to quality. Pairs with `effort-budget` (right-size the model; then
  prove it still clears the bar) and consumes `testing`, `data-analysis`, `data-engineering`,
  `model-and-effort-economy`. The `MUST` is shipping a non-deterministic change with no eval, claiming
  an improvement within the noise, or an unvalidated judge driving a ship decision. Stays out of
  deterministic-code territory, which belongs to the `testing` lens / `java-pr-review`.

## [0.4.0] — 2026-06-18

### Added
- **Lens `model-and-effort-economy`** — the cost-side sibling of `agent-skills`: right-sizing the
  model tier, thinking effort, context-window size, and multi-agent fan-out to a task's difficulty
  under a token or cost budget. Names the cost levers (each a spend multiplier), a difficulty-based
  right-sizing heuristic judged by the *hidden correctness surface* (not the surface label), and a
  deliberate severity asymmetry: **false economy** (a cheap tier on genuinely hard work, whose redo
  costs more than the right tier once) is the `MUST`; overspend is a `SHOULD`-or-softer nudge.
  Minimize total cost-to-correct, not per-turn cost; never downgrade hard work to hit a budget.
  Includes a **make-the-spend-visible** heuristic — you cannot right-size what you cannot see: the
  usage command (`/usage` / `/cost`), `/context`, per-turn parsing of the local session transcript
  (or `ccusage`), and OpenTelemetry metrics, all version-gated and working offline without telemetry.
- **Skill `effort-budget`** — a meta/ops skill that flags an over- or under-provisioned session and
  proposes one right-sizing checkpoint (current tier to recommended, reason, concrete saving),
  proceeding on the user's choice. Read-only/advisory; warns once, never nags; never switches
  silently; surfaces a budget-vs-need conflict (cut scope / split / raise budget) instead of
  silently downgrading. Consumes `model-and-effort-economy`.

## [0.3.0] — 2026-06-16

### Added
- **Theming for report templates** — the report templates are themeable via a documented CSS-variable
  surface, and a theme is a **render-time preset suggested by purpose** and confirmed by the user. The
  capability is taught where an agent learns it (the lens and the skill), with a concrete contract and
  neutral examples; a real brand's palette/logo belongs in the consuming environment, never here.
  - `templates/THEMING.md` — the theme-variable contract, the optional logo slot, how inline-SVG chart
    colours must read the theme variables (`style="fill:var(--x)"` / a class, since SVG `fill`/`stroke`
    presentation attributes do not accept `var()`), and how to add a theme.
  - `templates/themes/theme-slate.css` and `theme-dark.css` — two neutral example themes (no brand).
  - `lenses/reporting.md` — a "Theming & brand identity" section (a theme is the user's/organisation's
    skin, orthogonal to shape and chart type; legitimate only when subordinate to the data; suggested by
    purpose, confirmed by the user; the chart type and the shape are never a cosmetic menu) plus a
    "Theme overriding substance" anti-pattern.
  - `skills/report/SKILL.md` — the render step now selects and suggests a theme preset by
    audience/purpose, without altering the data-driven shape or chart type.

## [0.2.0] — 2026-06-16

### Added
- **Lens `spring-production-readiness`** — runtime risk off the happy path: timeouts/resilience,
  idempotency under retry & redelivery, transaction boundaries & consistency, concurrency / shared
  mutable state, query cost (N+1 / unbounded), error visibility, resource leaks. Consumed by
  `java-pr-review` (line/method altitude) and `architecture-review` (system altitude).
- **Lens `solid`** — one heuristic per principle (SRP/OCP/LSP/ISP/DIP), each consequence-driven, with
  a hard bias toward `NO_COMMENT`. Scoped to defer the mechanism to `design-patterns`, the local
  tangle to `clean-code`, and system-altitude dependency direction to `ddd`/`architecture-review`.
  Consumed by `java-pr-review`.
- **Skill `retrospective`** — turns a lesson, especially a mistake that recurred, into a durable
  config change along a durability ladder (a hook for the mechanically-preventable, a rule / CLAUDE.md
  for standing judgment, memory for cross-session facts) so it does not recur; checkpoints before
  writing and verifies the change will fire next time.
- **Lens `agent-skills` — new heuristic "Authorized Credentials — Use vs. Leak"** — using a
  *provisioned* credential is the agent's expected behavior; the protection is redaction and
  non-persistence, not refusal. Refusing or re-litigating authorized use each session, and treating
  expiry as a manual reminder instead of a self-recovered condition (refresh + retry, or a refresh
  hook), is mis-applied caution. The leak guardrail is unchanged.
- **Versioning & patches** — this `CHANGELOG.md`, the [`VERSION`](VERSION) marker, git release tags,
  and a *patch update path* in `CLAUDE.md` so a CLI absorbs only the delta of a new patch.

### Fixed
- **Onboarding (`CLAUDE.md`)** — rebuilt the structure map (it was stale at one skill / one lens; now
  it lists all five skills, the lenses, and the rules), fixed the severity-rubric link (it pointed at
  the old `skills/.../references/` path; the rubric now lives in `rules/`), and bounded the Learn
  protocol so "APRENDA COM ESSE REPOSITÓRIO" returns a concise summary plus an adoption proposal —
  not an unsolicited multi-point audit of the repo.

## [0.1.0] — 2026-06-15

### Added
- Baseline, as first absorbed by external CLIs. Skills: `java-pr-review`, `architecture-review`,
  `spec-author`, `report`, `claude-setup-audit`. Lenses: `design-patterns`, `clean-code`, `testing`,
  `ddd`, `saga`, `cqrs`, `cdc`, `data-engineering`, `data-analysis`, `reporting`, `agent-skills`.
  Rules: `severity-rubric`, `spec-rubric`, `analysis-rigor`. Plus the report templates, the
  sanitization gate (CI + pre-commit), and the self-teaching onboarding ("APRENDA COM ESSE
  REPOSITÓRIO").
