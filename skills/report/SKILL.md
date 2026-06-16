---
name: report
description: >-
  Produces a self-contained HTML report by first understanding the DECISION it must support, then
  discovering and VALIDATING the data, running the analysis that fits the question, and only then —
  from a filled and validated AnalysisSpec — choosing the narrative and rendering the HTML. It never
  starts from HTML, charts, or appearance; the visual is the last step, derived from a contract whose
  conclusions are sustained by evidence. Bad or insufficient data BLOCKS a strong conclusion: it
  yields a limited / data-quality output, never creative filling. Separates fact / inference /
  hypothesis / recommendation, states confidence, and shows freshness, sources, filters, and
  limitations. Use when asked to generate or write an HTML report, build a report, or turn data or
  documents into a report deliverable. Treats any credentials or secrets as inputs only — never
  written into the output or committed. General-purpose; not tied to Java/Spring.
---

# report

A construction workflow that produces a self-contained HTML report — but the HTML is the **last**
step, not the first. The skill orchestrates a full pipeline and the visual is derived from a
validated analytical contract, never the starting point:

```
request
  -> (1) understand the DECISION / question the report must support
  -> (2) DATA-ENGINEERING: DISCOVER the landscape (which accounts/services/repos/catalogs hold the
         data, the access path & owner of each), then model grain/keys/relationships and validate quality
  -> (3) DATA-ANALYSIS: pick the method that fits the question, analyze, interpret, state confidence
  -> (4) fill and VALIDATE the AnalysisSpec  (HARD GATE — no HTML until it passes the rigor rule)
  -> (5) REPORTING: choose the narrative and the HTML shape/visuals FROM the AnalysisSpec
  -> (6) render the self-contained HTML
```

The failure this skill stops is bigger than "one template for every situation." That failure still
matters — an infrastructure cost analysis, a monthly-volume trend, a docs-to-backlog learning trail,
and a one-page management summary should not come out structurally identical — but the larger failure
is **producing a confident report whose conclusions the data does not support**: a clean chart over a
duplicated join, a headline mean that an outlier makes a lie, a causal claim drawn from a correlation,
a trend across two incompatible periods. A polished HTML report is the most persuasive way to ship a
wrong conclusion, so the appearance is produced *last*, only after the analysis stands on its own.

## Core stance

- **Never start from HTML, charts, or appearance.** The request is a decision to support, not a
  document to format. Deciding the chart or the layout before the analysis exists is how the visual
  ends up dressing a conclusion the data cannot carry. The HTML is the final render of a validated
  AnalysisSpec — nothing is drawn before that contract is filled and passes.
- **Analysis before rendering.** Discover and validate the data, then run the analysis that fits the
  question, *then* choose a shape. The order is load-bearing: a shape chosen first dictates what the
  analysis is forced to say.
- **Conclusions never exceed the evidence.** Every important conclusion points to verifiable evidence
  — a query, a number, a check. A claim with no evidence behind it is downgraded or dropped, not
  rendered. Insufficient data yields a LIMITED conclusion, never creative filling — the skill never
  invents a missing number to complete a story.
- **Bad data blocks strong conclusions.** If the data-engineering stage finds the quality does not
  support the question — broken grain, a row-multiplying join, stale or incomplete coverage, an
  unreconciled total — the skill STOPS and produces a limited / data-quality output that says what is
  wrong and what could not be concluded, rather than a confident analysis built on sand.
- **Separate fact / inference / hypothesis / recommendation.** A measured number, a reasoned
  inference from it, an untested hypothesis, and a recommended action are four different kinds of
  claim. They are tagged distinctly so the reader never mistakes a guess for a measurement.
- **Show freshness, sources, filters, and limitations.** When they bear on the conclusion, the report
  carries where the data came from, how fresh it is, what was filtered out, and what the analysis
  could not establish. A report that hides its limitations is selling certainty it does not have.
- **Credentials and secrets are inputs only, never output.** A connection string, an API key, a
  token, or personal data may be needed to *gather* the data; none of it is ever written into the
  report or committed. A report shows results, not the keys used to obtain them.
- **Inspect the real request and data.** Never assume the decision, the audience, the data shape, the
  grain, or the environment. Establish what is actually being asked and what data actually exists
  before analyzing or rendering; a report built on an assumed question or an unvalidated dataset is
  wrong by default.

## How to produce a report

The numbered steps are the pipeline. Each later step depends on the one before it, and step 6 (the
HTML) cannot begin until step 4 (the AnalysisSpec) is filled and passes.

1. **Understand the DECISION / question.** Before touching data, pin down what decision this report
   supports and the precise question it answers — "should we right-size this datastore across
   `dev` / `hom` / `prod`?", "which way is monthly `Order` volume moving and why?", "go / no-go on the
   `PricingRule` migration?". Identify the audience the decision belongs to. A report with no decision
   behind it has no way to know what is relevant; if the decision or question is unclear, **ask**
   before going further (see Restraint rules).

2. **DATA-ENGINEERING — discover, then validate the data**, via
   [`../../lenses/data-engineering.md`](../../lenses/data-engineering.md). **First, DISCOVER the
   landscape** — before validating or analysing anything, map *where the data actually lives and what
   you must enter to get it*: enumerate the accounts/projects, the services/stores, the repositories,
   and the catalogs that hold each piece of data the question needs, and for each record its access
   path (how it is queried — described, never the credential) and its owner. A question is usually
   answered only by JOINING several sources across different tools (for example a Glue/Athena-queryable
   billing dataset, an `Order` count from a relational database behind a Java/Spring service, and a
   `TaxRule` that lives only in that service's repository) — **you cannot validate or analyse data you
   have not located**, and a needed source you cannot access or that no one owns is a discovery
   limitation or a blocker, recorded up front rather than discovered mid-analysis. Then, on the sources
   you located: model the grain, keys, and relationships, and validate quality before trusting any
   number: schema, types, units, and timezone; duplicates, nulls, and inconsistencies; freshness,
   completeness, and temporal coverage; dangerous joins and row-multiplication; and reconciliation of
   the source against the result. **If a needed source cannot be located or accessed, or the quality is
   insufficient to support the question, STOP** — produce a limited or data-quality output that states
   what is wrong or unreachable and what cannot be concluded, rather than proceeding to a confident
   analysis the data cannot back. This stage is the gate that makes "bad data blocks strong
   conclusions" real.

3. **DATA-ANALYSIS — analyze and interpret**, via
   [`../../lenses/data-analysis.md`](../../lenses/data-analysis.md). Formulate the question precisely,
   recognize which analytical *type* it is (a snapshot/KPI, a time-trend, a group-comparison, a
   composition, a distribution, an anomaly hunt, a diagnostic/root-cause, a funnel, a cohort, a
   forecast, a data-quality study, or an executive decision summary), and pick the analytical method
   that fits *that* question — not the one that is easiest to chart. Analyze, interpret, and tag every
   finding as FACT / INFERENCE / HYPOTHESIS / RECOMMENDATION; never claim causation from correlation
   alone; never report a mean without checking whether the distribution or an outlier makes it
   misleading; never compare incompatible periods without a warning. State the confidence in each
   finding, with the reason.

4. **Fill and VALIDATE the AnalysisSpec — the HARD GATE.** Fill the intermediate contract in
   [`../../templates/analysis-spec.md`](../../templates/analysis-spec.md): the business question, the
   decision supported, the audience, the sources (each with the system/account/service/repo it lives
   in, its access path, owner, and freshness), grain, dimensions,
   measures, time range, filters, transformations, the quality checks and their results, the
   limitations, the analysis method, the findings (each tagged FACT / INFERENCE / HYPOTHESIS /
   RECOMMENDATION), the evidence each finding links to, the confidence, and the recommended report
   type. Then check the filled spec against [`../../rules/analysis-rigor.md`](../../rules/analysis-rigor.md)
   and **resolve every `BLOCKER` or downgrade the conclusion** it is attached to (a conclusion the
   evidence cannot carry becomes a LIMITED finding, an open question, or is dropped). **This is a hard
   gate: no HTML is produced until the AnalysisSpec is filled and passes the rigor rule.** The HTML
   must be derivable from this contract and must not be producible without it. Record the outcome in
   the AnalysisSpec **`Status`** and its `Rigor verdict`: set `Status: Validated` ONLY when the verdict
   is `ready` / `ready-with-SHOULDs` and no `BLOCKER` remains; if a `BLOCKER` remains or the verdict is
   `not-ready` / `BLOCKED-by-data-quality`, set `Status: Blocked` and produce a LIMITED or
   data-quality output (conclusions downgraded, limitations foregrounded), never a confident report.
   Steps 5-6 MUST NOT run unless `Status` is `Validated` — rendering on any other status is itself a
   `BLOCKER` (analysis-rigor rule 11), so the gate is checkable from the artifact rather than trusted
   to the actor.

5. **REPORTING — choose the narrative and the shape**, via
   [`../../lenses/reporting.md`](../../lenses/reporting.md), *from* the validated AnalysisSpec. Use the
   spec's `recommended_report_type` and its audience to pick the narrative and the HTML shape and
   visuals — what to lead with, what to omit, and which (if any) visualization answers the question.
   Every chart must state which question it answers and must not distort scale, proportion, or trend;
   when no honest chart helps, a plain values table is the right choice. This stage runs *after* the
   analysis, never first — it shapes a conclusion that already stands, it does not manufacture one.
   Also select a **theme preset** (the visual skin) appropriate to the audience/purpose — **suggest** it
   and let the user confirm or change it — without letting it alter the shape or chart type chosen here;
   apply it via the theme-variable surface ([`../../templates/THEMING.md`](../../templates/THEMING.md)).
   The theme is the only cosmetic choice offered to the user; the chart type and the shape follow the data.

6. **Render the self-contained HTML** to the target reports directory the caller specified (or the
   project's conventional reports location). The visuals are inline and offline — no external
   JS/CSS/CDN, no web fonts, no remote images — so the report is a single file that renders the same
   offline and prints cleanly. Carry a **provenance / limitations block**: the sources, freshness,
   filters, confidence, and limitations that the AnalysisSpec recorded, so the reader can see how far
   to trust each conclusion. Never write a credential, token, connection string, or personal datum
   into the file, and never commit a report that contains one.

## Output

A single self-contained HTML file whose shape was selected by the validated AnalysisSpec, written to
the target reports directory. The shape leads with what its audience needs and carries the supporting
detail that audience can act on — for example:

- **Analytical** — leads with the question and the headline finding; context & scope, data sources &
  method (how the numbers were obtained — the queries, the window, the checks — never the credentials),
  findings, cost/impact breakdown, recommendations, appendix.
- **Metric-Trend** — leads with the headline number and its period-over-period delta; trend over time,
  breakdown by a dimension, notable movements, notes & caveats.
- **Discovery-Stories** — leads with the source map; epics/themes, stories (title, *As a … / I want …
  / So that …*, acceptance criteria), sequence & dependencies (the *trilha*), open questions.
- **Exec-Summary** — leads with the recommendation / TL;DR; 3–5 key numbers, risks & trade-offs,
  decision needed / next steps. Short by design.

Whatever the shape, the file is offline-ready (no external dependencies), print-friendly, carries the
provenance / limitations block, distinguishes fact from inference from hypothesis from recommendation,
and contains no credentials, secrets, or personal data.

## Restraint rules

- **Never render before the AnalysisSpec passes.** The HTML is step 6, derived from a contract that
  is filled (step 4) and clears [`../../rules/analysis-rigor.md`](../../rules/analysis-rigor.md). No
  chart, no layout, no appearance work begins before that — starting from the visual is the failure
  this skill exists to prevent.
- **Never invent missing data.** Insufficient data yields a LIMITED, honest conclusion or a
  data-quality output — never a number filled in to complete a story or smooth a chart.
- **Never hide a relevant limitation, and never overclaim.** A conclusion never exceeds its evidence;
  no causation from correlation alone, no misleading mean, no comparison of incompatible periods
  without a warning, no chart that distorts scale, proportion, or trend, and no chart that does not
  state which question it answers.
- **Show freshness, sources, filters, and limitations** whenever they bear on the conclusion. A
  report that omits them is asking the reader to trust more than the analysis earned.
- **Credentials and PII are inputs only.** They may be needed to gather the data; they are never
  written into the report and a report carrying one is never committed. Describe *how* the data was
  obtained — the query, the source, the window — not the keys used to obtain it.
- **Ask when the decision, the question, or the data is unclear.** A clarifying question, or a
  recorded open question, beats a confident report built on a guessed purpose or an unvalidated
  dataset. A limited honest report beats a confident wrong one, every time.
- **Scale the report to the audience and the question.** A one-page exec summary for a steering group
  and a deep analytical report for engineers are both correct when they match their reader and the
  decision; the wrong size — or the wrong shape — for the audience is the defect.

## Packaging note

The `../../` links above resolve while this skill, the lenses
([`../../lenses/data-engineering.md`](../../lenses/data-engineering.md),
[`../../lenses/data-analysis.md`](../../lenses/data-analysis.md),
[`../../lenses/reporting.md`](../../lenses/reporting.md)), the rule
([`../../rules/analysis-rigor.md`](../../rules/analysis-rigor.md)), and the templates
([`../../templates/analysis-spec.md`](../../templates/analysis-spec.md) and
[`../../templates/reports/`](../../templates/reports/)) are checked out together in the repository. If
this skill is ever exported to ship standalone, the packaging step co-locates those lenses, the rule,
and the templates into the skill so it stays self-contained — the same convention the other skills in
this repo follow.
