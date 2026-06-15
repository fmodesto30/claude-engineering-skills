# AnalysisSpec

<!--
This is the intermediate analytical CONTRACT — the thing that must be filled and validated BEFORE
any HTML report is produced. The HTML report is DERIVED from this contract; it is not a starting
point and must not be produced until this contract is filled and passes
[`../rules/analysis-rigor.md`](../rules/analysis-rigor.md).

That ordering is the whole point. The pipeline is:
  request -> understand the DECISION being supported -> DATA-ENGINEERING (discover sources, model
  the grain, validate quality) -> DATA-ANALYSIS (pick the method, interpret, separate fact from
  inference, state confidence) -> fill and VALIDATE this contract (HARD GATE) -> only then choose
  the report shape and render the HTML.
Never start from a chart, a layout, or an appearance and work backward to justify it. The visuals
are the last step and every one of them is derived from a finding recorded here.

Fill the fields below in order. Each carries guidance on what a good value looks like and what makes
it invalid. Delete the guidance comments before the contract is reviewed. Scale to the question — a
small, low-stakes question needs only a subset of fields filled honestly, not every field padded —
but the fields that are NEVER optional are: quality_checks, limitations, every finding's tag +
evidence + confidence, and recommended_report_type. A contract missing any of those does not pass
the gate.

Neutral domain only for examples: Order, Payment, Notification, Report, Customer, Invoice,
PricingRule, Shipment, AuditEntry, LineItem, Money, TaxRule; environments dev / hom / prod. Never a
real company, system, person, or dataset.

CREDENTIALS AND SECRETS ARE INPUTS ONLY. A connection string, token, key, or personal datum may be
needed to GATHER the data; none of it is ever written into this contract or the report. Describe HOW
the data was obtained (the query, the source, the window) — never the keys used to obtain it.
-->

## Status

<!--
Load-bearing and checkable from the artifact itself — a reader (or the report skill) must be able to
read these two lines and know whether rendering is permitted, without trusting the actor's word.
- Status is the assembly state and the SINGLE render-gate signal:
  - `Validated` — the filled contract passed ../rules/analysis-rigor.md with a `ready` or
    `ready-with-SHOULDs` verdict; rendering is permitted. `Validated` is RESERVED for this case.
  - `Blocked` — a BLOCKER remains, or the verdict is `not-ready` or `BLOCKED-by-data-quality`;
    rendering a confident report is forbidden. The honest output is a LIMITED or data-quality
    report (conclusions downgraded, limitations foregrounded), never a polished claim the data
    cannot carry. Never mark a blocked analysis `Validated`.
  - `Draft` / `In Review` — not yet gated; rendering is forbidden.
- Rigor verdict is the verdict that rule returns: ready / ready-with-SHOULDs / not-ready /
  BLOCKED-by-data-quality (see ../rules/analysis-rigor.md "Verdict"). `Validated` requires a
  `ready` / `ready-with-SHOULDs` verdict; Status and verdict must agree.
HARD GATE: the HTML report MUST NOT be rendered unless Status is `Validated` — that single line is
the gate, read from the artifact, not assumed.
-->

- Status: Draft | In Review | Validated | Blocked
- Rigor verdict: ready | ready-with-SHOULDs | not-ready | BLOCKED-by-data-quality <!-- per ../rules/analysis-rigor.md -->

## Metadata

<!--
One compact block.
-->

- Author: <!-- a person, not a team -->
- Date / last updated:
- Related: <!-- the request/ticket, the source systems, any prior analysis this builds on -->

## business_question

<!--
The one question this analysis exists to answer, stated plainly and answerably. Not a topic ("Order
volume"), a question ("Is Order volume in prod growing month over month, and where is the growth
concentrated?"). A reader must be able to tell, when the analysis is done, whether the question was
answered, partially answered, or could not be answered. If you cannot phrase it as a question with a
checkable answer, the analysis has no target yet — stop and pin it down.
INVALID: a vague theme; several unrelated questions bundled as one; a question whose answer is
already assumed in its phrasing ("Why did prod Order volume collapse?" when no collapse is
established).
-->

## decision_supported

<!--
The decision or action this analysis informs — why anyone asked. "Whether to right-size the prod
datastore for the next quarter"; "whether to approve the PricingRule migration go/no-go". An
analysis with no decision behind it tends to sprawl; naming the decision bounds what is in scope and
tells you when you have enough. If the honest answer is "exploratory, no decision yet", say that —
it legitimately changes how much rigor and how strong a conclusion the situation can bear.
-->

## audience

<!--
Who reads the result and acts on it — this drives the eventual report shape (see
recommended_report_type). Engineer / tech lead, ops / business, product owner / team, or
management / steering. The same facts are shaped very differently for different readers; record the
reader so the report is not mis-shaped later.
-->

## sources

<!--
Every data source the analysis draws on, each with its OWNER and its FRESHNESS. A source with no
owner is a source no one can vouch for; a source with no freshness is a source you cannot trust to
be current. For each: name / table / file, the owner (the team or system of record), how it was
accessed (the query or extract — described, never the credential), and freshness (as-of timestamp,
last load time, or "live"). Note the timezone the timestamps are in.
INVALID: "the database"; a source with no owner; a source whose freshness is unknown and unflagged.
Example:
- `orders` table (prod), owner: Ordering system of record; accessed via a read-only aggregate query
  over placed_at; freshness: snapshot as-of 2026-06-13 23:59 America/Sao_Paulo.
- monthly `Invoice` extract (hom), owner: Billing; CSV export; freshness: last load 2026-06-01,
  KNOWN one load behind prod — recorded as a limitation below.
-->

## grain

<!--
The grain of the data you analyzed — what ONE ROW represents after your transformations. "One row =
one placed Order" / "one row = one Customer-month". The single most common source of a wrong number
is a misunderstood grain (counting Order rows when a join has multiplied them to LineItem rows). State
the grain explicitly and, where you join, state what keeps the grain from multiplying (the key you
joined on and that it is unique on the many side). If the grain changed across a transformation, say
so.
INVALID: unstated grain; a grain that silently changed mid-analysis; a count taken at a grain
different from the one claimed.
-->

## dimensions

<!--
The dimensions you sliced by — the categorical axes of the analysis (environment dev/hom/prod,
region, Customer tier, time bucket). Each dimension that appears in a finding or a chart must be
justified: why this cut answers part of the business_question. A dimension included with no reason is
noise that invites spurious patterns. State the cardinality where it matters (a breakdown by a
high-cardinality key is usually the wrong cut).
-->

## measures

<!--
The quantities you measured, each with its UNIT and its exact definition. "count of placed Orders";
"sum of LineItem Money in BRL"; "p99 of Order-to-Shipment latency in hours". A measure with no unit
is unreadable; a measure with no definition is unreproducible (is "active Customer" one with an Order
in 30 days, or ever?). Where a measure is a mean or another summary statistic, note it here so the
distribution check in quality_checks is not forgotten — a mean is only honest if the distribution
supports it.
INVALID: a bare number with no unit; "revenue" with no definition of what is summed; a mean recorded
with no distribution check.
-->

## time_range

<!--
The exact time window the analysis covers, with timezone, and the boundary convention (inclusive /
exclusive). "2025-06-01 00:00 to 2026-06-01 00:00 America/Sao_Paulo, left-inclusive". If you compare
periods, state BOTH windows and confirm they are comparable in length and in calendar shape — a
28-day February against a 31-day month, or a partial current month against full prior months, is a
period-comparison hazard that MUST be flagged here and carried into limitations. Never compare
incompatible periods without a warning.
-->

## filters

<!--
Every filter applied to the data, stated so the result is reproducible and its scope is honest.
"prod only; excludes cancelled Orders; excludes internal test Customers (flagged is_test)". A filter
that materially shrinks the population (excluding a status, an environment, a Customer class) must be
named — an unstated filter is how a partial picture gets read as the whole. State what a filter
removes and roughly how much.
-->

## transformations

<!--
What you did to the raw data to get to the analyzed grain: the joins, aggregations, derivations,
dedup, currency conversion, bucketing. Enough that a peer could reproduce the numbers — describe the
steps, not paste the credentials or the full query if it carries secrets. Call out any join that
could multiply rows and what prevents it, any currency or unit conversion and its rate/as-of, and any
derived field and its formula. This is where row-multiplication and double-counting are caught before
they reach a finding.
-->

## quality_checks

<!--
REQUIRED. NEVER OPTIONAL. What you checked about the data's quality and the RESULT of each check —
not a promise that the data is fine, the actual checks and what they found. This is the
data-engineering heart of the contract: a finding is only as trustworthy as the data under it, and
an unchecked dataset yields, at best, a LIMITED conclusion. Cover, at minimum, the checks that apply:

- Schema & types: columns and types are as expected; no silent string-where-number.
- Units & timezone: every measure's unit is consistent; timestamps are in a known, single timezone.
- Duplicates: checked for duplicate rows / double-counting at the stated grain — result.
- Nulls: which columns had nulls, how many, and how they were handled (excluded? zero-filled? — and
  what that does to the measure).
- Inconsistencies: contradictory values across sources, impossible values (negative Money, a
  Shipment before its Order) — what was found.
- Freshness & completeness: is the data current enough for the question; are any periods or segments
  missing or partial?
- Temporal coverage: does the window actually contain data throughout, or are there gaps?
- Dangerous joins & row-multiplication: did any join multiply rows beyond the stated grain — checked,
  result.
- Reconciliation: does the analyzed total tie back to a known source-of-truth total (within an
  explained tolerance)? A result that does not reconcile to source is a red flag, not a rounding
  detail. MANDATORY — not merely "if it applies" — for any figure presented as a headline total:
  reconciliation is the final gate before a number may be a headline, and an unreconciled figure may
  not headline the report. A residual is only acceptable when it is mechanistically explained (you
  can name what causes it), bounded (within a stated tolerance), AND stable across runs (the same
  residual reproduces, not a different gap each time) — a residual that is merely labelled is not
  reconciled.

State each check as CHECK -> RESULT. A check you did not run is itself a limitation — record it as
one rather than implying the data is clean. INVALID: "data validated" with no specifics; a clean
bill of health on a dataset where nulls or duplicates were never examined.
Example:
- Duplicate check: grouped by Order id at stated grain; 0 duplicates. PASS.
- Null check: 1.2% of Orders have null region; excluded from the region breakdown only, kept in
  totals — recorded in limitations.
- Reconciliation (headline Order count): analyzed Order count (prod) ties to the Ordering
  daily-count metric within 0.3%; residual mechanistically explained (Orders placed in the last hour
  fall on the far side of the snapshot's timezone boundary), bounded (< 0.5% tolerance agreed with
  the source owner), and stable (same residual reproduced across three reruns). PASS.
- Freshness: hom Invoice extract is one load behind prod — FAIL for cross-env comparison; carried to
  limitations.
-->

## limitations

<!--
REQUIRED. NEVER OPTIONAL, and never hidden. Everything that bounds how far the reader should trust
the analysis: what the data does not cover, what could not be checked, the known quality gaps from
above, the period-comparison caveats, the segments excluded by a filter, the freshness shortfalls. A
relevant limitation omitted is the failure this contract exists to prevent — over-conclusion comes
from limitations left unsaid. If the data was insufficient to answer the question, that belongs here
AND in a LIMITED finding; it does not become a creative guess.
A limited-but-honest conclusion on limited data is a correct outcome, not a failure. State the
limits plainly so the reader can weigh them.
-->

## analysis_method

<!--
The analytical method you chose and WHY it fits the business_question. A trend question wants a
period-over-period comparison with a baseline; a "where is it concentrated" question wants a
distribution / breakdown; a "what changed" question wants a decomposition; an "is A related to B"
question wants a correlation — stated as correlation, never silently upgraded to cause. Name the
method and its assumptions, and confirm those assumptions hold against quality_checks (a mean assumes
a distribution that is not outlier-dominated; a period comparison assumes comparable periods). Picking
a method that does not fit the question, or a statistic whose assumptions the data violates, is a
rigor failure the gate will catch.
-->

## findings

<!--
The heart of the analysis. Each finding is a single claim, and EACH ONE MUST carry three things: a
TAG, an evidence link, and a confidence. The tag is the most important discipline in this whole
contract — it is how fact is kept separate from interpretation and from wish:

- FACT: directly observed in the validated data. "prod Order count rose from 41,200 to 48,900 month
  over month." A FACT points to a number or a query and does not interpret.
- INFERENCE: a reasoned conclusion drawn from facts, stated as inference. "The growth is concentrated
  in the South region (FACT: South rose 31%, others < 5%), which suggests the regional campaign
  reached its audience." The reasoning is shown; the leap is visible.
- HYPOTHESIS: a candidate explanation NOT established by this data, labelled as such. "HYPOTHESIS: the
  South spike may be driven by the new PricingRule — not tested here; would need a controlled
  comparison." Never dressed up as a finding.
- RECOMMENDATION: a proposed action, tied to the decision_supported. "RECOMMENDATION: right-size the
  prod datastore to the p95 observed load, not the mean, given the right-skew (see measures)."

Rules the gate enforces on this section:
- Never assert causation from correlation. A correlation is at most an INFERENCE that names it as
  correlation; "X causes Y" needs a HYPOTHESIS tag and a stated way it would be tested.
- Never present a mean where the distribution or outliers make it misleading — if you cite a mean,
  the distribution check in quality_checks must support it, or report a median/percentile instead and
  say why.
- Never state a strong conclusion on insufficient or contradictory data — downgrade it to a LIMITED
  finding or a HYPOTHESIS.
- Every finding links to evidence (next field) and carries a confidence (the field after).
Order findings by importance to the decision. A short list of well-supported findings beats a long
list of weak ones.
-->

## evidence

<!--
For EACH finding, the verifiable thing a skeptical peer could re-run or re-check to confirm it: the
query (described, secret-free), the specific number and where it came from, the quality_check that
backs it, the table or row. A finding with no evidence link is not a finding — it is an assertion,
and the gate treats it as a BLOCKER. "Conclusion -> evidence" must hold for every important claim;
this is the overriding rule of the whole analysis. Keep evidence specific enough to re-verify, never
so raw that it carries a credential.
Example:
- Finding F1 (FACT, Order growth) <- aggregate query over `orders` prod, placed_at in window, grouped
  by month; values table in appendix; reconciled in quality_checks.
- Finding F3 (INFERENCE, South concentration) <- per-region month-over-month deltas (South +31%,
  next-highest +4%); same query sliced by region.
-->

## confidence

<!--
The confidence in each finding (or an overall confidence, with the reason). State it as a level
(high / medium / low) WITH the reason that sets it, and the reason MUST name the specific
quality_check result or limitation that drove the level — so the confidence is auditable against the
recorded checks, not free text a reader has to take on faith. "high: reconciled to source within
0.3% — see quality_checks Reconciliation PASS — and no nulls in the measure"; "low: hom extract one
load stale — see quality_checks Freshness FAIL — and the period is partial (see limitations), so the
cross-env comparison is indicative only". A confidence that points to no check or limitation is a
number pulled from the air. Low confidence is not a failure to hide — it is information the
decision-maker needs. A finding whose confidence the data cannot support must be downgraded, not
asserted.
-->

## recommended_report_type

<!--
The report shape this analysis should be rendered into, chosen from the analytical-type taxonomy in
[`../lenses/reporting.md`](../lenses/reporting.md) — one of: Analytical (diagnostic/cost analysis for
engineers), Metric-Trend (one quantity over time for ops/business), Discovery-Stories
(docs-to-backlog for a product owner/team), or Exec-Summary (a short decision-oriented summary for
management). The choice follows from business_question + decision_supported + audience, NOT from
appearance. State the type and one line on why it fits, and what it will lead with. If purpose and
audience point at different shapes (a deep analysis requested for management), the resolution is
usually an Exec-Summary that references an Analytical report — two shapes, not one hybrid. If the
shape is genuinely ambiguous, that is an open question to ASK, not to guess.
This field, plus the validated findings, is what the report skill derives the HTML from. The HTML
must not be producible without this contract filled and passed against
[`../rules/analysis-rigor.md`](../rules/analysis-rigor.md).
-->

## Open Questions

<!--
Anything not yet decided or not yet answerable: a source whose owner has not confirmed freshness, a
check that could not be run, an ambiguity in the request, a shape decision waiting on the audience.
Mark genuine open questions as open — do NOT answer one with a guess to make the contract look
finished. An open question recorded here is worth more than invented data, which is never permitted.
-->
