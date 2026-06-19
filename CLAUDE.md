# claude-engineering-skills — agent guide

> This file is auto-loaded by Claude Code when a session opens in this repository.
> **If the user asks you to "learn from this repository" — including the Portuguese
> "APRENDA COM ESSE REPOSITÓRIO" / "aprenda com este repo" — execute the
> [Learn protocol](#learn-protocol) below, in full.**
> Answer in the user's language.

**Version:** see [`VERSION`](VERSION) · what changed per release: [`CHANGELOG.md`](CHANGELOG.md) · each
release is a git tag (`vX.Y.Z`). If you've absorbed an earlier version, use the
[patch update path](#staying-current--patches) — read only the delta, not the whole repo.

## What this repository is

A small, sanitized library of **software-engineering skills** for Claude Code. It encodes
engineering *judgment* — not new tools — so an agent applies the same calibrated,
consequence-driven standard whether it is **reviewing** code and designs (`java-pr-review`,
`architecture-review`), **constructing** specs and reports (`spec-author`, `report`), or
**auditing and improving** a Claude setup (`claude-setup-audit`, `retrospective`). First focus:
**Java / Spring Boot**. It is
built to be **dropped into any Claude CLI and adopted durably**.

The building blocks (see [README.md](README.md#architecture-model) for the full model):

- **Skill** = a mode of work (`skills/<name>/SKILL.md`), auto-discovered via its frontmatter.
- **Lens** = reusable specialized knowledge (`lenses/<topic>.md`), loaded by a skill on demand.
- **Rule** = a global rubric (`rules/<name>.md`) every skill obeys (e.g. the severity rubric).
- **Template** = an output format (`templates/…`).
- **Hook** = deterministic enforcement (`scripts/sanitization-check.sh`, run in CI and pre-commit).

## Philosophy (the stance to absorb)

- **A rule or pattern is a tool, never a goal.** Flag something only when you can name the
  concrete consequence — what breaks, what gets harder, what risk materializes. If you can't,
  it is `NO_COMMENT`.
- **Severity-calibrated.** Every finding is `MUST` / `SHOULD` / `NIT` / `NO_COMMENT`.
  Preferences never block a PR.
- **Style belongs to tooling, not review.** Formatting, `final var`, `this.`, import order
  are a linter's job (Checkstyle/Spotless/PMD/Sonar) — never a review finding.
- **Modern-first, but inspect the real stack.** Prefer current Java/Spring idioms, and always
  check the *target* project's actual versions and classpath before recommending an API.
- **Few strong findings beat many weak ones.** Saying nothing is a valid, frequent outcome.

## Structure map

Eight skills across three tracks. Load a skill's lenses only when the change actually touches that area.

**Review** — judge code/design that already exists (*evaluative*):

| Skill | Triggers when | Lenses it uses |
|---|---|---|
| [`java-pr-review`](skills/java-pr-review/SKILL.md) | a Java/Spring **diff or PR**, at line/method level | `design-patterns`, `clean-code`, `testing`, `spring-production-readiness`, `solid` |
| [`architecture-review`](skills/architecture-review/SKILL.md) | a Java/Spring **design or sizeable change** at system altitude | `ddd`, `design-patterns`, `saga`, `cqrs`, `cdc`, `spring-production-readiness` |

**Construction** — decide what to build (*generative*):

| Skill | Triggers when | Lenses / templates it uses |
|---|---|---|
| [`spec-author`](skills/spec-author/SKILL.md) | writing/refining a **spec** before building | the lenses above, read generatively, + `spec-rubric` + `templates/spec.md` |
| [`report`](skills/report/SKILL.md) | turning data/docs into an **HTML report** (general-purpose, not JVM-only) | `data-engineering`, `data-analysis`, `reporting` + `analysis-rigor` + `templates/` |
| [`architecture-decision-records`](skills/architecture-decision-records/SKILL.md) | recording **why** a hard-to-reverse, cross-cutting decision was made (boundary, datastore, consistency/auth model, integration contract) — context, alternatives, consequences; immutable, superseded not edited | `ddd`, `saga`, `cqrs`, `cdc`, `spring-production-readiness` (read generatively) |

**Meta/ops:**

| Skill | Triggers when | Lens it uses |
|---|---|---|
| [`claude-setup-audit`](skills/claude-setup-audit/SKILL.md) | auditing/fixing a `.claude/` setup (skill not triggering, resource won't resolve, secret in config) | `agent-skills` |
| [`retrospective`](skills/retrospective/SKILL.md) | after a task or a **repeated error** — "save this lesson", "don't repeat this", "configure so this can't happen again", "what did we learn" | `agent-skills` |
| [`effort-budget`](skills/effort-budget/SKILL.md) | right-sizing model/effort/window/fan-out, or flagging an **over-provisioned session** under a token/cost budget ("do I need the top model for this?") | `model-and-effort-economy` |
| [`eval-harness`](skills/eval-harness/SKILL.md) | measuring **non-deterministic outputs** (LLM feature, agent, classifier) — dataset + grader + baseline; "is the new model better?", "set up regression testing for the AI feature" | `testing`, `data-analysis`, `data-engineering`, `model-and-effort-economy` |

**Lenses** (`lenses/`, shared knowledge loaded on demand): `design-patterns`, `clean-code`, `testing`,
`spring-production-readiness`, `solid`, `ddd`, `saga`, `cqrs`, `cdc`, `data-engineering`,
`data-analysis`, `reporting`, `agent-skills`, `model-and-effort-economy`.

**Rules** (`rules/`, global rubrics a consumer obeys): [`severity-rubric`](rules/severity-rubric.md)
(`MUST`/`SHOULD`/`NIT`/`NO_COMMENT` — review & audit), `spec-rubric` (`BLOCKER`/`SHOULD`/`NIT`/`OK` —
specs), `analysis-rigor` (the report's evidence gate).

**Theming:** report templates are themeable via a documented CSS-variable surface
([`templates/THEMING.md`](templates/THEMING.md)) with neutral presets in `templates/themes/`. A theme is
a render-time **preset suggested by purpose** and confirmed by the user — never a chart/shape menu
(those follow the data).

> See [README.md](README.md#structure) for the full file tree (templates, examples, scripts). When the
> repo grows, update this map so it stays the single, cheap-to-read index of the repo's capabilities.

## Learn protocol

Run this when the user asks you to learn from / adopt this repository. The goal is to absorb
**both the structure and the content** durably — not skim it once.

### Phase 1 — Understand (read-only; do not write anything yet)

1. Read [README.md](README.md) — the philosophy, the skill/lens/template/rule/hook model, and
   the sanitization policy.
2. Read **every** `skills/*/SKILL.md`. For each, note its frontmatter `name`, `description`
   (this is the trigger surface), the lenses it declares, and its output contract.
3. Read the severity rubric and **every** file under `lenses/` **in full** — this is the actual
   judgment/content, and it is the part worth absorbing deeply.
4. Build the map: for each skill, *when it triggers → which lenses it pulls → what severity
   vocabulary it emits*.
5. Report back a **concise** summary **in the user's words** — at most ~12 bullets / one screen:
   what this repo is, its philosophy, the skills and lenses, and when each applies — so the user can
   confirm you absorbed it. Demonstrate understanding, not coverage. **Do not** turn this into a
   critique, audit, scorecard, gap-analysis, or list of questions about the repo — learning is not
   reviewing. If the user later asks for an assessment, give it then; otherwise proceed to Phase 2.

### Phase 2 — Propose durable adoption (ask before writing anything outside this repo)

A Claude CLI does not memorize a repo permanently. To make this knowledge persist and
auto-trigger every session, propose the options below, recommend one, and **wait for approval**:

- **Option A — Install verbatim (recommended for most).** Make the skills auto-discoverable in
  this CLI so they fire on every relevant diff, in every project — not just this repo.
- **Option B — Adapt to the corporate stack.** Generate a stack-tuned version of the review
  skill: inspect the team's real Java/Spring version, build tool, linters, and conventions, and
  fold them in, keeping the lenses and the severity rubric. Use this when the generic skill
  would recommend APIs the corporate stack doesn't have.
- **Option C — One-shot.** Just apply the review standard to the current diff now, without
  installing anything. Non-durable, but zero setup.

### Phase 3 — Execute (only after the user approves)

For **Option A**, install at **user scope** (so it works across all the team's repos, not only
this one). Determine the CLI's user skills directory (typically `~/.claude/skills/`; ask if
unsure). Then, for each skill:

1. Create `<skills-dir>/<skill-name>/` and copy its `SKILL.md` (and any `references/` it has) into it.
2. **Inline everything the skill references** so the installed copy is self-contained and does not
   depend on this repo's layout: for each `../../lenses/<x>.md`, `../../rules/<x>.md`, and
   `../../templates/<x>` the `SKILL.md` links, copy that file into a local subfolder of the new skill
   and rewrite the link to the local copy. (This is the packaging step the README describes.)
3. Optionally add a one-line pointer to the environment's `CLAUDE.md` (e.g. "For Java/Spring
   review, use the `java-pr-review` skill and obey its severity rubric").

Report exactly which files you created. Make minimal changes and stop if anything is ambiguous.

### Safety (corporate)

- **Read-only until Phase 3 is approved.** No writes outside this repo, no commits, no installs
  without an explicit go-ahead.
- **Never copy secrets, credentials, tokens, private keys, certificates, real logs, real
  payloads, or corporate code** into this repo or anywhere.
- **Keep this repo sanitized.** Examples here are synthetic and domain-neutral on purpose — do
  not paste real corporate identifiers, service names, or business rules into it.
- **The target project wins on conflicts.** Where this repo's defaults disagree with the team's
  existing conventions or stack, follow the team — and, in Option B, encode that.
- **Learn, don't critique.** Your task is to understand this repo and propose adoption, then stop. Do
  not generate an unsolicited audit, scorecard, or backlog of questions/improvements about the repo.
  Offer deeper analysis only if the user explicitly asks — and keep it bounded when they do.

## Staying current — patches

This repository is **versioned**: the current version is in [`VERSION`](VERSION), what changed in each
release is in [`CHANGELOG.md`](CHANGELOG.md), and every release is a git tag (`vX.Y.Z`). **A newer tag
/ `VERSION` than the one you last absorbed is the signal that a new patch is available.**

When the user says a new patch is out — **"saiu o novo patch"**, "atualizou o repo", "learn what
changed", "pull the latest" — run the **update path**, not a full re-learn:

1. `git pull` (and `git fetch --tags`); read [`VERSION`](VERSION) / the newest tag.
2. If it is newer than the version you last absorbed, read **only** the [`CHANGELOG.md`](CHANGELOG.md)
   entries since that version, and open just the lenses/skills those entries name — **not** the whole
   repo.
3. Update your durable memory/config for only those changes, and **record the new version** as the one
   you have absorbed (e.g. a memory note: "absorbed claude-engineering-skills @ vX.Y.Z").

Run the full [Learn protocol](#learn-protocol) only on first contact, or when you have no recorded
version to diff from.

## Adding to this repo (for maintainers)

- New **skills** go under `skills/<name>/SKILL.md` (one per *type of work*, never per pattern);
  new **lenses** under `lenses/<topic>.md` (one per subject, shared across skills).
- Update the [Structure map](#structure-map) above with the new skill/lens.
- For a user-visible change, add a [`CHANGELOG.md`](CHANGELOG.md) entry, bump [`VERSION`](VERSION), and
  tag the merge (`vX.Y.Z`) — that is what lets a CLI absorb the patch as a delta, not a full re-learn.
- Every finding a skill emits must name a concrete consequence; if it can't, it's `NIT` or
  `NO_COMMENT`. Keep architecture rules separate from style preferences. No copyrighted or
  corporate material — synthetic, neutral examples only.
