# Security Lens

Reusable application-security knowledge for Java/Spring: whether changed code, and the design it sits
in, can be made to leak data, execute attacker input, skip an authorization check, or expose a secret —
the failure that shows up not under load but under an adversary. The lens spans two altitudes: the
*line/method* security of a diff (a concatenated query, a `MessageDigest` over a password, a token in a
log) and the *system* security of a design (where the trust boundary falls, what the authorization model
is, how secrets are managed, what the threat surface looks like). **The *intent* of applying it — which
diffs, how strict, whether to block, or whether to *decide* a control up front — comes from the
consuming skill, not from this lens.**

## How skills use this lens

This lens has three consumers, at three altitudes and two intents. **`java-pr-review`** reads it
**evaluatively** at the **line/method level**: *this* query concatenates a request value, *this* handler
changes state with no authorization check, *this* `catch` logs the exception with the bearer token in
it, *this* `ObjectInputStream` deserializes a request body. **`architecture-review`** reads it
**evaluatively** at **system altitude**: where the trust boundary actually falls (and what crosses it
unvalidated), what the authorization model *is* (and whether it is enforced consistently or
ad-hoc per endpoint), how secrets flow from source to use, and what the change adds to the threat
surface (a new public endpoint, a new outbound call to a user-influenced URL, a new deserialization
sink). **`spec-author`** reads it **generatively**: *what security does this design have to decide up
front* — the trust boundary, the authorization model, the data classification of each field, the
secret-management story — so the reviewer does not later have to find it missing.

It is the lens the rest of the review track **delegates security to**. `spring-production-readiness`
says so explicitly: its error-handling heuristic notes that "a secret or PII written to a log is a
`MUST` under the severity rubric and the … `security` lens; here, only flag the *diagnosability* gap,"
and its observability modernization defers "deep security/PII-in-log concerns" to "the planned
`security` lens, not this one." So **this lens owns the secret-in-log / PII-in-log MUST** and the
adversarial reading of a flow; production-readiness owns the runtime-failure reading of the same code.
Both can fire on one diff with different findings: where production-readiness asks "does this `catch`
lose data silently?", this lens asks "does this `catch` log the credential or return the stack trace to
the caller?". Load this lens only when the change actually touches a **trust boundary** (external input,
an authenticated/authorized action, an outbound call, a deserialization or template/markup sink), a
**secret or credential**, **sensitive data** (PII, tokens, financial detail) on its way to a log /
response / URL, or a **cryptographic** operation — never because the word "security," "auth," or "token"
appears in a name.

## Purpose

Help a skill judge whether a change is safe against an adversary — someone supplying crafted input,
replaying a request, guessing an identifier, reading a log, or intercepting a response — and separate a
real, nameable exploit path from speculative hardening. Bias toward restraint, but with a different
center of gravity than the resilience lenses: a missing security control often *is* a concrete defect
(an unauthenticated state-changing endpoint is exploitable today, not "someday under load"), so the
restraint is not "stay silent about controls" but "name the exploit." A finding earns its place when you
can state the attack: *what an adversary does, and what they get* — read another customer's `Invoice`,
inject a SQL clause, recover a password from a weak digest, lift a token from a log. Defense-in-depth
beyond a named threat, a hardening header with no exposed asset, "add a WAF" with no vector — those are
`NO_COMMENT`. A few strong, exploit-backed findings beat a wall of "consider validating this."

Security tooling has a real and separate job, and this lens **delegates to it**: dependency/CVE scanning
(SCA — OWASP Dependency-Check, Snyk, `dependabot`), SAST, secret-scanning (`gitleaks`,
`trufflehog`), and DAST are **tooling**, run in CI, and find the classes of issue a human reviewer
should not be spending tokens enumerating. This lens is *not* a CVE database: it does not flag "library X
version Y has CVE-Z" — it flags the *code-shaped* and *design-shaped* vulnerabilities a scanner cannot
see (an authorization check that is structurally absent, a trust boundary drawn in the wrong place, a
secret committed in config). When the right answer is "this is what your SCA/secret-scanner is for," say
that and move on.

## When to Use

Engage this lens when the diff or design shows a *trust-boundary* trigger:

- **Untrusted input crossing into a sink** — a request parameter, path variable, header, body field,
  uploaded file, queue message, or external API response used to build a query, a command, a file path,
  an LDAP filter, an outbound URL, or markup/template output.
- **A state-changing or data-returning action reachable by a caller** — an HTTP endpoint, a message
  listener, a GraphQL resolver — where the question "who is allowed to do this, to *which* object?" must
  have an enforced answer.
- **An object/record accessed by an id from the request** — `findById(requestId)` returned or mutated
  without checking the caller owns or may access *that* object (the IDOR / broken-object-level-authz
  shape).
- **A secret or credential** — a password, API key, token, connection string, signing key, or
  certificate, appearing in code, a config file about to be committed, a log statement, an exception
  message, or a response/URL.
- **Sensitive data on the move** — PII, credentials, tokens, financial detail flowing into a log, an
  error response, a URL/query string, an analytics event, or an outbound third-party call.
- **A cryptographic operation** — password storage, token/nonce/salt generation, encryption,
  signing/verification, TLS configuration, random-number use where unpredictability matters.
- **A deserialization, XML-parsing, or outbound-fetch sink** — native Java deserialization of
  untrusted bytes, an XML/XXE-capable parser on external input, an HTTP/file fetch to a
  request-controlled destination (SSRF).
- **An authentication, session, or framework-security surface** — a Spring Security config change, a
  `permitAll()`, a CORS or CSRF setting, a session/cookie attribute, a custom filter on the auth path.

Do **not** engage for pure in-process logic with no untrusted input, no secret, no sensitive data, and
no auth decision — there is no attack to name, and the lens has nothing to say. **Do NOT engage merely
because** a class is named `*Security*`, a package is `auth`, a field is called `token`, or a dependency
appears in a CVE feed (that is the SCA tool's job). The trigger is a real trust boundary in the change,
not the vocabulary around it.

## Core Principle

Application security is about behavior **under an adversary**: not "does this work for a cooperative
caller?" but "what can a hostile caller make this do?" A finding is worth raising only when you can name
the **exploit** — *what an attacker does and what they gain*: a query built by string concatenation lets
a crafted parameter read the whole `Account` table; a state-changing endpoint with no authorization
check lets any authenticated user cancel another customer's `Order`; a token logged at `INFO` lets
anyone with log access impersonate the user; `MessageDigest.getInstance("MD5")` over a password lets a
stolen database be cracked offline in minutes. "This isn't validated" is not a finding; "this path
variable is concatenated into the JPQL `WHERE`, so `1 OR 1=1` returns every customer's `Invoice`" is.

Two boundaries discipline the lens. First, **a control is a trade, but an exploit is a fact.** Unlike a
retry or a circuit breaker — pure speculative cost until a failure is named — a missing authorization
check or a concatenated query is often *exploitable now*, so the bar for a security `MUST` is "name the
attack," not "wait for it to happen." But the inverse restraint is just as real: a hardening measure
with no exposed asset (a security header on an endpoint serving public data, a second validation layer
behind an already-validated boundary, encryption of data that is already non-sensitive and access-
controlled) is cost with no threat, and that is `NO_COMMENT`. Second, **this lens reads code and design,
not a CVE feed.** Every framework- or library-specific control below is version- and dependency-gated:
inspect the stack before recommending an API (Spring Security's method-security annotations, `BCrypt`
vs `Argon2`, the JSON library's polymorphic-typing default), and **delegate dependency-version
vulnerabilities to SCA tooling** rather than pretending to be a scanner.

## Severity Calibration

Map findings to the consuming skill's severity rubric (see [`../rules/severity-rubric.md`](../rules/severity-rubric.md)).
For security findings, the rubric's "security hole" `MUST` is this lens's home ground:

- **MUST** — a concrete, exploitable hole *now*. **SQL/JPQL injection** via string concatenation of
  untrusted input (a crafted value reads or alters the whole table). A **state-changing or
  data-returning endpoint with no authorization check** (any caller cancels another customer's `Order`,
  reads any `Invoice`). **Broken object-level authorization / IDOR** — an object fetched by a
  request-supplied id and returned/mutated without an ownership check (the attacker enumerates ids and
  reads or alters other tenants' records). A **secret/credential hard-coded** in source/config or
  **written to a log / exception message / response / URL** (anyone with the repo, the log, or the URL
  has the credential). **Weak password storage** — `MessageDigest`/SHA/MD5 or a plain hash for
  passwords instead of an adaptive KDF (`BCrypt`/`Argon2`/`PBKDF2`), so a stolen store is cracked
  offline. **Insecure deserialization** of untrusted input (native Java `ObjectInputStream`, or a JSON
  library with polymorphic typing enabled, on attacker-controlled bytes → remote code execution).
  **Command/LDAP/path-traversal injection** from unsanitized input. **XXE** on an XML parser reading
  external input with DTDs enabled (file read / SSRF). **SSRF** — an outbound fetch to a
  request-controlled URL with no allowlist (the attacker reaches internal services / cloud metadata).
  A **broken-crypto** primitive (ECB mode, a hard-coded key/IV, `java.util.Random` for a token/nonce).
  Each MUST blocks and must name the exploit.
- **SHOULD** — a real, nameable weakness that is not an open hole today. **No rate-limiting or
  lockout** on an authentication/credential endpoint (brute-force/credential-stuffing is feasible
  though not trivial). A **CORS policy wider than the trust boundary needs** (`allowedOrigins("*")`
  with credentials, or a reflected origin) where no cross-origin attacker is yet positioned but the
  surface is open. A **verbose error response** leaking a stack trace, SQL, an internal host, or a
  framework version to the client (recon that eases a later attack). **Mass assignment / over-broad
  binding** where a request can set a field it shouldn't (a `role` or `isAdmin` bound from the body)
  but the field is currently inert. A **token/session attribute** missing a hardening flag
  (`HttpOnly`, `Secure`, `SameSite`) on a real session cookie. Raise it with the concrete weakness
  named.
- **NIT** — a hardening measure on a named-but-low-value asset, or a defense-in-depth nicety with a
  marginal, statable benefit: a security header where the exposure is minor, a slightly stronger-than-
  needed parameterization on a path that is already safe, a constant-time comparison on a non-secret.
  Worth a brief note, never a blocker.
- **NO_COMMENT** — speculative hardening with no named asset or attacker: "add a WAF" / "add a security
  header" / "encrypt this" with no exposed data and no vector; defense-in-depth layered behind a
  boundary that is already correctly enforced; flagging a dependency version (that is SCA's job, not a
  code-review finding); demanding input validation on data that never reaches a sink and is not trusted
  downstream. Stay silent.

**Overriding rule:** every finding above NO_COMMENT names a concrete exploit or exposure — *what an
attacker does and what they get*, or *what sensitive thing is exposed to whom*. "This is insecure" /
"this doesn't follow OWASP" / "add defense-in-depth" is **not** a finding. "This concatenates the path
variable into the query, so `'; DROP TABLE …` or `' OR '1'='1` exfiltrates every row" **is**. If you
cannot name the attack or the exposure, drop it. A demand for a control "to be safe," with no asset and
no vector, defaults to NO_COMMENT.

## Review Questions

- Where is the **trust boundary**, and what untrusted value crosses it into a sink (query, command,
  path, URL, markup, deserializer) without being parameterized, validated, or encoded?
- For this action: **who is allowed to perform it, on which object** — and is that enforced *here*, or
  assumed to be enforced elsewhere (the gateway, the UI, "the frontend won't send that")?
- This object is fetched by an id from the request — is there a check that the **caller may access
  *that* object**, or can they enumerate ids and read/alter someone else's data (IDOR)?
- Does any **secret, token, or PII** reach a log, an exception message, a response body, an analytics
  event, or a URL/query string on this path?
- For this password/token/crypto operation: is the **primitive fit for the purpose** — an adaptive KDF
  for passwords, a CSPRNG for tokens, an authenticated cipher mode, a key that is *not* in the source?
- Does this path **deserialize untrusted bytes**, parse external **XML with DTDs**, or make an
  **outbound call to a request-controlled URL** — and is the sink locked down (no polymorphic typing,
  DTDs disabled, an egress allowlist)?
- Does this request **bind more fields than it should** be able to set (a privilege or ownership field
  bound from the body)?
- If this **error/exception** reaches the client, does the response leak a stack trace, a SQL fragment,
  an internal hostname, or a version that helps an attacker?
- Is this a **CVE/dependency-version** concern? If so, it is **SCA tooling's** job — note it as out of
  scope rather than reviewing it by hand.

## Heuristics

### Injection — parameterize the query, don't concatenate untrusted input

**What to look for:** Untrusted input concatenated or interpolated into an interpreter string — a JPQL/
HQL/SQL query built with `+` or `String.format` (`"… WHERE name = '" + name + "'"`), a
`@Query` with manual concatenation, a `Statement.executeQuery(sql)` over a built string, a
`createNativeQuery` with an inlined value, an LDAP filter assembled from input, an OS command built
from a request value (`Runtime.exec("… " + arg)`), or a file path joined from a request segment
(`new File(base, requestPath)` allowing `../`). The tell is request data reaching an interpreter
without a bound parameter, a typed API, or canonicalization.

**Why it matters:** An interpreter (SQL engine, shell, LDAP server, filesystem) cannot tell attacker
data from intended syntax once they are concatenated into one string. A crafted parameter changes the
*meaning* of the statement: `' OR '1'='1` turns a single-row lookup into a full-table dump; `'; DROP
TABLE invoice; --` destroys data; a path of `../../etc/...` escapes the intended directory; a command
arg of `; rm -rf …` runs a second command. This is the most reliably exploitable class of bug there is,
and it is invisible to a test that only sends well-formed input.

**When NOT to comment:** The query already uses bound parameters (`?`/named params in `@Query`, a
`PreparedStatement`, a JPA `setParameter`, a Spring Data derived method, a Criteria/QueryDSL builder),
the "input" is a server-side constant or an enum (not attacker-controlled), or the path is canonicalized
and constrained to a safe base. Do not demand parameterization of a value the application itself
supplies, and do not flag a Spring Data method name as injection — it is not concatenation.

**Modern Java/Spring idiom:** Bind every untrusted value as a parameter — named parameters in a JPA
`@Query`, `JdbcTemplate`/`NamedParameterJdbcTemplate` placeholders, the Criteria API or QueryDSL for
dynamic queries, never string-built SQL. For a dynamic `ORDER BY`/column (which *cannot* be a bound
parameter), allowlist against a fixed set of legal column names rather than passing input through. For
OS interaction prefer a library API over `exec`; if a process is unavoidable, pass arguments as an array
(no shell) and validate them. For file paths, resolve and canonicalize, then verify the result stays
under the intended base. *Verify the persistence stack (Spring Data JPA, JDBC, jOOQ) before naming the
exact API.*

**Key review questions:** Does any untrusted value reach this query/command/path as *syntax* rather than
a bound parameter? For a dynamic column/sort, is it allowlisted, or is raw input interpolated?

**Example review comment:**
> MUST: `findByName` builds JPQL with `"… WHERE c.name = '" + name + "'"` from the request parameter, so
> a value of `' OR '1'='1` returns every `Customer` and `'; …` can alter data — classic SQL injection.
> Could we switch to a bound parameter (`@Query("… WHERE c.name = :name")` + `setParameter`, or a Spring
> Data derived `findByName`) so the value can never change the statement's meaning?

### Authorization & access control — enforce *who* may do *what* to *which object*

**What to look for:** A state-changing or data-returning entry point (an HTTP endpoint, a message
handler, a resolver) with **no authorization check**, or a check that confirms *authentication* ("is
someone logged in?") but not *authorization* ("may *this* someone do *this*?"). The two highest-value
shapes: a **missing function-level check** (any authenticated user can hit an admin or cross-tenant
action), and **broken object-level authorization / IDOR** — an object loaded by a request-supplied id
(`orderRepo.findById(id)`) and returned or mutated with no check that the caller owns or may access
*that* object, so ids are enumerable into other users' data. Also: a `@PreAuthorize`/`@Secured` present
on some sibling methods but absent on a new one; a check done in the UI/gateway and assumed sufficient
at the service; a role check that uses the *requested* role rather than the caller's actual one.

**Why it matters:** Broken access control is consistently the most prevalent real-world web
vulnerability, and it does not require a crafted payload — just a logged-in attacker calling an endpoint
they shouldn't, or incrementing an id. A missing function-level check lets a normal user perform a
privileged action (escalation). An IDOR lets them read or alter records belonging to other customers or
tenants by guessing/enumerating identifiers — a `GET /invoices/{id}` that returns any invoice, a
`POST /orders/{id}/cancel` that cancels anyone's order. The damage (data disclosure across tenants,
unauthorized state change, privilege escalation) is immediate and total for the affected object, and a
single-user test never reveals it.

**When NOT to comment:** The endpoint is *intentionally* public and serves only non-sensitive data (and
that intent is visible — a `permitAll()` on a health/landing route), the ownership/tenant check is
already present (the query is scoped to the caller — `findByIdAndOwner(id, currentUser)` — or
`@PostAuthorize`/a domain check verifies access), or the action genuinely has no per-object authority
(a global lookup every authenticated user may read). Do not demand `@PreAuthorize` on a route whose
authorization is correctly enforced one layer in, and do not invent a tenant model the system does not
have.

**Modern Java/Spring idiom:** Enforce authorization at a single, consistent layer rather than ad-hoc per
controller — Spring Security method security (`@PreAuthorize`/`@PostAuthorize`, enabled via
`@EnableMethodSecurity`) or an authorization-manager/filter, with the rule expressed in terms of the
*caller's* authority. For object-level authority, scope the query to the principal
(`findByIdAndOwnerId(id, principal.id())`) so a wrong id returns nothing, or verify ownership after load
and 404/403 otherwise — do not load-then-return on a request id alone. Keep the check server-side; a
UI/gateway check is defense-in-depth, never the authority. *Verify Spring Security is present and the
method-security version/style before recommending the annotation; the load-scoped-by-owner pattern is
framework-independent.*

**Key review questions:** Who is allowed to perform this action, on which object — and is that enforced
*here*? If I change the id in the request to one I don't own, do I get someone else's data or action?

**Example review comment:**
> MUST: `GET /api/invoices/{id}` loads `invoiceRepo.findById(id)` and returns it with only an
> "authenticated" check — no verification that the caller owns the invoice. Any logged-in user can
> enumerate `id`s and read every customer's `Invoice` (broken object-level authorization / IDOR). Could
> we scope the load to the principal (`findByIdAndCustomerId(id, principal.customerId())`, returning 404
> when it doesn't match) so a foreign id discloses nothing?

### Secrets & credentials — never hard-coded, never logged

**What to look for:** A secret living somewhere it can be read — a password, API key, token, signing key,
private key, or connection string **literal in source** (`String key = "AKIA…"`,
`spring.datasource.password=…` committed in `application.yml`), a secret in a **log statement**
(`log.info("auth header {}", authHeader)`, logging a whole request/response that carries a token), a
secret in an **exception message or stack** that gets logged or returned, a credential in a **URL/query
string** (`https://api/…?api_key=…`), or a `.env`/`application-*.properties` with real values staged for
commit. This lens **owns this MUST** — `spring-production-readiness` explicitly defers it here.

**Why it matters:** A hard-coded secret is compromised the moment the repo is shared, forked, or
breached — and it stays in git history after it is "removed," so the only real fix is rotation. A secret
in a log is exposed to everyone who can read logs (often a much wider set than who can read the
database) and to every downstream log aggregator, and it is the classic way a token meant for one
service ends up in a third-party logging SaaS. A secret in a URL leaks into proxy logs, browser history,
and `Referer` headers. None of these require an "attack" — just access to an artifact that is less
guarded than the secret itself.

**When NOT to comment:** The value is sourced from the environment / a secrets manager / an externalized
config not in git (`${DB_PASSWORD}`, a Vault/secrets-manager lookup, a profile-specific file that is
git-ignored), the logged value is explicitly redacted/masked, or the "secret-looking" string is a public
identifier (a public key, a non-secret client id). Do not flag a placeholder in an example/test config
that is obviously fake, and do not treat every `token` variable as a leak — confirm it actually reaches
a sink.

**Modern Java/Spring idiom:** Externalize secrets — environment variables, Spring Cloud Config /
Vault / a cloud secrets manager, or at minimum a git-ignored profile file — referenced via
`${…}` placeholders or `@ConfigurationProperties`, never literals. Keep secrets out of logs by logging
identifiers, not credentials; mask sensitive fields (a custom `toString`, a logging filter, a serializer
that redacts); never log full auth headers or request bodies that carry tokens. Note the BOM gotcha when
reading a token from a UTF-8 file with a byte-order mark — a stray BOM corrupts a `Bearer` value — strip
it on load. Delegate detection of *committed* secrets to a secret-scanner (`gitleaks`, `trufflehog`) in
CI; this lens flags the *code-shaped* leak you can see in the diff. *Verify the project's config/secrets
mechanism before prescribing one.*

**Key review questions:** Is this secret a literal in source/committed config, or sourced from outside
git? Does any credential, token, or key reach a log line, an exception, a response, or a URL on this
path?

**Example review comment:**
> MUST: the exception handler logs `log.error("upstream call failed for request {}", request)` and the
> `request` includes the `Authorization` bearer token, so every failure writes a live token to the logs
> — anyone with log access (and the log aggregator) can impersonate the user. Could we log a correlation
> id and the status instead of the full request, and mask the auth header at the logging boundary?

### Sensitive-data exposure — classify it, then keep it out of logs, errors, and URLs

**What to look for:** PII or sensitive data (names tied to identifiers, financial detail, health data, a
full `Account`/`Customer` record, an internal-only field) flowing to a **log**, an **error response
returned to the client**, an **analytics/telemetry event**, a **URL/query string**, or an **outbound
third-party call** that does not need it. Also: an over-broad API response that serializes the *entire*
entity (including fields the caller should not see — internal flags, other users' references, hashed
credentials) instead of a purpose-built DTO; a verbose `@ControllerAdvice`/default error page returning
a stack trace or SQL to the caller.

**Why it matters:** Sensitive data in a log or a third-party call widens its exposure far beyond the
controlled store it came from — logs are retained, shipped, and read broadly, and a third party you send
it to now *has* it. A stack trace or SQL fragment in an error response is reconnaissance: it tells an
attacker your framework, versions, schema, and internal hostnames, lowering the cost of the next step.
Serializing a whole entity leaks fields the client was never meant to see (and couples the API to the
schema). The harm — a privacy/compliance breach, an information-disclosure foothold — is real even
without a further "exploit."

**When NOT to comment:** The data is genuinely non-sensitive (a public catalog field), the log/response
is already redacted or returns a safe, generic error with a correlation id, or the response is a scoped
DTO/projection rather than the raw entity. Do not demand redaction of data that carries no sensitivity,
and do not treat a generic 500 with a trace id as a leak. (The *diagnosability* of an error — is there
enough to debug it — is `spring-production-readiness`'s concern; *what the error reveals to the client*
is this lens's.)

**Modern Java/Spring idiom:** Return purpose-built DTOs/projections from APIs, not raw entities, so only
intended fields cross the boundary. Map exceptions to safe client responses via a single
`@ControllerAdvice`/`@ExceptionHandler` (or `ProblemDetail` on recent Spring) that returns a generic
message + a correlation id and logs the detail server-side — never the stack to the client. Classify
sensitive fields and mask them in logs (a redacting serializer, a `toString` that omits PII). Keep
sensitive values out of URLs/query strings (use the body or headers). *Verify the Spring version for
`ProblemDetail`/error-handling APIs before recommending them.*

**Key review questions:** What is the data classification of each field crossing this boundary, and does
anything sensitive reach a log, a client error, an analytics event, a URL, or a third party that doesn't
need it? Does this response serialize more of the entity than the caller should see?

**Example review comment:**
> SHOULD: the new `@ExceptionHandler` returns `ex.getMessage()` and the stack trace in the 500 body, so
> a failure hands the client the SQL, the schema, and the framework version — useful reconnaissance for
> an attacker. Could we return a generic message plus a correlation id and log the detail server-side
> (e.g. a `ProblemDetail` if the Spring version supports it)?

### Cryptography & randomness — fit the primitive to the purpose

**What to look for:** A cryptographic primitive used where it doesn't fit. **Passwords** hashed with
`MessageDigest`/SHA-256/MD5 or any fast/un-salted hash instead of an adaptive KDF; **tokens, nonces,
salts, session ids, password-reset codes** generated with `java.util.Random` or `Math.random()` instead
of a CSPRNG; **encryption** with `Cipher.getInstance("AES")` (defaulting to ECB) or a hard-coded /
checked-in **key or IV**; a **broken/legacy algorithm** (DES, RC4, MD5/SHA-1 for integrity where
collision-resistance matters); a hand-rolled crypto construction; a non-constant-time comparison of a
secret (`equals` on an HMAC/token). Also a TLS/host-verification setting disabled in code (a
trust-all `TrustManager`, `setHostnameVerifier` accepting all).

**Why it matters:** Each mismatch has a direct exploit. A fast hash over a password means a stolen
database is cracked offline at billions of guesses per second — an adaptive KDF (`BCrypt`/`Argon2`/
`PBKDF2`) is deliberately slow to make that infeasible. `java.util.Random` is a linear congruential
generator whose output is *predictable* from a few samples, so a token/reset-code built on it can be
guessed — letting an attacker forge a session or hijack a reset. ECB mode reveals plaintext patterns
(identical blocks encrypt identically), and a hard-coded key means "encrypted" data is readable by
anyone with the source. A trust-all TLS manager defeats the point of TLS — a MITM reads everything.

**When NOT to comment:** Passwords already use `BCryptPasswordEncoder`/`Argon2`/`PBKDF2`; tokens/salts
already use `SecureRandom`; encryption uses an authenticated mode (AES-GCM) with a key from a
KMS/keystore, not source; comparisons of secrets use a constant-time method. Do not demand
constant-time comparison on a non-secret, do not flag MD5/SHA-1 used for a *non-security* checksum
(a cache key, a content fingerprint where collisions are not adversarial), and do not invent a key-
rotation requirement with no threat. Do not re-derive crypto the platform already provides correctly.

**Modern Java/Spring idiom:** Store passwords with Spring Security's `PasswordEncoder` —
`BCryptPasswordEncoder` or an `Argon2`/`Pbkdf2` encoder, or `DelegatingPasswordEncoder` for migration.
Generate all security-sensitive randomness with `java.security.SecureRandom`. Encrypt with an
authenticated mode (AES/GCM) and a key from a keystore/KMS, never a literal. Compare secrets with
`MessageDigest.isEqual` (constant-time). Leave TLS verification on. *Verify Spring Security and the JCA
providers on the classpath before naming the encoder; never assume `Argon2` is available without the
dependency.*

**Key review questions:** Is this password stored with an adaptive KDF, or a fast/un-salted hash? Is
this token/nonce/salt from a CSPRNG, or a predictable `Random`? Is the cipher mode authenticated and the
key sourced from outside the code?

**Example review comment:**
> MUST: passwords are stored as `MessageDigest.getInstance("SHA-256").digest(pw)`, a fast unsalted hash,
> so a leaked `user` table is cracked offline almost instantly. Could we switch to an adaptive KDF via
> Spring Security's `BCryptPasswordEncoder` (or `Argon2`), which is deliberately slow and salted? Verify
> the encoder dependency is on the classpath.

### Untrusted deserialization, XXE & SSRF — lock down the dangerous sinks

**What to look for:** Three high-impact sinks fed by untrusted input. **Deserialization** — native Java
`ObjectInputStream.readObject()` on request/queue bytes, or a JSON/XML library with **polymorphic typing
enabled** (`ObjectMapper.activateDefaultTyping(...)`, `@JsonTypeInfo` over an open type) on external
input. **XML external entities (XXE)** — a `DocumentBuilderFactory`/`SAXParserFactory`/`XMLInputFactory`/
transformer parsing external XML **with DTDs/external entities not disabled**. **SSRF** — an outbound
HTTP/file fetch (`RestClient`/`WebClient`/`HttpClient`/`URL.openStream`) to a **URL taken from the
request** with no allowlist (a webhook target, an "import from URL", an avatar fetch).

**Why it matters:** Each is a top-tier exploit. Deserializing untrusted bytes with a reachable gadget
chain — or JSON with default typing — is **remote code execution**: the attacker instantiates arbitrary
types and runs code in your process. XXE lets a crafted document read local files (`file:///etc/...`),
reach internal URLs, or hang the parser (billion-laughs DoS). SSRF turns your server into the attacker's
proxy: a request-controlled URL lets them reach internal-only services, cloud metadata endpoints (often
holding credentials), or the loopback admin port — from inside your trust boundary, past your firewall.
None are theoretical; all are routinely weaponized.

**When NOT to comment:** Deserialization is of *trusted* internal data only, or uses a safe format (plain
JSON to known DTOs with default typing **off**, which is the modern Jackson default). The XML parser
already disables DTDs/external entities (or no XML of external origin is parsed). The outbound URL is a
fixed/configured endpoint, not request-controlled, or is already constrained by an allowlist/egress
proxy. Do not flag plain DTO binding as "deserialization RCE" — without polymorphic typing it is not the
gadget sink. Do not invent an SSRF where the destination is a constant.

**Modern Java/Spring idiom:** Avoid native Java serialization for any external boundary — use JSON to
explicit DTO types and keep polymorphic/default typing **off** (validate types explicitly if
polymorphism is genuinely needed). Harden XML parsers: disable DTDs
(`setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)`) and external entities, or
use a library configured secure-by-default. For request-driven outbound calls, **allowlist** the
destination (scheme + host), resolve and re-check the host, and block private/loopback/link-local
ranges and metadata IPs — ideally behind an egress proxy. *Verify the JSON/XML library and HTTP client
in use, and their versions' defaults, before prescribing the exact setting.*

**Key review questions:** Does this path deserialize attacker-controlled bytes, or enable polymorphic
typing on external input? Does the XML parser read external input with DTDs enabled? Is this outbound
URL taken from the request, and is the destination allowlisted?

**Example review comment:**
> MUST: the import endpoint fetches `restClient.get().uri(userSuppliedUrl)` with no destination
> allowlist, so an attacker passes an internal URL (the cloud metadata endpoint, a loopback admin port)
> and uses the server as a proxy past the firewall — SSRF, and the metadata endpoint often leaks
> credentials. Could we allowlist scheme+host, resolve and re-check the host, and reject
> private/loopback/link-local targets (or route through an egress proxy)?

### Mass assignment, CSRF & CORS — bind, change-protect, and share-cross-origin deliberately

**What to look for:** **Mass assignment / over-broad binding** — a request body bound straight onto a
domain entity or a wide command (`@RequestBody Account account` → `save(account)`), letting the caller
set fields they shouldn't (`role`, `isAdmin`, `ownerId`, `balance`, `verified`). **CSRF** — a
state-changing endpoint reachable by a browser session with CSRF protection disabled where it shouldn't
be (`csrf().disable()` on a cookie-authenticated form app). **CORS** — `allowedOrigins("*")` (especially
with `allowCredentials(true)`, which the spec forbids together but misconfigurations force), or an
origin reflected from the request, on an authenticated API.

**Why it matters:** Mass assignment lets an attacker escalate or tamper by adding a field the form never
showed — binding `"role":"ADMIN"` or `"ownerId":<someone-else>` into the entity and saving it. Disabling
CSRF on a cookie-session app lets a malicious site forge state-changing requests the browser sends with
the victim's session (transfer, delete, change-email). An over-broad CORS policy on a credentialed API
lets any origin's JavaScript read authenticated responses in the victim's browser — turning the same-
origin policy off for your sensitive data. Each is a concrete cross-user attack, not a hypothetical.

**When NOT to comment:** Binding is onto a **scoped DTO** that exposes only the settable fields (the
correct, common defense — the entity's privileged fields simply aren't in the DTO); CSRF is disabled on
a **stateless token-authenticated API** (no cookie, no CSRF risk — the correct case, do not demand CSRF
tokens there); CORS is scoped to known origins (or the API is same-origin only). Do not flag
`csrf().disable()` on a pure bearer-token REST API, and do not demand a CORS policy where there is no
browser cross-origin caller.

**Modern Java/Spring idiom:** Bind requests to **purpose-built DTOs/records** containing only the fields
the caller may set, then map to the entity server-side — never bind a request directly onto a JPA
entity. Keep Spring Security's CSRF protection **on** for cookie/session browser apps; disable it only
for stateless token APIs where it does not apply. Configure CORS with an explicit origin allowlist and
`allowCredentials` only with specific origins, never `*` + credentials. *Verify whether the app is
session- or token-authenticated before judging CSRF, and verify the Spring Security version for the CORS/
CSRF config API.*

**Key review questions:** Can this request set a field it shouldn't (privilege, ownership, balance) via
broad binding? Is this a cookie-session app with CSRF disabled, or a token API where CSRF doesn't apply?
Is the CORS origin an explicit allowlist, or `*`/reflected on a credentialed API?

**Example review comment:**
> MUST: `update` takes `@RequestBody Account account` and calls `repo.save(account)`, binding the whole
> entity — a caller can send `"role":"ADMIN"` (or another user's `ownerId`) and the field is persisted,
> escalating privilege. Could we bind to a DTO with only the editable fields and map onto the loaded
> entity server-side, so privileged fields can't be set from the body?

## Anti-Patterns

- **Concatenated query** — *Diff:* untrusted input joined into SQL/JPQL with `+`/`String.format` or an
  inlined `@Query`. *Harm:* SQL injection — a crafted value reads or alters the whole table, or destroys
  data. *Fix:* bound parameters / derived methods / Criteria; allowlist a dynamic column, never
  interpolate it.
- **Endpoint with no authorization check** — *Diff:* a state-changing/data-returning action gated only
  by authentication (or nothing). *Harm:* any caller performs a privileged or cross-user action
  (escalation). *Fix:* enforce authorization server-side (method security / authorization manager) in
  terms of the caller's authority.
- **IDOR / broken object-level authz** — *Diff:* an object loaded by a request id and returned/mutated
  with no ownership check. *Harm:* an attacker enumerates ids and reads/alters other tenants' records.
  *Fix:* scope the load to the principal (`findByIdAndOwner`), or verify ownership and 404/403.
- **Hard-coded secret** — *Diff:* a password/key/token literal in source or committed config. *Harm:*
  the secret is compromised on any repo share/breach and lives forever in git history. *Fix:* externalize
  to env/secrets manager via `${…}`; rotate the exposed value; let a secret-scanner gate commits.
- **Secret / PII in a log** — *Diff:* a token, credential, or PII written to a log line, exception, or
  response. *Harm:* exposure to everyone with log/aggregator/URL access — far wider than the store it
  came from. *Fix:* log identifiers not secrets; mask sensitive fields at the logging boundary.
- **Weak password storage** — *Diff:* `MessageDigest`/SHA/MD5 or a fast/un-salted hash for passwords.
  *Harm:* a stolen store is cracked offline almost instantly. *Fix:* an adaptive KDF — `BCrypt`/`Argon2`/
  `PBKDF2` via Spring Security's `PasswordEncoder`.
- **`java.util.Random` for a security token** — *Diff:* a token/nonce/salt/reset-code from `Random`/
  `Math.random()`. *Harm:* the value is predictable and can be guessed → forged session / hijacked reset.
  *Fix:* `java.security.SecureRandom`.
- **Broken cipher** — *Diff:* `Cipher.getInstance("AES")` (ECB), a hard-coded key/IV, or a legacy
  algorithm. *Harm:* "encrypted" data is readable / pattern-leaking. *Fix:* an authenticated mode
  (AES/GCM) with a key from a keystore/KMS.
- **Insecure deserialization** — *Diff:* native `ObjectInputStream` on untrusted bytes, or JSON
  polymorphic/default typing on external input. *Harm:* remote code execution via a gadget chain. *Fix:*
  JSON to explicit DTOs with default typing off; never native-deserialize external bytes.
- **XXE** — *Diff:* an XML parser on external input with DTDs/external entities enabled. *Harm:* local
  file read, internal SSRF, billion-laughs DoS. *Fix:* disable DTDs and external entities (or a
  secure-by-default parser).
- **SSRF** — *Diff:* an outbound fetch to a request-controlled URL with no allowlist. *Harm:* the server
  proxies the attacker to internal services / cloud metadata (credential theft). *Fix:* allowlist
  scheme+host, re-resolve and block private/loopback/metadata ranges, prefer an egress proxy.
- **Mass assignment** — *Diff:* a request body bound directly onto an entity/wide command. *Harm:* the
  caller sets a privilege/ownership field (`role`, `ownerId`) and it persists. *Fix:* bind to a scoped
  DTO with only settable fields; map server-side.
- **CSRF disabled on a session app / wildcard CORS on a credentialed API** — *Diff:* `csrf().disable()`
  with cookie auth, or `allowedOrigins("*")` + credentials. *Harm:* a malicious site forges
  state-changing requests / reads authenticated responses cross-origin. *Fix:* keep CSRF on for
  cookie/session apps; allowlist specific CORS origins, never `*` with credentials.
- **Verbose error to the client** — *Diff:* a handler returning a stack trace / SQL / internal host /
  version. *Harm:* reconnaissance that eases the next attack. *Fix:* a generic message + correlation id
  to the client, detail logged server-side.

## Modernization (Java/Spring security idioms)

Standing guidance: **inspect the target project's stack before recommending anything, and never assume a
version, a library, or a control is present.** Security facilities are version- and dependency-gated, and
**dependency-version vulnerabilities are SCA tooling's job, not this lens's** — do not hand-review a CVE
feed. Frame each as *verify against the actual project*:

- **Query parameterization** — JPA named parameters, `NamedParameterJdbcTemplate`, Criteria/QueryDSL,
  jOOQ. *Verify the persistence stack; for a dynamic column/sort, allowlist rather than parameterize.*
- **Method & web authorization** — Spring Security `@PreAuthorize`/`@PostAuthorize` (via
  `@EnableMethodSecurity`), `AuthorizationManager`, request-matcher rules. *Verify Spring Security is on
  the classpath and the method-security version/style; the load-scoped-by-owner pattern for object-level
  authz needs no framework.*
- **Password storage** — `BCryptPasswordEncoder`, `Argon2PasswordEncoder`, `Pbkdf2PasswordEncoder`, or
  `DelegatingPasswordEncoder` for migration. *Verify Spring Security and that the chosen encoder's
  dependency (e.g. Bouncy Castle for Argon2) is present.*
- **Randomness** — `java.security.SecureRandom` for every token/nonce/salt/id. *Version-independent;
  never `java.util.Random` for security values.*
- **Encryption** — AES/GCM (authenticated), key from a keystore/KMS/secrets manager. *Verify the JCA
  providers and the key-management facility; never a literal key.*
- **Secrets management** — environment variables, Spring Cloud Config/Vault, a cloud secrets manager,
  referenced via `${…}`/`@ConfigurationProperties`; secret-scanning (`gitleaks`/`trufflehog`) in CI.
  *Verify the project's config mechanism; delegate committed-secret detection to the scanner.*
- **Safe error handling** — a single `@ControllerAdvice`/`@ExceptionHandler`, `ProblemDetail` for a
  generic client response with detail logged server-side. *Verify the Spring version for `ProblemDetail`/
  RFC 7807 support.*
- **Deserialization & XML** — JSON to explicit DTOs with polymorphic/default typing **off**; XML parsers
  with DTDs/external entities disabled. *Verify the JSON (Jackson/Gson) and XML library and their
  version defaults.*
- **Outbound-call egress control** — destination allowlists, host re-resolution, private/metadata-range
  blocking, an egress proxy for request-driven fetches. *Verify the HTTP client (`RestClient`/`WebClient`/
  `HttpClient`) in use.*
- **CSRF/CORS/session** — CSRF on for cookie/session apps and off only for stateless token APIs; CORS
  with an explicit origin allowlist; `HttpOnly`/`Secure`/`SameSite` cookie attributes. *Verify whether
  the app is session- or token-authenticated and the Spring Security config API version.*
- **Dependency & static analysis (delegated, tooling)** — SCA (OWASP Dependency-Check, Snyk,
  `dependabot`), SAST, DAST, secret-scanning. *These find the dependency-version and broad-pattern issues
  a human reviewer should not enumerate by hand — recommend wiring them, do not perform them in review.*

When the simplest correct thing is *no* extra control — the input never reaches a sink, the endpoint
serves public data, the value is already parameterized and scoped — say so plainly. The named exploit is
the target, not maximal hardening.

## Suggested Comment Style

Respectful, consequence-first, severity-honest. Lead with the **exploit** — what an attacker does and
what they get — not the rule or the OWASP category. Make NITs explicitly optional, endorse code that is
already safe, and when something is the SCA/scanner's job, say so rather than hand-reviewing it. Example
openers:

- "A crafted value here would..." (names the injection)
- "Any logged-in user could change the id and..." (names the IDOR)
- "This writes the token to the logs, so anyone with log access..." (names the exposure)
- "This is a dependency-version concern — your SCA scanner is the right place for it, not this review."
  (delegates to tooling)
- "This binds to a scoped DTO and the query is owner-scoped — authorization looks correctly enforced, no
  change needed." (endorses)

Short examples with neutral nouns:

- > MUST: `findByName` concatenates the request `name` into JPQL, so `' OR '1'='1` returns every
  > `Customer`. A bound `:name` parameter closes it.
- > MUST: `GET /transfers/{id}` returns `findById(id)` with no owner check — any user enumerates ids and
  > reads others' `Transfer`s (IDOR). Scope the load to the principal so a foreign id returns 404.
- > SHOULD: the login endpoint has no rate-limit or lockout, so credential-stuffing is feasible. A
  > per-account attempt limit (or a `bucket4j`-style throttle, if available) would raise the cost.
- > NIT (not a blocker): a `Secure`/`SameSite` attribute on this session cookie is a cheap hardening; the
  > current exposure is low. Fine to defer.

## Integration (java-pr-review, architecture-review, and spec-author)

- Apply with the consumer's altitude and intent. **`java-pr-review`** reads it **evaluatively** on the
  **changed lines** (this query, this handler, this log statement, this deserializer).
  **`architecture-review`** reads it **evaluatively** at **system altitude** (the trust boundary, the
  authorization model, the secrets-management story, the threat surface a change adds). **`spec-author`**
  reads it **generatively** — *what security does this design have to decide up front* (trust boundary,
  authz model, data classification, secret handling) — recording it so the reviewer never has to find it
  missing. Same knowledge, three uses.
- **Never raise a finding without a named exploit or exposure.** "This is insecure" / "doesn't follow
  OWASP" / "add defense-in-depth" is `NO_COMMENT` unless you can say what an attacker concretely does and
  gets, or what sensitive thing is exposed to whom. Speculative hardening is not a finding.
- **A missing control with a named exploit is usually a `MUST`, not a speculative SHOULD.** Unlike a
  resilience control, an absent authorization check or a concatenated query is exploitable *now* — name
  the attack and rate it accordingly. But a hardening measure with no exposed asset (a header on public
  data, a second layer behind an enforced boundary) is `NO_COMMENT`.
- **Always tag severity** — MUST / SHOULD / NIT — per [`../rules/severity-rubric.md`](../rules/severity-rubric.md),
  and always name the concrete exploit/exposure. NO_COMMENT is the silent fourth outcome.
- **Delegate to tooling, don't be a scanner.** Dependency-version CVEs, broad pattern sweeps, and
  committed-secret detection are SCA/SAST/secret-scanner jobs run in CI — recommend wiring them; do not
  hand-review a CVE feed in a PR. This lens flags the *code-shaped* and *design-shaped* hole a scanner
  cannot see.
- **Stay in your lane.** This lens owns the **secret/PII-in-log MUST** that
  [`./spring-production-readiness.md`](./spring-production-readiness.md) explicitly delegates here, plus
  injection, authorization, crypto, the dangerous sinks, and the trust boundary. The *runtime-failure*
  reading of the same code (a swallowed exception losing data, a missing timeout, a race) is
  [`./spring-production-readiness.md`](./spring-production-readiness.md)'s. Input validation here is under
  a **security** lens (does it reach a sink / cross a trust boundary?), not generic Bean Validation
  shape. Idempotency/at-least-once handling at the boundary is production-readiness and
  [`./saga.md`](./saga.md); where the consistency/authority boundary *falls* (which aggregate owns a
  decision) is [`./ddd.md`](./ddd.md). Whether a security path is *tested* is [`./testing.md`](./testing.md);
  structural patterns are [`./design-patterns.md`](./design-patterns.md) and [`./solid.md`](./solid.md).
  Defer to those rather than re-litigating them here.
- **Prefer a few strong findings over many weak ones.** One concatenated query, one IDOR, or one logged
  token lands; ten "consider validating this" notes bury it. Drop the weak ones to NO_COMMENT.
