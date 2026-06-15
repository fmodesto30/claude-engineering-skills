# claude-engineering-skills — agent guide

> This file is auto-loaded by Claude Code when a session opens in this repository.
> **If the user asks you to "learn from this repository" — including the Portuguese
> "APRENDA COM ESSE REPOSITÓRIO" / "aprenda com este repo" — execute the
> [Learn protocol](#learn-protocol) below, in full.**
> Answer in the user's language.

## What this repository is

A small, sanitized library of **software-engineering review skills** for Claude Code.
It encodes review *judgment* — not new tools — so an agent applies the same calibrated,
consequence-driven engineering standard to every diff. First focus: **Java / Spring Boot
PR review**. It is built to be **dropped into any Claude CLI and adopted durably**.

Two building blocks (see [README.md](README.md) for the full model):

- **Skill** = a mode of work (`skills/<name>/SKILL.md`), auto-discovered via its frontmatter.
- **Lens** = reusable specialized knowledge (`lenses/<topic>.md`), loaded by a skill on demand.

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

| Skill | Triggers when | Uses lenses | Output |
|---|---|---|---|
| [`java-pr-review`](skills/java-pr-review/SKILL.md) | reviewing a Java/Spring diff or PR, or self-checking a change before review | [`design-patterns`](lenses/design-patterns.md) | severity-tagged findings (`file:line` → problem → consequence → suggestion) + verdict |

**Lenses** (shared knowledge, loaded only when the diff touches that area):
- [`lenses/design-patterns.md`](lenses/design-patterns.md) — when a design pattern helps vs.
  hurts in Java/Spring, with modern idioms that replace the classic forms.

**Rubric** (the severity vocabulary every review uses):
- [`skills/java-pr-review/references/severity-rubric.md`](skills/java-pr-review/references/severity-rubric.md)
  — `MUST` / `SHOULD` / `NIT` / `NO_COMMENT` and the overriding "name a concrete consequence" rule.

> As the repo grows, add a row per skill and a bullet per lens here so this map stays the
> single, cheap-to-read index of the repository's capabilities.

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
5. Report back a concise summary **in the user's words**: what this repo is, its review
   philosophy, the skills and lenses, and when each applies — so the user can confirm you
   absorbed it. Do not pad; demonstrate understanding, not coverage.

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

1. Create `<skills-dir>/<skill-name>/` and copy its `SKILL.md` and `references/` into it.
2. **Inline the lenses** it references: copy each `lenses/<x>.md` this skill declares into the
   new skill's `references/` (or a `lenses/` subfolder) and rewrite the `../../lenses/<x>.md`
   link in the copied `SKILL.md` to point at the local copy — so the installed skill is
   self-contained and does not depend on this repo's layout.
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

## Adding to this repo (for maintainers)

- New **skills** go under `skills/<name>/SKILL.md` (one per *type of work*, never per pattern);
  new **lenses** under `lenses/<topic>.md` (one per subject, shared across skills).
- Update the [Structure map](#structure-map) above with the new skill/lens.
- Every finding a skill emits must name a concrete consequence; if it can't, it's `NIT` or
  `NO_COMMENT`. Keep architecture rules separate from style preferences. No copyrighted or
  corporate material — synthetic, neutral examples only.
