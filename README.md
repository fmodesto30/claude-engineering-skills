# claude-engineering-skills

Original, sanitized software-engineering review skills for [Claude Code](https://claude.com/claude-code).
First focus: **Java / Spring Boot review** — both pull-request (diff) review and system/design (architecture) review.

These are reusable *review lenses* — checklists, heuristics, and severity rubrics that let
Claude apply the same engineering judgment to every PR, so reviewers stop retyping the same
comments and juniors can self-review before asking.

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
and *how* it uses them — the same lens serves a different intent in PR review vs. architecture
review vs. app bootstrap. Skills are created **per type of work**, never per book or per pattern.

## Structure

```
lenses/
├── clean-code.md            # readability & maintainability of changed code
├── ddd.md                   # domain modeling: boundaries, aggregates, consistency
├── design-patterns.md       # patterns that help vs. hurt (Java/Spring)
└── testing.md               # test quality: does a test fail for the right reason?
rules/
└── severity-rubric.md       # global severity rubric (MUST/SHOULD/NIT/NO_COMMENT)
skills/
├── architecture-review/
│   └── SKILL.md             # workflow: review a Java/Spring design at system altitude
└── java-pr-review/
    └── SKILL.md             # workflow: review a Java/Spring PR diff
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

## Roadmap

Lenses and skills grow by real need, never speculatively. Planned next, in rough order:

- **Lenses:** `solid`, `saga`, `cqrs`, `cdc` (change data capture), `event-driven`,
  `spring-production-readiness`, `observability`, `security`.
- **Skills:** `architecture-review` consumes the architecture lenses (`ddd` today;
  `saga` / `cqrs` / `cdc` / `event-driven` as they land).

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
