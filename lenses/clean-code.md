# Clean Code Lens

Reusable clean-code knowledge for Java/Spring: how to judge whether the readability and maintainability of changed code is genuinely at risk. The *intent* of applying it (what to do with a finding, how to phrase it, whether to block) comes from the consuming skill, not from this lens.

## How skills use this lens

Today the only consumer is `java-pr-review`, which applies this lens with a diff/PR focus: it reasons about the lines that changed, not the whole codebase. This lens is deliberately *not* generalized for hypothetical future skills — it is written for a reviewer reading a diff. A consumer should load it only when the diff actually touches one of the areas listed in **When to Use**; if the change is pure formatting, config, or untouched-area churn, the lens has nothing to say and should stay closed.

## Purpose

Help a skill decide whether the readability/maintainability of *changed* code is genuinely at risk, and separate a real consequence (a hidden bug, a divergent fix, a misleading name that causes a wrong edit) from cosmetic preference. The lens biases hard toward restraint: most readability observations on a diff are taste, and the correct output for taste is silence. A few strong, consequence-backed findings beat a wall of nits.

## When to Use

Engage this lens when the diff shows a *structural* trigger:

- A method or class that is long or grew noticeably in this change.
- A new public name or a new domain concept (class, method, field, enum constant) entering the codebase.
- Comments added, edited, or left stale next to changed code.
- Duplicated logic appearing — a block that closely mirrors another in the diff or nearby.
- Deepening nesting or tangled control flow (added `if`/`else`/`try` layers, flag arguments, early-vs-late returns).
- A method or class taking on several responsibilities at once.
- An obvious, small, *safe* refactor inside code the diff already touches.

Do **not** engage for pure formatting or mechanical style — indentation, brace placement, import order, line wrapping, `this.` qualification, whitespace. A linter (Checkstyle, Spotless, PMD, Sonar, Error Prone) owns those, and a review comment about them is noise.

## Core Principle

Readability matters only insofar as it makes code safer to change and test. "Cleaner" is not an end in itself — it earns its keep only when it measurably protects one of those: reading, changing, or testing. Prefer a concrete consequence over an aesthetic preference, every time.

**Style belongs to linters, not review.** Anything a formatter or static-analysis tool already enforces or could enforce — naming-case conventions, spacing, ordering, redundant qualifiers, "this comment is useless" mechanical removals — is out of scope here. Raising it in review wastes the author's attention and trains them to ignore you.

Only flag a readability issue when you can name a concrete consequence: a bug it hides, a future change it will break, a test it blocks, an edit it will mislead. If you cannot name one, the issue is taste, and **"no comment" is a valid, frequent, and correct outcome.**

## Severity Calibration

This lens's canonical severity ladder is **MUST / SHOULD / NIT / NO_COMMENT**. When a consumer's own rubric uses different labels (e.g. critical/major/minor), map onto it: MUST ≈ critical/major, SHOULD ≈ major/minor, NIT ≈ minor, NO_COMMENT ≈ drop. Keep these four labels as the lens's internal vocabulary; let the consumer translate at the boundary.

- **MUST** — a concrete defect or serious hazard *now*. Examples: logic duplicated where one copy was already fixed and the other was not (latent bug); a method so tangled that a real bug is hidden inside it and a reviewer cannot trace it; a name or comment that is actively wrong (`isExpired()` that returns `true` when the item is *valid*) and will cause the next author to make an incorrect change. A *merely possible* future misuse with no current victim is usually SHOULD, not MUST — reserve MUST for a defect or hazard that exists in the code as it stands.
- **SHOULD** — a real, nameable maintainability or testability cost. Examples: two near-identical blocks likely to diverge on the next edit; a method doing three separable things, where splitting it would let each be unit-tested in isolation.
- **NIT** — cosmetic or organizational preference with no behavioral consequence; never blocks. Example: a local variable name that is fine but could be slightly clearer. The friendly surface form "nit, not a blocker: ..." is an accepted rendering of this tag.
- **NO_COMMENT** — pure taste. The code reads fine to a competent peer, or the only objection is "I'd have written it differently." NO_COMMENT is never emitted; it means the finding is dropped and you stay silent. It is a decision outcome, not a tag that appears in a posted comment.

**Overriding rule:** every finding above NO_COMMENT must name a concrete consequence (what breaks, what gets harder, what risk lands). If you cannot, drop it. Cosmetic and stylistic observations default to NIT at most, and usually to NO_COMMENT.

## Review Questions

Before raising any readability finding, ask:

1. Does this actually impede understanding or risk a bug, or is it simply not how I would have written it?
2. Would a linter or static-analysis tool already catch this? If yes, stay silent and let the tool do it.
3. Will fixing it force the author to touch unrelated lines and inflate the diff? If the cost outranks the benefit, downgrade or drop.
4. Is the duplication incidental (two things that happen to look alike) or meaningful (one rule expressed twice)? Only meaningful duplication is worth a comment.
5. Can I state the consequence in one sentence? If not, it is NO_COMMENT.

## Heuristics

### Method size & length

**What to look for:** A method that grew several distinct phases deep in this diff (validate, then transform, then persist, then notify), multiple levels of nesting, or a body you cannot hold in your head at once. Length alone is a weak signal; *number of distinct responsibilities and nesting depth* is the real one.

**Why it matters:** A method that does many things at many indentation levels is where bugs hide — a misplaced branch or an early `return` that skips later work is invisible in the noise. It also forces every test to set up the whole world, so edge cases go untested.

**When NOT to comment:** A long but flat, linear method (e.g. a straightforward field-by-field mapping) reads fine top to bottom — do not split it just to hit a line count. Mechanical "this method exceeds N lines" is a linter rule, not a review finding.

**Modern Java idiom:** Use guard clauses / early return to flatten nesting instead of an `else` pyramid. Extract a genuinely independent phase into a private method *only when it has a name that means something*. A `switch` *expression* (GA since Java 14, so safe on most projects) can replace a long `if`/`else` ladder that maps cases to values; *pattern-matching* `switch` over types is newer (GA Java 21) — verify the language level before suggesting it.

**Key review questions:** Does the nesting hide a branch that could be wrong? Could a real test exercise one phase without constructing all of them?

**Example review comment:**
> SHOULD: `processShipment` now validates, prices, persists, and emits the notification in one body with three nesting levels. If we extract the pricing step into its own method, we can unit-test the tax edge cases without standing up a full `Shipment`, and the dispatch branch at the bottom becomes visible. Not a blocker if you'd rather do it in a follow-up.

### Naming

**What to look for:** A name that contradicts what the code does, a boolean whose polarity is backwards (`disabled` used where `true` means enabled), a method named for one effect that also does a hidden second thing, or a domain term reused with a different meaning than elsewhere in the module.

**Why it matters:** A lying name is worse than no name. The next author trusts it, calls it, and ships a defect because `getCustomer()` silently also wrote an `AuditEntry`. Misleading names cause wrong edits; that is a bug vector, not a style issue.

**When NOT to comment:** A name that is merely shorter or longer than you'd pick, abbreviation style, or `count` vs `total` when both are accurate — that is taste. Naming-*case* conventions are a linter's job. Do not bikeshed an accurate name.

**Modern Java idiom:** Prefer names that state intent over names that restate type. A method that returns `Optional<Customer>` should read as a lookup that may miss (`findCustomer`), not as a guaranteed `getCustomer` — let `Optional` carry the "may be absent" meaning instead of a name like `customerOrNull`. The `findX` vs `getX` convention is common but not universal: confirm the project's (or Spring Data's) established style first, since some codebases standardize on `getX()` returning `Optional<X>`.

**Key review questions:** If I only read this name, would I predict what the code actually does? Does the name hide a side effect?

**Example review comment:**
> SHOULD: `validateInvoice` also mutates `invoice.status` and persists it, so the name promises a pure check while a caller in a read-only path will get an unexpected write. Could we rename to reflect the write, or move the persistence out so the name stays honest? (MUST if a current caller is already relying on the pure-check name.)

### Comments

**What to look for:** A comment that is wrong or stale relative to the code beside it, or one that explains *what* an obvious line does. Distinguish sharply: a comment explaining *why* (a non-obvious constraint, a workaround, an invariant) is valuable; a comment narrating *what* is noise.

**Why it matters:** A *wrong* comment is a defect — it will mislead the next reader into an incorrect change, exactly like a lying name. That is the only comment problem worth a MUST. A redundant-but-correct comment is harmless clutter.

**When NOT to comment:** Do not ask the author to delete a merely-redundant comment, fix grammar, or reformat Javadoc — that is cosmetic and, where it matters, a linter/Javadoc-lint job. Removing obvious comments is not worth a review round-trip.

**Modern Java idiom:** Often the cleanest fix for a *what*-comment is to let the code say it — a well-named guard clause or an extracted predicate (`if (order.isStale())`) removes the need for the comment entirely. Reserve prose for the *why*.

**Key review questions:** Is this comment now false given the code next to it? Does it explain a non-obvious *why*, or just restate the line?

**Example review comment:**
> MUST: The comment says "retries up to three times" but the loop bound is now `5`. Whichever is right, the other will mislead the next person who tunes this — could we correct the comment (or the constant) so they agree?

### Duplication

**What to look for:** The same rule expressed in two places in the diff, or a block copy-pasted and then tweaked in one spot. The dangerous form is *one rule, two copies* — a pricing or validation rule that now lives in both the create and update path.

**Why it matters:** When the rule changes, someone fixes one copy and misses the other. If one copy was *already* fixed in this diff and the twin was not, that is a latent bug shipping now (MUST). If they are still identical but will clearly drift, that is a SHOULD.

**When NOT to comment:** Incidental similarity — two short blocks that look alike today but encode unrelated rules — is not duplication; forcing them together couples things that should move independently. Two-line boilerplate is rarely worth extracting. Do not chase a shared helper that only saves a line or two at the cost of indirection.

**Modern Java idiom:** Pull the shared *rule* into one well-named private method or a small pure function the two paths call. If the duplication is data-shaped (a fixed set of cases), a `switch` expression or a `Map.of` lookup can replace parallel `if` chains. Extract only when the two copies truly express one concept.

**Key review questions:** Is this one rule written twice, or two rules that happen to look similar? If this rule changes next quarter, will someone update both copies?

**Example review comment:**
> MUST: This fixes the rounding in the create path, but the same calculation in `updatePayment` (a few lines down) still rounds the old way, so the two paths now disagree. Could we move the calculation into one shared method so the fix applies in both?

### Unnecessary complexity

**What to look for:** A clever one-liner that packs three operations into one unreadable expression, a nested ternary, boolean flag arguments that switch a method's behavior, or control flow that is harder than the problem it solves.

**Why it matters:** Code optimized to look short is slow to read correctly, and a reviewer who can't trace it can't catch the bug in it. Flag arguments multiply a method's behaviors and its test matrix. Complexity that isn't load-bearing is pure cost.

**When NOT to comment:** Genuinely intrinsic complexity (a real algorithm, a necessary state machine) is not a smell — don't ask for it to be dumbed down. A compact expression that is still clear to a competent peer is fine. Don't trade a correct, readable stream for a loop (or vice versa) on taste alone.

**Modern Java idiom:** Replace a nested ternary with a `switch` expression or guard clauses. Split a flag-argument method into two intent-named methods. Use a `Stream` *only when it reads more clearly* than the loop — a filter/map/collect pipeline often does, but a loop with side effects, early exit, or an index is usually clearer as a plain loop. Enhanced `instanceof` (GA Java 16) removes the cast-after-check dance — verify the level if the project is older.

**Key review questions:** Would a competent peer trace this correctly on first read? Is the complexity essential to the problem, or self-inflicted?

**Example review comment:**
> SHOULD: The nested ternary picking the `TaxRule` is hard to verify by eye, and a wrong branch here is a silent mispricing. A `switch` expression over the region enum would make each case checkable at a glance. Your call on timing.

### Confused responsibility

**What to look for:** A class or method that reaches across concerns — parsing *and* persisting *and* formatting a `Report`, or a single method that both decides *and* performs *and* logs. In a diff this shows up as a method accreting an unrelated new duty.

**Why it matters:** Tangled responsibilities make code untestable in isolation (you can't test the decision without the I/O) and turn every change into a risk of breaking an unrelated concern in the same unit. This is a maintainability/testability cost, stated as such — not "it's not tidy."

**When NOT to comment:** Do not invoke grand architecture here — this lens is about a *local* tangle in changed code, not system layering (that belongs to a design/architecture lens). A small method that does one logical thing across a few statements is fine. Don't demand a class be split because of an abstract principle with no named cost.

**Modern Java idiom:** Separate the pure decision from the effect: a method that *computes* what to do (returns a value or an `Optional`) and a caller that *does* it. Records make good immutable carriers for the computed result handed between the two — verify the project is on a Java version that has them.

**Key review questions:** Can I test the core logic here without also exercising the I/O or formatting? Did this method just take on a second reason to change?

**Example review comment:**
> SHOULD: `buildReport` now also writes the file and sends the `Notification`. That means we can't test the report contents without touching the filesystem and the notifier. Could the method return the built `Report` and let the caller persist and notify? Each part then gets a focused test.

### Small in-scope refactors

**What to look for:** An obvious, safe cleanup *inside lines the diff already changes* — collapsing an `if`/`else` that both `return`, replacing a manual null check with `Optional`, using an early return to drop a level of nesting in the touched block.

**Why it matters:** Cheap improvements at the point of change keep code from rotting, and they cost nothing because the lines are already in the diff. The value is real but small — so the severity is small.

**When NOT to comment:** If the refactor would pull in unrelated lines, expand the diff, or touch code the PR didn't otherwise change, *don't* — it muddies the review and the blame history. Suggest it as an optional NIT, never a block. A PR is not the place to refactor the neighborhood.

**Modern Java idiom:** `Optional.ofNullable(...).map(...).orElse(...)` for a null-dance already being edited; a guard clause to replace an `else` that wraps the rest of a touched method; `var` where the type is obvious from the right-hand side and the change is already on that line.

**Key review questions:** Is this fully contained in lines already changing? Is it clearly safe, or am I asking for risk in unrelated code?

**Example review comment:**
> NIT (not a blocker): since these lines are already changing, the `null` check on `customer` could become `Optional.ofNullable(customer).map(Customer::tier).orElse(DEFAULT)` — a bit easier to follow. Equally fine to leave as is.

## Anti-Patterns

- **Comment that restates the code** — *Diff:* `// increment the counter` above `counter++`. *Harm:* clutter; and once the line changes the comment silently lies. *Fix:* NO_COMMENT in review — if you're already editing the line for another reason, drop the stale comment; do not open a review thread solely to delete a redundant-but-correct comment.
- **A name that lies about behavior** — *Diff:* `getActiveOrders()` that also archives stale ones. *Harm:* the next author calls it trusting the name and ships a side effect. *Fix:* rename to the truth, or remove the hidden effect. MUST when it will cause a wrong edit.
- **Copy-paste-with-a-tweak** — *Diff:* a block pasted into a second path with one number changed. *Harm:* the next fix lands in one copy only; the paths diverge. *Fix:* extract the shared rule into one method both call.
- **Deep nesting that guard clauses would flatten** — *Diff:* three `if` levels wrapping the real work, with the error cases as `else` branches. *Harm:* the happy path is buried; an early-return bug is easy to miss. *Fix:* return/throw early on the failure cases, leave the main path at the top indentation level.
- **God method** — *Diff:* one method that validates, computes, persists, and notifies. *Harm:* untestable in pieces; every change risks an unrelated concern. *Fix:* split into intent-named steps, or separate decision from effect.
- **Premature extraction of a one-use helper** — *Diff:* a two-line private method called from exactly one place, named vaguely. *Harm:* indirection with no reuse; the reader jumps to a helper that didn't need to exist. *Fix:* inline it unless the name genuinely clarifies intent.
- **Dogmatic line-count / method-length rule** — *Diff:* a comment demanding a split purely because a method passed N lines, though it is flat and linear. *Harm:* needless churn, worse cohesion, reviewer credibility lost. *Fix:* judge by responsibilities and nesting, not line count; if it's a hard limit, let the linter enforce it.
- **Nitpicking formatter-owned cosmetics** — *Diff:* comments on spacing, import order, brace style, `this.` usage. *Harm:* noise that trains the author to tune you out. *Fix:* say nothing; let Spotless/Checkstyle handle it.
- **Over-clever one-liner that hides intent** — *Diff:* a nested ternary or a dense stream chain doing three things. *Harm:* slow to read, easy to misjudge, the bug inside is invisible. *Fix:* a `switch` expression, guard clauses, or a named intermediate that states intent.

## Modernization (Java/Spring idioms for cleaner code)

Prefer current idioms — but **inspect the target project first.** Check the Java language level, the Spring Boot version, the established conventions, and the libraries already in use *before* recommending anything. Never assume a version or an API is available; a suggestion the project can't compile is worse than no suggestion.

Frame each of these as "verify against the actual project":

- **Records** for immutable data carriers (a computed result, a DTO) — verify the project is on a Java version that has them and isn't standardized on a different value-object approach.
- **Sealed types** where a closed set of subtypes makes intent and exhaustive handling clearer — verify availability and that the hierarchy is genuinely closed.
- **Pattern matching for `switch` and `instanceof`** to remove cast boilerplate and make case handling exhaustive — note that `switch` *expressions* are GA since Java 14, enhanced `instanceof` since Java 16, and *pattern-matching* `switch` over types since Java 21; verify the language level (and preview status, if relevant) before suggesting the newer forms.
- **`var`** for locals where the type is obvious from the right-hand side — verify the team's convention allows it; don't use it where the type is the only clue to intent.
- **`Optional`** as a return type to express "may be absent" instead of returning `null` — verify it isn't being shoehorned into fields or parameters, which it's not meant for.
- **`Stream`** where it reads more clearly than a loop — *with the caveat that a stream can be **less** readable than a plain loop*, especially with side effects, early exit, or index logic. Verify clarity case by case; don't convert a clear loop on principle.
- **Text blocks** for multi-line literals (SQL, JSON, formatted messages) — verify the language level (GA Java 15).
- **`List.of` / `Map.of` / `Set.of`** for small immutable constants instead of mutable-collection-then-populate — verify immutability is actually wanted at that call site.
- **`String.formatted(...)`** (or `String.format`) for interpolated messages where it reads more clearly than concatenation — verify the language level for `formatted` (GA Java 15). Do *not* reach for String Templates: that was a preview feature, has since been withdrawn, and is available in no GA Java release — never assume it is present.

## Suggested PR Comment Style

Be respectful, consequence-first, and severity-honest. Lead with the concrete consequence, not the rule. Make NITs explicitly optional, and say so when code is fine.

Example openers:

- "Could we... so that..." (proposes a fix tied to a benefit)
- "This may bite us later because..." (names the future cost)
- "NIT (not a blocker): ..." (flags taste-level, optional)
- "This reads clearly, no change needed." (explicitly endorses)

Example comments:

- > SHOULD: `applyPricingRule` is now duplicated in the create and update paths. When the rule changes, one copy will likely be missed — could we extract it into a single method both call?
- > NIT (not a blocker): `var` would read fine here since the type is obvious from the right-hand side. Equally happy to leave it.
- > This `Shipment` mapping is long but flat and linear, so it reads clearly top to bottom — no change needed from me.

## Integration (java-pr-review)

- Apply this lens with a **diff/PR focus** — reason about the changed lines, not the whole codebase, and not system architecture (that is the design-patterns lens and a future architecture skill, not this one).
- **Never emit a comment for cosmetics a linter owns** — formatting, naming-case, import order, brace style, `this.`, whitespace, redundant-but-correct comments. Stay silent and let the tooling handle them.
- **Never block on preference.** A NIT is optional by definition; a finding without a named consequence is NO_COMMENT.
- **Always tag severity** — MUST / SHOULD / NIT — so the consumer can route and so the author knows what blocks. (NO_COMMENT is the silent fourth outcome: it is never posted.)
- **Prefer a few strong findings over many weak ones.** Three consequence-backed comments land; fifteen nits get ignored and bury the one that mattered. Drop the weak ones to NO_COMMENT.