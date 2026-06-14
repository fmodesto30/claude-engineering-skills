# DDD Lens

Reusable Domain-Driven Design knowledge for Java/Spring: when modeling a boundary, an aggregate, or a value object pays for itself, and when DDD tactics are ceremony on a problem that does not have the complexity to justify them. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

Today this lens has one consumer: **`architecture-review`**, which applies it at **system/design altitude** — boundaries, model integrity, consistency rules, data ownership, and how the design will evolve — not line-by-line PR nitpicking. The review-flavored sections below (severity calibration, comment style, integration contract) are written for that design-review intent: *do the boundaries and the model hold together as the system changes, or is the design either leaking across contexts or paying for DDD machinery it does not need?*

The same knowledge could later serve `java-pr-review` at a smaller altitude — a single diff that introduces an aggregate, a domain event, or a repository — with a *different*, narrower intent. That is why it lives in `lenses/`. But the lens is **not** generalized for that second consumer now: it stays focused on the design-review questions a reviewer can actually answer from a boundary map and a model, and a neutral core is extracted only when a second real consumer exists. A consuming skill loads it only when the design or diff actually touches the structural areas in "When to Use" below — never just because the words "aggregate" or "bounded context" appear in a name, a package, or a design doc.

## Purpose

This lens helps the reviewer judge whether the domain-modeling decisions in a Java/Spring design actually serve correctness and changeability, or whether they are structure copied by rote. Its job is to separate model integrity that protects real invariants and real boundaries from tactical pattern ceremony applied out of habit or aspiration. The default bias is toward the simplest model that satisfies the requirement: a transaction script and a few CRUD tables are a legitimate, often correct, design. When the design introduces a boundary, a consistency rule, or a tactical building block (aggregate, value object, domain event, repository), the lens gives the reviewer a consistent way to ask "does this structure protect something concrete, and is the boundary in the right place?" and to phrase the answer as a consequence-anchored finding rather than a methodology preference. It is equally a tool for restraint — for confirming that the *absence* of a bounded context, an aggregate, or a rich domain model is correct, and that no comment is warranted.

## When to Use

Consult this lens when the design or diff does something structural at the domain level, including:

- A new boundary between subsystems is drawn or moved (a new bounded context such as Ordering, Billing, Shipping, or Notification, or a split/merge of existing ones).
- A model type is shared across more than one context (the same `Customer` or `Order` class, table, or schema read or written from two contexts).
- A single transaction (or unit of work) mutates more than one aggregate, or a consistency rule is asserted to hold synchronously across aggregates.
- A new aggregate, entity, or value object is introduced, or an existing entity gains or loses identity.
- Domain events are introduced, published, or relied on for a side effect or for cross-context propagation.
- An integration with a foreign or legacy model appears (an external partner schema, a vendor SDK, a legacy database whose concepts differ from the domain).
- The persistence shape is decided or changed — repositories, JPA mappings, the granularity of what gets loaded and saved together.
- Dependency direction across layers is set or altered (does the domain depend on the framework/persistence, or the reverse?).

Do NOT engage this lens merely because a DDD term appears in a class name, a package name, a comment, or a design document. `OrderAggregate`, `CustomerRepository`, `PricingService`, or a package called `domain` is not itself a reason to engage — the trigger is a structural decision about boundaries, consistency, ownership, or model shape, not the vocabulary used to label it. A plain CRUD application that happens to use these words is not a DDD problem.

## Core Principle

Domain-Driven Design is a tool, not an objective. Model integrity matters **only** insofar as it makes the system safer to change and harder to get into a wrong state. The fact that a design matches a named DDD building block is never, by itself, a reason to adopt it, and never a reason to praise it. A modeling decision earns its keep only when it does concrete work:

- Protects a real invariant that must always hold (an `Order` total must equal the sum of its `LineItem`s; an `Invoice` cannot be issued twice).
- Draws a boundary where two parts of the business genuinely change for different reasons and at different speeds, so the boundary lets them evolve independently.
- Keeps a foreign or legacy model from leaking its concepts inward, so a change outside cannot ripple through the domain.
- Makes an illegal state unrepresentable or hard to express, rather than relying on every caller to remember a rule.
- Gives a tangled responsibility a clear seam that improves testability or comprehension.
- Names a transactional consistency boundary so the team knows what is atomic and what is eventual.

If none of these apply, the correct recommendation is **no DDD machinery**. Keeping a transaction script, an anemic record, or a single shared model is a valid outcome and is frequently the best one. **Tactical DDD ceremony without real domain complexity is overengineering** — aggregates wrapped around single rows that have no invariants, value objects with no behavior and no equality semantics that matter, repositories over non-aggregate tables, domain events fired for a single synchronous consumer. This lens leans hard against dogma: DDD is the most over-applied methodology in this set, and the most common correct finding is restraint. **"No comment" is a valid, frequent, and correct outcome.**

## Severity Calibration

Apply these four levels to DDD findings (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md) for the shared definitions):

- **MUST** — A modeling decision causes a concrete defect or serious hazard now: a transaction that mutates several aggregates and so risks lock contention, deadlock, and a torn write that leaves the system in an inconsistent state; a mutable value object shared and aliased so one holder's mutation silently corrupts another's data; a cross-context read-write share of a model where one context's change breaks the other and the coupling is invisible; an invariant that *should* be enforced inside an aggregate but is instead spread across services so one path forgets it and persists corrupt state; a domain event that is the only thing performing a required, atomic side effect but runs after the originating transaction commits, so a failure leaves the work half-done with no rollback. These must be raised and must explain the failure mode.
- **SHOULD** — No defect today, but a specific modeling change would clearly improve changeability, correctness, or comprehension, and you can state the concrete benefit: a boundary drawn in the wrong place so two genuinely independent concerns must be deployed and changed together; an invariant enforced by convention that would be safer pulled into the aggregate; an anti-corruption seam that is missing where a foreign model is starting to leak inward. Raise it when the benefit is real and nameable.
- **NIT** — Naming of a building block, package placement, or an optional structural preference with no behavioral consequence (calling a class `OrderService` vs `OrderApplicationService`). Worth a brief note, never a blocker.
- **NO_COMMENT** — The suggestion would be pure taste or speculative methodology: "this should be an aggregate" / "extract a value object here" / "this is anemic" when the code is honest CRUD with no invariant to protect and no consequence to name. Stay silent. This is the most common outcome for this lens.

**Overriding rule:** every finding must name a concrete consequence — what breaks, what gets harder, what risk materializes, or what concretely improves. "This isn't a real aggregate" / "the model is anemic" / "this violates a bounded context" is **not** a finding. "This model is written by both the Ordering and Billing contexts, so a column Billing adds for tax will silently change Ordering's persistence and there is no test across that seam" **is**. If no concrete consequence can be articulated, the finding is NO_COMMENT, no matter how far the design diverges from a textbook DDD shape. Style (formatting, naming-case, import order, `this.`, whitespace) belongs to linters, never to review.

## Review Questions

Before raising or accepting a DDD modeling decision, the reviewer should be able to answer:

- Does this domain actually have invariants and rules worth protecting, or is it CRUD where a transaction script is honest and sufficient?
- Where is the transactional consistency boundary, and is it exactly one aggregate per transaction? If a transaction touches several aggregates, what serializes them and what happens on partial failure?
- Is a model shared across contexts, and if so, is the sharing read-only and stable, or read-write so a change in one context can break the other?
- For each boundary, do the two sides genuinely change for different reasons? If they always change together, is the boundary buying anything?
- When two contexts integrate, what is the relationship — does one conform to the other, is there a translation layer, is there a published contract — and does the design name it or leave it implicit?
- Is an invariant enforced in one place (inside the aggregate) or re-asserted by every caller, so one path can forget it?
- Does the "repository" hand back and accept whole aggregates, or is it CRUD over arbitrary rows wearing the name?
- Is a value object actually immutable, and does its equality reflect its value rather than an identity it does not have?
- Does a domain event hide a required, critical side effect that should be a visible, atomic call? What happens if the listener is missing or throws?
- Does the domain depend on the framework and persistence, and if so, what concrete change does that coupling make harder?

## Heuristics

### Ubiquitous Language

**What to look for:** The same business concept named differently in different parts of the design (a `Customer` here, an `Account` there, a `Party` in a third place, all meaning the same thing), or one name meaning different things in different contexts without that being acknowledged. In code, watch for domain types named after technical artifacts (`OrderData`, `OrderDTO` used as the model) rather than the term the business uses.

**Why it matters:** When the model and the business use different words for the same thing, every conversation needs a translation step, and the mismatch hides real disagreements about meaning. The concrete cost is misdiagnosed requirements and code that quietly models the wrong concept — a `Customer` that is actually a billing account, so a rule about "one customer, one address" is wrong because a customer can have several billing accounts.

**When NOT to comment:** When two contexts legitimately use the same word for different concepts — that is normal and healthy across a boundary (a `Customer` in Ordering is a buyer; a `Customer` in Billing is a payer). Do not force one global vocabulary across contexts; that is the mistake, not the fix. Synonyms that are obviously the same and cause no confusion are taste, not a finding.

**Modern Java/Spring idiom:** Name domain types after the business term, and keep that name consistent *within* a context's package. Let each bounded-context package carry its own vocabulary; a shared "common" model that tries to be everyone's `Customer` is usually the smell, not the solution.

**Key review questions:** Does this name match the term the business uses for this concept in this context? Is the same word being used for two different concepts without a boundary between them, or two words for one concept within one context?

**Example review comment:** "SHOULD: `Account`, `Client`, and `Customer` are used interchangeably across the Ordering package for the same concept. The mismatch makes it ambiguous which rules apply to which — a reader can't tell if `Account.creditLimit` and `Customer.tier` describe the same entity. Settling on one term inside this context would remove that ambiguity. Not a blocker."

### Bounded Contexts & Boundaries

**What to look for:** A boundary being drawn, moved, or erased — a new context, or two contexts being merged into one shared model. The key signals are: a single model serving two parts of the business that change for different reasons; or, conversely, a boundary so fine-grained that every change requires editing several contexts in lockstep.

**Why it matters:** A boundary in the right place lets two parts of the system evolve and deploy independently; a boundary in the wrong place does the opposite. If Ordering and Billing share one model, a change Billing needs (a new tax field, a different lifecycle) forces a change in Ordering and a coordinated redeploy, and a bug in one context's use of the model can corrupt the other's. If the boundary is too fine, you pay coordination cost with no independence in return.

**When NOT to comment:** A small system with one team, one deployable, and one coherent model does not need multiple bounded contexts. Splitting a modest application into "contexts" because the methodology says so adds package ceremony and integration overhead for no concrete benefit — that is overengineering, and the finding is NO_COMMENT (or a SHOULD *against* the split if it is actively making changes harder). Do not propose a context map for an app that has one context.

**Modern Java/Spring idiom:** Package-by-bounded-context (a top-level package per context, each owning its model, services, and persistence) keeps the boundary visible and enforceable. Spring Modulith can verify that contexts depend on each other only through declared APIs and events, turning the boundary into something the build checks rather than a convention — verify Spring Modulith is actually a dependency before recommending it; never assume it is on the classpath.

**Key review questions:** Do the two sides of this boundary change for genuinely different reasons and at different speeds? If they always change together, what is the boundary buying? If they are merged into one model, what change in one will be forced on the other?

**Example review comment:** "SHOULD: this design has Ordering and Shipping writing the same `Order` rows. They change for different reasons — Shipping adds its own delivery lifecycle states, Ordering adds pricing — so each change forces a coordinated migration and redeploy of both, and a Shipping write can violate an Ordering invariant unnoticed. Consider giving Shipping its own `Shipment` keyed by order id, so the two evolve independently. Worth weighing against the integration cost."

### Context Mapping & Integration Relationships

**What to look for:** A point where two contexts (or a context and an external/legacy system) integrate, and *how* the relationship is structured. Watch for the relationship being left implicit. The named shapes worth recognizing: an **anti-corruption layer** (a translation boundary that keeps a foreign model from leaking in); a **conformist** relationship (the downstream simply adopts the upstream's model wholesale); a **shared kernel** (two contexts deliberately share a small, jointly-owned model); a **customer–supplier** relationship (downstream needs drive upstream priorities); and **open-host service / published language** (the upstream offers a stable, documented contract for all consumers).

**Why it matters:** Naming the relationship makes its cost and its failure mode visible. An anti-corruption layer costs translation code but contains the blast radius of an external change to one place. A conformist relationship is cheap but means every upstream change ripples straight into your model. A shared kernel is convenient but couples two teams' release cycles. If the relationship is implicit, the team discovers its cost the hard way — a vendor's field rename breaks the domain in twelve places because there was no translation seam.

**When NOT to comment:** When the integration is a single stable internal call between two contexts owned by the same team with a coherent shared vocabulary, naming a formal relationship type is ceremony. Do not demand an anti-corruption layer for a stable internal collaborator whose model already fits — an ACL with nothing to translate is a passthrough. Reserve the heavier seams for genuinely foreign or volatile models.

**Modern Java/Spring idiom:** An anti-corruption layer is the Adapter pattern applied at a context boundary — define the port the domain needs as an interface in the domain, implement it in an infrastructure adapter that translates the foreign model fully at the edge, and keep external DTOs out of the domain (see [`./design-patterns.md`](./design-patterns.md), Adapter). A published language is often a versioned API contract or a shared event schema; an open-host service is the stable API a context exposes to all consumers. Domain events across contexts are a common integration mechanism — but a cross-context event is a published contract, so changing its shape breaks consumers (see Domain Events below).

**Key review questions:** What is the integration relationship here, and is it named in the design? If the upstream/foreign model changes, how many places inward does that change reach? Is there a translation seam, or do foreign concepts flow straight into the domain?

**Example review comment:** "MUST: the Billing context imports a third-party tax-rate provider's response DTOs directly into its domain services and persists them. There is no translation seam, so when the provider renames a field — which their changelog says is coming — the domain breaks wherever those DTOs are read, not in one adapter. An anti-corruption layer (a port the domain owns, an adapter that maps the provider model to a domain `TaxRule` at the edge) would contain that change to one class. This is the Adapter boundary described in the design-patterns lens."

### Aggregates & Consistency Boundaries

**What to look for:** An aggregate being defined, and specifically (1) whether it references other aggregates by object reference or by identity, (2) how many aggregates a single transaction mutates, and (3) whether the aggregate actually has invariants to protect. The strongest signal of a problem is one transaction (or one `@Transactional` method, or one save) creating or updating several distinct aggregate roots together.

**Why it matters:** An aggregate is the **transactional consistency boundary**: it is the unit that is loaded, mutated, and saved atomically, and whose invariants must hold at the end of every transaction. The disciplines that follow from that are concrete, not stylistic. **Reference other aggregates by identity (an id), not by object reference** — holding a direct reference invites loading and mutating the other aggregate in the same transaction, which erases the boundary. **Modify one aggregate per transaction**; a transaction that locks and writes several aggregates increases lock contention and deadlock risk and blocks the system from scaling those writes independently, and a partial failure can leave the set torn. **Consistency across aggregates is eventual**, typically propagated by a domain event after commit. When an aggregate has no invariant at all — it is a single row no rule constrains — calling it an aggregate is just vocabulary.

**When NOT to comment:** When the "aggregate" is genuinely CRUD with no invariant spanning its parts, do not insist on aggregate discipline — there is nothing to protect, and the ceremony costs comprehension. When a transaction legitimately touches one aggregate plus an append-only `AuditEntry` write, that is usually fine; do not treat every second write as a multi-aggregate violation if it carries no invariant. Eventual consistency is not free — if the business genuinely requires two things to be atomically consistent, forcing them into separate aggregates "because the rule says one per transaction" can be the wrong call; weigh it.

**Modern Java/Spring idiom:** Model the aggregate root as the entity callers load and save; hold child entities and value objects inside it; reference *other* roots by their id type (`CustomerId`, `OrderId`) rather than by mapping a JPA `@ManyToOne` to the other root. Keep one repository per aggregate root. Propagate cross-aggregate consistency with a domain event published on commit and handled in a separate transaction (see Domain Events). Note that JPA cascade mappings and lazy associations make it easy to accidentally load and mutate a neighboring aggregate — verify what a save actually touches.

**Key review questions:** What invariant does this aggregate protect, and is it real? How many aggregates does this transaction mutate, and if more than one, what serializes them and what happens on partial failure? Does it reference other aggregates by id or by object reference?

**Example review comment:** "MUST: `placeOrder` updates the `Order`, decrements the `Customer`'s loyalty balance, and marks the `Invoice` issued, all in one `@Transactional` method writing three aggregate roots. Under concurrency this widens the lock footprint across three tables — contention and deadlock risk rise, and a failure after the `Order` write but before the `Invoice` write leaves a torn state. Keep the transaction to the `Order` aggregate and propagate the loyalty and invoicing effects via a domain event handled in its own transaction, accepting that those become eventually consistent. If the business truly requires all three atomic, that is a sign the aggregate boundary itself is wrong — worth discussing."

### Entities vs Value Objects

**What to look for:** A new domain type, and whether it is being modeled as an **entity** (has identity and a lifecycle; two instances with the same field values are still distinct) or a **value object** (defined entirely by its values; no identity; interchangeable when equal — `Money`, a `TaxRule` rate, an address). The common mistakes: giving identity to something that is really a value (a `Money` row with a surrogate id), or treating something with a real lifecycle as an interchangeable value.

**Why it matters:** Value objects must be **immutable** and compared by value; that immutability is what makes them safe to share and pass around freely. If a value object is mutable and shared, two holders alias the same instance and one's mutation silently changes the other's — a `Money` whose `amount` is mutated in place corrupts every `LineItem` that happened to share it. Modeling a value as an entity adds identity, lifecycle, and equality semantics it does not need, and tempts a repository and a table that buy nothing. Modeling an entity as a value loses the identity the business actually tracks.

**When NOT to comment:** When a type is a plain immutable carrier and the distinction has no behavioral consequence, do not litigate the label. Whether a small immutable holder is "officially" a value object is taste; the finding only exists if mutability or identity causes a concrete problem.

**Modern Java/Spring idiom:** A `record` is the idiomatic value object in modern Java — immutable by construction, value-based `equals`/`hashCode`, with a compact constructor for validation (verify the project's Java version supports records; they are GA since Java 16). For JPA, a value object embedded in an entity maps with `@Embeddable`/`@Embedded`; verify the persistence approach the project uses before recommending a mapping. Entities keep an explicit identity field and equality based on that identity, not on all fields.

**Key review questions:** Is this defined by its values (interchangeable when equal) or does the business track its identity over time? If it is a value, is it immutable, and is it ever shared and then mutated? If it is an entity, is its equality based on identity rather than on mutable fields?

**Example review comment:** "MUST: `Money` is a mutable class with a setter on `amount`, and the same `Money` instance is shared across several `LineItem`s when they have the same price. Mutating it for one line silently changes the others, and the total is wrong with no exception. Making `Money` an immutable `record` (verify the project's Java version) removes the aliasing hazard — each line holds an independent value."

### Domain Events

**What to look for:** A domain event being introduced — published when something business-meaningful happens (`OrderPlaced`, `PaymentCaptured`) — and what reacts to it. The critical signals: an event whose only consumer performs a *required* side effect; an event published inside a transaction whose listener runs after commit; and an event used where there is exactly one synchronous consumer.

**Why it matters:** Domain events decouple a producer from several independent reactions and are the natural way to propagate consistency across aggregates and contexts. But they also make control flow invisible at the call site, which is fine for genuinely decoupled reactions and dangerous for required ones. The most important technical fact: **`@TransactionalEventListener(phase = AFTER_COMMIT)` runs after the originating transaction has committed**, so the listener's side effect is *outside* that transaction and cannot roll it back. If that side effect is required to be atomic with the originating work (it must happen, or the whole thing must fail), an after-commit listener is the wrong mechanism — a commit followed by a listener failure leaves the work half-done with no rollback. For an atomic effect, use a synchronous listener within the same transaction, or a direct call. (See [`./design-patterns.md`](./design-patterns.md), Observer, for the same hazard at PR altitude.)

**When NOT to comment:** When there is exactly one consumer, the reaction is synchronous and required, and traceability matters, a direct method call is simpler and the event is ceremony — but only raise this if you can name the cost (a hidden required side effect, a missing-listener failure mode). When the event genuinely fans out to several independent, non-critical reactions (audit, notification, a read-model refresh), the event is the right tool and absence of one would be the smell.

**Modern Java/Spring idiom:** `ApplicationEventPublisher` to publish, `@EventListener` for synchronous in-transaction reactions, and `@TransactionalEventListener(phase = AFTER_COMMIT)` for reactions that must only run once the work is durably committed (e.g. sending a `Notification` only after the `Order` is saved, so a rolled-back order never notifies). Choose the phase deliberately: AFTER_COMMIT for "only if it really happened, and a failure here must not undo the order"; a synchronous listener (or direct call) for "must be atomic with the order." Note that an AFTER_COMMIT listener runs after the original transaction has already closed, so any DB write inside it is non-transactional by default and may be silently lost unless the listener opens its own transaction (e.g. `@Transactional(propagation = REQUIRES_NEW)`); reserve AFTER_COMMIT for external, retry-safe effects like a `Notification` rather than further DB mutation. For cross-context propagation, an event is a *published contract* — changing its shape breaks consumers, so version it as you would an API.

**Key review questions:** Is this side effect required and atomic with the originating work, or an independent reaction? If it is an after-commit listener, is it acceptable that the originating transaction is already committed and cannot be rolled back if the listener fails? If the listener were missing or threw, what breaks, and would anyone notice?

**Example review comment:** "MUST: the `Invoice` is issued in a `@TransactionalEventListener(AFTER_COMMIT)` on `OrderPlaced`. Because that listener runs after the order transaction commits, if invoicing throws, the order is already persisted and there is no rollback — you get an order with no invoice and no error surfaced. If invoicing must be atomic with placing the order, do it synchronously in the same transaction (or as a direct call); reserve AFTER_COMMIT for effects that are safe to lose or retry independently, like sending the `Notification`."

### Repositories

**What to look for:** A repository being introduced, and *what* it is a repository of. The key distinction: a DDD repository is a **collection-like abstraction for one aggregate root** — you add a whole aggregate, get one back by identity, and save it as a unit. Watch for repositories over non-aggregate entities, repositories that expose arbitrary partial updates or column-level CRUD, and the conflation of a DDD repository with a Spring Data interface.

**Why it matters:** A repository that hands back and accepts whole aggregates preserves the aggregate's invariants — you cannot persist half of one. A "repository" that is really row-level CRUD over arbitrary tables lets callers load and save fragments, which is exactly how an aggregate's invariant gets violated (you update a `LineItem` row without going through the `Order` that enforces the total). The important nuance: **a DDD Repository is a different concept from a Spring Data `Repository` interface.** Spring Data is convenient and idiomatic, but its `JpaRepository`/`CrudRepository` over *every* entity tempts teams to expose CRUD on non-aggregate rows, dissolving aggregate boundaries — the framework makes the wrong thing easy.

**When NOT to comment:** In a genuine CRUD application with no aggregates and no invariants, a Spring Data repository per table is the honest, correct design — do not impose aggregate-repository discipline where there are no aggregates to protect. The finding exists only when treating a non-aggregate as freely-savable actually lets an invariant be violated.

**Modern Java/Spring idiom:** One Spring Data repository per **aggregate root**, typed to the root, exposing find-by-id and save of the whole aggregate; do not create repositories for the root's internal entities (persist them through the root via cascade or explicit aggregate save). Where Spring Data's generated CRUD would expose non-aggregate writes, constrain the repository interface to the aggregate-level operations the domain actually needs. Verify the project's persistence stack (Spring Data JPA, JDBC, etc.) before recommending a specific repository shape.

**Key review questions:** Is this a repository of an aggregate root, or CRUD over an arbitrary entity? Can a caller persist a fragment of an aggregate through it, bypassing the root's invariants? Is a Spring Data interface being treated as the aggregate boundary when it is really table-level access?

**Example review comment:** "SHOULD: there's a `LineItemRepository` exposing `save(LineItem)` alongside `OrderRepository`. `LineItem` is internal to the `Order` aggregate, and saving one directly lets a caller change a line's price without going through `Order`, which is what enforces 'total equals sum of lines.' Persisting line items only through the `Order` aggregate keeps that invariant enforceable. Drop the standalone repository unless there's a real need it serves that I'm missing."

### Domain Services vs Application Services

**What to look for:** Logic being placed in a service, and which *kind* of service it is. A **domain service** holds domain logic that does not naturally belong to a single entity or value object (a calculation spanning several aggregates, a policy that is genuinely stateless domain behavior). An **application service** orchestrates a use case — it loads aggregates, calls domain logic, manages the transaction, and coordinates infrastructure — but holds no business rules itself. The smell is each one doing the other's job: business rules living in the application/orchestration layer, or orchestration and transaction management leaking into a domain service.

**Why it matters:** When business rules live in the application service (or controller), the same rule gets re-implemented in every use case that needs it, so one path forgets it and the model is inconsistent. When a domain service grows transaction management and infrastructure calls, the domain logic becomes untestable without the framework and the rule is tangled with plumbing. Keeping the split clean means the rule lives in one place and the orchestration is thin and testable.

**When NOT to comment:** A simple use case that loads one aggregate, calls a method on it, and saves does not need a separate domain service — the logic belongs on the aggregate, and one application service is enough. Do not split a thin, honest service into "domain" and "application" halves on principle; that is ceremony. The finding exists when a concrete rule is duplicated or a rule is untestable because of tangling.

**Modern Java/Spring idiom:** Application service = a `@Service`/`@Transactional` bean per use case that loads aggregates via repositories, invokes domain behavior, and commits — this is the Facade/use-case role from [`./design-patterns.md`](./design-patterns.md). Domain service = a plain, framework-light class (often no Spring annotation, no transaction) holding the cross-entity rule, easily unit-tested. Put behavior on the aggregate first; reach for a domain service only when the logic genuinely spans aggregates or belongs to none.

**Key review questions:** Is a business rule living in the orchestration layer where it will be duplicated across use cases? Could the same rule be invoked from two paths, and would both stay consistent? Is the domain logic testable without standing up the framework and a transaction?

**Example review comment:** "SHOULD: the discount calculation lives in `OrderApplicationService.placeOrder`, and the same calculation is copied into `OrderApplicationService.reprice`. When the discount policy changes, both must be edited and one will be missed, leaving the two paths inconsistent. Moving the calculation onto the `Order` aggregate (or a small stateless domain service both call) keeps the rule in one place and unit-testable without the transaction. Not blocking."

### Rich vs Anemic Model

**What to look for:** Domain entities that are bags of getters and setters with all behavior in services (an **anemic** model), versus entities that own their data and the rules that protect it (a **rich** model). The signal worth acting on is not anemia itself — it is an invariant enforced *outside* the entity by every caller, so a single path can skip it.

**Why it matters:** **An anemic model is not automatically wrong.** For genuine CRUD — data in, data out, no invariant — an anemic record plus a service is the simplest honest design, and forcing behavior onto it is ceremony. The model becomes a problem only when there is a real invariant and it lives outside the entity: if "an `Order` cannot be confirmed with zero `LineItem`s" is checked in three different services, the fourth service that confirms an order will forget, and the system persists an invalid order. Pulling that rule into the entity (where the only way to confirm is a method that enforces it) makes the illegal state hard to express. The concrete consequence — a forgotten invariant corrupting state — is what justifies the finding, never the label "anemic."

**When NOT to comment:** CRUD with no invariant. A DTO. A read model. A projection. Setters on data that no rule constrains. In all of these, anemia is correct and "make this a rich model" is NO_COMMENT. Do not cite "anemic domain model" as a finding on its own — without a named, duplicated invariant, it is methodology preference.

**Modern Java/Spring idiom:** Put the invariant where the state is — a `confirm()` method on `Order` that throws if there are no `LineItem`s, rather than a check repeated in callers. Use immutable value objects (records) for the parts that have no lifecycle. Keep setters off fields that a rule constrains; expose intent-named mutators that enforce the rule. None of this applies to honest CRUD.

**Key review questions:** Is there a real invariant here, or is this CRUD? If there is an invariant, is it enforced in one place (the entity) or re-asserted by every caller? Is there a path that could mutate state and skip the rule?

**Example review comment:** "SHOULD: `Order` is a plain getter/setter bean, and the rule 'cannot confirm with no line items' is checked in `OrderApplicationService` and `BulkOrderService` but not in the new `ImportService` path this design adds — so an imported order can be confirmed empty and persisted invalid. Moving the check into an `Order.confirm()` method that all three call would make the invalid state impossible to reach. (If `Order` were genuinely CRUD with no such rule, anemic would be fine and I'd say nothing.)"

### Layering & Dependency Direction (Domain Isolation)

**What to look for:** Which way dependencies point across layers. The question is whether the domain depends on the framework and persistence, or whether infrastructure depends inward on the domain. Watch for JPA, Spring, Jackson, and other framework annotations on domain types; for the domain importing repository/infrastructure classes; and for persistence or transport concerns (lazy-loading, serialization groups, HTTP DTOs) shaping the domain model.

**Why it matters:** When the domain depends only on itself, you can change the framework, the database, or the transport without touching the rules, and you can unit-test the rules without standing anything up. When framework concerns leak in, a persistence or serialization change forces a domain change, and the rules become hard to test in isolation. **But this is a trade-off, not an absolute.** The purist stance — *no framework annotations in the domain* — buys isolation at the cost of an extra mapping layer between domain objects and persistence/transport models, which is real code to write and keep in sync. Pragmatically, many Spring applications annotate domain entities with JPA directly and accept the coupling because the mapping layer is not worth its cost for their scale. Present this as a trade-off with named consequences (isolation and testability vs. mapping overhead), not as a rule. The genuine MUST is only when the leak causes a concrete defect — e.g. a lazy-loading proxy escaping the transaction and throwing on access, or a serialization annotation changing what the domain considers equal.

**When NOT to comment:** A Spring app that annotates its entities with JPA and has decided the mapping layer is not worth it has made a legitimate trade-off — do not flag it as a violation. The finding exists when the coupling causes a named problem or when the team clearly wants isolation and a leak is undermining it. "The domain shouldn't import Spring" with no consequence is NO_COMMENT.

**Modern Java/Spring idiom:** If isolation is wanted, keep the domain in framework-free packages and define ports (interfaces) the infrastructure implements (hexagonal/ports-and-adapters); map between domain and persistence/transport models at the edge. If the team accepts coupling, annotate entities with JPA but keep transport DTOs separate from the domain so an API change does not reshape the model. Either way, keep the dependency arrow pointing inward: infrastructure knows the domain, not the reverse. Singleton-scoped Spring beans for stateless domain/application services are the idiomatic lifecycle (see [`./design-patterns.md`](./design-patterns.md), Singleton) — keep them stateless.

**Key review questions:** Which way do the dependencies point — does the domain import infrastructure, or the reverse? If framework annotations are on the domain, has the team accepted that trade-off deliberately, and does it cause a concrete problem? Can the domain rules be unit-tested without the framework?

**Example review comment:** "SHOULD: the `Order` domain type carries Jackson `@JsonView` groups that shape the HTTP response. A transport change (a new API view) now forces editing the domain model, and the model's meaning is entangled with serialization. Keeping a separate response DTO and mapping at the controller edge would let the API and the domain change independently. If the team has consciously accepted domain-as-DTO coupling for simplicity, that's a legitimate trade-off — just flagging the cost. (The JPA annotations on the same class are a separate, defensible trade-off; I'm not flagging those.)"

## Anti-Patterns

- **Tactical-DDD ceremony on a simple CRUD app** — *Diff/design:* aggregates, value objects, domain services, and per-table repositories layered onto an application that is honest data-in/data-out with no invariant to protect. *Harm:* every concept is indirection a reader must traverse to find a plain update; the structure costs comprehension and onboarding and protects nothing, and changes are slower for it. *Fix:* a transaction script or a thin service over CRUD entities; introduce a tactical building block only when a concrete invariant or boundary forces it.

- **One transaction mutating multiple aggregates** — *Diff/design:* a single `@Transactional` method (or unit of work) that updates several aggregate roots together to keep them "consistent." *Harm:* the lock footprint spans several tables, raising contention and deadlock risk and blocking independent scaling of those writes; a partial failure leaves a torn, inconsistent state. *Fix:* mutate one aggregate per transaction; propagate cross-aggregate consistency as eventual via a domain event handled in its own transaction. If the business truly needs all of them atomic, the aggregate boundary is wrong — revisit it.

- **Mutable value object shared and aliased** — *Diff/design:* a `Money` (or address, or `TaxRule`) modeled as a mutable class and the same instance shared across several holders. *Harm:* mutating it for one holder silently changes the others, producing a wrong total or rate with no exception — a data corruption that is invisible until something downstream is wrong. *Fix:* make value objects immutable (a `record`, verify the Java version); each holder then carries an independent value and aliasing cannot corrupt anything.

- **A domain model shared read-write across bounded contexts** — *Diff/design:* the same `Customer`/`Order` class, table, or schema written by two contexts (Ordering and Billing). *Harm:* a change one context needs (a column, a lifecycle state) is forced on the other and requires a coordinated migration and redeploy; one context's write can violate the other's invariant unnoticed, and there is usually no test across the seam. *Fix:* give each context its own model keyed by a shared identity; integrate through a published event or an API, not a shared mutable model. A small, deliberately co-owned shared kernel is the only acceptable shared form, and only when both teams accept the coupling.

- **Framework/persistence concerns leaking into the domain** — *Diff/design:* lazy-loading proxies, serialization view annotations, or HTTP DTO shapes driving the domain model and its equality. *Harm:* a persistence or transport change forces a domain change, the rules can't be unit-tested without the framework, and a lazy proxy can escape the transaction and throw on access. *Fix:* keep transport DTOs separate from the domain and map at the edge; if full isolation is wanted, define ports and map to persistence models too. Note JPA annotations *on* the domain are a defensible trade-off, not automatically this anti-pattern — flag only the leaks that cause a named consequence.

- **A "repository" that is really non-aggregate CRUD** — *Diff/design:* repositories over a root's internal entities, or Spring Data interfaces exposing column-level/partial writes treated as the aggregate boundary. *Harm:* callers persist fragments of an aggregate (a `LineItem` without its `Order`), bypassing the root that enforces the invariant, so invalid state gets saved. *Fix:* one repository per aggregate root, persisting the whole aggregate; persist internal entities only through the root. In a genuine CRUD app with no aggregates, a repository per table is correct — this anti-pattern only applies when an aggregate's invariant is being bypassed.

- **A domain event hiding a required critical side effect** — *Diff/design:* a required, must-happen effect (charging a `Payment`, issuing an `Invoice`) performed only by a listener, especially `@TransactionalEventListener(AFTER_COMMIT)`. *Harm:* control flow is invisible at the call site; a missing or throwing listener silently drops the work, and an after-commit listener runs outside the originating transaction so its failure cannot roll the work back, leaving a half-done state with no error. *Fix:* for a required atomic effect use a synchronous in-transaction listener or a direct call; reserve events (and AFTER_COMMIT) for genuinely decoupled, non-critical, retry-safe reactions. This is the Observer anti-pattern from [`./design-patterns.md`](./design-patterns.md) at design altitude.

- **A god application service** — *Diff/design:* one application service accreting the orchestration of many unrelated use cases across contexts, with a long dependency list and a grab-bag of methods. *Harm:* a single high-churn class that is hard to test and reason about, a merge-conflict magnet, and a place where unrelated changes collide. *Fix:* one focused application service per use case, each cohesive and independently testable. This is the Facade-becoming-a-god-service anti-pattern from [`./design-patterns.md`](./design-patterns.md).

## Modernization (Java/Spring idioms)

Treat these as the idiomatic modern expressions of DDD concepts — but **inspect the target project first and never assume a version or that a dependency is on the classpath.** Establish the Java language level, the Spring Boot version, the persistence stack, and which libraries are actually present before recommending any of them. A suggestion the project cannot compile or does not have on the classpath is worse than no suggestion.

Frame every version- or dependency-specific claim as *verify against the actual project*:

- **Records for value objects** — a `record` is the idiomatic immutable value object: value-based `equals`/`hashCode`, a compact constructor for validation, no setters. *Verify the project is on Java 16+ (records GA) and isn't standardized on a different value-object approach (e.g. Lombok `@Value`).*
- **Sealed types for closed domain hierarchies** — `sealed` interfaces/classes model a closed set of domain states or variants and give exhaustive, compiler-checked `switch` handling (a finite set of `Order` states, a closed `PricingRule` family). *Verify Java 17+ for sealed types, and Java 21+ for exhaustive pattern-matching `switch` over them (preview earlier); confirm the language level before recommending either, and only when the hierarchy is genuinely closed.*
- **`ApplicationEventPublisher` / `@EventListener` / `@TransactionalEventListener` for domain events** — publish via `ApplicationEventPublisher`; handle synchronously in-transaction with `@EventListener` for atomic reactions, or with `@TransactionalEventListener(phase = AFTER_COMMIT)` for reactions that must run only after a durable commit (and can tolerate that the originating transaction is already committed and unrollable). *Choose the phase by whether the effect must be atomic with the originating work; verify the Spring version supports the listener you suggest.*
- **Spring Modulith for modular bounded contexts** — lets you declare context boundaries within a single deployable and have the build verify that contexts depend on each other only through allowed APIs and published events, turning the boundary into a checked constraint rather than a convention. *Verify Spring Modulith is actually a dependency before recommending it — never assume it is present, and never recommend adding a dependency without naming the concrete benefit for this project.*
- **Package-by-bounded-context** — a top-level package per context (Ordering, Billing, Shipping, Notification), each owning its model, application services, and persistence, so the boundary is visible in the package structure and dependencies across it are easy to audit. This needs no dependency and is often the right first step before reaching for Modulith. *Verify it fits the project's existing package conventions rather than imposing it wholesale.*

When a transaction script over CRUD entities does the job, say so plainly — the newest tactical building block is not the goal; the model that protects real invariants with the least machinery is.

## Suggested Comment Style

Keep comments respectful, consequence-first, and severity-honest. Lead with what concretely breaks (or improves), not with a methodology label — name the failure mode so the author can weigh the trade-off rather than feel judged for not following a textbook. State severity honestly; a NIT should read like a NIT, not a blocker. Offer the alternative, and acknowledge the trade-off when there is one (eventual consistency, mapping overhead). When the code is honest CRUD, say it is fine and say nothing.

Example openers:

- "Could we... so that..." (proposes a change tied to a concrete benefit)
- "This may corrupt state because..." (names the failure mode)
- "Where's the consistency boundary here? If this transaction touches both..." (asks the boundary question)
- "If this is genuinely CRUD, an anemic model is fine — flagging only because there's a real invariant..." (acknowledges restraint)
- "NIT (not a blocker): ..." (flags taste-level, optional)
- "This boundary reads cleanly — each context owns its own model. No change needed." (explicitly endorses)

Example comments (neutral-domain):

- "MUST: this transaction updates the `Order`, the `Customer` balance, and the `Invoice` together. Under concurrency that's three tables locked at once — contention and deadlock risk go up, and a failure mid-way leaves a torn state. Could we keep the transaction to `Order` and propagate the rest via an event handled separately? That makes the balance and invoice eventually consistent — flagging that trade-off explicitly."
- "MUST: `Money` is mutable and shared across `LineItem`s, so mutating one line's price silently changes the others and the total is wrong with no error. An immutable `record` (verify the Java version) gives each line its own value."
- "SHOULD: the 'cannot confirm an empty `Order`' rule is checked in two services but not in the new import path, so an imported order can be confirmed empty. Moving the check onto `Order.confirm()` makes the invalid state unreachable. Not blocking."
- "If the Ordering and Billing split is overkill for one team and one deployable, I'd leave a single model — the two contexts here always change together, so the boundary is costing coordination without buying independence. No change needed if you'd rather keep it."

## Integration (architecture-review)

The consuming skill uses this lens as a judgment aid at system/design altitude, not a checklist to enforce:

- **Never comment because a DDD concept is absent.** A design with no aggregates, no domain events, or an anemic model is not a finding by itself. Absence is worth raising only when you can name the concrete consequence of that absence (a duplicated invariant that will be forgotten, a missing boundary forcing lockstep change).
- **Comment only when there is a real, articulable consequence** — a corruptible state, a torn transaction, a coupling that forces coordinated change, a boundary that blocks evolution, an invariant a path can skip.
- **Never block on methodology preference.** "This should be a bounded context / aggregate / value object" without a named consequence is NIT at most, and usually NO_COMMENT.
- **Always tag findings** `MUST` / `SHOULD` / `NIT` per [`../rules/severity-rubric.md`](../rules/severity-rubric.md) so the author can triage by severity. (NO_COMMENT is the silent fourth outcome and, for this lens, the most common one.)
- **A few strong findings beat many weak ones.** One well-justified MUST about a multi-aggregate transaction or a cross-context shared model is worth more than a list of "this isn't really an aggregate" observations — drop the weak ones to NO_COMMENT rather than padding the review.
- This lens reasons about boundaries, consistency, ownership, and model shape — *system/design altitude*. Local readability and small refactors belong to [`./clean-code.md`](./clean-code.md); test quality belongs to [`./testing.md`](./testing.md); pattern-level structural calls in a single diff belong to [`./design-patterns.md`](./design-patterns.md). Defer to those rather than re-litigating their concerns here.
