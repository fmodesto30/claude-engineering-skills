---
name: claude-setup-audit
description: >-
  Audits a Claude Code `.claude/` setup against current Anthropic best practices and fixes what
  is off — skill discovery and location, SKILL.md frontmatter and the description-as-trigger,
  resource resolution, CLAUDE.md size and precedence, settings.json vs settings.local.json,
  hardcoded secrets, and devcontainer reproducibility. Use when setting up or reviewing a
  `.claude/` directory, when a skill is not auto-triggering or not appearing in the `/` menu,
  when a referenced file or lens will not resolve, or when making a setup reproducible in a
  container. Inspects the actual setup and the actual Claude Code version, proposes fixes as a
  checkpoint, and applies them only on approval — never silently. Not for Java/Spring code review.
---

# claude-setup-audit

A meta/ops skill that inspects a Claude Code `.claude/` setup, judges it against the Agent Skills
lens, and corrects the deviations that have a concrete consequence — proposing the changes as a
checkpoint and applying them only on approval. It is distinct from the Java/Spring review track
(`java-pr-review`, `architecture-review`) and the construction track (`spec-author`): its subject
is the configuration itself, not application code.

## Core stance

- **Correctness over ceremony.** A setup is right when its skills are *discovered*, *auto-trigger*
  on a good description, *resolve* their resources, keep *secrets* out, and stay *reproducible* —
  not when it matches a maximal template. Flag something only when you can name the concrete
  consequence (not discovered / will not trigger / will not resolve / leaked secret / config
  drifts or vanishes). If you can't, it's `NO_COMMENT`.
- **Inspect the actual setup and the actual Claude Code version — never assume.** Confirm
  discovery, triggering, and resolution in the running version. Treat every version-dependent
  feature as *verify in your Claude Code version*.
- **Anti-over-configuration.** A tiny setup needs almost nothing — one well-placed, well-described
  skill is complete. Do not demand a `settings.json`, `disable-model-invocation`, custom `paths`,
  or a `rules/` tree where none does concrete work.
- **Fix with a checkpoint, never silently.** Propose the changes, show them, and apply only on
  explicit approval. Configuration is load-bearing; a silent rewrite can break discovery or leak a
  secret.

## How to run an audit

1. **Inventory the actual setup.** Enumerate what is really there before judging:
   - Skills in the project `.claude/skills/` (at the starting directory and every parent up to the
     repo root) and in personal `~/.claude/skills/` — note any `SKILL.md` in a folder Claude Code
     does *not* scan.
   - Each `SKILL.md`'s frontmatter: `name`, `description`, and any `disable-model-invocation`,
     `user-invocable`, `allowed-tools`/`disallowed-tools`, `paths`, `hooks`, `shell`, `model`,
     `effort`, `argument-hint`, `arguments`, `context: fork`.
   - `CLAUDE.md` files across the precedence chain (managed > user > project > local) and their
     sizes.
   - `settings.json` and `settings.local.json` — what each holds, and whether the local file is
     gitignored.
   - Hooks, `agents/`, `rules/`, `output-styles/`, and any legacy `commands/`.
   - The **Claude Code version**, so version-dependent features can be verified rather than assumed.
2. **Check against the lens.** Judge the inventory with
   [`../../lenses/agent-skills.md`](../../lenses/agent-skills.md) — discovery & location,
   frontmatter & the description-as-trigger, size & progressive disclosure & path resolution,
   `.claude/` layout & CLAUDE.md, settings/permissions/secrets, and devcontainer persistence. Load
   the lens; do not re-derive its rules from memory. (These `../../` links resolve while the repo is
   checked out together; if this skill ships standalone — a packaged plugin or personal scope — the
   repo's packaging step co-locates the lens and rubric into the skill, so verify the packaged copy
   is present rather than assuming the relative path resolves. This is the exact fragility this skill
   audits.)
3. **Classify findings.** Tag every finding `MUST` / `SHOULD` / `NIT` / `NO_COMMENT` per
   [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md), and obey the overriding
   rule: every finding names a concrete consequence.
4. **Propose fixes as a concrete checkpoint.** For each MUST/SHOULD, state the change precisely —
   what file *moves* and to where, what *frontmatter* changes (and the exact new `description`),
   what resource gets *co-located* or packaged, what gets *gitignored*, what *secret* is removed
   and read from the environment instead. Present it as a checkpoint (the affected paths, the diff,
   the rationale) and **wait for explicit approval**.
5. **Apply on approval.** Make exactly the approved changes — move the skill, rewrite the
   frontmatter, co-locate the resource, gitignore the local settings, strip the secret. Do not
   bundle unapproved changes.
6. **Re-verify.** Confirm the setup now does what the fix claimed: the skill is discovered (it
   appears and can be invoked), and a referenced resource resolves **on the scope the skill actually
   ships in** (project, personal, or packaged plugin) — not merely in the current repo checkout.
   Confirm in the running Claude Code version, not by inspecting the tree alone. Report what was
   verified.

## Output format

Render each finding the same way the rubric defines, with a location and a consequence:

```
[MUST|SHOULD|NIT] <path or skill name> — <problem>
  Consequence: <not discovered / will not trigger / will not resolve / secret leaks / config drifts or vanishes>
  Fix: <the concrete change — move to X, set description to Y, co-locate Z, gitignore the local file>
```

Then close with:

- **Verdict** — sound / sound with fixes / broken (a discovery, trigger, resolution, or secret
  problem must be fixed).
- **Per-severity count** — number of MUST / SHOULD / NIT.
- **Applied-changes summary** (after approval and apply) — what was changed and the result of
  re-verification (skill now discovered; resource now resolves).

## Restraint rules

- **Do not impose config a tiny setup does not need.** No `settings.json`, no
  `disable-model-invocation`, no `paths`, no `rules/` tree is not a finding by itself — raise an
  absence only when you can name the consequence of it.
- **Never commit secrets or un-gitignore the local settings.** A secret in a committed file is
  always a MUST to remove (read it from the environment, rotate it); `settings.local.json` must
  stay gitignored.
- **Never silently modify `.claude/`.** Checkpoint first, apply on approval. A silent rewrite can
  break discovery or leak config.
- **Defer code review.** Java/Spring correctness, design, and architecture belong to
  `java-pr-review` / `architecture-review`, not here. This skill audits the setup, not the code the
  setup reviews.
- Drop weak suggestions to `NO_COMMENT` rather than padding the audit; a few strong findings beat
  many weak ones.
