# claude-engineering-skills

Original, sanitized software-engineering review skills for [Claude Code](https://claude.com/claude-code).
First focus: **Java / Spring Boot** — reviewing changes (pull-request and architecture review) and authoring the specs that drive them (spec-driven construction). Both tracks share the same lenses.

These are reusable *review lenses* — checklists, heuristics, and severity rubrics that let
Claude apply the same engineering judgment to every PR, so reviewers stop retyping the same
comments and juniors can self-review before asking.

## Learn from this repository

Drop this repo into any Claude CLI, open a session in it, and say **"APRENDA COM ESSE
REPOSITÓRIO"** (or "learn from this repository"). The agent loads [CLAUDE.md](CLAUDE.md), reads
every skill and lens in full, summarizes what it learned, and then proposes how to **adopt the
skills durably** in your environment (install them so they auto-trigger every session, or adapt
them to your stack) — staying read-only until you approve. See the
[Learn protocol](CLAUDE.md#learn-protocol).

## Philosophy

- **A pattern or rule is a tool, never a goal.** Nothing is flagged unless a concrete
  consequence can be named.
- **Severity-calibrated.** Every finding is `MUST` / `SHOULD` / `NIT` / `NO_COMMENT`.
  Preferences never block a PR. See [severity-rubric.md](rules/severity-rubric.md).
- **Style belongs to tooling, not review.** `final var`, `this.`, import order, formatting,
  and "useless comment" removal are a linter's job (Checkstyle, Spotless, PMD, Sonar) — not an
  AI review finding. The skills spend their attention on reasoning-heavy concerns: correctness,
  transactions, idempotency, design, and production risk.
- **Modern-first.** Prefer current Java/Spring idioms (records, sealed types, pattern matching,
  functional interfaces, DI, `ApplicationEventPublisher`) over classic pattern ceremony — and
  always inspect the *target* project's actual stack before recommending anything.
- **Few strong comments over many weak ones.** One well-justified `MUST` beats a wall of nits.

## Architecture model

- **Skill** = a mode of work / workflow (`skills/<name>/SKILL.md`).
- **Lens** = reusable specialized knowledge (`lenses/<topic>.md`), loaded by skills on demand.
- **Template** = output format (`templates/…`).
- **Rule** = a global rule (`rules/`), e.g. the severity rubric shared by every skill.
- **Hook** = deterministic enforcement — the sanitization gate (`scripts/sanitization-check.sh`,
  run in CI and as a pre-commit hook).

Knowledge lives in lenses and is shared across skills; each skill declares which lenses it uses
and *how* it uses them — the same lens serves a different intent across two tracks: **review**
skills (`java-pr-review`, `architecture-review`) read it *evaluatively*, to judge code or a design
that already exists, while **construction** skills (`spec-author`) read the *same* lens
*generatively*, to decide what to build. Skills are created **per type of work**, never per book
or per pattern.

## Structure

```
lenses/
├── agent-skills.md          # (meta) Claude Code skill & .claude/ config best practices
├── cdc.md                   # capturing & streaming committed datastore changes
├── clean-code.md            # readability & maintainability of changed code
├── cqrs.md                  # separating read (query) from write (command) models
├── data-analysis.md         # analytical reasoning: question, method, evidence, confidence
├── data-engineering.md      # data quality, lineage, grain; blocks unsound conclusions
├── ddd.md                   # domain modeling: boundaries, aggregates, consistency
├── design-patterns.md       # patterns that help vs. hurt (Java/Spring)
├── reporting.md             # (output) final shaping stage: narrative + HTML from a validated analysis
├── saga.md                  # cross-service consistency without distributed transactions
├── solid.md                 # responsibility, substitutability & dependency direction of changed code
├── spring-production-readiness.md # runtime risk: timeouts, idempotency, transactions, concurrency, leaks
└── testing.md               # test quality: does a test fail for the right reason?
rules/
├── analysis-rigor.md        # report rigor gate: conclusions must be sustained by evidence
├── severity-rubric.md       # global review rubric (MUST/SHOULD/NIT/NO_COMMENT)
└── spec-rubric.md           # global spec-quality rubric (BLOCKER/SHOULD/NIT/OK)
templates/
├── reports/                 # HTML report templates, one per situation
│   ├── analytical.html      #   diagnostic analysis (usage/cost across envs)
│   ├── metric-trend.html    #   a quantity over time
│   ├── discovery-stories.html #  docs -> epics/stories/trilha
│   └── exec-summary.html    #   decision-first summary for management
├── analysis-spec.md         # intermediate analytical contract (the HTML derives from it)
└── spec.md                  # prescriptive engineering-spec format
skills/
├── architecture-review/
│   └── SKILL.md             # review: a Java/Spring design at system altitude
├── claude-setup-audit/
│   └── SKILL.md             # (meta) audit & fix a Claude Code .claude/ setup
├── java-pr-review/
│   └── SKILL.md             # review: a Java/Spring PR diff
├── report/
│   └── SKILL.md             # construction: understand -> validate data -> analyze -> HTML report
└── spec-author/
    └── SKILL.md             # construction: write a prescriptive spec for a change
examples/
└── reporting/               # behavioral-eval fixtures for report + EXPECTED.md
scripts/
└── sanitization-check.sh    # deterministic sanitization gate (CI + pre-commit hook)
.github/workflows/
└── sanitization.yml         # CI: sanitization gate + gitleaks
LICENSE                      # CC BY 4.0
```

Skills (by type of work) and lenses (by subject) are added the same way as the repo grows —
never a giant do-everything skill. If a skill ever needs to ship standalone, a packaging/export
step copies the lenses it references into the skill so it stays self-contained.

## Using a lens

The lenses are written for the skills to consult, but they double as human-readable checklists
you can paste into a review. Point Claude Code at a diff or PR and ask it to review using
`java-pr-review`, or at a design or architectural change and ask for `architecture-review`; the
skill loads the rubric and the relevant lenses, then emits severity-tagged findings.

## Sanitization & copyright policy

This repository contains **only original material written from general, common engineering
knowledge.** It reproduces **no** book text, examples, code, didactic structure, or identifiers
from any source. Where study material informed a lens, it was read as temporary input and
distilled into original heuristics, review questions, and synthetic examples — never
paraphrased or transcribed.

- **No copyrighted material is committed.** PDFs, EPUBs, and raw study notes are `.gitignore`d.
- **No corporate material is committed.** No real code, service names, business rules,
  endpoints, logs, payloads, secrets, tokens, or certificates.
- **All examples are synthetic and domain-neutral** — `Order`, `Payment`, `Notification`,
  `Report`, `Customer`, `Invoice` and similar — with no relation to any real system.

## Documentation

- [docs/SANITIZATION_POLICY.md](docs/SANITIZATION_POLICY.md) — the full sanitization rules,
  clean-room authoring process, and pre-commit checklist (the section above is the short version).
- [docs/CORPORATE_ADOPTION.md](docs/CORPORATE_ADOPTION.md) — a ready-to-use prompt for a Claude
  Code instance inside a corporate environment to read this sanitized reference and bootstrap an
  **internal** version behind the corporate sanitization gate. No corporate content lives here.
- [docs/field-notes-verification-and-agentic-harness.md](docs/field-notes-verification-and-agentic-harness.md)
  — sanitized field notes distilled from a real generation-and-verification project: the proof
  harness, the decision oracle / delegated autonomy, and the agentic operating system. Seeds for
  future lenses/skills.

## Roadmap

Lenses and skills grow by real need, never speculatively. Planned next, in rough order:

- **Lenses:** `event-driven`, `observability`, `security`.
- **Review skills:** `architecture-review` consumes the architecture lenses (`ddd`, `saga`, `cqrs`,
  `cdc` today; `event-driven` as it lands).
- **Construction skills:** `spec-author` and `report` (a data-engineering + data-analysis pipeline
  that validates the data, runs the analysis, and only then renders an HTML report whose conclusions
  are sustained by evidence) today; `feature-build` (spec → Java/Spring code) and `app-bootstrap`
  (scaffold a service or module) as they land — all reusing the lenses generatively.
- **Meta/ops skills:** `claude-setup-audit` today (audits & fixes the `.claude/` setup itself against
  the `agent-skills` lens); `skill-author` (scaffold a new skill correctly) as it lands.

A lens is added only when a real consumer needs it; a skill is added per type of work.

## License

Licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE) — share and
adapt freely, including commercially, with attribution.

## Contributing rules

1. No PDFs, EPUBs, books, or copyrighted excerpts.
2. No secrets, credentials, certificates, real logs, real payloads, or corporate code.
3. Synthetic, neutral examples only.
4. Every rule must state a concrete consequence; if it can't, it's a `NIT` or `NO_COMMENT`.
5. Keep architecture rules separate from style preferences.
