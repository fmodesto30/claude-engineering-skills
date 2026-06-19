# Model & Effort Economy Lens

Reusable judgment for operating Claude Code economically under a token or cost budget: when a model tier, a thinking-effort level, a wide context window, or a multi-agent fan-out earns its spend on a task — and when the same capability is over-provisioned ceremony on work a cheaper configuration would do correctly. The cost-side sibling of `agent-skills.md`: that lens asks whether a setup is *correct*; this one asks whether the way you are *running* it is *economical without sacrificing correctness*. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This lens has one consumer today and room for a second, used with opposite intents. **`effort-budget`** reads it **evaluatively and correctively** — it looks at how a session is currently provisioned (model tier, effort level, context-window size, how many subagents a fan-out would spawn) against the difficulty of the work in front of it, and surfaces a right-sizing nudge when capability and difficulty are mismatched in a way with a named cost consequence. A future generative consumer — a planner, or a `skill-author` choosing the tier up front — could read the *same* knowledge to start a task at the cheapest configuration that gets it right the first time, rather than correcting an over-provisioned session after the fact. That second consumer is a forward bet today; until it exists, a reviewer should treat the lens placement (versus folding this into `effort-budget`) as a deliberate choice, not an inherited default.

Knowledge lives in `lenses/` so each consumer supplies its own intent and the lens supplies the knowledge. A consuming skill loads it only when the work actually involves a provisioning choice with a cost consequence — a tier, an effort level, a window size, a fan-out — never just because a task is large or a session feels expensive.

This is a **meta** lens: its subject is how you operate Claude Code, not Java/Spring or any application domain, so it carries no domain examples. It keeps the same calibrated, consequence-first, restrained voice as the other lenses — and its most common correct outcome, on a well-matched session, is to say nothing.

## Purpose

This lens helps the reviewer judge whether the capability a session is spending — model tier, thinking effort, context-window size, multi-agent fan-out — is *matched to the difficulty of the task*, rather than maximal or minimal in the abstract. It separates provisioning that does concrete work (a top tier that earns its cost on a subtle bug, a wide window a task genuinely fills) from provisioning that burns budget by rote (the top tier on a rename, a 1M-token window on a single-file edit, a fan-out on a task one pass would finish). The default bias is toward the cheapest configuration that gets the task *right the first time* — not the cheapest per turn. It is equally a tool for restraint: confirming a hard task deserves the top tier, that a well-matched session needs no nudge, and that the user's explicit high-tier choice is theirs to make.

## When to Use

Consult this lens when the work involves a Claude Code provisioning choice with a cost consequence, including:

- Deciding which model tier or thinking-effort level to run a task at, or noticing a running session is provisioned far above (or below) the difficulty of its work.
- Setting or reviewing a context-window size — especially a wide window (a 1M-token window bills far more input per turn than the default ~200K) on work that does not fill it.
- Planning or launching a multi-agent fan-out (a workflow, a parallel-subagent run, a deep multi-agent review) where N subagents means roughly N times the spend.
- Watching a session re-read files it just wrote, re-derive what it already concluded, over-ask the human on routine decision-forks, or pad output with ceremony.
- Choosing whether a piece of work earns the top tier at all, or whether a mid or cheap configuration would get it right the first time.

Do NOT engage this lens merely because a task is large, a session has run a while, or a token counter is climbing. The trigger is a *provisioning choice with a nameable cost consequence* — a tier, window, or fan-out that does not earn its multiplier, or a too-cheap configuration about to get a hard task wrong — not the mere presence of spend. A budget is never a reason to downgrade genuinely hard work.

## Core Principle

Model tier, thinking effort, context-window size, and multi-agent fan-out are *cost levers*, each of which multiplies spend; capability is a tool, not an objective. A session is well-provisioned when its capability is matched to the difficulty of the task, and the match is specific and verifiable:

- **The top tier earns its multiplier** — the highest model tier and effort go to work that genuinely needs them (subtle correctness or concurrency reasoning, novel design, ambiguous requirements, security reasoning, cross-cutting change with hidden coupling), not mechanical work a mid tier gets right.
- **The window fits the work** — a wide (1M-token) window is used only when the task needs that much input in view at once; the default (~200K) window is the cheaper baseline.
- **Fan-out is proportional to the work** — subagents are spawned because the work genuinely parallelizes or needs independent passes, not because fan-out is available; N subagents is roughly N times the spend.
- **Capability is not wasted on what does not need it** — re-reading a just-written file, re-deriving a settled conclusion, asking the human a decision the agent could make, and padding output all spend capability on nothing.
- **Cheap capability is not applied to genuinely hard work** — a cheap/fast model or low effort on a hard problem produces a wrong or incomplete answer whose redo costs more than the right tier once, and erodes trust; false economy is as real a cost as overspend.

The objective is to **minimize total cost-to-correct, not per-turn cost.** Right-sizing sits between two failures: **overspend** (top tier on trivia, a wide window on a one-file edit, a fan-out one pass would finish) and **false economy** (a cheap configuration on hard work, where the redo costs more than the right tier once). **Never downgrade genuinely hard work to hit a budget** — the redo is the expensive path. And when a task genuinely needs the top tier but the budget cannot cover it, that is not a provisioning *finding* — it is a conflict to surface (cut scope, split the work, or raise the budget), never a reason to silently downgrade. The most common correct outcome on a well-matched session is restraint: **"No comment" is valid and frequent**, and the user's explicit high-tier choice is theirs, not a finding.

## Severity Calibration

Apply these four levels (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md) for shared definitions). Note the asymmetry from the other lenses: a `MUST` is reserved for *false economy* — the genuinely costly failure — while overspend on trivia is a `SHOULD`-or-softer nudge the user may decline:

- **MUST** — A provisioning choice that will produce a *wrong or incomplete result* with a concrete downstream cost: a cheap/fast model or a low effort level on genuinely hard work (subtle correctness/concurrency reasoning, security reasoning, a cross-cutting refactor with hidden coupling) where the likely-wrong answer carries a real cost — a redo, a missed bug, eroded trust — **whether or not a later gate happens to catch it** (the eroded trust and redo stand regardless). Also: an output-compression step on the path whose detector could drop an error line and turn a red result green (cross-reference `docs/field-notes-claude-code-config-hardening.md` section I). Name the failure mode and the cost of being wrong.
- **SHOULD** — The session works but is provisioned above its task and a right-sized configuration measurably saves: the top tier on well-specified mechanical work a mid tier handles correctly; a 1M-token window on a task that fits the default ~200K; a fan-out where the work does not parallelize; high effort on pure retrieval. Surface it as **one** nudge — current configuration, recommended configuration, reason, concrete saving — then let the user decide.
- **NIT** — A small economy with no real consequence either way: a slightly-higher-than-needed effort on a short task, a re-read costing a few hundred tokens. A brief note at most, usually better left as NO_COMMENT.
- **NO_COMMENT** — The session is well-matched, or the user made an explicit high-tier choice. Stay silent. This is the most common outcome on a well-matched session, and re-litigating an already-right configuration is itself waste.

**Overriding rule:** every finding names a concrete cost consequence — a wrong answer redone, a window or fan-out multiplier paid for nothing, capability spent on re-derivation or ceremony. "This could be cheaper" / "fan-out is expensive" is **not** a finding. "This is a rename on the top tier; a mid tier at medium effort does renames correctly for a fraction — drop the tier for this task" **is**, and so is "this is subtle concurrency reasoning on a fast model; the likely-wrong answer costs more to redo than the right tier once — raise the tier." If no concrete consequence can be articulated, it is NO_COMMENT, however expensive the configuration looks.

## Review Questions

Before raising or accepting a provisioning decision, the reviewer should be able to answer:

- What is the *difficulty* of this task — genuine reasoning (subtle correctness, novel design, ambiguity, security, hidden coupling) or mechanical/well-specified/retrieval — and does the tier and effort match it? Is the difficulty judged by the *hidden correctness surface*, not the task's surface label?
- Does the context-window size match the input the task needs in view, or is a wide (1M) window billing more per turn than a task that fits the default ~200K?
- Does this fan-out parallelize real, independent work, or pay roughly N times for what one strong pass would finish?
- If provisioned *above* the task: what is the one concrete nudge (current → recommended, reason, saving), and is the user left free to decide?
- If provisioned *below* the task: would the cheaper configuration produce a wrong/incomplete answer whose redo costs more than the right tier once? (If so, do not downgrade — raise it.)
- Is capability being spent on nothing — re-reading a just-written file, re-deriving a settled conclusion, asking a decision the agent could make, padding output?
- Can the session see its own spend — a session total and, if possible, per-turn — and under a stated budget is consumption read against the cap rather than guessed?
- Is this the user's explicit high-tier choice? (If so, NO_COMMENT.)
- What Claude Code version and provider is this, and do the model names, effort-level names, window sizes, and fan-out features this judgment relies on exist and behave as assumed?

## Heuristics

### Make the Spend Visible — you cannot right-size what you cannot see

**What to look for:** Whether the operator — and the agent — can actually see what a session is spending, per session and ideally per turn. Right-sizing is blind without a number to anchor it. Watch for a session running under a stated budget with no visibility into consumption, or an agent asserting "this is cheaper" with no measurement behind it.

**Why it matters:** A budget with no meter is a guess. Under a hard per-user cap, the difference between "there is headroom" and "the budget is about to run out" is a number the session can read — and without it, every right-sizing call is uncalibrated and overspend is discovered only when the budget is already gone, mid-task. Visibility is what turns the rest of this lens from intuition into a decision.

**When NOT to comment:** When the operator already has the spend in view (a usage command, a status line, a parsing tool, or telemetry) and is using it, say nothing — the meter is doing its job. Do not demand a heavyweight monitoring stack for a session with no budget pressure.

**Correct form (Claude Code idiom):** Surface the spend with the cheapest mechanism that fits. Claude Code exposes session totals through a usage command (`/usage`, and/or `/cost` — *verify the command name in your version*: a cost estimate, duration, and a token breakdown by attribution) and context-window pressure through `/context`. Per-turn granularity is not a built-in command — it comes from the local session transcript (a JSONL file under the per-project session directory that records per-message token usage), parsed directly or with a community accounting tool (for example `ccusage`); *the transcript schema is not officially documented, so verify the fields in your version*. Where telemetry is permitted, Claude Code emits per-request token and cost metrics over OpenTelemetry (`claude_code.token.usage`, `claude_code.cost.usage`) for a real dashboard — but with telemetry disabled those exports are gone, while the usage command, `/context`, and local transcript parsing still work offline. Pick the lightest mechanism that gives the operator a number; do not stand up a metrics backend a single budgeted session does not need.

**Key review questions:** Can this session see its own spend (a usage command, a transcript parse, a status line, telemetry)? Under a stated budget, is consumption being read against the cap, or only guessed? Is the chosen visibility mechanism proportionate to the need?

**Example finding:** "SHOULD: this session runs under a fixed per-user budget but nothing surfaces consumption, so every right-sizing call is uncalibrated and an overrun would only be noticed once the budget is spent. Check the session total with the usage command and per-turn cost from the local transcript (or a tool like `ccusage`) so the budget has a meter — verify the command name and transcript fields in your version."

### Right-Sizing Capability to Task Difficulty

**What to look for:** Whether model tier and effort match the *difficulty* of the task. The top tier and high effort EARN their multiplier on subtle correctness or concurrency bugs, novel design, ambiguous requirements, security reasoning, and cross-cutting refactors with hidden coupling. A MID model at medium effort handles well-specified mechanical edits, renames, formatting, doc tweaks, straightforward CRUD, following an established pattern, and localized single-file changes — **but only when the correctness surface is genuinely shallow.** A CHEAP/fast model does pure retrieval, locate/grep, summarize, compress. The signal of a problem is a clear mismatch in either direction.

**Why it matters:** This lever multiplies every turn. The top tier on a rename pays for capability the task cannot use. But the symmetric failure is worse: a cheap model on a genuinely hard problem produces a wrong answer whose redo costs more than the right tier once, and trust erodes. Right-sizing minimizes *total cost-to-correct* — so cheap-on-hard is the expensive mistake, not the safe one. The trap is judging difficulty by the task's *surface label*: a "straightforward CRUD" endpoint that must be idempotent under retry, or an "established pattern" copied into a different concurrency or transactional context, hides a hard correctness surface and earns the top tier despite the easy label.

**When NOT to comment:** When the tier already matches the task — a hard problem on the top tier, a genuinely shallow mechanical edit on a mid tier — say nothing. Never nudge a hard task *down* to hit a budget. When the user explicitly chose the top tier, it is their call — NO_COMMENT.

**Correct form (Claude Code idiom):** Match capability to difficulty, judging difficulty by the hidden correctness surface, not the surface label. When difficulty is genuinely unknown, prefer one strong pass at the tier the *hardest plausible* reading needs over a cheap pass that may be redone. *Verify the model-tier names, the effort-level names (e.g. xhigh/high/medium/low), and which are available in your Claude Code version* before relying on a specific one; do not hardcode a model name from memory.

**Key review questions:** Is this reasoning-heavy or mechanical/retrieval, and does the tier match? Does an easy-looking task hide an idempotency, concurrency, transactional, or security surface that makes it hard? If below the task, would the cheaper run produce a wrong answer redone for more than the right tier costs once?

**Example finding:** "SHOULD: this is a mechanical rename across a few files on the top tier at high effort, with a shallow correctness surface. A mid tier at medium effort does renames correctly for a fraction of the multiplier — recommend dropping the tier for this task. (If the top tier was deliberate, ignore this.)"

### Context-Window Size

**What to look for:** Whether the context-window size matches the input the task needs in view. The signal of a problem is a wide (1M-token) window on work that fits comfortably in the default (~200K) — a single-file change, a localized edit, a short task — where the extra capacity is paid for but never used.

**Why it matters:** Window size is a per-turn input lever. A wide window lets a session accumulate and re-send far more billed input per turn; the extra cost is a combination of larger billed input volume and, depending on version and provider, possibly a different rate above the standard window. (Prompt caching can make re-sent prefix tokens cheaper, so the exact cost shape varies — which is why it must be verified, not assumed.) Either way, an unneeded wide window inflates cost across the whole session, silently, because nothing flags that the window exceeds the task.

**When NOT to comment:** When the task genuinely needs the wide window — a large cross-cutting change that must hold many files in view, a long synthesis over a large corpus — the wide window earns its cost; say nothing. Do not push a task that legitimately fills the window down to the default and force it to thrash.

**Correct form (Claude Code idiom):** Default to the standard (~200K) window; reach for a wide (1M) window only when the task needs that much input in view at once. *Verify the available window sizes, the default, how a wide window is selected and billed, and whether the provider deployment supports it in your Claude Code version and provider* — and confirm a configured wide window actually engaged rather than being silently capped.

**Key review questions:** Does this task need 1M tokens of input in view, or does it fit the default ~200K? Is a wide window billing extra per turn for capacity the task never uses — and did the configured window even engage?

**Example finding:** "SHOULD: this session runs a 1M-token window for a single-file change that fits well inside the default ~200K. The wide window bills more input every turn for capacity this task never uses — recommend the default window here and reserving the wide one for changes that must hold many files in view at once. Verify the configured window actually engaged in your version/provider."

### Multi-Agent Fan-Out

**What to look for:** Whether a multi-agent fan-out — a workflow that spawns subagents, a parallel-subagent run, a deep multi-agent review — is proportional to the work. Spawning N subagents is roughly N times the spend. The signal of a problem is a fan-out on work that does not parallelize: serial work split into subagents that mostly duplicate each other, or a deep review of a small, low-risk change one pass would cover.

**Why it matters:** Fan-out is the largest single multiplier available — it multiplies the whole per-agent cost by N at once. On work that genuinely parallelizes (independent files, independent questions, independent verification passes) that buys real speed or coverage and earns the spend. On serial or trivial work, N subagents pay N times for what one strong pass would finish, often producing overlapping output someone must then reconcile — paying more to get *more to sort through*, not more signal.

**When NOT to comment:** When the work genuinely parallelizes, or a high-stakes change warrants independent verification passes, the fan-out earns its multiplier; say nothing. A deliberate deep multi-agent review of a genuinely risky change is the right tool, not waste.

**Correct form (Claude Code idiom):** Fan out only when the work decomposes into independent pieces or genuinely benefits from independent passes; otherwise prefer one strong pass. Size the fan-out to the number of *independent* pieces, not the maximum available. Reserve deep multi-agent review for changes whose risk justifies N times the cost. *Verify the fan-out mechanism, its default and maximum subagent count, and the per-subagent cost model in your Claude Code version* before sizing a fan-out.

**Key review questions:** Does this work decompose into N independent pieces, or is it serial work split for no parallel benefit? Does the risk of this change justify N times the cost of a single pass?

**Example finding:** "SHOULD: this launches a multi-agent fan-out for a small, localized, low-risk change. The work is serial and does not parallelize, so the fan-out pays roughly N times for what one pass would finish and produces overlapping output to reconcile. Recommend a single pass here and reserving fan-out for work that decomposes into independent pieces or warrants independent verification."

### Token-Economy Techniques That Cost No Quality

**What to look for:** Whether the session is leaving free economy on the table — savings that do not touch quality: **progressive disclosure** (load detail on demand); **delegate compressible or mechanical work to a cheap subagent and keep only the conclusion** (the compressed-subagent / "caveman" pattern — the expensive context decides, a cheap agent does the legwork and returns a distilled result); **do not re-read a file you just wrote**; **route routine decision-forks to a judgment you can make instead of asking the human**; **prefer one strong pass over many weak iterations**; **stop when the slice is genuinely done.** The signal of a missed economy is the opposite of any of these.

One technique in this family is **conditional, not free**: compressing noisy tool output with a hook. It is free economy *only if* its critical-line detector is proven against real failure output and passes the original through on any uncertainty; otherwise it is the single item here that can silently turn a red result green — the most expensive failure, not a saving (cross-reference `docs/field-notes-claude-code-config-hardening.md` section I).

**Why it matters:** The unconditional techniques reduce spend without reducing correctness, so leaving them on the table is pure waste — re-reading a just-written file re-pays for input already in context; doing compressible legwork at full tier spends reasoning on mechanical work; many weak iterations cost more *and* often converge worse than one strong pass; over-asking spends a round-trip and the operator's attention on a decision the agent could make. None of these trades quality for cost.

**When NOT to comment:** When the session is already lean — disclosing progressively, delegating legwork, not re-reading, deciding routine forks itself, stopping when done — say nothing. Do not push delegation or progressive disclosure as ceremony onto a short task that does not need it; they earn their place when there is real legwork or real context to defer.

**Correct form (Claude Code idiom):** Load detail on demand; hand compressible legwork to a cheap subagent and keep only its conclusion; trust a file you just wrote; resolve routine forks with the judgment you have; prefer one strong pass; stop when the slice is done. Use an output-compression hook only with a detector proven to never drop an error/warning/failure line. *Verify the subagent-delegation and hook mechanisms in your Claude Code version.*

**Key review questions:** Is compressible legwork being done at full tier instead of delegated and distilled? Is the session re-reading what it just wrote or re-deriving what it concluded? Is a human asked a decision the agent could make? Does any output-compression hook risk dropping an error line?

**Example finding:** "SHOULD: this session re-reads three files immediately after writing them and re-derives a conclusion it reached two turns ago. The re-reads re-pay for input already in context and the re-derivation spends reasoning on a settled result — trust the writes and the prior conclusion. (Free economy — no quality traded.)"

### Restraint — Cut Redundancy, Never the Reasoning

**What to look for:** What is being cut, or proposed to be cut, for economy. The thing to cut is *redundancy* — re-derivation, ceremony, needless questions, padding. The thing to **never** cut is the reasoning and explanation the user needs to follow the work and trust the result. The signal of a problem is economy aimed at the wrong target: a terse, unexplained answer on a decision the user needs to understand; a hard task quietly downgraded; a verification step skipped to save tokens.

**Why it matters:** Economy aimed at the wrong target is a false saving. A clear explanation the user needs is not overhead — cutting it forces a follow-up round-trip (costing more than it saved) or leaves the user acting on a result they cannot evaluate. The same goes for downgrading hard work or skipping verification to hit a budget: the redo and lost trust cost more than the tokens.

**When NOT to comment:** When the session is already concise but complete — terse on the routine, full on the load-bearing — say nothing. Do not push for *more* verbosity as a goal; clarity is the target, not length.

**Correct form (Claude Code idiom):** Cut redundancy, ceremony, re-derivation, and needless questions; keep every piece of reasoning the user needs. When a budget is tight, find savings in the free techniques above and in right-sizing — never in downgrading hard work, skipping verification, or withholding the explanation the user needs. And remember that **not nagging a well-matched session is itself the correct, economical outcome most of the time.**

**Key review questions:** Is the economy here cutting redundancy and ceremony, or cutting reasoning the user actually needs? Is a hard task being downgraded, or verification skipped, where the redo costs more than the saving?

**Example finding:** "MUST: this drops to a fast model for subtle concurrency reasoning to stay under budget. The likely-wrong answer costs more to redo than the right tier once and trust erodes — do not downgrade genuinely hard work for budget; raise the tier here and find the savings in right-sizing the mechanical tasks instead."

## Anti-Patterns

- **Flying blind under a budget** — *Setup:* a session running under a hard token or cost cap with no visibility into its own consumption — no usage command checked, no transcript parse, no telemetry. *Harm:* right-sizing is uncalibrated guesswork and an overrun is discovered only when the budget is already gone, mid-task. *Fix:* surface the spend with the lightest mechanism that fits — a usage command for the session total, `/context` for window pressure, local transcript parsing (or a tool like `ccusage`) for per-turn — and read it against the cap. (Verify command names and transcript fields in your version.)

- **Top tier on trivia** — *Setup:* the highest tier and effort on a rename, a formatting pass, a doc tweak, or pure retrieval. *Harm:* a large per-turn multiplier paid for capability the task cannot use. *Fix:* drop to a mid tier at medium effort for shallow mechanical work, or a cheap/fast model for retrieval; surface one nudge and let the user decide.

- **False economy on hard work** — *Setup:* a cheap/fast model or low effort on subtle correctness/concurrency reasoning, novel design, security reasoning, or a cross-cutting refactor with hidden coupling. *Harm:* a wrong or incomplete answer whose redo costs more than the right tier once and erodes trust — the expensive failure, whether or not a later gate catches it. *Fix:* raise the tier/effort to match difficulty; never downgrade hard work to hit a budget.

- **Difficulty judged by the surface label** — *Setup:* "straightforward CRUD" or "follow the existing pattern" downgraded to a cheap tier on appearance, when the task hides idempotency, concurrency, transactional, or security concerns. *Harm:* the hidden hard edge gets a wrong answer — false economy wearing an easy label. *Fix:* judge difficulty by the hidden correctness surface; if a CRUD or pattern-follow task carries those concerns, it is reasoning-heavy and earns the top tier.

- **Wide window on small work** — *Setup:* a 1M-token window on a single-file or localized change that fits the default ~200K. *Harm:* more billed input every turn for capacity the task never uses, compounding across the session, silently. *Fix:* use the default window; reserve the wide one for work that must hold many files in view. Verify the configured window actually engaged.

- **Fan-out on serial work** — *Setup:* a multi-agent or deep-review fan-out on serial, single-threaded, or low-risk work that does not parallelize. *Harm:* roughly N times the spend for what one pass would finish, plus overlapping output to reconcile. *Fix:* one strong pass; reserve fan-out for work that decomposes into independent pieces or whose risk warrants independent verification.

- **Re-reading and re-deriving** — *Setup:* re-reading a just-written file or re-deriving a settled conclusion within a session. *Harm:* re-pays for input already in context and spends reasoning on a settled result. *Fix:* trust the writes and the prior conclusion; load detail on demand.

- **Over-asking the human** — *Setup:* pinging the operator for a routine decision-fork the agent could make. *Harm:* spends a round-trip and the operator's attention, and trains the operator to babysit. *Fix:* resolve routine forks with the judgment you have; escalate only genuine ambiguity of scope or intent.

- **Output-compression that can hide an error** — *Setup:* a hook whose critical-line detector can drop an error/warning/failure line. *Harm:* a failed command looks clean and the agent proceeds on a false green — the most expensive silent failure. *Fix:* the detector must preserve every critical line and pass the original through on any uncertainty (cross-reference `docs/field-notes-claude-code-config-hardening.md` section I).

- **Cutting the reasoning instead of the redundancy** — *Setup:* a terse answer on a decision the user needs to understand, or a hard task downgraded / verification skipped to save tokens. *Harm:* forces a costlier follow-up, or leaves the user acting on a result they cannot evaluate. *Fix:* cut redundancy and ceremony — never the explanation and verification the user needs.

- **Nagging a well-matched session** — *Setup:* re-litigating an already-right configuration, or second-guessing the user's explicit high-tier choice. *Harm:* the nudge itself is waste, and overriding a deliberate choice erodes trust. *Fix:* when capability matches the task, or the user chose deliberately, say nothing — NO_COMMENT is the economical outcome.

## Verify Against Current Docs

Claude Code evolves, and the cost levers below are version- and provider-dependent. **Inspect the actual version, provider, and session configuration; never assume.** Frame every version-specific claim as *verify in your Claude Code version*:

- **Model-tier names and ordering** — the specific model names and their relative cost/capability tiers change across releases. Confirm which exist and how they are named; do not hardcode a model name from memory.
- **Effort-level names** — the thinking/effort levels (e.g. xhigh/high/medium/low) and which a model or command exposes are version-dependent.
- **Context-window sizes and billing** — the default (~200K) and wide (1M) sizes, how a wide window is selected, whether the provider deployment supports it, and how it is billed (including whether prompt caching or a premium tier applies) are all version- and provider-dependent. A configured wide window can be silently capped — verify the *effective* window engaged, not the configured string.
- **Multi-agent fan-out** — whether and how a workflow, parallel subagents, or a deep multi-agent review are available, their default and maximum subagent counts, and the per-subagent cost model are version-dependent.
- **Background/utility model** — the model used for background work runs independently of interactive settings and its variable names change across versions; confirm the current configuration and cost before assuming it is cheap or disabled.
- **Usage and cost visibility** — the usage command name and output (`/usage` and/or `/cost`), `/context`, the local session-transcript location and schema, and the OpenTelemetry metric names are all version-dependent, and the transcript schema is not officially documented. Verify them in your version before relying on a specific command or field; with telemetry disabled the OTEL exports are unavailable while the usage command, `/context`, and local transcript parsing still work.
- **Delegation and hook mechanisms** — subagent delegation and output-compression hooks are documented, but verify they are available and behave as expected before depending on them.

When the running version, provider, or effective configuration disagrees with an assumption, the running configuration wins — inspect it.

## Suggested Comment Style

Lead with the concrete cost consequence — a wrong answer redone, a window or fan-out multiplier paid for nothing — not with "this could be cheaper." When provisioned above the task, surface **one** nudge (current → recommended, reason, concrete saving) and leave the decision to the user; do not re-litigate every task. State severity honestly — the false-economy `MUST` and the overspend `SHOULD` read differently on purpose. Frame version-specific claims as something to verify in the running version. When the session is well-matched, or the user chose the tier deliberately, say nothing.

Example comments (meta subject, no domain):

- "SHOULD: top tier at high effort on a rename with a shallow correctness surface. A mid tier at medium effort does renames correctly for a fraction — recommend dropping the tier for this task. (If deliberate, ignore.)"
- "MUST: a fast model is assigned to subtle concurrency reasoning to stay under budget. The wrong answer costs more to redo than the right tier once and trust erodes — raise the tier; never downgrade hard work for budget."
- "SHOULD: a 1M-token window is open for a localized single-file change that fits the default ~200K, billing extra input every turn — recommend the default window. Verify it actually engaged in your version."
- "If the tier already matches the task and you chose it deliberately, this needs no nudge — I'd leave it as is."

## Integration (effort-budget)

The consuming skill uses this lens as a judgment aid for right-sizing a real session, not a budget to impose:

- **Never comment because a session *could* be cheaper.** A higher-than-minimal tier, a wide window, or a fan-out is a finding only when you can name the concrete cost consequence.
- **Surface one nudge, then let the user decide.** Do not re-litigate every task or treat the nudge as a blocker.
- **The user's explicit high-tier choice is NO_COMMENT.**
- **Never downgrade genuinely hard work to hit a budget** — the false-economy `MUST` exists to stop this. When the budget cannot cover genuinely-needed capability, surface the conflict (cut scope, split, raise the budget); do not silently downgrade.
- **Always tag findings** `MUST` / `SHOULD` / `NIT` per [`../rules/severity-rubric.md`](../rules/severity-rubric.md), with this lens's asymmetry (false economy is the `MUST`; overspend is a `SHOULD`-or-softer nudge). NO_COMMENT is the silent fourth outcome and, on a well-matched session, the most common.
- **Inspect the actual session and version.** Confirm the effective tier, effort, window, and fan-out cost in the running version and provider, not from the configuration string.
- **Cut redundancy, never the reasoning.** The economy this lens seeks is in right-sizing and the free techniques — never in withholding the explanation or verification the user needs.
