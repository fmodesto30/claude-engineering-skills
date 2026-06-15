# SOLID Lens

Reusable SOLID knowledge for Java/Spring: how to judge whether changed code has its responsibilities,
substitutability, interfaces, and dependency directions right — *when getting one wrong has a named
cost*. The *intent* of applying it (which diffs, how strict, whether to block) comes from the consuming
skill, not from this lens. SOLID is the single most over-applied idea in code review, so this lens
biases hard toward restraint: a principle named without a concrete consequence is `NO_COMMENT`.

## How skills use this lens

**`java-pr-review`** reads it **evaluatively**, with a diff/PR focus: it reasons about the
responsibility, hierarchy, interface, or dependency that *this change* introduces or moves — not the
whole codebase, and not system architecture. **`spec-author`** may read it **generatively** — *what
responsibility boundary and dependency direction should this design decide?* — though most of that
decision lives in the `ddd` and `design-patterns` lenses.

It borders three neighbors, and the framing keeps them distinct. **`design-patterns`** owns the
*mechanism* (a strategy, a factory, DI vs. a service locator); this lens owns the *principle* (is the
code closed where it should be, does it depend on an abstraction) and points at design-patterns for the
fix. **`clean-code`** owns a *local* method tangle in the changed lines; this lens owns a *class/module*
taking on a second reason to change. **`ddd`/`architecture-review`** own dependency direction at
*system* altitude; this lens stays at the changed class. Load it only when the diff actually moves a
responsibility, a type hierarchy, an interface, or a dependency direction — never because the word
"SOLID" or an interface name appears.

## Purpose

Help a skill judge whether a SOLID-shaped decision in a diff pays for itself, and separate a real,
nameable cost (a change that forces editing unrelated code, a subtype that breaks its callers, a seam
that genuinely needs to be testable) from dogma. The default bias is the simplest construction that
satisfies the requirement: one class, a direct call, a concrete dependency. SOLID is a diagnostic for
when that simplicity has *stopped* paying — not a checklist to impose. Recommending *no* SOLID change —
keeping the concrete, direct code — is a valid and frequent outcome.

## When to Use

Engage this lens when the diff shows a *structural* trigger tied to one of the principles:

- A class or method taking on a **second reason to change** — orchestration plus a business rule,
  mapping plus persistence, a decision plus its I/O (SRP).
- A change that **edits existing, tested code to add a case** — a `switch`/`if`-ladder over a type or
  status grown again, a behavior that varies and recurs (OCP).
- A **subtype or interface implementation** that may not honor the base contract — overrides that throw,
  strengthen preconditions, weaken postconditions, or return `null` where the base does not (LSP).
- A **new or widened interface**, or a client depending on a broad interface while using one method of
  it (ISP).
- A **dependency direction** decision — high-level policy (a use case, a domain service) reaching for a
  concrete or infrastructure detail, or `new`-ing its own collaborator (DIP).

Do **not** engage for pure formatting, a local readability tangle (that is `clean-code`), a pattern's
mechanics (that is `design-patterns`), or system-altitude module structure (that is
`architecture-review`/`ddd`).

## Core Principle

Each SOLID principle is a *tool for naming a specific future cost*, never a goal in itself. A class
matching "one responsibility," an interface that is "segregated," a dependency that is "inverted" — none
of these is good by virtue of the label. The principle is justified only when applying it removes a
concrete cost you can state: a change that would otherwise ripple, a caller that would otherwise break,
a collaborator that genuinely needs to be substitutable in a test.

The opposite error is the common one. **Forcing SOLID where the cost is hypothetical is the canonical
over-engineering trap**: an interface with one implementation and no second on the horizon, a class
split because "it does two things" when both things always change together, a dependency inverted behind
a port that has exactly one adapter and no test seam. These add indirection and files to read for no
benefit. If you cannot name what concretely breaks or gets harder *without* the SOLID change, the
finding is `NO_COMMENT`. "This violates SRP/OCP/DIP" is not a finding; "this violates OCP, so the next
payment type means editing these three methods together and a missed one ships a bug" is.

## Severity Calibration

Map findings to the consuming skill's rubric (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md)).
Most SOLID findings are `SHOULD` or below; `MUST` is reserved for a violation that causes a defect or
hazard *now*.

- **MUST** — a SOLID violation with a concrete defect today. An **LSP** break a caller already relies on
  (a subtype that throws or returns `null` where the polymorphic call site assumes a valid result →
  runtime failure / NPE in production). A responsibility tangle so severe that a real bug is hidden in
  the mixed concern and a reviewer cannot trace it.
- **SHOULD** — a real, nameable maintainability or testability cost, no defect yet. An **OCP** `switch`
  that must be edited in several places for each new case (a new case will likely miss one). An **SRP**
  class doing two separable things where splitting would let each be unit-tested in isolation. A **DIP**
  coupling to a concrete that blocks a test seam *that is actually needed* (a real external dependency
  you must fake to test the policy). An **ISP** fat interface forcing implementers to stub methods they
  do not use.
- **NIT** — an organizational or naming preference with no behavioral consequence (where a method lives,
  a slightly cleaner interface name). Never blocks.
- **NO_COMMENT** — speculative SOLID: an interface extracted for a single implementation "to be safe", a
  class split on principle when both concerns always change together, a port inverted with one adapter
  and no test seam, an OCP abstraction for a variation that does not exist. Stay silent — this is the
  most frequent correct outcome for this lens.

**Overriding rule:** every finding above `NO_COMMENT` names a concrete consequence — what ripples, what
breaks, what becomes untestable. If you cannot, drop it. SOLID-by-dogma defaults to `NO_COMMENT`.

## Review Questions

- Does this class have **two reasons to change**, and do those two reasons actually change at *different*
  times — or do they always move together (in which case splitting buys nothing)?
- To add the next case, must I **edit existing tested code**, and is that case-set actually growing — or
  is it fixed and small?
- Does every subtype/implementation **honor the base contract** a caller relies on, or does one throw,
  return `null`, or strengthen a precondition that breaks polymorphic use?
- Does any implementer have to **stub or throw** on interface methods it does not need — is the interface
  too wide for its clients?
- Does high-level policy depend on a **concrete/infrastructure detail**, and is there a *real* need to
  substitute it (a second implementation, a test seam) — or would a port just add a layer over the one
  thing that exists?

## Heuristics

### Single Responsibility (SRP)

**What to look for:** A class or service that mixes axes that change for different reasons and at
different times — a use case that also maps DTOs and issues the SQL, a `Report` class that computes
*and* formats *and* writes the file, a controller holding a business rule. In a diff this shows up as a
class accreting a second, unrelated duty.

**Why it matters:** When two reasons to change live in one unit, a change to one risks breaking the
other, and neither can be tested without dragging in the other's collaborators. The cost is concrete:
mixed concerns are where an unrelated regression sneaks in, and where a unit test has to stand up the
world.

**When NOT to comment:** The "two things" always change together and are cohesive (splitting them just
spreads one decision across two files). A short method doing one logical thing across a few statements.
A *local* method tangle is `clean-code`'s confused-responsibility heuristic, not this one — defer to it.

**Modern Java/Spring idiom:** Separate the decision from the effect (a method that *computes* a result,
a caller that *performs* it), and keep mapping/persistence in their own collaborators (a mapper, a
repository adapter) so the use case orchestrates. Inject the collaborators; do not let one bean own
every step. A `record` is a clean carrier for the computed result handed between split parts (verify the
Java version).

**Key review questions:** Do the two responsibilities here change at different times, for different
reasons? Can I test the core logic without the I/O it is tangled with?

**Example review comment:**
> SHOULD: `InvoiceService` now both prices the `Invoice` and renders its PDF. Those change for different
> reasons (tax rules vs. layout), so a layout tweak risks the pricing path and neither is testable alone.
> Could the pricing stay here and the rendering move to a dedicated formatter the service calls?

### Open/Closed (OCP)

**What to look for:** A `switch`/`if`-ladder over a type tag, enum, or status that this diff edits *again*
to add a case — and the same branching key reappearing across several methods, each needing the new
branch. The tell is "to add a behavior, I edited existing tested code in N places."

**Why it matters:** When every new case means editing (and risking) existing code in several spots, the
cost compounds and a missed branch ships a silent bug. OCP names the moment to make the variation
pluggable — *once the variation is real and recurring*.

**When NOT to comment:** Only one or two fixed cases that never grow — a straight `if`/`else` is clearer
than an abstraction. A `switch` in exactly one place is fine; the cost is the *repetition* across
methods, not the switch itself. The *mechanism* for closing it (strategy, enum-with-behavior, a `Map` of
beans) belongs to the `design-patterns` lens — point there rather than re-deriving it.

**Modern Java/Spring idiom:** Where the variation is real and recurring, dispatch instead of branch — an
`enum` with behavior per constant, a `Map<Key, Handler>` of injected beans, or a sealed type with
pattern-matching `switch` (verify the Java version). See `design-patterns` for the trade-offs; here the
judgment is only *whether* the code should be closed against this change.

**Key review questions:** Is this case-set genuinely growing, or fixed? Does adding a case force editing
several existing methods that must stay in sync?

**Example review comment:**
> SHOULD: this `switch (paymentType)` is now edited in three methods to add `PIX`; each new type means
> touching all three and a missed one is a latent bug. If the set keeps growing, dispatching per type
> (see the design-patterns lens) would make a new type one new unit. Fine as-is if the set is done.

### Liskov Substitution (LSP)

**What to look for:** A subtype or interface implementation that does not honor what callers assume of
the base: an override that throws `UnsupportedOperationException`, returns `null` where the base returns
a value, strengthens a precondition (rejects input the base accepts), or weakens a postcondition. A tell
is a caller doing `instanceof`/`getClass()` checks to special-case one subtype — the hierarchy is
already lying.

**Why it matters:** Polymorphism's whole promise is that a caller can use any subtype through the base.
When one subtype breaks the contract, the call site that trusted it fails — often as a runtime exception
or an NPE in production, not a compile error. This is the SOLID principle most likely to produce a real
defect, hence the only one that is routinely a `MUST`.

**When NOT to comment:** The hierarchy is genuinely substitutable, or the "subtype" relationship is
modeling something that is not actually an *is-a* (in which case the real fix is composition — flag
that, gently). A `default` method an implementer legitimately opts out of via the interface's own
contract is not a violation.

**Modern Java/Spring idiom:** Prefer composition over inheritance when a subtype cannot honor the base
contract; model a closed set as a `sealed` interface so the cases are explicit and exhaustively handled
(verify the Java version) rather than a base with holes. If a method does not apply to all subtypes, it
does not belong on the shared type.

**Key review questions:** Can a caller use this subtype through the base type without knowing which
subtype it is? Does any override throw, return `null`, or reject input the base accepts?

**Example review comment:**
> MUST: `ReadOnlyAccount` extends `Account` but `withdraw()` throws `UnsupportedOperationException`, and
> `TransferService` calls `withdraw()` on any `Account`. A read-only account flowing through that path
> throws at runtime. Could read-only be modeled so it is not substitutable where `withdraw` is required
> (a narrower type, or composition) rather than a subtype that breaks the contract?

### Interface Segregation (ISP)

**What to look for:** A fat interface whose implementers must stub or throw on methods they do not need;
a new method bolted onto a broad interface that only one implementer cares about; a client that depends
on a wide interface while calling one of its methods. In a diff: an interface growing a method that not
all implementers can meaningfully provide.

**Why it matters:** A wide interface couples every implementer and client to methods they do not use, so
a change to an unused method ripples to classes that do not care, and every test double must stub
irrelevant methods. The cost is real coupling and test friction, not tidiness.

**When NOT to comment:** A cohesive interface whose methods genuinely belong together and all
implementers use. Do not split an interface on principle into one-method fragments — that is its own
over-engineering, and a tiny role interface per method is rarely worth the scatter.

**Modern Java/Spring idiom:** Define narrow, role-based interfaces named for what the *client* needs (a
consumer depends only on the slice it uses); let a class implement several small interfaces rather than
one broad one. A functional interface is the natural form when the role is a single operation.

**Key review questions:** Does every implementer use (and can meaningfully provide) every method here?
Does this client depend on more of the interface than it actually calls?

**Example review comment:**
> SHOULD: adding `archive()` to `Repository` forces the three in-memory implementations to throw, since
> only the JPA one supports it. A separate `ArchivableRepository` that only the JPA adapter implements
> would keep the others honest and their tests free of stubbed throwers.

### Dependency Inversion (DIP)

**What to look for:** High-level policy depending on a low-level detail: a use case or domain service
importing a concrete infrastructure type (a JPA repository class, an HTTP client, a vendor SDK),
`new`-ing its own collaborator, or reaching into a static/global to fetch one. In a hexagonal codebase,
the tell is an `application`/`domain` class importing from `infrastructure`.

**Why it matters:** When policy depends on a concrete detail, you cannot substitute that detail — for a
test, for a second provider, or to keep the domain free of framework concerns — without editing the
policy. The cost is a domain coupled to infrastructure and a seam you cannot fake in a unit test.

**When NOT to comment:** There is exactly one implementation, no second on the horizon, and no test seam
that the indirection would unlock — then a port is a layer over nothing (`NO_COMMENT`; this is the
common over-application of DIP). The collaborator is a stable value type or a standard-library class, not
a volatile dependency. The *mechanism* (constructor injection vs. service locator) is the
`design-patterns` lens's DI section — defer there.

**Modern Java/Spring idiom:** Depend on an interface the high-level module owns (a port in the
domain/application layer) and inject the concrete adapter via constructor injection; let Spring wire it.
Reserve this for a dependency that genuinely varies or must be substitutable in a test — not for every
collaborator.

**Key review questions:** Does this high-level code depend on a concrete/infra detail, and is there a
*real* need to substitute it (a test seam, a second adapter)? Or would a port just wrap the one thing
that exists?

**Example review comment:**
> SHOULD: `PlaceOrderUseCase` imports and `new`s `JpaOrderRepository` directly, so the use case can't be
> unit-tested without a database and is coupled to JPA. Could it depend on an `OrderRepository` port
> (owned by the application layer) injected by Spring, with the JPA class as the adapter? (NO_COMMENT if
> there's truly only ever one store and no test needs to fake it.)

## Anti-Patterns

- **Interface with a single implementation "to be safe"** — *Diff:* a new `XxxService` interface with one
  `XxxServiceImpl` and no second case in sight. *Harm:* the reader chases an interface to find the only
  behavior; wiring is harder to follow; no flexibility gained. *Fix:* keep the concrete class; extract the
  interface in minutes when a real second case or test seam appears. `NO_COMMENT` unless that case exists.
- **Class split on principle** — *Diff:* one cohesive class broken into two because "it does two things,"
  though both things always change together. *Harm:* one decision now spans two files; cohesion drops.
  *Fix:* leave it; split only when the two axes change for different reasons at different times.
- **God class / service** — *Diff:* a service accreting orchestration, mapping, persistence, and
  formatting. *Harm:* untestable in pieces; every change risks an unrelated concern; a merge-conflict
  magnet. *Fix:* separate the concerns that change independently; keep the use case orchestrating
  injected collaborators.
- **Subtype that breaks the contract** — *Diff:* an override that throws or returns `null` where callers
  assume a valid result. *Harm:* polymorphic call sites fail at runtime. *Fix:* composition, a narrower
  type, or a sealed model where the case is explicit — not a base with holes. `MUST` when a caller relies
  on it.
- **Fat interface** — *Diff:* a broad interface whose implementers stub/throw on unused methods. *Harm:*
  coupling to unused methods; test doubles littered with throwers. *Fix:* narrow, role-based interfaces
  named for the client's need.
- **Domain depending on infrastructure** — *Diff:* an `application`/`domain` class importing a concrete
  infra type or `new`-ing it. *Harm:* domain coupled to framework; no unit-test seam. *Fix:* a port the
  domain owns + an injected adapter — *when* substitutability is actually needed.
- **Port over nothing** — *Diff:* a DIP port inverted with exactly one adapter and no test seam. *Harm:*
  indirection with no benefit; the over-correction of DIP. *Fix:* depend on the concrete until a second
  adapter or a real test seam justifies the port.

## Modernization (Java/Spring idioms for SOLID)

Standing guidance: **inspect the target project first.** Check the Java language level, the Spring Boot
version, the DI style, and the architecture in use before recommending anything — a suggestion the
project can't compile or that fights its conventions is noise. Frame each as *verify against the actual
project*:

- **Constructor injection** (final fields, no field `@Autowired`; with a single constructor, no
  annotation needed on Spring 4.3+) as the default way to invert a dependency. *Verify the Spring style.*
- **`sealed` interfaces + pattern-matching `switch`** to model a closed set substitutably and handle it
  exhaustively, instead of a base class with holes or an `instanceof` ladder. *Verify the Java version
  (sealed: 17; pattern-matching `switch` over types: 21).*
- **Functional interfaces** for a single-operation role (the natural minimal interface for ISP) and small
  strategies, instead of a wide interface. *Verify the project's style.*
- **`record`s** as immutable carriers when splitting a responsibility hands a computed result between
  parts. *Verify the Java version.*
- **A `Map<String, Handler>` of injected beans** or an `enum` with behavior per constant to close code
  against a growing case-set (the OCP mechanism; see the `design-patterns` lens). *Verify before
  suggesting the newer forms.*

When the simplest thing — one concrete class, a direct call, no interface — satisfies the requirement,
say so plainly. The correct amount of SOLID is the amount that removes a *named* cost, and no more.

## Suggested PR Comment Style

Respectful, consequence-first, severity-honest, and explicitly happy to leave it alone. Lead with the
cost the principle prevents, not the principle's name; make speculative suggestions explicitly optional
or drop them. Example openers:

- "This will be costly to extend because..." (names the OCP cost)
- "A caller using this through the base type would break because..." (names the LSP defect)
- "NO_COMMENT-worthy unless...": say plainly when an interface/port is *not* yet worth it.
- "This concrete dependency is fine here — there's no second impl or test seam that a port would unlock."

Example comments (neutral nouns):

- > SHOULD: the `status` switch is edited in three methods to add a state; a new state means touching all
  > three. If states keep growing, moving the behavior onto the enum would make a new state one place.
- > MUST: `GuestCart` extends `Cart` but `checkout()` throws, and `OrderService` checks out any `Cart`.
  > A guest cart on that path fails at runtime — composition would avoid the broken substitution.
- > This `EmailSender` is injected as a concrete class, but there's one implementation and the test uses
  > the real SMTP stub fine — a port here would just add a layer. Happy to leave it.

## Integration (java-pr-review)

- Apply with a **diff/PR focus** — the responsibility, hierarchy, interface, or dependency *this change*
  moves, not the whole codebase and not system architecture (that is `architecture-review`/`ddd`).
- **Bias hard toward `NO_COMMENT`.** SOLID is the most over-applied review idea; an interface, a split,
  or a port is a cost, and most of the time the concrete, direct code is correct. Recommending *no* SOLID
  change is the frequent right answer.
- **Never raise a finding without a named consequence** — what ripples, what breaks at runtime, what
  becomes untestable. "Violates SRP/OCP/DIP" alone is `NO_COMMENT`.
- **Defer the mechanism to `design-patterns` and the local tangle to `clean-code`.** This lens judges the
  principle; it points at the other lenses for the fix rather than re-deriving it.
- **Always tag severity** — `MUST` / `SHOULD` / `NIT` — per the consuming skill's rubric; `MUST` only for
  a defect now (typically a broken LSP substitution). `NO_COMMENT` is the silent fourth outcome.
- **Prefer a few strong findings over many weak ones.** One real extension-cost or broken-substitution
  finding lands; five "extract an interface" notes are noise and bury it.
