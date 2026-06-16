# Agent Skills Lens

Reusable knowledge for Claude Code Agent Skills and `.claude/` configuration: when a skill, a setting, or a layout choice does concrete work — gets a skill discovered, makes it auto-trigger, lets a reference resolve, keeps a secret out, survives a container rebuild — and when extra configuration is ceremony a small setup does not need. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This lens has two consumers, used with opposite intents. **`claude-setup-audit`** reads it **evaluatively and correctively** — it inspects an actual `.claude/` setup, judges each piece against the practices below, and proposes fixes for the deviations that have a named consequence (a skill that will not be discovered, a description that will not trigger, a reference that will not resolve, a secret that leaks, a setup that will not survive a container rebuild). A future **`skill-author`** could read the *same* knowledge **generatively** — to place, name, and describe a new skill correctly the first time, rather than to repair one after the fact.

That shared use — corrective for the auditor, generative for the author — is exactly why this knowledge lives in `lenses/` rather than inside one skill: each consumer supplies its own intent, the lens supplies the knowledge. A consuming skill loads it only when the work actually touches a `.claude/` setup, a SKILL.md, a reference, a setting, or container reproducibility — never just because the words "skill" or "agent" appear somewhere.

This is a **meta** lens: its subject is Claude Code configuration, not Java/Spring or any application domain, so it carries no domain examples. It keeps the same calibrated, consequence-first, restrained voice as the other lenses.

## Purpose

This lens helps the reviewer judge whether a Claude Code setup actually works — whether the skills are discovered, auto-trigger on a good description, resolve the resources they reference, keep secrets out, and stay reproducible — rather than whether it matches a maximal template. Its job is to separate configuration that does concrete work from configuration copied by rote or added "to be thorough." The default bias is toward the smallest setup that satisfies the need: a single SKILL.md in the right folder with a strong description and no settings file at all is a complete, correct setup. When a setup adds a frontmatter field, a settings entry, a hook, a custom layout, or a cross-directory reference, the lens gives the reviewer a consistent way to ask "does this get the skill discovered, triggering, resolving, secret-free, or reproducible — and is it placed where Claude Code will actually find it?" and to phrase the answer as a consequence-anchored finding. It is equally a tool for restraint — for confirming that a tiny setup needs nothing more and that no comment is warranted.

## When to Use

Consult this lens when the work touches a Claude Code setup at the configuration level, including:

- Auditing or setting up a `.claude/` directory (project) or `~/.claude/` (personal).
- Authoring a new skill, or moving/renaming an existing one.
- Debugging why a skill does not auto-trigger, does not appear in the `/` menu, or is never discovered at all.
- Debugging why a reference inside a SKILL.md does not resolve (a bundled file, a shared lens, a script).
- Reviewing or changing `CLAUDE.md`, `settings.json`, or `settings.local.json`.
- Making a setup reproducible — committing the right files for team sharing, or surviving a devcontainer rebuild.

Do NOT engage this lens merely because a `.claude/` directory, a `SKILL.md`, or the word "skill" appears in a tree. The trigger is a concrete configuration decision with a consequence — discovery, triggering, resolution, secrets, reproducibility — not the presence of the vocabulary. A setup that already works and is being read for unrelated reasons is not a reason to engage.

## Core Principle

A skill and its `.claude/` configuration are tools, not objectives. A setup is correct when it does concrete work, and the work is specific and verifiable:

- **Discovered** — Claude Code can find the skill, because its `SKILL.md` lives at `<scope>/.claude/skills/<name>/SKILL.md` (personal, project, or plugin), not in a loose folder that is never scanned.
- **Triggers** — the skill auto-invokes when it should, because its `description` names concrete use cases and trigger phrases (or it deliberately opts out via `disable-model-invocation` and is invoked by name).
- **Resolves** — every resource the skill references actually loads, because resources are co-located inside the skill directory (or referenced by a stable, packaged path), not reached through fragile `../../` links that break on a different install.
- **Secret-free** — no token, credential, or key is hardcoded in a `SKILL.md`, in `settings.json`, or in any committed file; secrets come from the environment.
- **Reproducible** — the setup survives the way it is actually run: the right files are committed for team sharing, `settings.local.json` is gitignored, and a devcontainer either commits its `.claude/` or mounts `~/.claude/` so it does not vanish on rebuild.

The fact that a setup *could* add a field, a settings file, a hook, or a custom layout is never, by itself, a reason to add it. **A tiny setup needs almost nothing** — one well-placed, well-described skill is complete, and demanding `settings.json`, `disable-model-invocation`, custom `paths`, or a `rules/` tree where none is needed is over-configuration, a cost without a benefit. This lens leans against ceremony: the most common correct finding on a small, working setup is restraint. **"No comment" is a valid, frequent, and correct outcome.**

## Severity Calibration

Apply these four levels to setup findings (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md) for the shared definitions):

- **MUST** — The setup is broken in a way with a concrete consequence now: a skill placed outside `.claude/skills/<name>/` so it is **never discovered**; missing or malformed YAML frontmatter, or a vague/absent `description`, so the skill **never auto-triggers**; a reference to a bundled file or shared resource that **does not resolve** at the skill's location (it loads `../../lenses/foo.md` that is not there on this install); a **secret hardcoded** in a `SKILL.md` or `settings.json`; `settings.local.json` committed (not gitignored) so personal config and any secret in it **leaks**; a devcontainer that relies on `~/.claude/` without a volume mount so the setup **disappears on rebuild**. These must be raised and must name the failure mode.
- **SHOULD** — It works today, but a specific change clearly improves it and you can name the benefit: a `SKILL.md` well over ~500 lines that should move reference detail into supporting files so the context budget is not spent on every load; a description that triggers but buries its use cases past the listing truncation so discovery is degraded; a cross-directory `../../` reference that resolves *here* but is fragile across personal/project/plugin installs and should be co-located or packaged; a `CLAUDE.md` far over ~200 lines, or conflicting guidance across nested `CLAUDE.md` files; an undocumented or unjustified `allowed-tools` entry that pre-approves a broad tool. Raise it when the benefit is real and nameable.
- **NIT** — Cosmetic or organizational preference with no behavioral consequence: a skill directory name that could read better, frontmatter key ordering, a description phrased slightly less crisply but still triggering and within budget. A brief note, never a blocker.
- **NO_COMMENT** — The suggestion would impose configuration a tiny setup does not need: "add a `settings.json`" / "set `disable-model-invocation`" / "add `paths` globs" / "split this into a `rules/` tree" when the setup is one small skill that is discovered, triggers, resolves, holds no secret, and is reproducible as run. Stay silent. This is the most common outcome for a small, working setup.

**Overriding rule:** every finding must name a concrete consequence — the skill will not be discovered, it will not auto-trigger, a reference will not resolve, a secret leaks, config drifts or vanishes, or the context budget is spent for nothing. "This isn't the canonical layout" / "you should have a settings file" / "real setups use hooks" is **not** a finding. "This skill lives in `projects/skills/foo/SKILL.md`, which Claude Code does not scan, so it is never discovered and the `/foo` command does not exist" **is**. If no concrete consequence can be articulated, the finding is NO_COMMENT, no matter how far the setup diverges from a maximal template.

## Review Questions

Before raising or accepting a setup decision, the reviewer should be able to answer:

- Is this skill at `<scope>/.claude/skills/<name>/SKILL.md` (personal, project, or plugin), or in a folder Claude Code does not scan? Was discovery actually confirmed in the running version, not assumed?
- Does the `description` lead with concrete use cases and trigger phrases, and does it fit within the listing truncation budget so the trigger signal is not cut off? Has `/doctor` been used to check it is not being truncated?
- Should this skill auto-trigger at all, or is it side-effecting/destructive enough that it should set `disable-model-invocation` and be invoked by name?
- Does every resource the skill references resolve from the skill's own location, on the install scope it actually ships in? Is any reference reaching outside the skill directory with `../../`?
- Is the `SKILL.md` small enough that loading it does not waste the context budget, with detail pushed into supporting files that load on demand?
- Is there any secret in a committed file? Is `settings.local.json` gitignored?
- Which files must be committed for a teammate (or a rebuilt container) to get the same behavior, and are they?
- What Claude Code version is this, and do the version-dependent features this setup relies on exist in it?
- Does the setup tell the agent that a *provisioned* credential is authorized for use — so it does not re-litigate or refuse it every session — and is credential expiry self-recovered (refresh + retry) rather than a manual reminder loop?

## Heuristics

### Discovery & Location

**What to look for:** Where a skill's `SKILL.md` actually lives. Claude Code auto-discovers skills from personal `~/.claude/skills/<name>/SKILL.md`, project `<project>/.claude/skills/<name>/SKILL.md` (loaded from `.claude/skills/` at the starting directory and every parent up to the repo root), and from plugins (namespaced as `/plugin-name:skill-name`). The strong signal of a problem is a skill file in a folder that is *not* one of these — a plain `projects/skills/foo/SKILL.md`, a `skills/` at the repo root with no `.claude/` parent, or a SKILL.md nested one level too deep or too shallow.

**Why it matters:** Discovery is binary. A skill in the wrong folder is not "harder to find" — it is **never loaded**, never auto-triggers, and has no `/name` entry, with no error to explain the silence. The author sees nothing and assumes the skill is broken when it was simply never scanned.

**When NOT to comment:** When the skill is already at a discovered path for the scope it is meant for, do not propose moving it to another scope on principle (a personal skill does not need to become a project skill). Edits to a discovered `SKILL.md` take effect within the session — verify in your Claude Code version — so do not tell an author to restart unless the version actually requires it.

**Correct form (Claude Code idiom):** Put each skill at `<scope>/.claude/skills/<name>/SKILL.md`. Use `~/.claude/skills/` for personal skills available everywhere, the project's `.claude/skills/` for team skills committed with the repo, and a plugin for distribution (consumers see it namespaced). `name` defaults to the directory name, so the directory is the identity.

**Key review questions:** Is this file under a `.claude/skills/<name>/` directory at a scope Claude Code scans? If it is not triggering, is it discovered at all — or is the real problem location, not the description?

**Example finding:** "MUST: `projects/skills/release-notes/SKILL.md` is not under any `.claude/skills/` directory, so Claude Code never scans it — the skill is not discovered, does not auto-trigger, and has no `/release-notes` command. Move it to `.claude/skills/release-notes/SKILL.md` (project scope) and confirm it appears in your Claude Code version."

### Frontmatter & the Description-as-Trigger

**What to look for:** The YAML frontmatter block between `---` markers, and especially the `description`. The `description` is the key field and the **trigger signal** for auto-invocation. Watch for missing or malformed frontmatter (no `---` fences, broken YAML), and for a vague description ("utilities for git", "helpful utility") that names no use case. Note the optional fields and whether they are used deliberately: `when_to_use` (extra trigger phrases appended to the description, counting toward its ~1536-char cap), `disable-model-invocation` (true means no auto-trigger; the user types `/name`), `user-invocable` (false hides it from the `/` menu — knowledge-only), `allowed-tools`/`disallowed-tools`, `model`, `effort`, `paths` (globs that gate auto-activation), `argument-hint`, `arguments`, `hooks`, `shell`, and `context: fork` with `agent`.

**Why it matters:** A skill with broken or absent frontmatter does not register; a skill with a vague description registers but **never auto-triggers**, because the model has no concrete signal to match a user request against. The description (plus optional `when_to_use`) is truncated around 1536 characters in skill listings — *verify the exact budget in your Claude Code version* — so use cases buried past the cut-off do not contribute to triggering. A side-effecting or destructive skill that auto-triggers can run when the user did not intend it; one that sets `disable-model-invocation` is safe but only fires when invoked by name.

**When NOT to comment:** When a description already leads with concrete use cases and trigger phrases and fits the budget, do not rewrite it for taste. Do not demand `disable-model-invocation`, `paths`, or `when_to_use` on a read-only, idempotent skill that is safe to auto-trigger — those fields earn their place only when there is a side effect to guard or an activation to scope.

**Correct form (Claude Code idiom):** Write a description that leads with concrete action verbs plus when-to-use plus example trigger phrases — e.g. "Stage, commit, and push changes. Use when you are ready to commit or want to review your diff." Front-load the use cases so the trigger signal survives truncation. Set `disable-model-invocation: true` for destructive or side-effecting workflows so they fire only on `/name`. Use `/doctor` to confirm the description is not being truncated by the context budget.

**Key review questions:** Does the description name concrete use cases and trigger phrases first, within the listing budget? Is the frontmatter valid YAML between `---` markers? Does this skill have a side effect that warrants opting out of auto-invocation?

**Example finding:** "MUST: the `deploy` skill's description is `Deployment utilities`, which names no use case, so the model has no signal to auto-trigger it and it effectively only runs if the user already knows to type `/deploy`. Rewrite as concrete use cases first — e.g. `Build, tag, and push a release. Use when cutting a release or promoting a build to staging` — and, because it has side effects, set `disable-model-invocation: true` so it fires only when invoked by name."

### Size, Progressive Disclosure & Path Resolution

**What to look for:** The length of the `SKILL.md` and how it references its resources. Keep `SKILL.md` under about 500 lines — *verify the guidance in your Claude Code version*. Watch for a bloated SKILL.md that inlines long reference material, examples, and scripts; and watch for the resolution model: relative links inside a `SKILL.md` resolve relative to the **skill directory**, not the working directory. References that reach *outside* the skill directory (for example `../../lenses/foo.md`) are fragile across personal/project/plugin installs.

**Why it matters:** A SKILL.md is loaded into context when the skill activates; an oversized one spends the context budget on detail that is not needed every time. Progressive disclosure — keeping the entry file lean and linking heavier reference, examples, and scripts that load on demand — keeps activation cheap. Path resolution is a correctness issue, not a style one: a `../../` link that resolves while the repo is checked out **will not resolve** when the same skill ships as a plugin or is installed at personal scope, so the resource silently fails to load. This is exactly why a library repo that shares files across skills needs a packaging step that copies the referenced shared files into the skill when it ships standalone.

**When NOT to comment:** A short SKILL.md that inlines everything it needs is fine — do not split a 120-line skill into a tree of supporting files for its own sake. A cross-directory reference inside a *monorepo of skills that always ship together* (like this repository, where lenses and skills are co-checked-out and a packaging step is documented) is a known, accepted trade-off; flag it only if the skill is meant to ship standalone without packaging.

**Correct form (Claude Code idiom):** Keep `SKILL.md` lean and link supporting files inside the skill directory so they load on demand. Co-locate resources the skill needs inside `<name>/`. For scripts invoked via shell-injection commands, reference them with the `${CLAUDE_SKILL_DIR}` variable rather than a relative guess — *verify `${CLAUDE_SKILL_DIR}` and `context: fork` are available in your Claude Code version*. When a skill in a shared-library repo references files outside its directory, define a packaging/export step that copies those files into the skill for standalone shipping.

**Key review questions:** Will this resource resolve from the skill's own directory on the scope it ships in, or only because the repo happens to be checked out a certain way? Is the SKILL.md large enough that loading it wastes context that supporting files could defer?

**Example finding:** "SHOULD: `pr-review/SKILL.md` references `../../lenses/severity.md`. That resolves while the repo is checked out, but if this skill ships as a plugin or installs at personal scope the lens is not at that relative path and the reference will not resolve — the skill loads without its rubric. Either co-locate the lens inside `pr-review/` or add a packaging step that copies it in on export. (Inside this repo's documented packaging model it is acceptable as-is.)"

### `.claude/` Layout & CLAUDE.md

**What to look for:** The shape of the `.claude/` directory and the `CLAUDE.md` files. The conventional layout is `CLAUDE.md` (project instructions, target under ~200 lines), `settings.json` (team-shared, committed), `settings.local.json` (personal, gitignored), `skills/`, `agents/`, `rules/` (path-scoped via `paths` frontmatter), `hooks/`, `output-styles/`, and `commands/` (legacy — prefer `skills/`). Watch for a `CLAUDE.md` far over ~200 lines, for conflicting guidance across nested `CLAUDE.md` files, and for use of the legacy `commands/` instead of `skills/`.

**Why it matters:** `CLAUDE.md` is concatenated into context broad-to-narrow with a defined precedence — managed policy > user (`~/.claude/CLAUDE.md`) > project (`./CLAUDE.md` or `./.claude/CLAUDE.md`) > local (`./CLAUDE.local.md`, gitignored). An oversized `CLAUDE.md` spends the budget on every turn; *conflicting* nested files mean the narrower file silently overrides the broader, so guidance the author thinks is in force is not, with no error. The legacy `commands/` mechanism still works but is superseded by `skills/`, which carry richer frontmatter and auto-triggering — staying on `commands/` forgoes discovery and triggering behavior.

**When NOT to comment:** A small project with a single, focused `CLAUDE.md` under the size guidance needs nothing more — do not demand a `rules/` tree, an `agents/` directory, or split files. Nested `CLAUDE.md` files that *refine* rather than *contradict* each other are working as designed; flag only an actual conflict with a consequence.

**Correct form (Claude Code idiom):** Keep `CLAUDE.md` focused and under the size guidance, with detail in the skills and rules it points to. Commit `.claude/` (skills, `settings.json`, `CLAUDE.md`) for team sharing and gitignore `settings.local.json`. Use path-scoped `rules/` (gated by `paths` frontmatter) for guidance that applies only to part of the tree. Prefer `skills/` over the legacy `commands/`.

**Key review questions:** Is `CLAUDE.md` within the size guidance, and do nested `CLAUDE.md` files refine rather than contradict each other? Is anything still in `commands/` that should be a skill? Is the layout matched to what the project needs, or padded with empty ceremony?

**Example finding:** "SHOULD: `.claude/CLAUDE.md` is ~600 lines and repeats the full review rubric that the `pr-review` skill already carries. Every turn pays that context cost. Trim it to the project-specific instructions and let the skill own the rubric, keeping `CLAUDE.md` near the ~200-line guidance — verify the guidance in your Claude Code version."

### Settings, Permissions & Secrets

**What to look for:** What lives in `settings.json` versus `settings.local.json`, whether the local file is gitignored, any secret in a committed settings file or `SKILL.md`, and how `allowed-tools`/`disallowed-tools` are used. Settings precedence is managed > CLI flags > local (`settings.local.json`) > project (`settings.json`) > user (`~/.claude/settings.json`). Watch for a hardcoded token/credential/key, a committed `settings.local.json`, and a broad `allowed-tools` entry (for example `Bash(rm *)`) with no justification.

**Why it matters:** A secret in any committed file **leaks** the moment the repo is shared or pushed — this is a MUST regardless of how the rest of the setup looks. A `settings.local.json` that is not gitignored leaks personal config and any secret it holds, and creates drift because each clone carries someone else's local overrides. `allowed-tools` is a **pre-approval** for the active turn — it does *not* replace or restrict the permission model — so a broad entry quietly widens what runs without prompting; on a side-effecting skill, that combined with auto-invocation is how an unintended command runs.

**When NOT to comment:** A setup with no `settings.json` at all is fine — settings are optional, and a skill that needs no pre-approved tools and no env config needs no settings file. Do not invent one. A narrow, justified `allowed-tools` entry (a specific read-only command the skill runs every time) is appropriate; flag breadth and missing justification, not the existence of the field.

**Correct form (Claude Code idiom):** Keep secrets out of every committed file; read them from environment variables at run time. Commit `settings.json` for team-shared config and gitignore `settings.local.json` for personal overrides. Scope `allowed-tools` to the specific commands a skill actually needs, justify a broad one, and pair a side-effecting skill with `disable-model-invocation` rather than a wide pre-approval that can fire unprompted.

**Key review questions:** Is there any secret in a committed `SKILL.md` or settings file? Is `settings.local.json` gitignored? Does any `allowed-tools` entry pre-approve more than the skill needs, and is it justified?

**Example finding:** "MUST: `.claude/settings.json` contains `\"API_TOKEN\": \"<literal-token-value>\"` and is committed, so the token leaks to everyone with repo access and to history. Remove it, read the token from an environment variable at run time, and rotate the exposed value. Keep machine-specific overrides in `settings.local.json`, which must be gitignored."

### Authorized Credentials — Use vs. Leak

**What to look for:** Whether the setup tells the agent that a credential it is *provisioned with* — a token, an SSO session, an API key in the environment, a Git credential in a cloned repo's config — is **authorized for use**, and whether expiry is handled. The tell of a gap: nothing in `CLAUDE.md` (or a rule/skill) states the credential is pre-approved for the operations it exists for, so the agent treats every use as a secret-handling risk — re-asking permission, hesitating, or refusing — and nothing tells it what to do when the credential expires, so it stalls and waits for the operator.

**Why it matters:** "Keep secrets out of committed files" (above) is about not *leaking* a secret; it is **not** a reason to *refuse to use* a credential the agent is meant to act with. An agent that conflates the two **mis-applies caution**: it stalls on authorized work, re-litigates the same approval every session, and trains the operator to babysit it — and an expired credential becomes a manual reminder loop instead of a self-recovered condition. Using the provisioned credential is the expected behavior; the protection is *redaction and non-persistence*, not refusal.

**When NOT to comment:** When the setup already pre-authorizes the credential and handles expiry, do not pile on. And do not weaken the real guardrail: a credential that is *out of scope*, *someone else's*, or being *sent somewhere it should not go* should still not be used, and a genuine secret hardcoded in a committed file is still a `MUST` to remove (above). The point is to distinguish authorized *use* from *exposure*, not to drop the leak protection.

**Correct form (Claude Code idiom):** Make the authorization explicit and durable so it is not re-decided each session. In the always-loaded `CLAUDE.md` (or a path-scoped rule), state that the provisioned credential is pre-approved for its documented operations, that output is **always redacted** (pipe it through a redactor; never print or commit it raw), and that on an auth failure (e.g. `401`/`403`) the agent should **refresh via the documented mechanism and retry**, escalating only if the refresh itself fails. Better, climb to a deterministic mechanism — a credential helper or a session-start refresh hook — so the agent never meets an expired credential and the operator never reminds it. The litmus for "use it": is this the agent's intended, scoped, provisioned authorization to act? Then use it, redacted. Is it out of scope, someone else's, or bound for somewhere it should not go? Then do not.

**Key review questions:** Does anything tell the agent the provisioned credential is authorized for use, or will it re-litigate or refuse every session? When the credential expires, does the agent self-recover (refresh + retry) or stall waiting for a human? Is output redacted so *use* never becomes *exposure*?

**Example finding:** "SHOULD: nothing in `CLAUDE.md` states that the provisioned API token is authorized for the agent's push/API operations, so the agent re-asks or hesitates every session and stalls when it expires — the operator ends up reminding it each time. Add a short pre-authorization rule (use it freely for the documented operations, output always redacted, refresh-and-retry on a `401`/`403`), or a session-start refresh hook, so authorized use is settled once rather than re-litigated per session."

### Devcontainer Persistence

**What to look for:** When the setup runs in a devcontainer, which parts of it survive a rebuild. Project files persist (they are a bind mount), so a committed `.claude/` comes back. But `~/.claude/` does **not** persist across container rebuilds unless it is mounted as a named volume (a mount like `source=claude-code-config,target=/home/<user>/.claude,type=volume`). Watch for a setup that relies on personal-scope skills, settings, or auth in `~/.claude/` inside a container with no such mount.

**Why it matters:** A personal-scope skill or setting that works in the container today **disappears on the next rebuild**, with no error — the skill simply stops being discovered and the behavior silently changes. The failure is invisible until someone rebuilds and the setup is gone.

**When NOT to comment:** A setup that does not use a devcontainer needs none of this. A container that relies only on the committed project `.claude/` (skills, `settings.json`, `CLAUDE.md`) is already reproducible — do not demand a `~/.claude` mount it does not use.

**Correct form (Claude Code idiom):** For reproducibility, commit what the project needs — `.claude/skills/`, `.claude/settings.json`, `.claude/CLAUDE.md` — so it rides the bind mount. If the workflow genuinely depends on personal scope inside the container, mount `~/.claude/` as a named volume so it survives rebuilds.

**Key review questions:** Does this container rely on anything in `~/.claude/`, and if so is `~/.claude/` mounted as a named volume? Is everything the project needs committed under `.claude/` so it persists on the bind mount?

**Example finding:** "MUST: the devcontainer relies on a personal skill in `~/.claude/skills/` but mounts no named volume for `~/.claude/`, so on the next container rebuild the skill is gone and silently stops triggering. Either move it into the committed project `.claude/skills/`, or add a named-volume mount for `~/.claude/` — verify the mount syntax in your Claude Code / devcontainer version."

## Anti-Patterns

- **Skill in a folder Claude Code does not scan** — *Diff/setup:* a `SKILL.md` under `projects/skills/`, a root-level `skills/`, or any path that is not `<scope>/.claude/skills/<name>/SKILL.md`. *Harm:* the skill is never discovered, never auto-triggers, and has no `/name` command — and there is no error to explain it, so the author debugs the description when the problem is the location. *Fix:* move it under a scanned `.claude/skills/<name>/` directory at the intended scope and confirm it is discovered in the running version.

- **Vague or missing description** — *Diff/setup:* frontmatter with no `description`, or one like "utilities" / "helpful tool" that names no use case, or use cases buried past the listing truncation. *Harm:* the skill registers but never auto-triggers, because the model has no concrete signal to match a request against; it only ever runs if the user already knows the name. *Fix:* lead the description with concrete action verbs, when-to-use, and example trigger phrases, front-loaded to survive truncation; check with `/doctor` that it is not being cut off.

- **Bloated SKILL.md** — *Diff/setup:* a single `SKILL.md` well over the size guidance that inlines long reference, examples, and scripts. *Harm:* the whole file loads into context on every activation, spending the budget on detail not needed each time. *Fix:* keep the entry file lean and move detail into supporting files inside the skill directory that load on demand (progressive disclosure).

- **Broken or fragile resource reference** — *Diff/setup:* a SKILL.md that references a bundled file that is not there, or reaches outside the skill directory with `../../` to a shared file. *Harm:* the reference does not resolve at the skill's location — silently, with no rubric/resource loaded — and the `../../` form breaks across personal/project/plugin installs even when it works in the checked-out repo. *Fix:* co-locate resources inside the skill directory, use `${CLAUDE_SKILL_DIR}` for scripts, and add a packaging step that copies shared files in when the skill ships standalone.

- **Secret in a committed file** — *Diff/setup:* a token, credential, or key hardcoded in a `SKILL.md` or in `settings.json`. *Harm:* the secret leaks to everyone with repo access and into history the moment it is shared or pushed. *Fix:* remove it, read it from an environment variable at run time, rotate the exposed value, and keep machine-specific config in the gitignored `settings.local.json`.

- **`settings.local.json` not gitignored** — *Diff/setup:* the personal local settings file committed to the repo. *Harm:* personal overrides (and any secret in them) leak, and every clone inherits someone else's local config, causing drift and confusing behavior differences. *Fix:* gitignore `settings.local.json`; keep only team-shared config in the committed `settings.json`.

- **Dangerous `allowed-tools` with no guard** — *Diff/setup:* a broad pre-approval such as `Bash(rm *)` in an auto-invocable skill, with no justification and no `disable-model-invocation`. *Harm:* `allowed-tools` is pre-approval, not restriction, so the broad command can run without a prompt; on an auto-triggering skill it can fire when the user did not intend it. *Fix:* scope `allowed-tools` to the specific command needed, justify any breadth, and set `disable-model-invocation` on a side-effecting skill so it runs only when invoked by name.

- **Oversized or conflicting CLAUDE.md** — *Diff/setup:* a `CLAUDE.md` far over the size guidance, or nested `CLAUDE.md` files whose guidance contradicts across the precedence chain. *Harm:* the budget is spent every turn, and a narrower file silently overrides a broader one, so guidance the author believes is in force is not. *Fix:* trim `CLAUDE.md` to focused project instructions within the guidance, point it at the skills/rules that own the detail, and reconcile conflicts so nested files refine rather than contradict.

- **Legacy `commands/` instead of `skills/`** — *Diff/setup:* workflows kept in `.claude/commands/` when they would be skills. *Harm:* `commands/` is superseded and forgoes the richer frontmatter, auto-triggering, and discovery that skills provide. *Fix:* migrate to `.claude/skills/<name>/SKILL.md` with a proper description — verify the migration path in your Claude Code version.

- **Personal-scope reliance in a devcontainer with no mount** — *Diff/setup:* a container that depends on `~/.claude/` skills or settings without a named-volume mount. *Harm:* the setup vanishes on the next rebuild and silently stops working. *Fix:* commit what the project needs under `.claude/` (it rides the bind mount), or mount `~/.claude/` as a named volume.

- **Agent that refuses or re-litigates its authorized credential** — *Diff/setup:* nothing pre-authorizes a provisioned token/session/key, so the agent treats *using* it as a risk — re-asking, hesitating, or stalling — and has no expiry-refresh path. *Harm:* authorized work stalls, the same approval is re-litigated every session, and an expired credential becomes a manual reminder loop; the operator is trained to babysit. *Fix:* state the credential is pre-approved for its documented operations with output always redacted, and self-recover on an auth failure (refresh + retry) — or add a credential helper / session-start refresh hook. Distinguish *use* (expected) from *exposure* (forbidden); do not drop the leak guardrail.

## Verify Against Current Docs

Claude Code evolves, and several items below are version-dependent. **Inspect the actual Claude Code version and the actual setup; never assume.** Frame every version-specific claim as *verify in your Claude Code version*, and prefer current official documentation over older guidance:

- **Skill commands and generators** — `/run`, `/verify`, and `/run-skill-generator` need a recent Claude Code (around v2.1.145+). Confirm the command exists before relying on it.
- **Auto memory** — needs around v2.1.59+. Confirm before assuming memory features are present.
- **`context: fork` and `${CLAUDE_SKILL_DIR}`** — documented, but verify they are available and behave as expected in the running version before recommending them.
- **Description token budget** — the description (plus optional `when_to_use`) is truncated around 1536 characters in skill listings, but the exact math may vary by version; use `/doctor` to check whether a specific description is being truncated rather than trusting the number.
- **Frontmatter fields** — `disable-model-invocation`, `user-invocable`, `allowed-tools`/`disallowed-tools`, `paths`, `hooks`, `shell`, `model`, `effort`, `argument-hint`, `arguments` are documented, but confirm each is honored in the running version before depending on it.
- **Devcontainer mount syntax** — the named-volume mount for `~/.claude/` is the documented approach, but verify the exact mount specification against the current devcontainer docs.
- **Standard alignment** — Skills follow the Agent Skills open standard; the discovery and frontmatter rules above are the stable core, but treat anything version-gated as something to confirm by inspecting the running version, not from memory.

When the running version and the docs disagree with an assumption, the running version wins — inspect it.

## Suggested Comment Style

Keep comments respectful, consequence-first, and severity-honest. Lead with what concretely breaks (the skill will not be discovered, it will not trigger, a reference will not resolve, a secret leaks, the setup vanishes on rebuild), not with "this isn't the canonical layout." State severity honestly; a NIT should read like a NIT, not a blocker. Offer the fix, and frame every version-specific claim as something to verify in the running version. When the setup is tiny and working, say it needs nothing more and say nothing.

Example openers:

- "This skill won't be discovered because... — move it to..."
- "This description won't auto-trigger because it names no use case; lead with..."
- "This reference won't resolve when the skill ships as..., because..."
- "This is a secret in a committed file — remove it, read it from the environment, and rotate..."
- "NIT (not a blocker): ..."
- "This setup is small and works — it's discovered, triggers, and holds no secret. No change needed."

Example comments (meta subject, no domain):

- "MUST: this `SKILL.md` lives outside any `.claude/skills/` directory, so Claude Code never scans it — it is not discovered and `/name` does not exist. Move it to `.claude/skills/<name>/SKILL.md` and confirm it appears in your version."
- "MUST: the description is `helpful utilities`, which gives the model no signal to auto-trigger. Lead with concrete use cases and trigger phrases so it fires when intended — and check with `/doctor` that it isn't truncated."
- "SHOULD: this references `../../shared/foo.md`, which resolves in the checked-out repo but not when the skill installs at personal scope. Co-locate it in the skill directory or add a packaging step. (Acceptable as-is under this repo's documented packaging model.)"
- "If this is just one small skill that's discovered and triggers, it needs no `settings.json` and no `disable-model-invocation` — I'd leave it as is."

## Integration (claude-setup-audit)

The consuming skill uses this lens as a judgment aid for inspecting and repairing a real setup, not a template to impose:

- **Never comment because a setup lacks an optional piece.** No `settings.json`, no `rules/` tree, no `disable-model-invocation` is not a finding by itself. Absence is worth raising only when you can name the concrete consequence (a side-effecting skill that will auto-fire unprompted, a secret that should move out of a committed file).
- **Comment only when there is a real, articulable consequence** — not discovered, will not trigger, will not resolve, a leaked secret, config that drifts or vanishes, or context spent for nothing.
- **Inspect the actual setup and the actual Claude Code version.** Confirm discovery, triggering, and resolution in the running version rather than asserting them from the layout.
- **Always tag findings** `MUST` / `SHOULD` / `NIT` per [`../rules/severity-rubric.md`](../rules/severity-rubric.md) so the author can triage by severity. (NO_COMMENT is the silent fourth outcome and, for a small working setup, the most common one.)
- **A few strong findings beat many weak ones.** One well-justified MUST about a skill that is never discovered or a leaked secret is worth more than a list of "you could add a settings file" suggestions — drop the weak ones to NO_COMMENT.
- **Never silently rewrite configuration.** Propose the fix as a concrete checkpoint and apply it on approval; this lens describes *what* is wrong and *why*, and the skill owns the propose-then-apply discipline.
