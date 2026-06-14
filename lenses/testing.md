# Testing Review Lens

Reusable test-quality knowledge for Java/Spring: what a test actually asserts, what it misses, and how it stays honest under change. The *intent* of applying it — which diffs, how strict — comes from the consuming skill, not from this document.

## How skills use this lens

Today the only consumer is `java-pr-review`. It applies this lens with a diff/PR focus: the unit of review is the **changed tests** and the **code under change** they are meant to protect — not the whole test suite, not a coverage audit. Load this lens only when the diff touches tests or touches production code that carries enough risk to deserve a test. It is not generalized for hypothetical future skills; keep the scope to PR review.

## Purpose

Help a skill judge whether the tests in a diff *genuinely protect behavior*. The job is separation: tell a real protection gap — a regression that would slip through, a flake that will erode CI trust, a wrong-level brittle test that breaks on a safe refactor — apart from coverage theater and personal taste. Bias toward restraint. A few strong, consequence-backed findings beat a long list of cosmetic ones.

## When to Use

Engage this lens when a diff shows any of:
- Tests added, changed, or deleted.
- Production code added or changed on a path that should be covered (a new branch, a new error mode, a changed calculation).
- A critical path touched with no accompanying test: payment or money math, authentication/authorization, persistence and data writes, anything irreversible.
- A test that newly mocks a collaborator or newly asserts something — the assertion and the mock are where regressions hide.

Do **not** engage to police test formatting, import order, or naming-case a linter owns. Do **not** engage to chase a coverage number or to demand a test on trivial code.

## Core Principle

A test earns its place only if it can **fail for exactly one real reason** — a specific behavior breaking. Test the *behavior and contract* of the code under change, not its implementation details; a test bound to how the code works (rather than what it guarantees) will break on a safe refactor and protect nothing.

Coverage percentage is a weak signal, not a goal. A line can be 100% covered by a test that asserts nothing. "No test is needed here" and "no comment" are valid, frequent outcomes — say them out loud.

Test style belongs to linters, not to review. Formatting, import order, and naming-case are tool jobs; if a finding has no behavioral consequence, it is at most a NIT and usually NO_COMMENT.

## Severity Calibration

Map every finding to the consuming skill's severity rubric. For testing findings:

- **MUST** — a concrete hazard now. A test that cannot fail or asserts nothing real (e.g. only that no exception was thrown when the *value* is what matters). A critical path — money movement, auth, a data write — with no test at all. A flaky test that will intermittently red CI and erode trust. A test asserting the wrong thing, so a genuine regression passes green.
- **SHOULD** — a real, nameable gap. A missing error or edge-case test on an important path. Over-mocking that hides an integration break. The wrong test level that materially slows CI (a full-context boot where a unit test would do, especially as these accumulate) or makes the suite brittle. A test coupled to implementation detail so a safe refactor breaks it.
- **NIT** — test naming, structure, or formatting cosmetics with no behavioral consequence. Never blocks.
- **NO_COMMENT** — pure taste; coverage-for-coverage on trivial code; a getter/DTO test demand. Stay silent.

Overriding rule: **every finding must name a concrete consequence** — the regression that slips through, the CI flake, the refactor that breaks, the production path left unguarded. If you cannot name one, it is NO_COMMENT. Coverage-for-coverage requests and cosmetics default to NIT or NO_COMMENT; they never rise to MUST.

## Review Questions

- Could this test actually **fail** if the behavior broke — or does it only assert "no exception was thrown"?
- Is the **untested** path the one that actually carries risk (money, auth, persistence), or just an easy-to-cover trivial branch?
- Is this test mocking something we **do not own** (the database, the framework, an HTTP client), and does that hide a real integration that could break?
- Is the test bound to **implementation detail** — call order, private structure, exact interaction sequence — so a safe refactor turns it red?
- Is there a hidden source of **flakiness**: wall-clock time, iteration/order assumptions, shared mutable state, randomness, real `Thread.sleep`?
- Is this the **right level** — a pure unit test, a Spring slice, or a full integration test — for what it claims to verify?

## Heuristics

### What the test asserts

**What to look for** — A test that exercises the code but asserts nothing meaningful: no `assertThat`, or only `assertThat(result).isNotNull()` on a path where the *value* matters; a `@Test` that calls the method and ends; an assertion on a field the change did not affect while the changed field goes unchecked. Watch for asserting on a stubbed return value (you assert what the mock was told to say, not what the code computed).

**Why it matters** — A test with no real assertion is green forever; the regression it was supposed to catch ships unnoticed, and the green check actively misleads the next reader.

**When NOT to comment** — The single meaningful assertion is present and correct; you would only be adding redundant assertions for symmetry. The method genuinely returns `void` with no observable effect worth pinning.

**Modern idiom** — AssertJ `assertThat(order.total()).isEqualTo(expected)` for value checks; `assertThatThrownBy(() -> service.charge(...)).isInstanceOf(PaymentDeclinedException.class)` for the failure path. Prefer asserting the returned/observable value over `verify(...)` when a value is what the contract promises.

**Key review questions** — If the computed result were wrong by one unit, would this test still pass? Are you asserting the code's output or the mock's scripted answer?

**Example review comment** — "MUST: `chargesOrder_succeeds` calls `charge()` but only asserts the result is non-null. If the charged amount were computed wrong, this stays green. Could we assert `assertThat(receipt.amount()).isEqualTo(expectedTotal)` so the test fails when the math breaks?"

### Edge & error cases

**What to look for** — Only the happy path is tested on a path that has real failure modes: a `PaymentDeclinedException` branch, an empty/oversized `LineItem` list, a null `Customer`, a boundary in a `PricingRule` or `TaxRule`, a rounding edge in money math. The diff adds a `catch` or a guard clause but no test drives it.

**Why it matters** — The error and boundary branches are exactly where regressions hide and where production incidents originate; an untested `catch` block can swallow or mistranslate a failure and no one notices until it fires.

**When NOT to comment** — The branch is trivial and low-risk, or the edge is already covered by an adjacent test. Do not demand a case per input permutation when one parameterized case captures the contract.

**Modern idiom** — `@ParameterizedTest` with `@ValueSource`/`@CsvSource`/`@MethodSource` to sweep boundaries without copy-paste; `assertThatThrownBy(...).isInstanceOf(...).hasMessageContaining(...)` for the failure contract.

**Key review questions** — Which branch added in this diff has no test driving it? Does the most expensive *wrong* behavior here have a test that would catch it?

**Example review comment** — "SHOULD: the new `declined` branch in `PaymentService` has no test. A regression that treats a decline as success would pass CI. A `@ParameterizedTest` over a couple of decline reasons would guard it."

### Test structure & naming

**What to look for** — A test whose name claims one thing but asserts another; a single `@Test` exercising five unrelated behaviors so a failure does not localize; setup so tangled the assertion's meaning is unclear. The genuine structural smell is *non-localizing* failure, not formatting.

**Why it matters** — When one test asserts many things, a failure does not tell you *what* broke, and a later author deletes or weakens an assertion to make it pass. A misleading name sends the next reader down the wrong trail during an incident.

**When NOT to comment** — Naming-case, blank lines, given/when/then comments, import order — that is linter and formatter territory; say so and move on. One test legitimately covering one behavior with several related assertions is fine.

**Modern idiom** — One behavior per `@Test`; `@DisplayName` or an intent-revealing method name; `@Nested` to group cases around one collaborator. JUnit 5 `@BeforeEach` for shared, *non-leaking* setup.

**Key review questions** — If this test fails in CI, will the name tell you what behavior broke? Is it asserting one behavior or several stapled together?

**Example review comment** — "SHOULD: `test1` covers both the discount and the tax path; if it fails we won't know which broke, slowing diagnosis. Splitting into two named tests would localize the failure. (Pure naming/format is the linter's job — separate concern.)"

### Mocking & test doubles

**What to look for** — Mocks of types you do not own (a JDBC connection, the framework, an HTTP client, the clock); a test where every collaborator is mocked so nothing real is exercised; `verify(...)` on every interaction so the test re-states the implementation; stubbing a method then asserting the stub's own return value.

**Why it matters** — Mocking what you don't own bakes your *assumption* of its behavior into the test; if the real dependency behaves differently, the test stays green and the integration breaks in production. Over-specified `verify` couples the test to call sequence, so a harmless refactor reds CI.

**When NOT to comment** — Mocking a genuine external boundary you own the interface to (a `NotificationGateway` port) to isolate a unit is correct. A single `verify` on the one interaction that *is* the contract (an audit write must happen) is legitimate.

**Modern idiom** — `@ExtendWith(MockitoExtension.class)` with `@Mock`; mock your own ports, not third-party internals; for a real database or broker prefer **Testcontainers** or the appropriate Spring slice *where the project already supports it* (see Modernization for the Docker/CI caveat) over mocking the driver. In Spring, `@MockBean` (Spring Boot, `org.springframework.boot.test.mock.mockito`) is deprecated since Spring Boot 3.4 in favor of `@MockitoBean` (Spring Framework 6.2+, `org.springframework.test.context.bean.override.mockito`) — and they are not a strict 1:1 swap (behavior can differ, e.g. with `@Configuration` classes), so verify the project's version before recommending either.

**Key review questions** — Does this mock stand in for something we own and control? If you assert on a value, is it the code's output or the stub's scripted reply?

**Example review comment** — "SHOULD: this test mocks the `InvoiceRepository` and then `verify`s the exact save sequence. A safe refactor that batches the writes would break it without any behavior changing. Could we assert the persisted `Invoice` state via a `@DataJpaTest` slice instead, so we test the outcome rather than the calls?"

### Test level & isolation

**What to look for** — `@SpringBootTest` booting the whole context to test one pure calculator; a controller mapping verified through a full integration test instead of a `@WebMvcTest` slice; pure (de)serialization checked by booting the web layer instead of a lighter `@JsonTest`; a repository query checked with everything mocked instead of a `@DataJpaTest`; conversely, a true cross-component integration faked entirely with mocks.

**Why it matters** — The wrong level makes the suite slow and flaky (full-context boots multiply CI time and shared-state flakes) or hollow (a mocked-out "integration" test proves nothing about integration). Both erode trust and slow every future change.

**When NOT to comment** — The chosen level is defensible; do not relevel a test that is already fast and focused. A `@SpringBootTest` is right when wiring across many beans *is* the thing under test.

**Modern idiom** — Plain JUnit + Mockito for pure logic; `@WebMvcTest` for controller/serialization and `@JsonTest` for pure (de)serialization; `@DataJpaTest` for queries; `@SpringBootTest` reserved for genuine end-to-end wiring; Testcontainers when a real datastore matters and CI can run it.

**Key review questions** — Does this test need the Spring context at all, or is it pure logic? If it claims to test integration, is anything real actually integrated?

**Example review comment** — "SHOULD: `PricingRule` math is pure, but this uses `@SpringBootTest` and boots the full context. As these accumulate, CI slows for everyone. A plain unit test would run in milliseconds and assert the same thing."

### Flakiness & determinism

**What to look for** — `Thread.sleep` to wait for async work; assertions on `LocalDateTime.now()` or `Instant.now()` without a fixed clock; dependence on `HashMap`/`Set` iteration order or unsorted query results; shared static/mutable state across tests; unseeded randomness; tests that pass alone but depend on execution order.

**Why it matters** — These red CI intermittently for reasons unrelated to the change. Flaky tests train the team to re-run until green, and a real failure hiding in the noise ships. A time- or order-based assertion can also be silently wrong in another timezone or JVM.

**When NOT to comment** — The nondeterminism is already controlled (injected `Clock`, sorted results, Awaitility with a bounded timeout). Do not flag a `sleep` in non-test helper code outside this lens's scope.

**Modern idiom** — Inject `Clock` and use `Clock.fixed(...)` for time; **Awaitility** (`await().atMost(...).until(...)`) instead of `Thread.sleep` for async; assert on sorted/normalized collections or use order-agnostic AssertJ (`containsExactlyInAnyOrder`); seed randomness or inject the generator; keep each test's state local.

**Key review questions** — Will this test pass on a slow CI box, in another timezone, and when run in a different order? What shared state does it read or mutate?

**Example review comment** — "MUST: the async assertion uses `Thread.sleep(200)` before checking the `Notification` was sent. On a loaded CI runner that 200ms isn't enough and this will flake red. `await().atMost(Duration.ofSeconds(2)).until(() -> gateway.sent())` waits only as long as needed and stays deterministic."

### Test data & maintainability

**What to look for** — Sprawling inline object graphs repeated across tests with one field varied; magic numbers whose meaning the assertion depends on but does not explain; a test where you cannot tell which input drives the asserted output; copy-pasted setup that drifts out of sync with the production model.

**Why it matters** — Opaque or duplicated test data makes failures hard to diagnose and tempts the next author to "fix" a red test by editing the expectation rather than the code. Drifted fixtures stop resembling real inputs, so the test guards a shape that no longer occurs.

**When NOT to comment** — The data is already clear and local; do not impose a builder framework on a two-field object. Minor duplication that aids readability is fine — do not DRY tests to the point of obscurity.

**Modern idiom** — Small test-data builders or factory methods for the parts that vary; named constants for boundary values so the assertion reads as intent; `@MethodSource` to supply case tables. Keep the *relevant* input visible in the test body.

**Key review questions** — Can a reader see which input produces the asserted result? Will this fixture still resemble a real `Order` after the next model change?

**Example review comment** — "NIT: the expected total `4297` is a magic number here; if this fails, the next reader won't know if the code or the expectation is wrong. A named constant or a one-line comment showing the derivation would make the intent survive the next change."

## Anti-Patterns

- **Assertion-free test** — *Diff:* a `@Test` that calls the method under change and ends, or asserts only `isNotNull()` where the value matters. *Harm:* green forever; the regression ships invisibly. *Fix:* assert the observable value/effect that the change is responsible for.
- **Testing the mock, not the behavior** — *Diff:* `verify(...)` on every interaction, or asserting a stub's own scripted return. *Harm:* the test restates the implementation; a safe refactor reds CI while broken behavior can still pass. *Fix:* assert the outcome (returned value, persisted state); keep `verify` for the one interaction that *is* the contract.
- **`@SpringBootTest` for a pure unit** — *Diff:* full context boot to test a calculator or a mapper. *Harm:* slow, flake-prone CI that taxes every future change. *Fix:* plain JUnit + Mockito; reserve `@SpringBootTest` for real wiring.
- **Coverage-driven trivial tests** — *Diff:* tests for getters, setters, plain DTOs, or `toString`. *Harm:* maintenance weight and false confidence with no regression caught. *Fix:* delete; spend the effort on a path that can actually break. Default these to NO_COMMENT.
- **`Thread.sleep` async waits** — *Diff:* `Thread.sleep(n)` before asserting an async result. *Harm:* flaky under CI load; either too short (false red) or too long (slow suite). *Fix:* Awaitility with a bounded timeout, or test the async unit synchronously.
- **Order-dependent / shared-mutable-state tests** — *Diff:* tests reading or mutating static state, or relying on run order or `HashMap` iteration order. *Harm:* intermittent reds unrelated to the change; failures that vanish on re-run. *Fix:* isolate state per test; assert order-agnostically; reset between runs.
- **Copy-pasted test, one value changed, no new assertion** — *Diff:* a duplicated `@Test` with a different input but the same (or no) meaningful assertion on the new behavior. *Harm:* suite bloat and the illusion of coverage. *Fix:* fold into a `@ParameterizedTest`, or add the assertion that makes the new case earn its place.
- **Brittle tests coupled to implementation detail** — *Diff:* assertions on private structure, exact call sequence, or log strings. *Harm:* a behavior-preserving refactor breaks the test, so the suite punishes good changes. *Fix:* assert the public contract and observable outcome.
- **Over-mocking that hides integration breakage** — *Diff:* the database, framework, or HTTP client mocked out so "integration" is entirely synthetic. *Harm:* the real integration can break with every test green. *Fix:* exercise the real boundary with Testcontainers or the appropriate Spring slice (`@DataJpaTest`, `@WebMvcTest`) where the project's CI can run it (see the Modernization Docker caveat).

## Modernization (Java/Spring testing idioms)

Standing guidance: **inspect the target project's test stack before recommending anything.** Check JUnit 4 vs 5, AssertJ vs Hamcrest, the Mockito version, the Spring Boot version, whether Testcontainers is present, and the build tool. Never assume; a "modern" suggestion that fights the project's existing conventions is noise.

Idioms to recognize, each framed as *verify against the actual project*:
- **JUnit 5 (Jupiter)** — `@Test`, `@ParameterizedTest`, `@Nested`, `@DisplayName`, `@BeforeEach`. *Verify the project isn't still on JUnit 4 (or running both via the vintage engine) before recommending a migration.*
- **AssertJ fluent assertions** — `assertThat(...).isEqualTo(...)`, `assertThatThrownBy(...)`, `containsExactlyInAnyOrder(...)`. *Verify whether the project standardizes on AssertJ or Hamcrest before switching styles.*
- **Mockito** — `@ExtendWith(MockitoExtension.class)`, `@Mock`, `@InjectMocks`. *Verify the Mockito version; strict stubs and some APIs differ across versions.*
- **`@ParameterizedTest`** — for boundary sweeps via `@CsvSource`/`@MethodSource`. *Verify the `junit-jupiter-params` dependency is present.*
- **Spring Boot test slices** — `@WebMvcTest`, `@DataJpaTest`, `@JsonTest` for focus; `@SpringBootTest` only for real wiring. *Verify the Spring Boot version supports the slice you suggest.*
- **`@MockBean` vs `@MockitoBean`** — `@MockBean` (Spring Boot) is deprecated since Spring Boot 3.4 in favor of `@MockitoBean` (Spring Framework 6.2+, a different package), and the two are not a strict 1:1 replacement (behavior can differ, e.g. with `@Configuration` classes). *Recommend `@MockitoBean` only if the project is on Spring Boot 3.4+ / Framework 6.2+; otherwise `@MockBean`. Verify the version first; do not blanket-suggest either.*
- **Testcontainers** — real database/broker/queue instead of mocking the driver. *Verify it's already a dependency and that CI can run Docker before recommending it.*
- **Awaitility** — bounded async waiting instead of `Thread.sleep`. *Verify it's available or worth adding before suggesting it.*

When a plain assertion or a simpler test level does the job, say so plainly — the newest tool is not the goal; the deterministic, behavior-pinning test is.

## Suggested PR Comment Style

Respectful, consequence-first, severity-honest. Lead with the regression or flake that could result, not with a rule. Example openers:
- "Could we add a case for when the `Payment` is declined? Right now that branch isn't exercised."
- "This may pass even if the total is computed wrong, because the only assertion is `isNotNull()`."
- "NIT (not a blocker): splitting this into two named tests would localize the failure."
- "Good coverage of the failure path here — the `assertThatThrownBy` makes the contract explicit."

Short examples with neutral nouns:
- "SHOULD: the new rounding branch in `TaxRule` has no test. A regression that rounds the wrong way would ship green — a `@ParameterizedTest` over a couple of boundary amounts would guard it."
- "MUST: this asserts the `Notification` was sent after `Thread.sleep(100)`. Under CI load that will flake red; `await().atMost(...)` waits only as long as needed and stays deterministic."
- "NIT: `expected = 1899` is a magic number; a named constant showing how it's derived would help the next reader. Not a blocker."

## Integration (java-pr-review)

Apply this lens with a diff/PR focus: the changed tests and the code under change, **not** a whole-suite audit. Concretely:
- Never demand a coverage number or treat coverage percentage as a target.
- Never block on a test-style preference — formatting, naming-case, and import order belong to the linter; say so.
- Always tag each finding **MUST / SHOULD / NIT** per the consuming skill's severity rubric, and always name the concrete consequence.
- Prefer a few strong findings (an unguarded critical path, an assertion-free test, a flake) over many weak ones.
- Drop anything you cannot back with a concrete consequence to **NO_COMMENT** and stay silent.