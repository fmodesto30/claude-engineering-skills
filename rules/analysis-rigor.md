# Analysis Rigor Rule

The rigor GATE for an analytical report, and the construction-side sibling of
[`spec-rubric.md`](spec-rubric.md). Where the spec rubric keeps a *spec* honest by separating the
decisions that must be pinned down from the ceremony that buries them, this rule keeps an *analysis*
honest by separating the conclusions the data actually supports from the ones it does not. It grades
a filled `AnalysisSpec` (see [`../templates/analysis-spec.md`](../templates/analysis-spec.md)) and the
report derived from it. It is HOW the system refuses to over-conclude — and it is a HARD GATE: no
HTML report is produced until the contract is filled and passes this rule.

## What this rule is for

An analytical report exists to support a decision, and its only value is that its conclusions are
trustworthy. A confident conclusion the data does not support is worse than no report — it launders a
guess into a decision. This rule grades the *gaps between what is claimed and what the data backs*,
the same way the severity rubric grades the findings in a code review and the spec rubric grades the
gaps in a spec. A report is good when every important conclusion points to verifiable evidence, every
limitation is stated, and the strength of each claim matches the strength of the data under it — and
no more.

## The overriding rule

**Every important conclusion must point to verifiable evidence, and insufficient data yields a
LIMITED conclusion, never creative filling.** This is the spine of the whole rule. A claim a skeptical
peer cannot re-check against a query, a number, or a recorded quality_check is not a finding — it is an
assertion, and an assertion presented as a finding is a BLOCKER. When the data cannot answer the
question, the honest output is a clearly-bounded "here is what the data does and does not support",
not an invented number, an extrapolated trend, or a filled-in gap. This mirrors the spec rubric's
"every requirement must be testable" and the review rubric's "every finding must name a concrete
consequence": if a conclusion can carry neither evidence nor an honest limitation, cut it.

A limited-but-honest conclusion on limited data is a CORRECT outcome, not a failure. The gate exists
to stop over-conclusion, never to punish restraint.

## The four levels (analysis rigor)

- **BLOCKER** — A conclusion the data does not support, or a claim that cannot be verified. The report
  cannot ship until it is fixed or downgraded. Each BLOCKER names *which* claim outruns *which* data
  and why. The exhaustive list of what is always a BLOCKER is in "Mandatory rules mapped to BLOCKERs"
  below; in summary: a strong claim on insufficient or contradictory data; causation asserted from
  correlation alone; a mean presented where the distribution or outliers make it misleading;
  incompatible periods compared with no warning; a finding with no evidence link; invented or
  filled-in data; or a chart that distorts scale, proportion, or trend.

- **SHOULD** — A real rigor gap that does not by itself make a conclusion false, but weakens trust and
  should be fixed: confidence not stated on a finding that drives the decision; a relevant limitation
  omitted (when its omission does not yet flip a conclusion — otherwise it is a BLOCKER); a dimension
  or a period used but not justified; a visualization that does not state which question it answers; a
  measure whose unit or definition is left implicit. A SHOULD is raised and named with the rework it
  will cause, but does not block.

- **NIT** — A cosmetic or presentational gap with no consequence for whether a conclusion holds: a
  chart label that could be clearer, a table column order, a findings list that would read better
  reordered, slightly wordy guidance left in the contract. Worth a brief `nit:` note, never a reason
  to withhold the report. When in doubt between SHOULD and NIT, it is a NIT.

- **OK** — The analysis claims what the data supports and no more. This is the silent, frequent,
  correct outcome — and it EXPLICITLY INCLUDES a limited-but-honest conclusion on limited data. A
  report that says "the data supports X with medium confidence, cannot establish Y, and Z is out of
  scope because the source was stale" is OK, not incomplete. Saying "this is as far as the data goes"
  is a valid and common verdict, not a shortfall.

## Mandatory rules mapped to BLOCKERs

Each mandatory rule below is non-negotiable; violating it is a BLOCKER. This is the explicit map the
gate enforces — a filled `AnalysisSpec` or its report that trips any of these does not ship.

1. **Never invent missing data.** Any number, trend, segment, or value not traceable to a real source
   and a recorded transformation is invented data. → **BLOCKER.** Insufficient data yields a LIMITED
   conclusion or a HYPOTHESIS, never a filled-in value.
2. **Never hide a relevant limitation.** A limitation that, if known, would change how the reader
   weighs a conclusion, and is omitted from the contract or the report. → **BLOCKER** when its omission
   props up a conclusion that would otherwise be limited; **SHOULD** when the conclusion stands
   regardless but trust is weakened.
3. **Never claim causation from correlation alone.** "X drives / causes / explains Y" presented as a
   FACT or INFERENCE when only an association is shown. → **BLOCKER.** A correlation may be stated as a
   correlation; a causal claim must be a HYPOTHESIS with a stated way it would be tested.
4. **Never use a mean the distribution makes misleading.** A mean cited as the headline on a skewed or
   outlier-dominated distribution, with no distribution check supporting it. → **BLOCKER.** Report a
   median/percentile, or show the distribution, and say why.
5. **Never compare incompatible periods without a warning.** Periods of different length, different
   calendar shape, or a partial current period against full prior ones, compared with no caveat. →
   **BLOCKER.** The incompatibility must be flagged in `time_range`, `limitations`, and at the point of
   comparison.
6. **Never produce a chart without stating which question it answers.** A visual with no stated
   question it serves. → **BLOCKER** for a chart load-bearing to a conclusion; **SHOULD** for a
   secondary visual. Every chart traces back to a `business_question` or a finding.
7. **Never use a visualization that distorts scale, proportion, or trend.** A truncated or non-zero
   magnitude baseline presented as if zero-based, inconsistent axes across compared panels, a pie of
   parts that do not sum to a whole, a 3-D effect that warps proportion, a dual axis that manufactures
   a correlation. → **BLOCKER.** A plain values table is better than a chart that misleads.
8. **Every important conclusion must point to verifiable evidence.** A finding that drives the decision
   with no evidence link (a query, a number, a quality_check). → **BLOCKER.**
9. **The report must show freshness, sources, filters, and limitations when relevant.** A report whose
   conclusions depend on data whose freshness, source, applied filters, or limitations are not
   surfaced. → **BLOCKER** when their absence could mislead the reader about scope or currency;
   **SHOULD** otherwise.
10. **Credentials, secrets, and personal data are inputs only.** A credential, token, connection
   string, or personal datum written into the contract or the report is a leak. → **BLOCKER**, and the
   report must never be committed. This standing rule is inherited from the reporting lens and the
   contract.
11. **Never render a report before the contract is validated.** Rendering any report while the
   `AnalysisSpec` Status is absent, Draft, or In Review — rather than Validated with a recorded ready /
   ready-with-SHOULDs verdict — is a **BLOCKER.** The render step must be refusable from the artifact
   (the Status field), not trusted to the actor.

## Calibration examples (neutral domain)

**BLOCKER**

- "prod `Order` volume is up because of the new `PricingRule`" stated as a finding, when the analysis
  only shows that volume rose in the same month the rule shipped. Correlation asserted as cause →
  recast as a HYPOTHESIS with a stated test, or drop to "rose in the same period as".
- "Average `Order`-to-`Shipment` time is 6 hours" headlined as the result, when the distribution is
  right-skewed (most under 2 hours, a long tail past 48) and no distribution check is recorded. The
  mean misleads → report the median and p95 and show the spread.
- Current month-to-date `Invoice` total compared directly against last month's full total, charted
  side by side with no caveat → the current bar is structurally short; flag the partial period or
  annualize comparably.
- A bar chart of cross-environment cost whose y-axis starts at 40,000 (near the data minimum) so a 5%
  real difference fills most of the panel and reads as a far larger gap → zero-baseline the magnitude
  comparison or state the truncation explicitly and why.
- "`Customer` churn is 12%" with no link to the query, the cohort definition, or the window that
  produced it → no evidence link; not verifiable.
- A `Shipment`-delay rate quoted for "all regions" when the `region` column was 40% null and the nulls
  were silently dropped, and `limitations` does not say so → a hidden limitation that changes the
  scope of the conclusion.

**SHOULD**

- A solid, evidence-backed finding that the decision turns on, but no confidence stated → the
  decision-maker cannot tell how hard to lean on it. State the level and its reason.
- A breakdown by `Customer` tier presented with no justification of why tier is the relevant cut →
  reads as a fishing expedition; justify the dimension or drop it.
- A trend line that is clearly the right chart but carries no caption saying which question it answers
  → state the question it serves.
- "Revenue" used as a measure without defining what `Money` is summed or in which currency → define it
  so it is reproducible.

**NIT**

- Findings would read more clearly if ordered by impact rather than by discovery order.
- A chart legend placed below where beside would be tidier.

**OK**

- "On the available data (one month, prod only, `region` 40% null), `Order` volume rose ~18% over the
  prior month with medium confidence; the regional breakdown is indicative only because of the nulls,
  and causation cannot be established from this data." A limited-but-honest conclusion → OK, ship it.
- A short Metric-Trend report stating the headline number, its period-over-period delta, the time
  series, and a one-line caveat about a one-month spike → OK.
- "The data is insufficient to answer whether the `PricingRule` change moved conversion; this would
  need a controlled before/after with comparable periods, which the current extract does not support."
  Stated as a LIMITED conclusion plus an open question → OK, not a failure.

## Review questions before a report ships

A report author or reviewer should be able to answer each of these before the HTML is rendered and
shipped:

- Is the `AnalysisSpec` contract filled — including `quality_checks`, `limitations`, and, for every
  finding, a FACT / INFERENCE / HYPOTHESIS / RECOMMENDATION tag, an evidence link, and a confidence?
- Does every important conclusion point to verifiable evidence a peer could re-run or re-check?
- Is every FACT actually observed, every INFERENCE shown as reasoning over facts, every HYPOTHESIS
  labelled as untested, and every RECOMMENDATION tied to the decision?
- Is any causal claim backed by more than correlation — or is it tagged HYPOTHESIS with a stated test?
- Where a mean is used, does a distribution check support it, or should it be a median/percentile?
- If periods are compared, are they comparable — and if not, is the incompatibility flagged everywhere
  it appears?
- Does every chart state the question it answers, and does no chart distort scale, proportion, or
  trend (honest baseline, consistent axes, a chart type that matches the data)?
- Are freshness, sources, filters, and limitations surfaced wherever their absence could mislead?
- Is the strength of each claim matched to the strength of its data — is anything asserted more
  confidently than the data allows, and is a limited conclusion stated as limited rather than padded?
- Is there any invented, extrapolated, or filled-in value standing in for missing data?
- Does the report contain no credential, secret, or personal datum?
- Is the chosen `recommended_report_type` the shape that serves this audience and decision?

## Verdict

Close an analysis review the way the spec rubric closes a spec review — a short verdict and a count
per level. The four verdicts:

- **ready** — OK overall; conclusions match the data, evidence and limitations are in place. Ship.
- **ready-with-SHOULDs** — no BLOCKER, but real rigor gaps named (missing confidence, an unjustified
  dimension, an uncaptioned chart). Ship after addressing them, or ship with them explicitly accepted.
- **not-ready** — one or more BLOCKERs that are fixable by re-stating, re-tagging, re-charting, or
  downgrading a conclusion (correlation recast as a hypothesis, a mean replaced by a median, a chart
  re-baselined, an evidence link added). The analysis can pass once the claims are brought back in
  line with the data.
- **BLOCKED-by-data-quality** — the analysis-side addition to the spec-rubric verdict set — the data
  itself cannot support the question at the rigor required (insufficient coverage, unreconcilable
  sources, freshness that invalidates the comparison). No amount of re-wording fixes it. The correct output is a LIMITED conclusion plus the open questions
  that say what data would be needed — never a confident report manufactured to look finished.

Prefer a few precisely-named gaps over a long list of presentational notes — drop weak observations to
OK rather than padding the review. A report whose contract is OK overall, with its BLOCKERs resolved or
its conclusions honestly downgraded, is ready to render and ship. A limited-but-honest report is a
pass, not a near-miss.
