# Field Notes — Claude Code Configuration Hardening

> **Source and scope.** These notes distill the reusable, domain-neutral gotchas observed while *auditing one real, security-hardened Claude Code setup* — running through an enterprise model gateway (Bedrock) inside a devcontainer, with a managed read-only `settings.json`, a heavy `permissions.deny` list, and a token-compression `PostToolUse` hook. Everything proprietary has been stripped: there are no host names, image registries, account identifiers, internal tool names, emails, or secrets from the source. Every claim about Claude Code's *own* behavior was checked against current Claude Code documentation; everything version-gated is marked *verify in your Claude Code version*. The subject is the *configuration*, never any application it reviews.
>
> **Status.** Field notes, not a lens or a skill. They **seed** a future hardening section in `lenses/agent-skills.md` (consumed by `skills/claude-setup-audit/SKILL.md`) — or a dedicated `config-hardening` lens — once a second real setup makes a practice recur. Where the lens already carries a practice, the note cross-references it by path rather than restating it.
>
> **Voice.** Same as the lenses: consequence-first, severity-honest, biased toward restraint. A practice earns its place only when a concrete failure mode can be named. The recurring theme here is **silent failure**: configuration that *looks* set, or *looks* safe, but is inert, bypassed, or reverted — with no error to tell you.

---

## How to read these notes

The `lenses/agent-skills.md` lens already judges whether a setup is *discovered, triggers, resolves, secret-free, and reproducible*. These notes add an orthogonal axis it does not yet cover: **is the setup's hardening real, and is the model/env config the one actually in force** — the parts that fail *silently and still look fine*. Three themes, each entry shaped **Principle -> Why it matters -> How to apply / verify**:

- **G. The `permissions.deny` list is hardening, not a boundary.**
- **H. Model & environment precedence — the silent-revert trap.**
- **I. Output-compression hooks must never swallow an error.**

---

## G. The `permissions.deny` list is hardening, not a boundary

A heavy deny-list reads as containment. It is not. It raises the cost of an *accidental or naively-injected* bad command, but it cannot be the boundary that keeps a determined or prompt-injected agent from exfiltrating or escaping — and treating it as one manufactures false confidence. Name what the deny-list actually stops versus what only the network and OS layers can.

### G1. Deny rules are per-tool — denying `Edit` does not deny `Write`

**Principle.** `Edit`, `Write`, and `MultiEdit` are *separate tools* in the permission model. A rule like `Edit(~/.claude/**)` blocks only `Edit`; `Write(~/.claude/**)` and `MultiEdit(~/.claude/**)` still go through. To protect a path from modification you must deny **all three** (and `NotebookEdit` where notebooks apply). *(Verify the current tool set in your Claude Code version.)*

**Why it matters.** A setup that denies `Edit(~/.claude/**)` to protect its own skills and hooks looks locked down, but an agent can still rewrite those same files with `Write` — the protection is an illusion with no error to reveal the gap. The most load-bearing files (a `PostToolUse` hook, a skill the agent auto-triggers) are exactly the ones worth protecting from *every* edit tool, not one.

**How to apply.** For every path you deny one edit tool on, deny `Edit`, `Write`, and `MultiEdit` together. Confirm by attempting a `Write` to a denied path in a throwaway turn — not by reading the deny-list and assuming coverage.

### G2. Directory globs miss sibling state files (`~/.claude.json`)

**Principle.** A glob scoped to a directory — `~/.claude/**` — matches files *under* that directory, not its siblings. The global state file `~/.claude.json` (mode 600) sits **beside** `~/.claude/`, not inside it, so a `~/.claude/**` deny never touches it — yet it carries flags such as `hasTrustDialogAccepted`.

**Why it matters.** A setup that believes it has frozen `~/.claude` config has left the trust/state file writable; flipping a flag there changes the agent's standing posture silently. One directory glob does not fence the whole config surface.

**How to apply.** Enumerate the *actual* sensitive targets and deny each explicitly: the config directory tree **and** the sibling `~/.claude.json`. The same caution applies to any `*/dir/**` glob — check for sibling files (`dir.json`, `dir.local`) the glob silently skips.

### G3. A command deny-list cannot be your exfiltration boundary

**Principle.** Egress and code-exec have unbounded forms; you cannot enumerate them. Blocking `wget`, `nc`, `ssh`, and inline `perl -e` / `ruby -e` / `php -r` does nothing against `curl`, `python -c`, `node -e`, a bash `/dev/tcp/host/port` redirect, or a dozen other channels. (`curl` is routinely *left out on purpose* because tooling needs it for an internal API — so the channel is open by design.) The same holds for the anti-encoding entries: denying `base64` leaves `xxd`, `od -An -tx1`, and `hexdump`.

**Why it matters.** A deny-list that *looks* like it blocks exfiltration but doesn't is worse than none: it tells the operator the box is contained when the real boundary was never set. Exfiltration must be stopped where it is enumerable — **at the network egress** (an allow-list of reachable hosts on the proxy/firewall), not by guessing binary names.

**How to apply.** Treat the command deny-list as defense-in-depth, never the boundary. The first question for any "is this setup contained?" audit is *is egress allow-listed at the network layer?* If yes, the curl / python / `/dev/tcp` gaps are moot; if no, they are open channels regardless of how long the list is. Do not invest in completing an inherently incompletable list.

### G4. Destructive-command denies are cosmetic; the real guard is elsewhere

**Principle.** `rm -rf /*`, `rm -rf ~/*`, `chmod 777 *` as deny patterns catch the exact string and little else — not `rm -rf /`, not a specific path, not `find / -delete`, not a clobbering `>` redirect.

**Why it matters.** They read as protection against catastrophe but stop only the literal forms. The genuine guards against destructive Bash are *no `sudo`*, *Bash not auto-approved by `acceptEdits`* (that mode auto-accepts file edits only, so a destructive command still prompts), and *recoverable backups*. Leaning on the pattern list invites a false sense of safety.

**How to apply.** Keep a couple of headline destructive denies as belt-and-suspenders, but do not treat them as the control. Rely on least privilege (no sudo), the permission prompt for Bash, and backups — and *verify* that `acceptEdits` does not auto-approve Bash in your version.

---

## H. Model & environment precedence — the silent-revert trap

Which model and settings are *actually in force* is decided by a precedence chain whose highest layers are managed/policy ones an operator cannot see from inside the container. The failure mode is uniform: the config you wrote is silently overridden or made inert, and the only symptom is subtly different behavior or cost.

### H1. `ANTHROPIC_MODEL` (shell env) outranks the `model` field — and managed policy can outrank both

**Principle.** Model selection precedence runs roughly: default -> `model` field (user, then project, then local settings) -> `env` blocks inside settings -> the shell `ANTHROPIC_MODEL` variable -> the `--model` flag, with **managed/policy settings able to enforce an available-model set above the project's `model` field** when `enforceAvailableModels` is on. *(Verify the exact ordering in your Claude Code version — managed enforcement is relatively new.)*

**Why it matters.** This cuts both ways. It is *why* pinning a model via a local `env.ANTHROPIC_MODEL` works when a managed `model` field disagrees — and it is also why that pin is **fragile**: if the platform later turns on `enforceAvailableModels`, a managed policy push can reclaim the model and the local override silently reverts, with no error. You keep answering — and billing — on a different model than you think.

**How to apply.** When you pin a model against a managed default, treat it as provisional: record *why* (so a later session does not undo it), and re-verify the *effective* model after any managed-settings refresh — read it from `/status` or the session header, not from the settings file you wrote. If the platform owns the policy layer, the durable fix is a policy change, not a local override racing it.

### H2. On Bedrock/Vertex, the `[1m]` context suffix is stripped before the request — verify it actually engaged

**Principle.** The `[1m]` suffix on a model id (e.g. `...claude-opus-4-8[1m]`) selects the 1M-token context window and is **standard-priced** — no per-token premium above 200K. But Claude Code **strips `[1m]` before sending the model id to Bedrock/Vertex/Foundry**, and the suffix applies *per variable* — so 1M only truly engages if the provider deployment supports it and every relevant variable carries the suffix. *(Verify in your version and provider.)*

**Why it matters.** A config string that reads `...opus-4-8[1m]` *looks* like 1M context, but on a gateway whose deployment caps at 200K you silently get 200K — the suffix is cosmetic and the documented intent ("we run 1M") is untrue with no error. Separately, while the *rate* is not premium, 1M lets a session *accumulate* far more billed input tokens per turn, so an unintended `[1m]` still inflates cost by volume.

**How to apply.** Do not trust the suffix in the config string — verify the *effective* context window against the running version and provider. Reconcile the model string with the documented cost/context target; if the target is 200K, drop the suffix rather than relying on it being stripped.

### H3. `ANTHROPIC_SMALL_FAST_MODEL` is deprecated and runs independently of fast-mode

**Principle.** The background/utility model (summaries, titles) is set by `ANTHROPIC_SMALL_FAST_MODEL`, which is **deprecated in favor of `ANTHROPIC_DEFAULT_HAIKU_MODEL`**, and it is used **independently of `CLAUDE_CODE_DISABLE_FAST_MODE`** — disabling interactive fast mode does **not** stop the background model from being invoked. *(Verify the current variable name in your version.)*

**Why it matters.** Two silent costs: a setup that put a heavier or *stale* snapshot (e.g. an old mid-tier model) in that slot keeps paying for it on every background task even with fast mode "off"; and a deprecated variable may stop being honored in a future version, reverting background work to a default without warning.

**How to apply.** Use the current variable name, put a genuinely small/cheap model in the background slot, and do not assume `CLAUDE_CODE_DISABLE_FAST_MODE=1` zeroes background-model usage — it does not.

---

## I. Output-compression hooks must never swallow an error

A `PostToolUse` hook on `Bash` that compresses command output to save context is a legitimate, useful pattern — but it sits on the path between a command's real output and what the agent sees, so a bug in it can hide failure.

### I1. The risk is the "critical line" detector, not the truncation

**Principle.** A compressing hook is safe only if it **never drops an error, warning, stacktrace, or test/build failure** — the contract must be: preserve every critical line, mark any elision explicitly with a count, and on *any* uncertainty (or its own exception) pass the original output through untouched. The danger is not the truncation logic; it is the **pattern that decides what counts as "critical."** A failure marker the pattern does not recognize — `BUILD FAILURE` from one build tool, `FAILED` from one test runner, a non-English or custom error string — gets compressed away.

**Why it matters.** If the hook eats the one line that said the build failed, a failed command looks clean and the agent proceeds on a *false green* — the most expensive kind of silent failure, because every downstream step inherits the wrong premise. A token-saving optimization must never be able to turn a red result green.

**How to apply.** Test the critical-line detector against **real** failure outputs from the actual toolchain (build, test, lint, deploy), not synthetic happy-path samples — this is the highest-leverage check in the whole hook. Default to passing the original through whenever the detector is unsure, and gate the hook so a below-threshold or error case is a no-op. This mirrors the proof-harness lesson that *a green check is only as trustworthy as the thing that decides "green"* — see `docs/field-notes-verification-and-agentic-harness.md` (sections A1 and A5).

---

## What the lens already carries (cross-reference, don't duplicate)

| This note's theme | Already in the repo | Path |
|---|---|---|
| Settings/secrets precedence; `allowed-tools` is pre-approval, not restriction; secrets out of committed files | `agent-skills` lens — "Settings, Permissions & Secrets" | `lenses/agent-skills.md` |
| `settings.local.json` gitignored; reproducibility / devcontainer persistence | `agent-skills` lens — "Devcontainer Persistence" | `lenses/agent-skills.md` |
| Version-dependent features are *verify in your version*, never assumed | `agent-skills` lens — "Verify Against Current Docs" | `lenses/agent-skills.md` |
| A green check is only as good as the thing deciding "green" | verification field notes — A1 / A5 | `docs/field-notes-verification-and-agentic-harness.md` |

**What is genuinely new here** (candidate seeds, none currently in the lens):

- the **deny-list-is-not-a-boundary** cluster — per-tool deny granularity; directory-glob sibling gaps; command-deny is not egress containment; cosmetic destructive denies;
- the **model/env silent-revert** cluster — env outranks the `model` field while managed `enforceAvailableModels` can reclaim it; provider stripping of `[1m]`; deprecated `ANTHROPIC_SMALL_FAST_MODEL` running independently of fast-mode;
- the **output-compression-hook** safety rule — the critical-line detector is the real risk surface.

When a second real setup makes any of these recur, the natural promotion is a "Permissions Hardening & Model/Env Precedence" heuristic block inside `lenses/agent-skills.md`, consumed by `claude-setup-audit` — mirroring how the lens already feeds that skill.
