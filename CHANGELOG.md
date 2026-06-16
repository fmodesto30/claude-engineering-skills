# Changelog

All notable changes to this repository are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and every release is a git tag (`vX.Y.Z`) plus the
[`VERSION`](VERSION) marker. A newer tag / `VERSION` than the one a CLI last absorbed is the signal
that **a new patch is available**.

> **Absorbing a patch:** an agent that has already learned an earlier version should read **only** the
> entries below that are newer than the version it recorded — and open just the lenses/skills those
> entries name — rather than re-reading the whole repo. See the *patch update path* in
> [`CLAUDE.md`](CLAUDE.md#staying-current--patches).

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
