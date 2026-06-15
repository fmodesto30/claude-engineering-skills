# Field Notes — Engineering and Agentic Practices for Generation-and-Verification Systems

> **Source and scope.** These notes distill the reusable, domain-neutral engineering and agentic practices observed in *a real generation-and-verification project* — a long-running, mostly-autonomous system that generated a complex structured artifact from a declarative input and then had to *prove* the artifact was faithful. Everything proprietary has been stripped: there are no project, company, client, tool, format, or file names from the source, no real identifiers, and no secrets. The practices are stated generically so they transfer to any system where an agent (or a pipeline) produces something and a harness must decide whether to trust it.
>
> **Status.** Field notes, not a lens or a skill. They are written to *seed* future lenses and skills (e.g. a `proof-harness` lens, a `decision-oracle` lens, an `agentic-os` lens) once a real consumer needs them. Where this repo already carries a practice, the note cross-references it by path rather than restating it.
>
> **Voice.** Same as the lenses: consequence-first, severity-honest, biased toward restraint. A practice earns its place only when a concrete failure mode can be named. "You don't need this" is a frequent and correct conclusion for a small system.

---

## How to read these notes

Each entry below follows the same shape the lenses use: **Principle → Why it matters (the failure it prevents) → How to apply it generically**. The six themes are:

- **A. The proof harness** — make "the output is correct" provable, not asserted.
- **B. Behavioral eval** — prove the system *behaves*, not that files exist. *(This repo already does this.)*
- **C. The decision oracle / delegated autonomy** — route real decisions to an automated gate; reserve the human for the one irreducibly-human judgment.
- **D. The agentic operating system** — constitution, tiered memory, numbered lessons, autonomy states, skills, specs, evals.
- **E. Artifact discipline** — scratch versus promoted canonical.
- **F. Multi-agent coordination** — isolation, async handoff, liveness.

A short cross-reference map of what already lives in this repo is at the end.

---

## A. The proof harness

The central problem of any generation system is that a plausible-looking output can be wrong, and the cheapest signals (the code ran, the file exists, the unit tests are green) say *nothing* about whether the output is faithful to its source. The harness is the set of layers that turn faithfulness from an assertion into a provable claim.

### A1. Green tests are not proof of correctness

**Principle.** A passing automated check proves only what that check measures. "The builder code did not regress" and "the structural integrity booleans are all true" are *orthogonal axes* to "the artifact is faithful to its source." State each layer's blind spot in writing.

**Why it matters.** In the source project, a full set of machine-readable integrity booleans was all-green while a human suspected a real regression in the output; the only way to dismiss the suspicion was to rebuild from scratch and compare counts before/after. A green check that is mistaken for proof is worse than no check — it actively reassures the next reader that something unverified is fine.

**How to apply.** Layer your verification by what each layer actually proves, and document the blind spot of each layer next to it:
- *Layer 1 — contract/unit tests:* the producing code didn't regress. (Blind to: whether the produced artifact matches intent.)
- *Layer 2 — structural self-checks:* the artifact's internal structure is well-formed (a machine-readable set of booleans on the output itself). (Blind to: whether the structure is in the *right place* / means the right thing.)
- *Layer 3 — fidelity-vs-source judgment:* does the output match what it was supposed to represent. (This is the only layer that proves faithfulness, and — see C — it is often the one you must not automate.)

Write the law down literally: *a green Layer-1/Layer-2 result is not visual/semantic proof.* Make each layer's doc state, in one sentence, what it does **not** measure.

### A2. Deterministic gates for the objective part

**Principle.** Everything that is objectively checkable should be a pure, deterministic detector that runs cheaply (no network, no heavy build, no rendering) and is itself unit-testable on synthetic inputs. Aggregate many small detectors into **one runnable suite that emits one verdict** with meaningful exit codes.

**Why it matters.** Cheap deterministic detectors catch a whole class of defects that a confident rendering masks. In the source project, detectors found that most generated openings were attached to the *wrong* host element and one element was duplicated — yet the rendered preview "passed," because the rendering path happened not to depend on the corrupted field and the duplicate dissolved on merge. The render gave a **false pass** over rotten data.

**How to apply.**
- Make detectors pure functions over the declarative input where possible; lock the detection contract with unit tests on synthetic good/bad inputs *before* wiring in any empirical calibration.
- Aggregate into a single command that returns distinct exit codes: `PASS=0`, `FAIL=1`, `INCOMPLETE=…` (see A5). Have CI gate on the **exit code**, never on log text — a "loud warning" printed to stdout still exits 0 and ships unverified.
- **Run the cheap deterministic detectors before trusting any rendered/derived/expensive view.** A plausible render can hide a corrupt model.

### A3. An oracle/judge for the subjective part — and distrust it

**Principle.** For the part that is irreducibly subjective (aesthetics, "does this *look* right," fitness-for-intent), you may consult a model-based judge — but treat its verdict as **advisory only**. Combine it with the objective checks via a **worst-of aggregation**: `final = worst(judge, deterministic, known_warnings)`. A judge PASS can never override a deterministic FAIL or a documented known issue.

**Why it matters.** In the source project the model-based visual judge returned a *confident* PASS on an artifact from which a clearly-visible structural element had been deliberately erased — it even narrated that everything "appears correctly aligned." A judge that can't see an obvious defect cannot be the authority. Letting a soft judge overrule a hard finding is how broken output ships green.

**How to apply.**
- Keep the judge as a complement, never an authority. Route any judge-vs-deterministic *disagreement* to an explicit escalation path (consult again, or escalate to a human) rather than silently picking a side.
- A model consulting another instance of the **same model family is not an independent check** — it shares the asker's blind spots and biases toward agreement. The real independent ground truth is the deterministic detector, not a second model. If you still want self-critique, force an explicit *steelman-the-opposition* (red-team) mode on the highest-stakes calls rather than trusting a same-family "second opinion."

### A4. Negative dogfood — prove the gate catches a known-bad

**Principle.** A gate you have never seen fail is a gate you cannot trust. Prove the gate (especially a subjective judge) *discriminates* by injecting a **deterministic, reproducible, byte-stable** known-bad input and confirming the gate rates it strictly worse than the clean baseline.

**Why it matters.** This is how the false-PASS-on-erased-element was discovered in the first place. Two design lessons came out of it:
1. **The clean baseline must PASS first.** The first dogfood attempt was inconclusive because a degenerate single-input probe *saturated* the judge at FAIL even on the clean baseline — with no headroom, corruption couldn't make it "worse," and it even hallucinated findings about an input it was never given. A negative test with no headroom proves nothing.
2. **Mirror production inputs exactly,** corrupt only one of them, and pre-declare a *finding-level* secondary metric so a top-level verdict can't mask a localized real defect.

**How to apply.**
- Build a reproducible corruptor: identical inputs → identical output bytes; record before/after hashes.
- Pre-declare pass criteria: *clean baseline = PASS/WARN* **and** *corrupted = strictly worse (or a new localized finding)*.
- If the clean baseline itself saturates/fails, return a distinct `INCONCLUSIVE` status — **never fabricate a verdict.**

### A5. "Didn't run" is not "passed" — distinct status and exit code

**Principle.** A check that silently skips because a prerequisite was missing is the most dangerous failure mode: it ships unverified work wearing a green badge. Make "could not run" a distinct, non-green status (`INCOMPLETE`) with its own exit code, separate from both `PASS` and `FAIL`.

**Why it matters.** In the source project a key verification step auto-skipped because a required sidecar file was never copied during promotion — so the canonical artifact shipped "PASS" with that gate *never having executed*. Two fixes followed: (a) the sidecar is part of the **deliverable** (see E2), copied on every promotion; (b) the runner enforces by **exit code**, not by print — required input present but prerequisite missing yields `INCOMPLETE`. Collapsing `INCOMPLETE` into `FAIL` would cry wolf on tooling gaps; collapsing it into `PASS` hides real defects. Keeping them distinct preserves triage: `INCOMPLETE` means "regenerate the missing input," `FAIL` means "the output is actually wrong."

**How to apply.**
- Reserve exit codes the tooling already uses (e.g. usage-error codes) and pick a fresh one for `INCOMPLETE`.
- "No silent caps": any prerequisite the gate needs to run is part of the deliverable and travels with it.

### A6. Before/after regression against a known-good baseline — escape circular validation

**Principle.** Validate against an *independent* known-good baseline, never against the artifact's own output. Self-comparison is structurally blind to whole classes of omission — something missing from both sides can never be flagged.

**Why it matters.** A detector only catches the bug classes you already encoded. To catch a *missing* element you need a baseline that *has* it. In the source project this was stated as: if the expected reference is missing the same element the candidate is, the gate "inherits the blindness." The "No regenerated artifact + before/after comparison, no progress" rule grew directly out of a green-metrics-but-suspected-regression incident: every fidelity-affecting change must emit a fresh artifact plus a before/after comparison into a human-facing location as part of "done."

**How to apply.**
- Pin a known-good baseline and diff the current output against it (counts, structure, key invariants).
- Expect that **promoting a new baseline will break tests that pinned the old state** — that is correct, not a regression. Re-pin them to the new values *only after independently verifying the new state is sound* (re-derive an invariant, e.g. a conservation relation between element classes, before trusting any changed number). Keep capture/regression behavior on **synthetic** fixtures so promoting the real baseline doesn't erode coverage.

### A7. Calibrate from the data under test; carve out the unverifiable

**Principle.** Derive calibration constants (scale, conversion factors) from the data being verified — e.g. the median of observed measurements — rather than a hardcoded default; prefer an exact transform over a heuristic fallback and **record which path was used** so the verdict carries its own provenance. And build an explicit *"unverifiable, therefore not failing"* branch into every spatial/visual check.

**Why it matters.** A hardcoded unit/scale default silently produced out-of-proportion output until scale was anchored to a real, declared physical dimension. Separately, a fidelity check that reports clipped/out-of-frame regions as "missing" produces false positives and destroys trust; the fix was to skip samples that *cannot be judged* and tolerate legitimate gaps, keeping the false-positive rate low enough that people actually act on the gate.

**How to apply.**
- If a critical numeric constant has no real anchor in the input, **refuse/BLOCK** rather than guess (this is the "never fabricate" principle applied to a number — see D6).
- Tag the calibration path (`exact` vs `fallback`) in the output so a reader knows how much to trust it.
- Reserve hard FAILs for **categorical absurdities** (missing artifact, count mismatch, a confirmed structural defect); treat environment-sensitive signals (pixel-exact diffs across machines/drivers) as **human-review evidence**, not bit-exact gates; mark "asserted-but-unproven" as an advisory WARN, not a FAIL.

### A8. Pin known imperfections as a carried-forward baseline

**Principle.** Document accepted imperfections as an explicit baseline that the final verdict must always carry forward, so no later "pass" can silently erase a known caveat and "green" never overstates quality.

**Why it matters.** Some imperfections are honest and accepted (the source data genuinely doesn't support a feature). Without a pinned baseline, a future automated PASS quietly drops the documented WARN and the verdict overstates fidelity. Honest incompleteness is a first-class WARN state with a written justification — fabricating structure to hit a target metric is *worse* than an explained gap (see D6).

**How to apply.** Keep a small `known_warnings` list; the aggregator includes a *known-warnings verdict* in its worst-of so a documented WARN can never be overwritten by a fresh PASS.

---

## B. Behavioral eval — prove the system behaves, not that files exist

**Principle.** An eval must prove the system *does the thing it claims*, not that it produced output. Run the system **blind** on fixtures that each carry a *planted* problem plus an adversarial judge that checks the **behavior made visible in the artifact** — the reasoning, the refusals, the status it set — not the presence of a file.

**Why it matters.** "Emitted a polished output file" is the canonical false pass. The discriminating question is whether the system *detected the planted defect, refused to over-conclude, and set its own status correctly.* A pretty demo with no path back to the real target proves nothing.

**This repo already implements this.** Rather than restate it, see:
- `examples/reporting/EXPECTED.md` — the behavioral-eval contract: one fixture per *situation type* (sufficient / incomplete / duplicated / contradictory / discovery), each with explicit **MUST / MUST-NOT** behavior and a "REJECT the run if…" trigger. Its opening line — *"a run that merely emits a polished HTML file is a FAIL unless it also exhibits the MUST/MUST-NOT behavior"* — is exactly this principle.
- `rules/analysis-rigor.md` — the rigor **gate** the eval grades against (conclusions must point to verifiable evidence; insufficient data yields a LIMITED conclusion, never creative filling).

**Field-note additions from the source project** (generic, not yet captured in the repo's eval fixtures):
- **A green deterministic gate ≠ a good artifact.** A structural gate passing every check proves *legality*, not *quality*; keep the deterministic axis and the subjective axis separate and require both. Don't let a green gate convince you the work is done.
- **When iteration stalls and no parameter change helps, suspect the *observation path*, not the thing being tuned.** Multiple cycles were burned tuning the artifact when the real defect was in *how it was being viewed/measured* (an encoding/transform artifact in the preview). A measurement bug masquerades as a substance bug.
- **A contract bug can manufacture a systemic false signal.** A single wrong field in the artifact's contract produced a false warning on *every* instance; the fix was the contract, not the cases. When the eval surfaces uniform noise, suspect the shared contract.

---

## C. The decision oracle / delegated autonomy

A long-running agent hits genuine decision forks (which option, merge or not, accept a regenerated input). Blocking on a human in chat for each one stalls the agent until someone looks; the human becomes a copy/paste relay. The pattern is to route real decisions to an **automated decision endpoint** and reserve the human for the *one* judgment only a human can make.

### C1. Route real decisions to an automated gate; reserve the human for the irreducible

**Principle.** Give the agent a local decision endpoint (an "oracle") it can consult to resolve routine forks itself. A decision routed to the endpoint is answered at the agent's own cadence and logged; the same decision asked in chat blocks until a human notices. Define **exactly one** human escalation point — the single judgment the system is *provably* unreliable at — and let the agent decide everything else.

**Why it matters.** In the source project the only human gate was the appearance-vs-source judgment, precisely because the automated visual judge was *proven* untrustworthy on that axis (see A3/A4). Drawing the human boundary at the proven-weak axis (not arbitrarily) is what makes delegated autonomy safe.

**How to apply.**
- Keep the endpoint contract minimal and stable (`health` + `ask → {verdict}`) so the engine behind it is swappable at a single seam.
- Enforce the one human-only carve-out in **multiple layers** — the policy/system prompt, the routing config, and any background worker — so it can never silently leak into auto.

### C2. Never fabricate a verdict — degrade honestly

**Principle.** On any failure the oracle must produce an *honest* status, never a guessed answer. Distinguish the degrade modes explicitly: dependency-offline-but-proceed (`SKIPPED_OFFLINE`, persist the question as evidence and continue) vs offline-and-block (`BLOCKED_OFFLINE`, exit non-zero) vs internal-error (an honest error). When a component genuinely cannot decide, persist the request so a human can stand in.

**Why it matters.** An honest "I couldn't decide" is strictly better than a confident wrong verdict. The same rule governs every provider in the chain: *unavailable*, *incompatible*, and *invalid-response* are distinct statuses, and a stand-in request is written to disk rather than a fabricated answer.

### C3. Make the verdict machine-actionable: verdict + confidence + assumptions

**Principle.** The oracle is blind to everything except its prompt, so any factual claim about something it *cannot see* must be labeled an **assumption** (with a confidence), never stated as fact. A structured answer — `Verdict / Confidence / Assumptions / Risks / Next-action` (with the next-action starting with a machine-parseable token) — lets the caller know precisely which claims to re-verify deterministically versus accept.

**Why it matters.** This turns a prose answer into something a program can act on and audit. Confidence + an explicit assumptions list is what gives the verdict "teeth." Keep the parsers as pure functions so they're testable without I/O.

### C4. Tier consults by stakes; default unknown to expensive; pin the highest stakes

**Principle.** Route cheap/exploratory consults to a fast tier and the few high-consequence judgments (merge, artifact approval, architectural) to an expensive, high-effort tier. **Default an unknown/empty purpose to the expensive tier** (fail-safe), and **hard-pin** the single highest-stakes purpose so it can never be accidentally cheapened — only an explicit human override may downgrade it.

**Why it matters.** Silently cheapening the decision that matters most is how a high-stakes call gets a low-effort answer. The final approval verdict in the source project was pinned to the deep tier for exactly this reason.

### C5. Append-only audit of every decision — replay to detect judgment drift

**Principle.** Log every automated decision append-only: the exact input, the exact output, the verdict, latency, and (filled in afterward) the action actually taken. This lets you **replay** a saved input against the current engine to detect *judgment drift* — a regression test for the decision-maker itself.

**Why it matters.** "You're not in the loop, but you see and can reproduce every decision." Make audit writes **best-effort** so logging never breaks a request, and keep secrets out of the log (the token stays in the environment, never the log).

### C6. Read-only, default-deny fact-fetching

**Principle.** If the oracle must fetch supporting files to decide, make access read-only and default-deny: resolve paths strictly inside the project root (block traversal), allowlist safe suffixes, deny secret-looking names, cap size. Fetch facts; never mutate.

### C7. Self-describing contract; self-hosted status; minimal infra

**Principle.** Derive any advertised contract (fields, endpoints, capabilities) from the single source that actually implements it (the live route table), so documentation can't drift from behavior — and expose it from a self-describing health endpoint so consumers stop reverse-engineering field names. Let the service host its **own** lightweight status page with no extra stack: if the page won't load, the service is down — self-coherent monitoring with nothing separate to keep alive. Don't stand up a heavyweight framework for a peripheral status page.

**Why it matters.** A constrained caller had been discovering fields by trial and error; a self-describing health endpoint killed that. And "infra-for-infra" was explicitly rejected — minimal tooling that fails loudly beats a second system you must also keep alive.

### C8. Don't run the decision engine inside the environment it controls

**Principle.** Never run the engine that drives an automated decision *inside* the environment whose lifecycle it controls — it can recurse by re-triggering its own startup. Run it in a neutral working directory isolated from the project's hooks/config.

**Why it matters.** In the source project, running the headless engine from inside the project caused it to load the project's startup hooks — the very hooks that *boot the oracle being called* — so the oracle spawned itself infinitely. Running it from a neutral temp directory outside the project both broke the recursion and suppressed a per-project permission prompt.

### C9. Honest health, not UP/DOWN

**Principle.** Health is not binary. "Up but unconsulted for a long time," and "alive but making no progress," are failure modes a naive UP/DOWN signal hides. Track a **monotonic progress token** to distinguish *progressing* from *merely breathing*, and derive honest states (`active` / `idle` / `blocked` / `stale-source` / `unknown`) from real timestamps — emit `UNKNOWN` rather than inventing a value. (Liveness for autonomous loops in F3.)

### C10. Don't let "deferred" become a mute button

**Principle.** A "deferred / known-issue" status easily becomes a way to hide hard problems. Require a deferral to carry a full justification (why-not-fixed, next hypothesis, acceptance criteria) **and** an un-expired review-by date; otherwise it auto-reopens and counts as blocking.

---

## D. The agentic operating system

This is the steering layer that turns a generic agent into a disciplined operator for a hard goal — *not* product code, the agent's OS. Its job: keep an unattended agent from corrupting state, inventing make-work, or overstating its results.

### D1. Thin bootloader + explicit fixed load order

**Principle.** Keep the agent's entry-point instruction file a *thin bootloader*: a short root file that imports an explicitly **ordered** chain (principles → living memory → specs → evals → plans) and pushes all detail into the imported files. Ship a verifier (a one-line grep) that confirms every imported path actually resolves.

**Why it matters.** Detail in the bootloader is paid for on every turn. An ordered import chain makes precedence explicit; a path verifier catches a silently-missing import before it costs a session.

### D2. A short, load-bearing constitution with one precedence rule

**Principle.** Write a short constitution of a handful of non-negotiable principles with **one explicit precedence rule**: "if this file conflicts with any other doc, this one wins; the other must change." Require a deliberate change-with-justification to edit it, so it can't be edited away mid-task. Everything else is "regulation" derived from it.

**Why it matters.** Without a single tie-breaking authority, conflicting guidance across nested instruction files silently resolves in unpredictable ways. A protected constitution is the stable anchor the rest of the system derives from. (The source project's keystone constitutional rule was the "No regenerated-artifact-and-comparison, no progress" rule from A6.)

### D3. Three context-loading mechanisms by cost

**Principle.** Load context by cost/relevance, not all at once:
- **always-on imports** for non-negotiables;
- **capability modules (skills)** whose *description* is always visible but whose *body* loads only when a trigger fires;
- **on-demand reference docs** read only when the task touches them.

**Why it matters.** Auto-loading everything bloats the prompt and spends the budget on detail not needed this turn. *(This repo's skill/lens/rule split — see `lenses/agent-skills.md` — is exactly this mechanism; cross-reference rather than duplicate.)*

### D4. Tiered memory with explicit decay semantics

**Principle.** Tier memory by decay rate:
- **stable identity facts** (rarely change);
- a **fast-decaying dated snapshot** of current state whose *own header* orders re-verification from the source of truth (version control, issue tracker) **before** any irreversible remote action;
- **permanently numbered lessons** (each tied to a real past cost — a rework, an incident);
- a **deprecated-context** file that keeps superseded decisions for traceability but is explicitly labeled "do not follow."

**Why it matters.** A daily snapshot trusted as current is how an agent acts on stale state. Numbered lessons make a rule traceable to the cost that justified it; a deprecated-but-retained file prevents re-litigating settled decisions while making clear they're settled.

### D5. Numbered lessons-learned — each tied to a concrete cost

**Principle.** Capture every hard-won lesson as a numbered entry tied to a concrete incident/PR/rework, cross-referenced to the spec or skill that *operationalizes* it. A rule is never just prose — it points at its enforcer. Recurring lesson shapes from the source project worth pre-seeding any such system:
- *"Branch X already has feature Y" / "the reviewer said Z" is hearsay until proven empirically* — verify with a detector or an ancestry check, not someone's recollection.
- *Code landing ≠ process running* — after changing anything a long-lived process executes, **restart it and validate its health** before assuming the change is live.
- *External/peer review judges what you SEND it* — aim review at a single canonical fixed path and re-verify every finding against the *current* state; delete misleadingly-named "current/latest" snapshots that can fool a future reviewer; convert each finding into a permanent regression check.
- *Root-cause beats symptom-tweaking* — a cluster of symptoms often traces to one upstream cause; fixing the root resolves the cluster and frequently improves downstream behavior as a side effect.

### D6. "Never fabricate" as a mechanically-enforced hard rule

**Principle.** Treat one declarative input as the single source of truth and enforce "never fabricate" *mechanically*: anything not present in the input must never appear in the output, and an element with no provenance is **skipped, not guessed**. Honest incompleteness is a first-class WARN with a written justification — fabricating structure to hit a target metric is worse than an explained gap.

**Why it matters.** When the source genuinely lacked a feature, the honest output was a permanent WARN, not an invented element — inventing one to hit an expected count would have violated the rule and laundered a guess into a result. *(This is the same spine as `rules/analysis-rigor.md` rule 1: "Never invent missing data → insufficient data yields a LIMITED conclusion, never creative filling.")*

### D7. Provenance-driven, per-element behavior — kill the global flag

**Principle.** Prefer per-element behavior keyed on each element's **provenance** and **type** over a single global on/off flag. Provenance decides *whether* an element is produced at all; its type decides *how*.

**Why it matters.** A single global flag for a multi-instance feature produces a cross-session "seesaw" — all-on, then all-off — which is just *disabling* the feature, not fixing it. The source project oscillated for sessions on a global flag until it was replaced by per-element rendering (unsourced elements skipped; type decides form), backed by two gates so neither over- nor under-production can pass.

### D8. Two orthogonal routing keys — *what it is* vs *whether to act*

**Principle.** Use two orthogonal routing keys rather than one overloaded enum: a **semantic** key (*what* the thing is, which determines how to process it) and a **provenance** key (*where it came from / whether to act on it at all*). Decoupling "what is it" from "do I act on it" keeps dispatch clean and auditable.

**Why it matters.** Some inputs are already-handled upstream and must be left alone; collapsing that into the semantic enum produces a tangle of special cases.

### D9. Autonomy states with concrete stop-criteria — and a definition of "valid stop"

**Principle.** Define autonomy in tiers — **GREEN** (execute), **YELLOW** (execute + open a change for review), **RED** (stop and ask) — with *concrete, enumerated* RED criteria, not "use judgment." Typical RED triggers: exposed credentials; an irreversible destructive operation; a declared goal change; an unresolvable conflict; a red required check; a missing mandatory artifact; an operational limit reached. Equally important: define what a **valid stop** is — completing a declared slice *is* done; auto-continue only if the next item maps to a short, explicit list of value categories.

**Why it matters.** "Never stop" as an absolute is a failure mode, not a virtue: the source project's agent invented audit-after-audit and cleanup loops that converged on "preserve nothing to do." Naming a slice-complete as a legitimate stop, and gating continuation behind a ROI filter, killed the make-work.

### D10. Path-triggered process tax, not blanket process

**Principle.** Scope a heavy gate by **explicit path triggers plus a documented escape hatch**, not "when in doubt, apply it." Apply the gate only when the change touches enumerated high-risk paths; let doc-only / test-only / refactor-with-proven-output-equivalence opt out with a one-line justification.

**Why it matters.** "In doubt, applies" as a blind rule taxes throughput on changes that can't possibly affect the output; over-coverage kills velocity as surely as under-coverage ships defects.

### D11. Ban checklist theater — concrete evidence per axis

**Principle.** Every review axis must carry a *concrete, specific* sentence of evidence (a named region, before/after numbers, a baseline reference) or it is blocked; a bare "PASS — ok" is treated as failing. Allow an explicit **N/A** per axis only when the change provably doesn't touch that area.

**Why it matters.** A checklist of "PASS — ok" entries is theater that launders unverified work as reviewed.

### D12. Spec-driven, with a harness contract

**Principle.** A contract-touching change needs a short spec (problem / proposal / test cases / acceptance / out-of-scope) *before* code — and a spec without a failing-then-passing test is shelfware. Name the anti-patterns: *fake harness*, *spec-without-harness*, *prototype-without-real-application*. Prove a risky technique on a minimal fixture first, then on the real artifact, and force every experiment to end in an explicit verdict (`applied` / `rejected` / `blocked`). Use a tiered truth model where higher-confidence sources outrank inference and an experimental hypothesis never ships without promotion-by-proof. *(This repo's `templates/spec.md` + `rules/spec-rubric.md` are the construction-side instance of this discipline.)*

### D13. Cleanup needs a real trigger; archive-before-delete

**Principle.** Require a real trigger for any cleanup pass (a broken gate, a proven-superseded file, a stray artifact). Name cleanup-in-a-loop as an anti-pattern with hard stop conditions (e.g. consecutive hygiene passes all converging on "preserve" → stop, do product work). Archive-before-delete to a dated path; **never** remove ground-truth, canonical deliverables, regression baselines, or contract tests even if they look unreferenced. Inventory before any destructive op; when uncertain, keep or quarantine; apply a time-to-live to external scratch rather than instant deletion.

### D14. Don't rely on disciplined-local-runs as your only gate

**Principle.** Without CI, real breakages (undeclared dependencies, import-time path coupling) can hide for months and surface only on a clean checkout. Add at least a minimal CI that installs clean and runs the suite. Make automated tests environment-independent and skip cleanly when an external dependency is absent. *(This repo's `.github/workflows/` sanitization gate is an instance of CI-as-control.)*

---

## E. Artifact discipline — scratch vs promoted canonical

### E1. Gate-guarded promotion to a fixed canonical path

**Principle.** A build is promoted to its canonical deliverable location **only if** it was actually rebuilt (not served from cache), its self-checks are green, **and** the full deterministic suite passes. Never publish an unverified or stale artifact to a fixed path.

**Why it matters.** A fixed canonical path is what humans and external reviewers point at (D5). If anything unverified can land there, "the canonical artifact" stops meaning "the verified artifact."

### E2. The metadata/sidecar that lets a gate run is part of the deliverable

**Principle.** Any sidecar/metadata file a verification step needs in order to run is a **deliverable**, not scratch — it must be carried on every promotion/copy. (This is the structural fix behind A5: the gate skipped because its required sidecar wasn't promoted.)

### E3. Content-hash caching keyed on input *and* producer identity

**Principle.** Cache expensive builds on a content hash of the input **and** the producing tool's identity, via a sidecar metadata file, so an unchanged input short-circuits — but one tool never reuses another tool's cached output for its own request.

### E4. Read-from-model, never re-derive; build the full solid then subtract

**Principle.** After producing geometry/structure, **read the realized coordinates back from the artifact** before adding a dependent feature, rather than recomputing the expected position — this survives float/representation drift between spec and built result. For a feature that must preserve material on both sides (e.g. an opening in a wall), build the full solid first and subtract only the feature region as a real through-cut; never remove the full extent and try to refill, which yields visually and structurally separate pieces. And never assume a *global* parameter holds for every element after a transformation that can locally alter it (e.g. a merge that averages a property) — carry and use each element's **own** local parameter.

### E5. Single source of truth for shared constants, enforced by a gate

**Principle.** Centralize any shared constant (scale, conversion factor) in one source (environment-configurable), re-export for back-compat, and add a deterministic gate that **bans redefinition elsewhere** — so the rule isn't aspirational, it breaks the build on violation and forces every future branch to migrate at merge.

**Why it matters.** Multiple definitions of one constant silently corrupt outputs system-wide — the source project had a value duplicated across many files producing "artifact at scale A / sub-component at scale B / gate at scale C," which "burned entire sessions." Verify a centralization refactor across independent angles (semantics, completeness, byte-identical behavior) before accepting it.

### E6. Emit a rich machine-readable report; bucket skips by cause

**Principle.** Emit a structured report next to every artifact, bucketing skips/failures by **cause** — *by-design* skips kept in a separate field from *real-error* skips — so legitimate skips don't trip a "skipped is not empty" check. Embed self-check booleans for fast gating. Default to the safe, non-destructive runtime mode for local/interactive work; enable aggressive auto-teardown **only under CI**, resolved via an explicit mode flag/env var with a CI-aware default.

### E7. Encode tuning constants with their meaning and the experiment that set them

**Principle.** Annotate each tuning constant with its physical/real-world meaning *and* the experiment or safe range that justified its value (e.g. "swept range R, value V gives zero overlap"; "tolerance T removes only noise, real values are orders larger"), so a future maintainer knows the *safe envelope*, not just the magic number.

---

## F. Multi-agent coordination

### F1. Isolate parallel workers; no shared working tree

**Principle.** Isolate parallel agents in **dedicated branches/worktrees** off a feature branch; never touch another worker's working tree. On detecting any change you didn't author, **stop remote mutation**, register the finding, reconcile (read / accept / rebase / escalate), and only then resume. Run version-control pre-flight checks **sequentially** — parallel reads can return stale refs.

**Why it matters.** In the source project, multiple agents sharing one working tree moved the branch out from under each other several times — a near data-loss event. Observability could *see* it (F3) but only isolation prevents it.

### F2. Async, durable handoff — read first, write last

**Principle.** Keep a single durable handoff document as the thread between sessions/agents — **read first** at session start, **written last** before handoff — carrying the current branch, last commit, status, frozen recipes/decisions, open items, and named stress cases, so a cold worker resumes without the prior conversation's memory. Route real decisions through an async, logged channel (the oracle of section C), not a live blocking prompt.

### F3. Liveness for autonomous loops — monotonic progress token; detect spinning

**Principle.** For long autonomous loops, emit a **monotonic per-cycle progress counter** as a heartbeat so an observer can distinguish *progressing* from *alive-but-stuck* (same counter across pings) vs *dead* (no ping). Make the heartbeat **best-effort** so it never blocks the work. Detect spinning explicitly: *N* cycles with no new committed progress (same failure, nothing committed, the same attempt repeated) → **stop and report**, rather than iterating in the dark. Stopping when the real work is done is correct; continuing without ROI is waste.

### F4. Give any auto-actuator hard rails

**Principle.** An autonomous *actuator* (one that acts, not just watches) needs hard safety rails: a single-actuator lock with a TTL, an isolated workspace off the protected branch, **never touch the protected branch / never auto-merge**, a deterministic verify before keeping any change, and **auto-escalate any human-judgment-requiring change to a review queue** instead of auto-approving. Provide `--once` / `--dry-run` / `--loop` modes and an append-only action ledger.

### F5. Robust evidence handoff to an external reviewer; absolute paths to out-of-process tools

**Principle.** When passing visual/binary evidence to an external reviewer over a constrained channel, the robust path is often to publish it to a fetchable URL and hand over the link, rather than fighting clipboard/upload/relay limitations that silently corrupt or are blocked. **Always pass absolute paths to out-of-process tools** — a relative path is resolved against the *other* process's working directory and silently writes outputs to the wrong place. Before deleting a shared workspace/path, grep for external launchers/scripts/scheduled jobs that hardcode it — the breakage otherwise surfaces as a *misleading unrelated error*.

---

## What this repo already carries (cross-reference, don't duplicate)

| Field-note theme | Already in this repo | Path |
|---|---|---|
| Behavioral eval — prove behavior, not file existence | The `report` skill's eval fixtures: planted-problem fixtures + MUST/MUST-NOT + "polished file is a FAIL" | `examples/reporting/EXPECTED.md` |
| The rigor gate behind the eval — never over-conclude, never fabricate | Analysis-rigor rule (BLOCKER/SHOULD/NIT/OK; "insufficient data → LIMITED, never creative filling"; render only when `Validated`) | `rules/analysis-rigor.md` |
| Spec-driven construction with a harness contract | Spec template + spec rubric (BLOCKER/SHOULD/NIT/OK) | `templates/spec.md`, `rules/spec-rubric.md` |
| Severity-calibrated, consequence-first findings | Shared severity rubric (MUST/SHOULD/NIT/NO_COMMENT) | `rules/severity-rubric.md` |
| Agentic-OS / `.claude/` discipline (discovery, triggering, resolution, secrets, reproducibility; layered loading; restraint) | Agent-skills lens + the meta audit skill | `lenses/agent-skills.md`, `skills/claude-setup-audit/SKILL.md` |
| Sanitization as a mechanized gate (the control, not a checklist) | Deterministic scan + CI workflow + clean-room policy | `scripts/sanitization-check.sh`, `.github/workflows/sanitization.yml`, `docs/SANITIZATION_POLICY.md` |
| Test honesty — a test must fail for one real reason; coverage is a weak signal | Testing lens | `lenses/testing.md` |

**What is genuinely new here** (candidate seeds for future lenses/skills, none currently in the repo): the **proof-harness** stack as a unit (deterministic gates + advisory judge + negative-dogfood + before/after-vs-baseline + the `INCOMPLETE≠FAIL≠PASS` exit-code discipline + worst-of aggregation); the **decision-oracle / delegated-autonomy** pattern (route decisions to an automated gate, one human carve-out, honest degrade, verdict+confidence+assumptions, tiered consults, append-only decision audit, don't-run-the-engine-inside-its-own-environment); the **autonomy-state + valid-stop + path-triggered-process** governance; **artifact promotion discipline** (scratch vs canonical, sidecar-is-a-deliverable, single-source-of-truth constant with a banning gate); and **multi-agent coordination** (worktree isolation, durable async handoff, monotonic liveness, auto-actuator rails). A natural next step, when a real consumer exists, is a `proof-harness` lens and a `decision-oracle` / `agentic-os` lens consumed by a meta audit skill — mirroring how `agent-skills.md` is consumed by `claude-setup-audit`.
