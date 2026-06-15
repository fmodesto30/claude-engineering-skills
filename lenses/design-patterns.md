# Design Patterns Lens

Reusable design-pattern knowledge for Java/Spring code: when a pattern helps or hurts, and the modern idioms that often replace the classic forms. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This lens has three consumers. Its primary review consumer is **`java-pr-review`**, which applies it to a **diff/PR** — *does this pattern in the diff make the code simpler and safer, or is it ceremony/overengineering?* — and emits severity-tagged review comments. It is also consulted by **`architecture-review`** at **system/design altitude**, which asks the same question about a structural choice in a design rather than in a single diff. The review-flavored sections below (severity calibration, comment style, integration contract) are written primarily for the PR-review intent; `architecture-review` applies the same pattern knowledge with a design-altitude intent. A third consumer, **`spec-author`**, reads the same knowledge **generatively** — choosing which structure to adopt when writing a spec, rather than judging one after the fact.

Those consumers are exactly why this knowledge lives in `lenses/` rather than inside one skill. The lens is still **not** over-generalized: it stays grounded in the concrete review questions both skills can act on, and each consumer supplies its own altitude and intent. A consuming skill loads it only when the diff or design actually touches the structural areas in "When to Use" below — never just because a pattern name appears.

## Purpose

This lens helps the reviewer judge whether the design-pattern decisions in a Java/Spring PR actually pay for themselves. Its job is to separate patterns that remove real complexity from patterns applied out of habit, anticipation, or aesthetic preference. The default bias is toward the simplest construction that satisfies the requirement: a plain method, a direct call, an `if`/`else`, a constructor. When the PR introduces or removes an abstraction, the lens gives the reviewer a consistent way to ask "does this structure earn its keep?" and to phrase the answer as a concrete, actionable comment rather than a stylistic opinion. It is equally a tool for restraint — for confirming that the absence of a pattern is correct and that no comment is warranted.

## When to Use

Consult this lens when the diff does something structural, including:

- Adds or removes an interface, abstract class, or other indirection layer.
- Introduces inheritance or changes a type hierarchy.
- Branches on a type tag, enum, or state field (`switch`/`if`-chains over `instanceof` or a discriminator) to vary behavior.
- Centralizes or restructures object creation (factories, builders, static creators, Spring `@Bean` wiring that encodes selection logic).
- Crosses an integration boundary (external API client, persistence gateway, message broker, third-party SDK adapter).
- Adds cross-cutting behavior (logging, retry, caching, authorization, transactions) around existing calls.
- Introduces eventing, callbacks, publish/subscribe, or other inversion of control between components.

Do NOT consult this lens merely because a pattern name appears in a class name, comment, or PR description. The name `XxxFactory` or `XxxStrategy` is not itself a reason to engage — the trigger is a structural change in the diff, not vocabulary.

## Core Principle

A design pattern is a tool, not an objective. The fact that a construction matches a named pattern is never, by itself, a reason to adopt it, and never a reason to praise it. A pattern is justified only when it does concrete work:

- Removes meaningful, real duplication (not incidental similarity).
- Isolates a variation that genuinely exists in the code today.
- Protects a boundary, invariant, or contract from leaking or being violated.
- Improves testability by making a collaborator substitutable.
- Tames real complexity by giving a tangled responsibility a clear seam.
- Enables an extension that is concretely planned, not merely imaginable.
- Reduces maintenance or production risk in a way you can name.

If none of these apply, the correct recommendation is no pattern. Recommending no pattern — keeping the direct, literal implementation — is a valid outcome and is frequently the best one. Speculative generality, abstractions with a single implementation and no second on the horizon, and patterns introduced "to be safe" are costs without benefits and should be treated as such.

## Severity Calibration

Apply these four levels to PATTERN findings (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md) for the shared definitions):

- **MUST** — The pattern (or its absence) causes a concrete defect or serious hazard: a bug, a production risk, severe or cyclic coupling, inconsistent or corrupted state, a transactional/consistency error (for example, mutable instance fields on a default singleton-scoped Spring bean accessed concurrently across requests, or a factory that escapes the transaction boundary), broken polymorphic substitutability, a violated contract, or a structure that makes a required near-term evolution unsafe. These must be raised and must explain the failure mode.
- **SHOULD** — No defect today, but a specific pattern would clearly improve maintainability, testability, or extensibility, and you can state the concrete benefit (for example, "extracting this `switch` into polymorphic types removes the three parallel branches that must currently be edited together"). Raise it when the benefit is real and nameable.
- **NIT** — Naming, file/package organization, or an optional style preference with no behavioral consequence (for example, a builder that would read slightly better than a long constructor). Worth a brief note, never a blocker.
- **NO_COMMENT** — The suggestion would be pure taste, or it is speculative overengineering (adding an abstraction for a variation that does not exist, a second implementation that is not coming). Stay silent.

Overriding rule: every finding must name a concrete consequence — what breaks, what gets harder, what risk materializes. If no concrete consequence can be articulated, the finding is NO_COMMENT, regardless of how strongly the code diverges from a conventional pattern shape.

## Review Questions

Before suggesting or accepting a pattern, the reviewer should be able to answer:

- Does the variation this pattern abstracts actually exist in the code today, or is it hypothetical?
- How many real implementations exist right now? One implementation usually does not justify an interface.
- Does the framework already solve this? Spring frequently provides the seam (dependency injection, `@Transactional`, `@EventListener`, `@Cacheable`, `RestClient`/`@Retryable`) — a hand-rolled pattern that duplicates a framework facility is a cost, not a benefit. But these facilities are version- and dependency-gated: `@Retryable` needs `spring-retry` plus `@EnableRetry`, `@Cacheable` needs `@EnableCaching` and a configured cache provider, and `RestClient` needs Spring Framework 6.1+/Boot 3.2+. Confirm each is actually on the classpath before recommending it.
- Does this make tests simpler or harder? If it forces more mocking, indirection, or setup than the direct version, that is a strike against it.
- What concretely breaks, or becomes risky, if we do NOT introduce it? If the answer is "nothing, yet," lean toward no pattern.
- Is the team likely to recognize and maintain this pattern, or does it add a comprehension cost that outweighs its structural gain?

## Cross-Cutting Trade-off Lenses

These apply across every pattern below. Use them to decide whether a structural change is worth its cost:

- **Every pattern is a trade, not a free win.** Name what was given up — almost always added indirection and more types — and judge whether it buys something real. The most dangerous design cost is the *unacknowledged* one.
- **Separate what varies from what stays fixed.** Most patterns name a single axis of change and protect the stable skeleton around it. Find the axis of variation; confirm it is cleanly isolated; confirm that *independent* axes have not been jammed into one structure (the tell is duplication that grows multiplicatively).
- **Composition and inheritance are complementary.** Inheritance is the cheap, open-ended extension point early on but freezes the choice at construction and spends the single-inheritance budget; composition allows runtime swapping and independent variation. Prefer composition when variation must combine or change at runtime.
- **Polymorphism over repeated conditionals.** A `switch`/`instanceof` ladder over a type tag or state value that must be edited for every new case is the canonical trigger to consider dispatch — but only once the variation is real and recurring.
- **Protect invariants deliberately.** Method visibility and `final`/`sealed` are design messages about what may be overridden. Substitutability is the test for whether inheritance is even appropriate. Immutability is the precondition for safely sharing an instance.
- **Decouple creation, not just usage.** An abstraction delivers no flexibility if the construction site still names concretes and re-couples everything. Push the decoupling out to the wiring boundary (DI/configuration).
- **A pattern is knowledge, not a template, and never a goal.** Real systems combine several patterns naturally — but each one present should answer a distinct "what problem does this solve?" If it can't, it should go.
- **Refactor toward a pattern in small, test-backed steps.** Patterns are as much an incremental target (driven by smells: duplication, bloated classes, repeated conditionals) as an up-front choice. The safety net is a test run at each step.

## Pattern Heuristics

### Strategy / Policy Object

**When it helps:** Several rules vary independently along the same axis and are selected at runtime — e.g. per-`Customer` `PricingRule` selection, multiple `Payment` capture methods, or pluggable `Report` formats. It makes swapping behavior explicit and each branch unit-testable in isolation.

**Warning signs:** A growing `if/else` or `switch` over a type/enum where each branch holds non-trivial logic; the same branching key reappearing in multiple methods; a new case added by editing an existing method rather than adding a unit.

**When NOT to use:** Only one implementation exists and no variation is expected, or branches are one-liners. Introducing an interface, a bean per case, and a selector for a single behavior just adds indirection to read through.

**Modern Java/Spring alternative:** An `enum` with abstract/overridden behavior per constant, a functional interface plus a `Map<Key, Strategy>`, or a `Map<String, Strategy>` of injected Spring beans keyed by name. Reserve the full interface-hierarchy form for genuinely open-ended sets.

**Key review questions:** Does this behavior actually vary across more than one real case, or is it indirection for its own sake? If the pluggable collaborator is never set, is there a safe default rather than a latent null failure? Could a runtime swap leave dependent state inconsistent?

**Example review comment:** "This `switch` on `paymentType` now appears in three methods; each new payment kind means editing all three. Consider one `PaymentHandler` per type selected from a map, so adding a kind is a new class plus one registration and stays independently testable."

### Template Method

**When it helps:** A fixed algorithm skeleton (validate, then transform, then persist, then notify) where only a couple of steps differ between variants — e.g. distinct `Report` generators sharing one orchestration. Centralizing the invariant order prevents each variant from re-implementing (and drifting on) the flow.

**Warning signs:** A new `abstract` base added purely to host shared steps; subclasses overriding `protected` hooks while also reaching into parent state; an inheritance tree deepening just to reuse one method.

**When NOT to use:** When inheritance is chosen only for code reuse and raises coupling, or variants need to combine independently. Forcing a single skeleton onto flows that legitimately differ in shape produces awkward, half-used hooks.

**Modern Java/Spring alternative:** Compose instead — pass the varying steps as functional-interface parameters (a "skeleton" method taking lambdas), or inject step strategies. Keep classic Template Method when the step set is fixed, small, and the base genuinely owns the invariant.

**Key review questions:** Are the steps that protect the algorithm's invariants `final`/sealed so a subclass can't silently break the skeleton? Is there really only one axis of variation, or are two independent variations being forced through one inheritance chain? Would a caller ever need to change a step after the object exists — which inheritance precludes?

**Example review comment:** "`AbstractInvoiceJob` now has three subclasses overriding only `enrich()`. Inheritance couples them to the base's protected state. Passing the enrich step as a function into one concrete orchestrator would reuse the skeleton without the hierarchy."

### Factory Method / Factory / Builder

**When it helps:** Creation is complex or scattered, an invariant must hold for every instance, or a constructor takes many parameters (especially several of the same type) where order is easy to get wrong. A `Builder` clarifies optional fields; a factory centralizes branching construction and guards validity.

**Warning signs:** A constructor call with 6+ positional args or several adjacent booleans; the same multi-step construction copy-pasted across call sites; a "factory" whose every method is a one-line `return new X(...)` with no logic.

**When NOT to use:** A factory that only forwards to `new` adds a layer without protecting anything. For a handful of fields a plain constructor or `record` is clearer than a builder.

**Modern Java/Spring alternative:** A `record` with a compact constructor for validation, plus static factory methods (`of`, `from`) that name intent and enforce invariants. For many optional fields, use a builder — but note records do not generate one, so you hand-write or generate it; a record needing many optional fields is itself a hint the carrier may be wrong. Lean on Spring for wiring rather than hand-rolled factories of beans.

**Key review questions:** Is the raw constructor restricted (private/package) so callers can't bypass the intended creation path? Can the builder hand back an incompletely or invalidly configured object — are required fields enforced before `build()`? Does the factory/static method name actually communicate the creation intent?

**Example review comment:** "`new Shipment(...)` here passes five `String`s and two booleans positionally — a silent swap won't fail to compile. A static factory or builder that names each field would protect the invariants and make call sites readable."

### Adapter

**When it helps:** Isolating an external integration, third-party SDK, or legacy interface behind a port your domain defines, so the outside shape can change without rippling inward. Keeps external `DTO`s and protocol quirks at the edge.

**Warning signs:** External/provider `DTO`s imported into domain or application packages; an adapter that, beyond mapping, starts computing discounts, validating `Order`s, or making decisions; mapping logic duplicated at several call sites instead of in one adapter.

**When NOT to use:** Wrapping a stable internal interface you fully control, or adding an adapter for a single call that already matches your needs. An adapter with no translation to do is just a passthrough.

**Modern Java/Spring alternative:** The classic form still fits — define the port as an interface in your domain and implement it in an infrastructure adapter (a Spring component). Keep mapping in a dedicated mapper; the adapter should translate and delegate, not decide. This is also the anti-corruption boundary for legacy/foreign models: translate fully at the edge so legacy concepts never leak inward.

**Key review questions:** What information or capability is lost in this translation, and is that loss acceptable and documented? When converting errors across the boundary, is the original cause preserved (chained), not swallowed? Are there *semantic* — not just syntactic — differences between the two interfaces that the adapter must reconcile?

**Example review comment:** "This adapter now applies `Invoice` rounding rules in addition to mapping the provider response. Business rules here will be invisible to the domain and re-run on every integration. Suggest moving the rounding into the domain and keeping this class to translation only."

### Facade

**When it helps:** Presenting one coherent entry point over a multi-step subsystem so callers (controllers, jobs) don't orchestrate internals — e.g. a single `processOrder` call that coordinates pricing, `Payment`, and `Notification`. Reduces coupling to the subsystem's shape.

**Warning signs:** A facade gaining unrelated methods across many domains; it growing toward hundreds of lines and many dependencies; callers still reaching past it into internals, signaling the abstraction isn't holding.

**When NOT to use:** When the subsystem is one or two calls, a facade just relays. Don't add one speculatively before there's real orchestration to hide.

**Modern Java/Spring alternative:** A focused application service / use-case bean per workflow is the idiomatic facade. Keep each cohesive around one use case; split when it accumulates unrelated responsibilities rather than letting it become a god service.

**Key review questions:** Does this facade expose only what the application needs, or is it mirroring the whole subsystem surface? Are subsystem-internal types leaking through it and re-coupling clients? Is it staying a coordination layer, not absorbing logic that belongs inside the subsystem?

**Example review comment:** "This service has grown to coordinate orders, payments, and reporting in one class with twelve dependencies. It's becoming hard to test and reason about. Consider splitting per use case so each entry point stays cohesive and independently testable."

### Decorator / Proxy

**When it helps:** Layering cross-cutting behavior — caching, authorization, logging, metrics, retries, lazy loading — onto a component without touching its core logic, especially when the wrap is optional or composable per deployment.

**Warning signs:** Cache/auth/logging code interleaved directly into business methods; several concerns hand-stacked in one class; a wrapper added where a single framework annotation would do, or so many layers that the call path becomes hard to follow.

**When NOT to use:** A single fixed concern that an existing aspect (`@Cacheable`, `@Transactional`, security annotations) already covers. Deep decorator stacks make stack traces and debugging painful for little gain.

**Modern Java/Spring alternative:** Prefer Spring AOP / built-in annotations (`@Cacheable`, `@Transactional`, `@PreAuthorize`) for standard cross-cutting needs. Use an explicit decorator bean when the behavior is domain-specific or must compose in a controlled order; keep the layering shallow and named. Note: these annotations are proxy-based — a self-invocation (one method in a bean calling another `@Transactional`/`@Cacheable` method on `this`) bypasses the proxy and the advice silently does not run. Verify the call crosses a bean boundary, or the behavior won't apply.

**Key review questions:** Can this wrapper return without ever invoking the real target — is that intended and visible at the call site? If it adds caching, how are invalidation, concurrent access, and staleness handled? How many layers deep is the stack, and does the order of layers change the outcome (and is that order documented)?

**Example review comment:** "Caching is now woven into `loadCustomer` alongside the lookup itself, so the two can't be tested or changed separately. A `@Cacheable` method or a thin caching decorator would keep the core query clean and the cache policy visible — just confirm it's invoked from another bean, since a same-class call would skip the cache proxy."

### Observer / Domain Events

**When it helps:** Decoupling a producer from consumers when several independent reactions follow one fact — e.g. on `Order` placed, write an `AuditEntry`, send a `Notification`, refresh a `Report`. Lets you add reactions without editing the producer.

**Warning signs:** A method accreting unrelated follow-up calls; a publish with no obvious subscriber, or a listener whose absence silently breaks a flow; ordering or transactional outcome depending on listener execution that isn't spelled out.

**When NOT to use:** When there's exactly one consumer and the call is synchronous and required — a direct method call is simpler, traceable, and easier to debug than an event whose effects are invisible at the call site.

**Modern Java/Spring alternative:** Spring's `ApplicationEventPublisher` with `@EventListener` (and `@TransactionalEventListener` for after-commit reactions). Note that `@TransactionalEventListener(phase = AFTER_COMMIT)` runs after the originating transaction has committed, so its side effect is outside that transaction and cannot roll it back; if the side effect must be atomic with the main work, use a synchronous listener within the same transaction or an explicit call. Use events when fan-out and decoupling are real; prefer a plain call when the relationship is one-to-one and must be obvious.

**Key review questions:** If one listener throws or hangs, are the others still notified — is failure isolated per subscriber? Can subscribers be removed/unsubscribed, or will registrations leak over time? Should notification be synchronous on the producer's thread given listener latency, and is delivery order being relied on implicitly?

**Example review comment:** "Publishing `OrderPlacedEvent` here hides the fact that a `Notification` must follow — there's no visible link, and a missing listener would fail silently. Since this is the only consumer and it's required, a direct call would be more traceable; reserve the event for when fan-out actually appears."

### Chain of Responsibility

**When it helps:** A request flows through an ordered set of handlers — validations, filters, enrichment rules — where several may act and the set changes over time. Each handler stays small and the pipeline is reconfigurable, e.g. a sequence of `Order` validation rules.

**Warning signs:** A long sequence of guard clauses or validation steps inlined in one method; handler order that matters but is implicit; a new rule inserted mid-method where a misordering silently changes behavior with no test pinning the sequence.

**When NOT to use:** Two or three fixed checks that never vary — a straight sequence of calls is clearer than a handler framework. A chain whose order is fragile and undocumented trades one readability problem for another.

**Modern Java/Spring alternative:** An ordered `List<Validator>` of Spring beans (`@Order` or an explicit comparator) iterated explicitly, or a `Stream` of rule functions. This keeps ordering visible and each rule independently testable; reserve the linked-handler form for true short-circuiting pipelines. For HTTP-level concerns, a servlet `Filter` or Spring interceptor is the framework-native chain — don't hand-roll one.

**Key review questions:** Does every handler correctly forward (or intentionally terminate), and is "intentionally stops here" obvious? Is the chain's behavior order-dependent, and if so is that order explicit and tested? Is there a defined end-of-chain behavior rather than an accidental fault?

**Example review comment:** "These six `Order` checks run in one method and the order is load-bearing but implicit — reordering them would change which error surfaces first, with nothing to catch it. An ordered list of named validator beans would make the sequence explicit and each rule testable on its own."

### Command

**When it helps:** When an action must be reified as data — enqueued, retried, scheduled, logged for audit, or executed asynchronously. A `PlaceOrder` or `RefundPayment` carrying its own parameters lets a worker, retry loop, or audit trail treat all actions uniformly.

**Warning signs:** A `Command` interface whose single implementation just forwards to one service method with no extra context, queuing, or undo. A `new XxxCommand(...).execute()` chain that adds an indirection layer over what was a direct call.

**When NOT to use:** Wrapping a trivial, synchronous method call in a command object. If there is no queue, no retry, no undo, and no audit, the wrapper is pure ceremony.

**Modern Java/Spring alternative:** A `Runnable`, `Supplier<T>`, or a small `record` carrying parameters plus a handler often suffices. For async/audit, lean on `ApplicationEventPublisher` events or a job queue. On Java 21+ (Boot 3.2+ with `spring.threads.virtual.enabled`), virtual threads or a structured executor can run reified I/O-bound actions cheaply — verify the Java version and that virtual threads are enabled in the actual project. Reserve an explicit command hierarchy for genuine undo/replay needs (the reified-operation idea remains alive in event sourcing and CQRS).

**Key review questions:** Does turning this operation into an object force it to reach into a collaborator's internals that should stay encapsulated? If commands run remotely or from external input, is execution restricted to known/authorized operations (not an arbitrary-execute surface)? For undo/redo, is history managed correctly — e.g. is the redo stack invalidated after a fresh action?

**Example review comment:** "This `NotificationCommand` wraps a single call to `notificationService.send(...)` with no queuing, retry, or undo. The extra layer adds indirection without behavior — consider calling the service directly until one of those needs is real."

### State

**When it helps:** When behavior genuinely changes with an object's internal status and the transition rules are spreading. If `Order` status drives diverging logic in many methods, modeling states (or transitions) explicitly centralizes the rules and makes illegal transitions hard to express.

**Warning signs:** The same `switch (status)` or `if (status == ...)` ladder copied into several methods, each adding a new branch. New status added by editing many scattered conditionals rather than one place.

**When NOT to use:** A class per state when states are few, stable, and the behavior difference is one or two branches. That trades a readable conditional for a constellation of tiny classes.

**Modern Java/Spring alternative:** An `enum` with abstract methods per constant, or pattern-matching `switch` over a `sealed` interface, captures state-specific behavior without a class explosion. Exhaustive pattern matching for `switch` over sealed types is standard on Java 21+ (preview earlier) — confirm the project's Java version before recommending it. Reserve full State objects for rich per-state data and complex transition graphs.

**Key review questions:** Is the same state-based conditional repeated in several places — i.e. is the state concept implicit and worth making explicit? Does any state need to carry instance-specific data, and is the shared-vs-per-instance representation safe for that? Can a reader still reconstruct the full set of states and legal transitions after this refactor?

**Example review comment:** "The `status` switch now appears in three methods on `Invoice`, and this diff adds a branch to each. Consider moving status-specific behavior onto an enum or sealed type so a new status touches one place, not three."

### Composite

**When it helps:** When clients must treat a single element and a group of elements through one interface, and the structure is genuinely recursive — e.g., a `PricingRule` group composed of nested rule groups evaluated uniformly.

**Warning signs:** A "tree" with a fixed two-level depth, or a leaf type forced to implement `add()`/`remove()` it throws on. Group-handling code that special-cases single vs. many instead of recursing.

**When NOT to use:** When the data is flat or has fixed, shallow nesting. A `List<T>` plus a simple loop is clearer than a composite hierarchy invented for a structure that never recurses. Beware modeling "a collection of X" as a *subtype* of X when it isn't really one of its own elements.

**Modern Java/Spring alternative:** Often a plain collection with a stream traversal, or a `record` tree walked by pattern-matching `switch`, expresses the same intent with less machinery. Keep the classic Composite when the recursion is real and clients must stay oblivious to depth.

**Key review questions:** Does this aggregate genuinely behave as one of its elements in *this* context, or is uniformity being forced? Is the composite sharing an abstraction with the leaves, rather than inheriting a leaf's structure it then ignores? Are recursive operations over the tree bounded and cycle-safe?

**Example review comment:** "`ReportSection` here is always exactly one level deep, yet leaves must implement `addChild()` and throw. If the nesting is fixed, a flat list reads more honestly than a composite that fakes recursion."

### Mediator

**When it helps:** When several components would otherwise hold direct references to each other and coordinate in tangled n-to-n ways. Routing their interaction through one coordinator (or an event bus) cuts the coupling — useful for workflow orchestration across `Shipment`, `Invoice`, and `Notification`.

**Warning signs:** A newly introduced coordinator that keeps absorbing responsibilities — every feature adds another method and another collaborator field, turning it into a catch-all hub.

**When NOT to use:** When only two or three objects collaborate in a stable, readable way. A mediator there adds an indirection that hides a simple, direct call. Beware the mediator that becomes a god object.

**Modern Java/Spring alternative:** Spring's `ApplicationEventPublisher` with `@EventListener` decouples publishers from subscribers without a hand-written hub. For request/response orchestration, an explicit service method is often clearer than a mediator abstraction.

**Key review questions:** Are the interactions complex enough (many participants, real interaction rules) to justify centralizing them? Is the mediator turning into a god-object that knows too much about everyone? With an event-based mediator, can a maintainer still trace who reacts to what?

**Example review comment:** "This coordinator has grown to reference `Order`, `Payment`, `Shipment`, and `Notification` and now owns most of their logic. Consider publishing domain events so each handler subscribes independently, rather than centralizing everything here."

### Visitor

**When it helps:** When you must add new operations across a set of types whose structure is stable, and you would otherwise scatter `instanceof` chains. Visitor concentrates each new operation in one class while the type hierarchy stays put.

**Warning signs:** A per-type dispatch method (a double-dispatch `accept` hook) added over a hierarchy that is still actively gaining new types, forcing every operation class to change with each new element.

**When NOT to use:** When the type set changes more often than the operations, or when the team is unfamiliar with double dispatch. The boilerplate and indirection can outweigh the benefit, and misuse is easy.

**Modern Java/Spring alternative:** Pattern-matching `switch` over a `sealed` interface gives exhaustive, compiler-checked dispatch without the per-type dispatch ceremony — usually the better choice on modern Java, and standard on Java 21+ (preview earlier), so confirm the project's Java version first. Keep the classic Visitor mainly for open hierarchies or codebases that cannot use sealed types.

**Key review questions:** Which changes more often here — the set of element types or the set of operations? (Visitor only pays off when operations vary and element types are stable.) Will adding the next element type force edits across every operation, and is that acceptable? Is this genuinely a many-operations-over-a-fixed-hierarchy problem, or is simpler polymorphism enough?

**Example review comment:** "This adds a per-type dispatch layer over `AuditEntry` subtypes, but the structure is sealed and finite. A pattern-matching `switch` would give the same exhaustiveness with far less scaffolding and no per-type dispatch method."

### Singleton

**When it helps:** Rarely worth a hand-rolled implementation. A legitimate case is a single, immutable, stateless instance with no framework managing its lifecycle — and even then a single immutable `enum` constant is a safer form in plain Java.

**Warning signs:** A `private static` instance with global `getInstance()` access, especially holding mutable state. Code reaching into that static to fetch collaborators, and tests that can't isolate because the instance leaks across them.

**When NOT to use:** Inside Spring, a manual singleton duplicates what the container already guarantees and introduces global mutable state. Almost always the wrong tool here.

**Modern Java/Spring alternative:** Define a singleton-scoped Spring bean (the default scope) and inject it. A default singleton-scoped bean is shared across all request threads, so mutable instance fields are a data race, not just a test-isolation problem — keep such beans stateless, or carry mutable state in method-local variables, a request-scoped bean, or a properly synchronized owned component. For a non-Spring constant, a single `enum` constant is the idiomatic form.

**Key review questions:** Is "exactly one instance" a genuine domain/technical requirement, or just a convenient global? Does this hurt testability — can collaborators substitute a fake, or is the single instance hard-wired? If lazily created, is the initialization safe under concurrency?

**Example review comment:** "`PricingCache` exposes a static `getInstance()` holding mutable state. Under Spring this is a shared singleton across all request threads, so concurrent writes race and corrupt state, and it also leaks between tests. A stateless singleton-scoped bean with state passed explicitly would remove the race and restore test isolation."

### Dependency Injection vs Service Locator

**When it helps:** Constructor injection makes a class's collaborators explicit, final, and visible at construction — the dependencies are right there in the signature, easy to see and to substitute in tests. This is the default to prefer.

**Warning signs:** Classes calling a static locator or global context to fetch collaborators (`ServiceRegistry.get(...)`, a static `ApplicationContext` holder) instead of receiving them. Dependencies that don't appear in the constructor and surface only at runtime.

**When NOT to use:** Service Locator is rarely the right default — it hides dependencies and couples code to the lookup mechanism. Reserve lookup approaches for genuine dynamic-plugin scenarios where the set of collaborators isn't known at construction.

**Modern Java/Spring alternative:** Plain constructor injection — ideally with `final` fields and no field-level `@Autowired`. With a single constructor, no `@Autowired` is needed at all; Spring wires it automatically (Spring 4.3+), which is the idiomatic Boot 3.x form. When a choice among implementations is needed at runtime, inject a `Map<String, Handler>` or a factory rather than reaching into a locator.

**Key review questions:** Are mandatory dependencies injected via the constructor so the object can't exist unwired (optional ones via setters)? Is there integration/wiring-level coverage proving the assembler actually wires this, not just unit tests with fakes? Does an absent dependency fail clearly at startup rather than as a late null dereference?

**Example review comment:** "`ReportGenerator` pulls its `Formatter` from a static registry, so the dependency is invisible in the constructor and hard to stub in tests. Injecting it as a constructor parameter would make the collaborator explicit and the class testable without global setup."

## Anti-Patterns

- **Pattern for pattern's sake** — A diff introduces an interface, an abstract base class, and one concrete implementation to do what a single concrete method already did. Harm: more indirection to read, more files to navigate, no added flexibility; reviewers and future maintainers pay a comprehension tax for nothing. Fix: inline the concrete logic; reintroduce the abstraction only when a second real case appears.

- **Factory that only calls `new`** — A `SomethingFactory.create(...)` whose body is a single `return new Something(...)` with no branching, no caching, no validation. Harm: an extra hop that hides a plain constructor and obscures what is actually built. Fix: call the constructor directly, or use constructor injection / a static factory method only if it adds naming or validation value.

- **Strategy with a single implementation** — A `Strategy` interface with exactly one implementing class and no concrete second case on the horizon. Harm: the reader must chase an interface to find the only behavior, and dependency wiring is harder to follow. Fix: collapse to the single class until a real variant is needed; the interface can be extracted later in minutes.

- **Service locator hiding dependencies** — Code pulls collaborators from a global registry or context lookup (`Locator.get(PaymentClient.class)`) instead of receiving them. Harm: dependencies become invisible at the call site, tests need global setup, and coupling is untraceable. Fix: inject collaborators via the constructor so the type signature states what the class needs.

- **Singleton as global mutable state** — A class exposing a static `INSTANCE` holding mutable fields that handlers read and write. Harm: hidden shared state, race conditions and state corruption under concurrency, order-dependent tests, and impossible-to-mock seams. Fix: model it as a stateless Spring bean (default singleton scope) with state passed explicitly, or hold mutable state in a properly synchronized, owned component.

- **Facade becoming a god service** — A class introduced to simplify a subsystem slowly absorbs unrelated orchestration until it has many dependencies and a grab-bag of methods. Harm: a single high-churn merge-conflict magnet that is hard to test and reason about. Fix: split by responsibility into focused collaborators; keep the facade thin or remove it.

- **Observer / event with invisible side effects** — A diff publishes an event (or registers a listener) where a critical effect — persisting an `Invoice`, charging a `Payment` — happens in an unseen handler. Harm: control flow and failure handling become non-obvious; an exception or missing listener silently drops work. Fix: for required, transactional effects prefer an explicit method call; reserve events for genuinely decoupled, observable, non-critical reactions.

- **Adapter that leaks external DTOs inward or accumulates business rules** — An adapter/mapper returns third-party response types into the domain, or grows pricing/validation logic instead of just translating. Harm: the external contract bleeds across the codebase (a vendor change ripples everywhere) and business rules hide in a translation layer. Fix: map to domain types at the boundary and keep the adapter translation-only; move rules into the domain.

- **Inheritance where composition is simpler** — A subclass extends a base only to reuse a couple of helper methods or override one hook, dragging in unwanted protected state. Harm: fragile base-class coupling, constrained single-inheritance budget, surprising overrides. Fix: compose — inject the collaborator and call it, or pass behavior as a functional interface.

- **Abstraction introduced before any variation exists** — Generic type parameters, plugin registries, or extension points added for a future that has not arrived and is not on the roadmap. Harm: speculative generality that is harder to read and often wrong when the real requirement lands. Fix: write the concrete code now; extract the abstraction when the second case forces it.

## Modernization Rule

Treat classic class-based pattern implementations as conceptual inspiration only. The pattern's *intent* may still be valid, but the traditional class structure rarely is the best expression of it in a modern Java/Spring codebase. Prefer the simpler, safer, more idiomatic solution the platform already gives you.

**Inspect the target project first — do not assume.** Before recommending any pattern, the reviewer MUST examine the actual repository to establish: the Java version, the Spring Boot version, the DI framework, the build tool, the libraries already on the classpath, the existing coding conventions, and the architecture style in use. Recommendations must fit what the project actually is, not a generic template. When official or current documentation for the project's stack is available, prefer it over older pattern guidance.

**Five questions to answer before recommending any pattern:**
1. Is this pattern still useful *here*, given the concrete problem in the diff?
2. Is there a simpler modern Java or Spring alternative that achieves the same goal?
3. Does the project already provide a framework feature that solves this?
4. Would the classic pattern increase complexity rather than reduce it?
5. Would *not* using it create real maintenance, testability, extensibility, or production risk?

If the honest answers point to "no real risk and a simpler alternative exists," the recommendation is **no pattern**.

**Modern alternatives to reach for first:**
- **Strategy** — Spring beans selected by qualifier or type, a `Map<String, Handler>` of injected beans keyed by discriminator, an `enum` with behavior per constant, or a plain functional interface / lambda. A full interface-plus-classes hierarchy is rarely needed.
- **Factory** — often unnecessary given constructor injection, static factory methods, builders, or Spring configuration (`@Bean` methods). Reserve a real factory for genuine runtime branching or non-trivial construction.
- **Singleton** — use bean scope (the default singleton-scoped bean), not a hand-rolled static `INSTANCE`. Manual singletons fight testing and concurrency.
- **Observer** — Spring's `ApplicationEventPublisher` for in-process decoupling, a message broker or queue for cross-process events, or simply an explicit method call when coupling is fine and observability matters more. Choose based on the coupling and traceability you actually need.
- **Template Method** — prefer composition (inject the varying step as a collaborator or functional interface) when inheritance would create base-class coupling.
- **Adapter** — usually already present in the codebase as a mapper, gateway, client wrapper, or hexagonal port/adapter; recognize the existing one before adding another.
- **Builder** — unnecessary for simple immutable objects (a `record` is enough), but genuinely useful for objects with many optional fields or construction invariants to enforce.
- **Service Locator** — discouraged; it hides dependencies that injection would make explicit. Recommend against it.
- **Visitor** — only worthwhile for a stable, rarely-changing structure operated on by a team comfortable with the double-dispatch indirection. Otherwise it is overhead; a sealed type with pattern matching usually wins.
- **Chain of Responsibility** — only with clear, explicit ordering and traceability of which link handled what; for HTTP concerns use the framework-native filter/interceptor instead of a hand-rolled chain.

**Modern features worth referencing** (accurately, and always as "verify against the actual project"): `record` types for immutable carriers, `sealed` types to model closed hierarchies, pattern matching for `switch` to replace visitor-like dispatch (standard on Java 21+, preview earlier), virtual threads for high-concurrency I/O (Java 21+, enabled via `spring.threads.virtual.enabled` on Boot 3.2+), functional interfaces and lambdas for small strategies, and Spring Boot 3.x idioms such as constructor injection and `ApplicationEventPublisher`. Frame every version-specific claim as something to confirm by inspecting the project's build file and configuration — never assume a version or an available API.

## Per-Pattern Recommendation Format

When the review recommends (or rejects) a pattern, emit one block per candidate:

```md
### Pattern Candidate: <name>
Current Problem: <what in the diff motivates considering a pattern>
Classic Pattern Approach: <how the traditional class-based form would solve it>
Modern Alternative: <the simpler idiomatic Java/Spring option, or "none needed">
Recommendation: <Use / Do not use / Consider only if...>
Why: <consequence-focused justification tied to this code>
Severity: <MUST / SHOULD / NIT / NO_COMMENT>
```

Remember: a pattern is not the goal; simpler, safer, more maintainable code is.

## Suggested PR Comment Style

Keep comments respectful, ready-to-paste, and always anchored to a concrete consequence — name what will go wrong (or what improves) so the author can weigh the trade-off rather than feel judged. State the severity honestly; a nit should read like a nit, not a blocker. Offer the alternative, not just the objection.

Example openers:
- "Could we consider..."
- "This may become risky because..."
- "I'd avoid introducing this pattern here because..."
- "This abstraction seems useful because..."
- "This looks like a nit, not a blocker..."

Example comments (neutral-domain):
- "This looks like a nit, not a blocker — the `OrderFactory` only calls `new Order(...)`. Could we use the constructor directly and drop the extra hop? It's one less indirection to follow."
- "This may become risky because the `Notification` is sent inside an event listener, so a missing or failing handler silently drops it. For a required side effect, I'd prefer a direct call so the failure surfaces in the request path."
- "This abstraction seems useful because we now have two real `PricingRule` variants selected at runtime; a small `Map` of injected handlers keyed by type would keep the wiring visible. Happy to leave it as-is if a second variant isn't actually coming."

## Integration With java-pr-review

The main skill uses this lens as a judgment aid, not a checklist to enforce:

- Do not emit a comment merely because a pattern is absent. Absence is only worth raising when you can name the concrete consequence of that absence.
- Comment only when there is a real, articulable consequence — a bug, a maintainability cost, a testability barrier, a contract risk.
- Never block or gate a PR on a pattern preference. Preferences are NIT at most.
- Always tag findings with `MUST`, `SHOULD`, or `NIT` so the author can triage by severity.
- Prefer a few strong, specific comments over many generic ones. One well-justified MUST or SHOULD is worth more than a list of pattern-name observations, and unjustified suggestions should be dropped to NO_COMMENT rather than padded into the review.
