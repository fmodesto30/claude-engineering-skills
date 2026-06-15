# Reporting Lens

Reusable knowledge for the **final stage** of the reporting pipeline: given an already-validated **AnalysisSpec** — findings tagged fact / inference / hypothesis / recommendation, with evidence links, stated confidence, a `recommended_report_type`, and explicit limitations — choose the **narrative** and the **HTML shape and visuals** that carry it to a reader, and only then render the HTML. **The shaping and the HTML are the LAST step, never the first.** This lens runs *after* data-engineering and data-analysis; it derives everything from the AnalysisSpec and never from a raw request. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This is a **construction / judgment** lens, not a review lens — it carries no severity rubric, because nothing here grades an artifact that already exists; its job is to *shape* an output from an input that has already been validated elsewhere. Its consumer today is the [`report`](../skills/report/SKILL.md) skill, which runs a pipeline — `request -> understand the decision -> data-engineering -> data-analysis -> fill and validate the AnalysisSpec -> SHAPE (this lens) -> render HTML` — and reaches this lens **only at step five**, with a filled, gated AnalysisSpec in hand. It could later serve other output-producing skills (a dashboard generator, a release-notes writer) the same way — each supplies its own intent and its own validated contract, the lens supplies the shaping discipline.

The non-negotiable ordering: **a skill never starts from HTML, a chart, or an appearance.** Shaping is downstream of analysis, and analysis is downstream of data quality. By the time this lens is consulted, the hard questions — is the data trustworthy, what method fits the question, what is fact versus hypothesis, how confident are we — have already been answered and recorded in the AnalysisSpec by [`../lenses/data-engineering.md`](../lenses/data-engineering.md), [`../lenses/data-analysis.md`](../lenses/data-analysis.md), and the gate in [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md). This lens does not re-open them. It reads the contract and decides how to *present* it. If the AnalysisSpec is not filled and has not passed the rigor gate, **this lens does not run** — there is nothing trustworthy to shape, and producing HTML anyway is the dominant failure the whole pipeline exists to prevent.

A consuming skill loads this lens whenever it has a validated AnalysisSpec and must decide what shape the report should take — never to enforce a house format, because there is no single house format. The whole point is the opposite: the shape is chosen from the analytical type and the audience the AnalysisSpec already records.

## Purpose

This lens exists to kill two specific failures. The first is **shaping before analysis**: jumping to "make an HTML report" — picking a chart, a template, a colour — before the question is understood, the data validated, and the findings separated into fact / inference / hypothesis / recommendation. A report that starts from its appearance is a presentation in search of a point; it dresses up whatever numbers are at hand and lends them a credibility the analysis never earned. The second is **one report shape applied to every situation**, so a snapshot of KPIs, a time-trend, a root-cause diagnosis, and a one-page decision summary all come out structurally identical and none of them serves its reader well.

Against both, this lens gives the consuming skill a small, concrete taxonomy of report shapes, a mapping from the **analytical type** the AnalysisSpec already carries (snapshot, trend, comparison, composition, distribution, anomaly, diagnostic, funnel, cohort, forecast, data-quality, executive-summary) to the shape that fits it, and a per-shape description of what to lead with and what to leave out. The default bias is restraint: a report carries only what its audience needs to act, leads with the thing that audience came for — the finding, the number, the recommendation — and never buries the conclusion or distorts a chart. It also carries forward, visibly, the things the AnalysisSpec recorded and a reader must see to trust the conclusion: **data freshness, sources, the filters applied, and the stated limitations and confidence.** When the AnalysisSpec's `recommended_report_type` and the actual audience genuinely disagree, the right move is to surface that — usually as two shapes, not one hybrid that serves neither — rather than to default to a familiar template.

## When to Use

Consult this lens at the **shaping step** of the pipeline — after the AnalysisSpec is filled and has passed the rigor gate — when a skill must decide the narrative and the HTML shape, including:

- A validated AnalysisSpec whose analytical type is a snapshot or a set of KPIs, or a comparison of one metric across environments (`dev` / `hom` / `prod`) or dimensions.
- A validated AnalysisSpec that tracks one quantity over time, or a composition/segmentation, distribution, or anomaly finding.
- A validated AnalysisSpec carrying a diagnostic / root-cause chain, a funnel, a cohort/retention analysis, or a forecast/scenario set.
- A validated AnalysisSpec whose findings must be compressed into a short, decision-oriented summary for management.
- A data-quality & lineage AnalysisSpec whose own conclusion is that the data does not support strong claims — which still gets shaped honestly, foregrounding the limitations.

Do NOT engage this lens before the AnalysisSpec exists and passes the gate; do not engage it to impose a fixed corporate template, to add chrome (logos, cover pages, boilerplate) that serves no reader, or because a request merely contains the word "report." And do not use it to *re-derive* the analysis — the analytical type, the confidence, and the limitations are inputs, decided upstream. The trigger is a real decision about *what shape best carries this validated AnalysisSpec to this audience*, not the vocabulary used to ask for it.

## Core Principle

**Shape follows function, and function is decided upstream.** A report is not a document format; it is an instrument that carries a *validated analysis* to a specific audience, and its structure is correct only when it matches the analytical type and the reader the AnalysisSpec already records. The dominant failure modes are three, and worth naming directly:

1. **Shaping before analysis.** Starting from HTML, a chart, or an appearance — before the data is validated and the findings are separated into fact / inference / hypothesis / recommendation. The output then looks like a report and is one only by accident; it presents numbers no one vouched for. The cure is the pipeline order itself: this lens runs *last*, on a contract that already passed [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md).
2. **One template for everything.** Reusing a single structure — usually whichever one was built first — for a snapshot, a trend, a diagnosis, and a summary alike. The structure then fits at most one of them and quietly fails the rest: the trend report has no trend, the management summary buries its conclusion under method, the diagnostic has no causal chain.
3. **Burying the conclusion, or distorting the picture.** Leading with context, method, and scaffolding when the reader came for a finding or a decision; or rendering a chart whose baseline, axis, or type makes the data say something it does not. Every shape leads with what *its* audience needs first, surfaces the freshness/sources/filters/limitations the AnalysisSpec carries, and renders honestly.

A report earns its structure only when that structure does concrete work for the reader: it puts the thing the audience came for at the top, carries exactly the supporting detail that audience can act on, marks what is fact versus inference versus hypothesis as the AnalysisSpec tagged it, surfaces the freshness/sources/filters/limitations and the confidence, and omits the rest. A correct report for an engineer is the wrong report for a steering committee, and vice versa — same validated findings, different shape. **Credentials, secrets, and personal data are inputs to producing the analysis, never content of the report:** a report shows results, not the keys used to obtain them, and is never committed if it carries one.

## Mapping analytical types to report shapes

The AnalysisSpec records the **analytical type** of the question (defined and chosen in [`../lenses/data-analysis.md`](../lenses/data-analysis.md)): snapshot/KPIs; time-trend; group-comparison; composition/segmentation; distribution/dispersion; anomalies; diagnostic/root-cause; funnel; cohort/retention; forecast/scenarios; data-quality & lineage; executive-summary-for-decision. This lens turns that type into a shape. The rule of thumb is **the type decides the shape, the audience confirms it** — and several types legitimately *share* a shape's components rather than each demanding a bespoke template. The point is the opposite of one-template-for-everything: distinct types must not collapse into one identical report, but neither does every type need its own structure invented from scratch.

The four shapes below are families, not a rigid one-per-type catalogue. Use these mappings:

- **Analytical** carries: group-comparison, composition/segmentation, distribution/dispersion, **diagnostic/root-cause**, funnel, cohort/retention, and forecast/scenarios. These share the analytical skeleton (question -> method -> findings -> impact -> recommendation), but two need their *own* additional structure on top of it: a **diagnostic/root-cause** report must show the causal chain and the alternatives ruled out (a bare findings table is not a diagnosis), and a **forecast/scenarios** report must show the assumptions, the scenario set, and the confidence band (a point estimate with no band misleads). Funnel and cohort reuse the comparison/composition components (stage-to-stage tables, retention grids) without a new template.
- **Metric-Trend** carries: time-trend, and the simple **snapshot/KPIs** case when the snapshot is one headline quantity watched over time. A snapshot of *several unrelated* KPIs is a dashboard-style composition and leans toward Analytical's multi-panel components instead.
- **Discovery-Stories** carries the docs-to-backlog / learning-trail (*trilha*) case — a construction output rather than a data analysis, but it still flows through the same pipeline (its "analysis" is reading and structuring source documents, recorded in the AnalysisSpec as the source map and the derived items).
- **Exec-Summary** carries the **executive-summary-for-decision** type, regardless of which analytical type produced the underlying findings — it is the compression layer over any of the above when the audience is a decision-maker.
- **Data-quality & lineage** does not get a fourth template of its own; it is shaped as an Analytical report whose headline finding *is* the quality verdict and whose recommendations are about trust and remediation. When the AnalysisSpec's limitations are severe, the honest shape foregrounds them and explicitly bounds what the reader may conclude.

Every shape, whatever the type, must **surface the AnalysisSpec's freshness, sources, filters, and limitations**, must **carry the fact / inference / hypothesis / recommendation tags and the confidence** through to the reader rather than flattening them into undifferentiated assertions, must **never bury the conclusion**, and must **never distort a chart**.

## Report Shapes

Four shapes. Each has a distinct structure, a distinct audience, and a distinct thing it leads with. The AnalysisSpec's `recommended_report_type` and analytical type select the shape; the audience confirms it.

### 1. Analytical

A diagnostic or exploratory analysis of a system or dataset, often compared across environments — the report that answers "what is going on here, and what does it cost / imply?"

- **Carries analytical types:** group-comparison, composition/segmentation, distribution/dispersion, diagnostic/root-cause, funnel, cohort/retention, forecast/scenarios, and data-quality & lineage (shaped as a quality verdict).
- **Audience:** engineers and tech leads — readers who can and will scrutinize the method and the data.
- **Lead with:** the question being answered and the headline finding (taken from the AnalysisSpec) — the answer first, the build-up after.
- **Structure:** Context & scope -> Data sources, freshness & method (*how* the numbers were obtained — the queries, the time window, the filters applied; never the credentials themselves) -> Findings, with fact/inference/hypothesis tags and confidence carried through (tables, simple charts) -> Cost / impact breakdown -> Recommendations -> Limitations & caveats -> Appendix / raw detail.
- **Own structure where the type demands it:** a **diagnostic/root-cause** report adds the causal chain and the alternatives ruled out; a **forecast/scenarios** report adds assumptions, the scenario set, and the confidence band. Funnel and cohort reuse comparison/composition components.
- **What to OMIT:** management-level hand-holding, motivational framing, and any restating of basics the engineering audience already knows. Keep the appendix for raw detail rather than inlining it.
- **Visual:** comparison tables across environments or dimensions; a simple bar or grouped-bar chart for the cost/impact breakdown; for a forecast, a line with an honest confidence band. When the analysis spans multiple sources or is *about the data path* — a lineage or architecture question, a data-quality report, any case where the reader must see where the numbers came from — add a **data-flow / architecture flowchart** (see "Data-flow / architecture diagrams" below): source nodes -> transformation/reconciliation nodes -> output/consumer nodes, rendered as inline SVG with no dependencies. It is a *component* of this shape, not a new report type.
- **Neutral example:** usage and cost of a datastore or messaging service across `dev` / `hom` / `prod`, with a recommendation on right-sizing, sourced from a validated AnalysisSpec that reconciled the billing export against the metered usage.

### 2. Metric-Trend

One quantity tracked over time — the report that answers "what is this number, and which way is it moving?"

- **Carries analytical types:** time-trend, and the single-headline-quantity case of snapshot/KPIs.
- **Audience:** operations and business readers who watch the number routinely and want the movement at a glance.
- **Lead with:** the headline number for the current period and its period-over-period delta — up or down, by how much — as the AnalysisSpec records it, with its confidence.
- **Structure:** Headline number + period-over-period delta -> Trend over time (a simple line/bar chart or a values table) -> Breakdown by a dimension -> Notable movements / anomalies -> Freshness, filters & caveats (from the AnalysisSpec's limitations).
- **What to OMIT:** deep method, recommendations, and exploratory analysis — those belong in an Analytical report. Do not turn a trend into a diagnosis; if the question was "why did it move," the AnalysisSpec's type is diagnostic and the shape is Analytical, not this.
- **Visual:** a single clear time-series (line or bar); a small table of the underlying values so the chart is verifiable.
- **Neutral example:** monthly `Order` volume over the last twelve months, broken down by region, with a note on a one-month spike that the AnalysisSpec flagged as a backfill artefact rather than real demand.

### 3. Discovery-Stories

Reading source documents and producing a backlog or learning trail (a *trilha*) — the report that answers "given these documents, what should we build and in what order?"

- **Carries analytical types:** the docs-to-backlog construction case; its AnalysisSpec records the source map and the derived items rather than a statistical analysis.
- **Audience:** a product owner and the delivery team — readers who will refine, estimate, and pull the items into work.
- **Lead with:** the source map — what was read — so the reader can trust the backlog is grounded in the documents and see what it is derived from.
- **Structure:** Source map (what was read, by title / path) -> Epics / themes -> Stories (each with a title, an *As a ... / I want ... / So that ...* line, and acceptance criteria) -> Sequence & dependencies (the *trilha* / ordering) -> Open questions.
- **What to OMIT:** cost analysis, trend charts, and management framing — none of those is what a backlog is for. Do not invent stories the sources do not support; record gaps as open questions (the AnalysisSpec's equivalent of a limitation) instead.
- **Visual:** the epic -> stories grouping itself (cards or a nested list); a simple ordered list or dependency arrows for the sequence.
- **Neutral example:** read a `Notification` feature document and produce epics, stories with acceptance criteria, and a suggested build order.

### 4. Exec-Summary

A short, decision-oriented summary for management — the report that answers "what should we decide, and why?"

- **Carries analytical types:** executive-summary-for-decision — the compression layer over any underlying analytical type when the audience is a decision-maker.
- **Audience:** management / a steering group — readers who want the conclusion and the trade-offs, not the derivation.
- **Lead with:** the recommendation / TL;DR — the conclusion (the AnalysisSpec's top recommendation, with its confidence) is the *first* thing on the page, never the last.
- **Structure:** Recommendation / TL;DR **first** -> 3 to 5 key numbers -> Risks, trade-offs & limitations (the confidence and caveats the AnalysisSpec records, stated plainly) -> Decision needed / next steps. Keep it to roughly a page.
- **What to OMIT:** method, raw data, appendices, and engineering depth — link to or reference the underlying Analytical report rather than reproducing it. If it does not help a decision, it does not belong here. But never omit the confidence and the key limitation: a recommendation presented as certain when the AnalysisSpec marked it a hypothesis is a misrepresentation, not a simplification.
- **Visual:** at most a few large key-number callouts; no dense tables, no exploratory charts.
- **Neutral example:** summarize a `PricingRule` migration initiative for a steering committee — recommend go / no-go, with three key numbers, the main risk, and the stated confidence drawn from the validated AnalysisSpec.

## How to Choose the Shape

The AnalysisSpec has already decided the question type and the audience. This lens reads them and selects:

1. **Read the AnalysisSpec's `recommended_report_type` and analytical type.** Map the type to a shape using "Mapping analytical types to report shapes" above — snapshot/trend -> Metric-Trend; comparison/composition/distribution/diagnostic/funnel/cohort/forecast/data-quality -> Analytical; docs-to-backlog -> Discovery-Stories; executive-summary-for-decision -> Exec-Summary.
2. **Confirm against the AUDIENCE the AnalysisSpec records.** An engineer wanting to scrutinize numbers confirms Analytical; an ops reader watching a number confirms Metric-Trend; a product owner confirms Discovery-Stories; a steering group confirms Exec-Summary. If the type and the audience disagree (e.g. a diagnostic analysis requested *for* management), the usual resolution is an Exec-Summary that *references* an Analytical report — two shapes, not one hybrid that serves neither.
3. **Apply the type's own structure where it needs one.** A diagnostic or a forecast inside the Analytical family needs its extra structure (causal chain; assumptions and confidence band). A simple snapshot reuses Metric-Trend's components. Do not invent a new template where a shared component fits, and do not flatten a type that needs its own structure into the generic skeleton.

If the AnalysisSpec itself is **ambiguous about audience or `recommended_report_type`** — the analysis was done but the consumer was never pinned down — surface that to the consuming skill so it can ask, rather than defaulting to whichever template is most familiar. Defaulting silently is exactly the one-template-for-everything failure this lens exists to prevent. (If the *analysis* is what is missing or untrustworthy, that is an upstream gate failure, not a shaping decision — this lens does not run at all.)

## Audience Adaptation

The same validated findings are shaped differently for different readers. Adapt depth, jargon, and what is foregrounded — but never change what the AnalysisSpec marked as fact versus inference versus hypothesis:

- **Engineer / tech lead (Analytical):** maximum depth; domain and technical jargon is fine; foreground method, sources, freshness, and the data so the reader can trust and reproduce the finding. Carry the fact/inference/hypothesis tags and the confidence explicitly. An appendix of raw detail is welcome, not noise.
- **Ops / business (Metric-Trend):** moderate depth; minimal jargon; foreground the number and its direction. The reader wants the movement at a glance and the caveat (from the AnalysisSpec's limitations) that stops them over-reading a blip.
- **Product owner / team (Discovery-Stories):** foreground actionable, well-formed stories with acceptance criteria and a clear order; tie everything back to the sources so the backlog is trustworthy; surface gaps as open questions rather than filling them with guesses.
- **Management / steering (Exec-Summary):** minimum depth; no unexplained jargon; foreground the conclusion and the trade-offs. Compress ruthlessly — but the compression must preserve the confidence and the headline limitation, because dropping them turns a hedged recommendation into a false certainty. A second page is usually a sign the wrong shape was chosen.

The failure to avoid in every direction is mismatch: analytical depth dumped on management, a one-line summary handed to an engineer who needed the method, or — the subtler one — a hypothesis the AnalysisSpec hedged being re-rendered as a hard fact because the audience "wants a clear answer."

## Data-flow / architecture diagrams

Most reports need only a table or a simple chart. But when the analysis **spans multiple sources or is about the data path itself** — a lineage or architecture question, a data-quality report, or any analysis where the reader must see *where the numbers came from* before they will trust them — the right visual is a **data-flow / architecture flowchart**: source nodes -> transformation / reconciliation nodes -> output / consumer nodes. It draws, for the reader, the same lineage [`../lenses/data-engineering.md`](../lenses/data-engineering.md) already recorded in the AnalysisSpec's `sources` and `transformations`; it is the visual answer to "where does this number come from / what feeds this read model."

- **It must answer a question, never decorate.** A flowchart earns its place only when it answers *where did this number come from* or *what feeds this read model* — the same must-answer-a-question discipline every chart is held to. If it does not make the lineage legible, drop it; a sources/transformations table is better than a diagram that is just chrome.
- **Label nodes with neutral sources, edges with the transformation.** Nodes are the named sources and outputs the AnalysisSpec records (e.g. a Glue cost dataset, a DynamoDB usage table, a Java service config -> a per-env analysis output); edges carry the transformation the lineage records (dedup, reconcile, join at env grain). The nodes and edges come *from* the contract, not invented for the picture.
- **Render it as inline SVG with no dependencies.** Plain rectangles, arrows, and text inline in the HTML — no chart or diagram library, no external refs, self-contained and print-friendly, exactly like every other visual this lens allows. The reusable block lives in [`../templates/reports/analytical.html`](../templates/reports/analytical.html).
- **It is a component of the Analytical shape, not a new report type.** A data-quality & lineage analysis is still shaped as an Analytical report (see "Mapping analytical types to report shapes"); the flowchart is one of its components, used inside that shape — it does not add a fifth shape to the four above.

## Anti-Patterns

- **Shaping before the analysis exists** — *Diff:* a report (HTML, chart, template) produced from a raw request or a pile of numbers, before any AnalysisSpec was filled and gated. *Harm:* the output presents numbers no one validated — wrong joins, stale data, a correlation read as a cause — wearing the authority of a finished report; the reader acts on a conclusion the analysis never sustained. *Fix:* run the pipeline in order. Shaping is the *last* step; it consumes a validated AnalysisSpec that already passed [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md). If there is no validated AnalysisSpec, this lens does not run.

- **One template for every situation** — *Diff:* a single report structure (usually whichever was built first) reused for a snapshot, a trend, a diagnosis, and a summary alike, ignoring the analytical type the AnalysisSpec records. *Harm:* the structure fits at most one of them; the trend report has no trend, the diagnosis has no causal chain, the management summary opens with method. Each reader has to dig past scaffolding meant for someone else, and most give up. *Fix:* map the AnalysisSpec's analytical type to a shape; apply the type's own structure where it needs one. There is no default.

- **The conclusion buried at the bottom of an exec summary** — *Diff:* a management summary that opens with context, scope, and method and reaches its recommendation only on the last screen. *Harm:* the one reader with the least time has to read the most to find the one thing they came for, and the decision the report exists to drive is the hardest part to locate. *Fix:* lead with the recommendation / TL;DR (the AnalysisSpec's top recommendation); put the supporting numbers, risks, and limitations after it.

- **Confidence and caveats stripped on the way to the reader** — *Diff:* the AnalysisSpec tags a finding as a hypothesis with low confidence and lists a sampling limitation, and the report renders it as a flat, unqualified assertion — especially in an Exec-Summary compressed for a decision-maker. *Harm:* a hedged finding becomes a false certainty; the decision-maker over-trusts a result the analyst deliberately bounded, and acts beyond what the evidence supports. *Fix:* carry the fact/inference/hypothesis tags, the confidence, and the headline limitations through to the reader. Compression removes depth, never the caveat that bounds the claim.

- **Freshness, sources, and filters left off the report** — *Diff:* a report that shows numbers without saying when the data is from, where it came from, or what filters were applied to produce it — facts the AnalysisSpec recorded. *Harm:* the reader cannot tell whether they are looking at today's data or last quarter's, the whole population or a filtered slice, and so cannot judge how far to trust it. *Fix:* surface freshness, sources, and the filters applied on every shape — a "data as of / sources / filters" line is not optional chrome, it is what makes the numbers legible.

- **Credentials, secrets, or PII written into the report** — *Diff:* a connection string, an API key, a token, or personal data pasted into the report because it was part of the input used to gather the data. *Harm:* the report becomes a leak — a deliverable that is shared, printed, and committed now carries a secret or personal data, and the blast radius is everyone who receives it. *Fix:* treat credentials and PII as **inputs only**. Describe *how* the data was obtained (the query, the source, the window) without ever reproducing the secret; a report shows results, not the keys used to get them. Never commit a report that contains them.

- **Charts that mislead** — *Diff:* a truncated or non-zero baseline that exaggerates a movement, an inconsistent axis between panels, a pie chart for parts that do not sum to a whole, a 3-D effect that distorts proportion, or a point-estimate forecast drawn with no confidence band the AnalysisSpec specified. *Harm:* the reader draws a conclusion the data does not support — a 2% change looks like a cliff, two panels look comparable when their axes differ, a forecast looks certain — and acts on the distortion. *Fix:* use a baseline and axis honest to the data (zero baseline for magnitude comparisons unless the deviation itself is the subject, and say so), keep axes consistent across panels, choose a chart type that matches the data's shape, and draw the confidence band the analysis recorded. A plain values table is better than a chart that misleads. (The choice of *which* visual fits *which* analytical type is decided upstream in [`../lenses/data-analysis.md`](../lenses/data-analysis.md); this lens renders that choice honestly.)

## Integration (report skill)

The consuming skill uses this lens at the **final, shaping step** of the pipeline — not as a classifier and not as a format to enforce:

- **Shape last, never first.** The HTML is the last step, derived from a validated AnalysisSpec. This lens runs only when the AnalysisSpec `Status` is `Validated` (which is reserved for a `ready` / `ready-with-SHOULDs` verdict); any other status — absent, `Draft`, `In Review`, or `Blocked` — means the gate has not passed and this lens must not run. The skill does not reach this lens until data-engineering, data-analysis, and the AnalysisSpec gate ([`../rules/analysis-rigor.md`](../rules/analysis-rigor.md)) have run. Never start from HTML, a chart, or an appearance.
- **Read the AnalysisSpec, do not re-derive it.** The analytical type, the audience, the fact/inference/hypothesis tags, the confidence, and the limitations are inputs. This lens maps the type to a shape and decides the narrative and visuals; it does not re-open the analysis.
- **Map type to shape; apply own structure where the type needs it.** Use the mapping above. Distinct types must not collapse into one identical report; types that share components should reuse them rather than spawn a new template.
- **Lead with what the audience needs, omit the rest, surface freshness/sources/filters/limitations, and never distort a chart.** Each shape's "Lead with" and "What to OMIT" are the operative guidance once the shape is chosen.
- **Carry the caveats through.** A hypothesis stays a hypothesis; a low-confidence finding stays hedged; a limitation stays visible — even under the heaviest compression of an Exec-Summary.
- **Surface ambiguity in the AnalysisSpec rather than defaulting.** If audience or `recommended_report_type` was never pinned down, ask. If the *analysis* is what is missing, that is an upstream gate failure and this lens does not run.
- **Credentials and PII are inputs only.** Never write a secret, token, connection string, or personal datum into the report output, and never commit a report that contains one. Describe the method, not the keys.
- This lens reasons about *narrative, shape, audience, and honest rendering* given a validated analysis. It does not grade an existing artifact and carries no MUST/SHOULD severity rubric — that machinery belongs to the rigor gate ([`../rules/analysis-rigor.md`](../rules/analysis-rigor.md)) and the review lenses, not here. Data quality and lineage belong to [`../lenses/data-engineering.md`](../lenses/data-engineering.md); analytical reasoning, method selection, and visual selection belong to [`../lenses/data-analysis.md`](../lenses/data-analysis.md). Defer to those rather than re-litigating their concerns here.

> Packaging note: the `../lenses/...` and `../rules/...` links above resolve while this lens and its siblings are checked out together in this repository. If the `report` skill is ever exported to ship standalone, the packaging step co-locates the lenses, the rules, and the templates it depends on into the skill so the cross-links stay resolvable — the same convention the other skills in this repo follow.
