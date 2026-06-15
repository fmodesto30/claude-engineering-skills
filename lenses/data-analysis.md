# Data-Analysis Lens

Reusable analytical reasoning for turning validated data into a defensible finding: how to formulate the question, pick the analytical method that fits it, separate what the data **proves** from what it merely **suggests**, and choose a visualization that shows the evidence without distorting it. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This is a **construction / judgment** lens, not a review lens — it carries no MUST/SHOULD/NIT severity rubric, because nothing here grades an artifact that already exists. Its job is to help a skill *reason its way to a finding* before any output is shaped. That machinery — the enforceable gate that decides whether a conclusion is sustained by its evidence — lives in [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md), and the contract the analysis fills lives in [`../templates/analysis-spec.md`](../templates/analysis-spec.md). This lens supplies the reasoning; the rule grades it; the contract records it.

Its consumer today is the [`report`](../skills/report/SKILL.md) skill, which loads it at the **ANALYSIS stage** — *after* [`./data-engineering.md`](./data-engineering.md) has discovered the sources and validated their quality, and *before* any HTML, chart, or layout is chosen. The order is not negotiable: data-engineering establishes whether the data can bear weight at all (and must block a strong conclusion when it cannot), this lens decides what the data actually says, the AnalysisSpec records it, the rigor rule passes it, and only then does [`./reporting.md`](./reporting.md) choose a narrative and a visual. A skill that reaches for a chart before this lens has run has skipped the analysis and is decorating an unexamined number.

A consuming skill loads this lens whenever it must move from validated data to an interpreted finding — never to enforce a house analysis format, because the right method is chosen from the question, not imposed.

## Purpose

This lens exists to kill one specific failure: a number presented as a conclusion it does not support. A mean reported over a skewed distribution, a correlation narrated as a cause, two incomparable periods set side by side, a chart whose truncated axis turns a 2% drift into a cliff — each is a real, validated number bent into a claim the data never made. The lens gives the consuming skill a disciplined path from data to finding: recognize what *kind* of question is being asked, choose the analytical method that answers that kind, interpret the result honestly, and tag every statement as a **fact**, an **inference**, a **hypothesis**, or a **recommendation** so the reader can see exactly how far each one is load-bearing.

The default bias is restraint and honesty about uncertainty. **Insufficient data yields a limited conclusion, never a creative one** — the lens never fills a gap with a plausible guess dressed as a finding. A finding that says "we cannot conclude X from this data, and here is what we would need" is a correct and valuable outcome, not a failure. The analysis comes first and the visual comes last; the picture serves the finding, never the reverse.

## When to Use

Consult this lens when a skill has validated data in hand and must decide what it *means*, including:

- A request to analyze a system or dataset and report what is going on (usage, cost, errors) — once the data is validated and before the shape of the report is chosen.
- A request to track a quantity over time and say which way it is moving and whether the movement is real.
- A comparison across groups, segments, environments (`dev` / `hom` / `prod`), or periods, where the question is whether a difference is meaningful.
- A diagnosis — "why did this number change?" — where the temptation to assert a cause from a coincidence is strongest.
- Any moment where a number is about to become a claim, a chart, or a recommendation, and the leap from one to the other needs to be examined.

Do NOT engage this lens to validate the data itself — that is [`./data-engineering.md`](./data-engineering.md)'s job, and it runs first. Do NOT engage it to choose the report's narrative shape, audience framing, or HTML — that is [`./reporting.md`](./reporting.md), and it runs after. This lens occupies the middle: validated data in, a tagged-and-evidenced finding out. Engaging it before the data is validated, or letting it choose the visual before the finding is settled, is using it out of order.

## Core Principle

**A report exists to answer a question, support a decision, or show a finding — the analysis comes first, the visual comes last, and no conclusion may travel beyond its evidence.** Every analytical claim is anchored to something verifiable — a query, a number, a check — or it is dropped. The most common correct move is to *narrow* the claim to what the data actually supports: a directional statement instead of a precise one, a hypothesis instead of an inference, a "cannot conclude" instead of a forced answer.

Three disciplines carry this principle, and the rest of the lens elaborates them:

- **Recognize the question type before choosing a method.** A snapshot, a trend, a comparison, a distribution, a root-cause, a forecast — each is a different question and needs a different method and different evidence. Answering a trend question with a single snapshot number, or a root-cause question with a correlation, is the analytical equivalent of the one-template failure: the method does not fit the question and the finding is wrong before the first chart.
- **Separate FACT / INFERENCE / HYPOTHESIS / RECOMMENDATION, and tag every finding.** A fact is what the data directly shows; an inference is a reasoned step beyond the data; a hypothesis is a candidate explanation not yet tested; a recommendation is an action proposed on top of all three. Collapsing these — narrating an inference as a fact, or a hypothesis as a cause — is how a report misleads while every individual number in it is true.
- **State confidence, and let data quality lower it.** A finding carries how much weight it can bear and why. Poor freshness, a small sample, a period mismatch, a known data-quality caveat from the data-engineering stage — each lowers confidence, and the lens carries that reduction forward rather than presenting a shaky finding as a firm one.

**Credentials, secrets, and personal data are inputs to obtaining the data, never content of the analysis or the report** — the analysis describes *how* a number was produced (the query, the source, the window), not the keys used to produce it.

## Analytical Types

Recognizing the **question type** is the first analytical act — and it turns on the *question*, not merely the audience or the purpose. "How many `Order`s last month?" (snapshot), "is `Order` volume rising?" (trend), and "why did `Order` volume fall in `prod` but not `hom`?" (root-cause) are three different analyses over the same table. Misclassify the question and every later choice — method, evidence, visual — inherits the error.

For each type below: the question it answers, the method that fits, the evidence it needs, and the visualization that shows it. **Not every type needs its own report structure.** Some are distinct enough to demand their own shape (a funnel, a cohort/retention grid, a forecast with its scenario bands); others are *components* that compose inside a larger analysis (a snapshot KPI block, a single distribution panel, an anomaly callout). The note on structure for each says which — so two genuinely different analyses do not collapse back into one identical report, and so a component is not inflated into a whole report of its own.

- **Snapshot / KPIs** — *Question:* what is the value right now? *Method:* aggregate at a point in time. *Evidence:* the figure plus its as-of timestamp and the filter that scoped it. *Visual:* a few large number callouts; a small table. *Structure:* almost always a **component** (the KPI header of a larger report), rarely a report on its own — a bare number with no context, comparison, or caveat is the weakest standalone finding.

- **Time-trend** — *Question:* which way is this moving, and is the movement real? *Method:* the same measure over consecutive comparable periods, with the period-over-period delta. *Evidence:* the series values, the delta, and a note on what could distort it (seasonality, an incomplete current period). *Visual:* a line or bar time series with a values table to verify it. *Structure:* its **own structure** when tracking is the purpose; a component when one trend supports a larger diagnosis.

- **Group-comparison** — *Question:* do these groups differ, and does the difference matter? *Method:* the same measure across groups (regions, segments, environments) on a common basis; consider whether the difference exceeds normal variation before calling it real. *Evidence:* per-group values on identical definitions, and the base sizes (a difference in tiny groups is fragile). *Visual:* grouped or sorted bars with a consistent axis. *Structure:* a **component** that slots into an analytical report, or its own structure when comparison is the whole point.

- **Composition / segmentation** — *Question:* what is this total made of? *Method:* decompose the whole into parts that sum to it. *Evidence:* parts that genuinely add to the total (no double-counting, no missing remainder). *Visual:* a stacked bar or — only when the parts truly sum to a meaningful whole — a single pie; a sorted bar is usually clearer. *Structure:* a **component**.

- **Distribution / dispersion** — *Question:* how is this spread, and is a single summary number honest? *Method:* look at the shape — median, percentiles (p50/p90/p99), spread, outliers — not just the mean. *Evidence:* the distribution itself, not one summary statistic. *Visual:* a histogram or a box/percentile view. *Structure:* a **component**, and a mandatory check before any report quotes a mean (see Method Selection).

- **Anomalies** — *Question:* what here is unexpected, and is it real or an artifact? *Method:* compare against an expected baseline or normal range; rule out a data-quality cause before a business cause. *Evidence:* the anomalous value, the baseline it departs from, and the data-quality checks that exclude an artifact. *Visual:* the series or distribution with the outlier marked. *Structure:* a **component** (an anomaly callout) feeding a trend or diagnostic report. A count or share is not interpretable without its base rate — 40% of errors being region A is expected if region A is 40% of traffic; compare against the denominator share before calling it anomalous.

- **Diagnostic / root-cause** — *Question:* *why* did this change? *Method:* decompose the change across dimensions, test candidate explanations against the data, and distinguish a contributing correlate from a cause (see Correlation vs Causation). *Evidence:* each candidate cause linked to a number that supports or rules it out; confounders named. *Visual:* a contribution breakdown (waterfall, segmented bars). *Structure:* its **own structure** — the discipline of fact/hypothesis separation is most load-bearing here, where the pull toward asserting a cause is strongest.

- **Funnel** — *Question:* where do entities drop off across ordered stages? *Method:* count entities reaching each stage, in order, on a consistent denominator. *Evidence:* stage counts and the conversion between consecutive stages, with the cohort definition fixed. *Visual:* a funnel or an ordered bar of stage counts. *Structure:* its **own structure** — the stage order and the denominator are intrinsic to it.

- **Cohort / retention** — *Question:* how does a group defined at a point in time behave over subsequent periods? *Method:* fix a cohort (entities that share an origin period) and follow it across later periods. *Evidence:* the cohort grid with consistent cohort and period definitions; note when a recent cohort's later periods are still incomplete. *Visual:* a cohort/retention grid (heatmap-style table). *Structure:* its **own structure** — the cohort-by-period grid does not reduce to a simple trend.

- **Forecast / scenarios** — *Question:* what might this become, and under what assumptions? *Method:* project from history with the assumptions and their basis stated; present a range, not a single false-precision point. *Evidence:* the historical basis, the stated assumptions, and the uncertainty band. *Visual:* the history continued into a projection with a clearly-marked uncertainty range. *Structure:* its **own structure** — the assumptions and the band are first-class content, and a forecast tagged as fact rather than as a stated-assumption inference is a core anti-pattern. The uncertainty band is conditional on the stated assumptions and on the future resembling the historical basis; it does NOT bound the risk of a regime change or structural break. Label it a stated-assumption range, not a calibrated probability of coverage, unless that coverage has actually been validated.

- **Data-quality & lineage** — *Question:* can this data bear the weight a conclusion would put on it? *Method:* the checks in [`./data-engineering.md`](./data-engineering.md) (schema, types, units, timezone, duplicates, nulls, freshness, completeness, dangerous joins, reconciliation). *Evidence:* what was checked and the result. *Structure:* a **component** that should appear (at least as a limitations note) in any report whose data quality is not obviously sufficient — and a **gate** that can block a strong conclusion outright. This type is upstream of the others; this lens consumes its result.

- **Executive-summary-for-decision** — *Question:* what should we decide, and why? *Method:* compress a completed analysis to the conclusion, the few numbers that drive it, and the trade-offs. *Evidence:* references the underlying analysis rather than reproducing it. *Visual:* a few key-number callouts. *Structure:* its **own structure**, owned by [`./reporting.md`](./reporting.md)'s Exec-Summary shape — listed here because the *question* ("what to decide") is analytically distinct, but the rendering decision belongs to the reporting lens.

## How to Formulate the Analytical Question

A vague ask ("analyze our orders", "how are we doing on cost?") cannot be answered — it can only be guessed at. Before choosing a method, sharpen the request into a precise question by pinning down four things; if any cannot be inferred from the request and the data, **ask** rather than assume:

1. **The metric** — the exact measure, defined unambiguously. "Orders" is not a metric; "count of `Order` rows with status `PLACED`, excluding test accounts" is. An undefined metric is the most common reason two analyses of "the same thing" disagree.
2. **The dimensions** — the breakdowns that matter (by region, by environment, by `Customer` segment). The dimension is often where the real finding lives; a single aggregate hides it.
3. **The period** — the time window, and for any comparison, the **comparison basis** (vs. the prior period, vs. the same period last year, vs. a target). State whether the current period is complete; a partial period compared against full ones is a false drop.
4. **The comparison or threshold** — what makes an answer "good", "bad", "up", or "anomalous". A number with no basis of comparison is not yet a finding.

A well-formed question reads like: *"Month-over-month change in count of `PLACED` `Order`s, by region, for the last 12 complete months, vs. the prior month — flagging any region whose change exceeds its normal monthly variation."* That question selects its own method (time-trend with group breakdown), its own evidence, and its own visual. A vague ask does none of that, which is why sharpening it is the first analytical act, not a formality.

## Method Selection

Choose the method from the question type, not from habit or from the chart you imagined first:

- **Snapshot** when the question is "what is it now" — a point-in-time aggregate, always carrying its as-of timestamp.
- **Trend** when the question is "which way is it moving" — comparable consecutive periods and a delta; never a single snapshot dressed as a trend.
- **Comparison** when the question is "do these differ" — the same definition across groups on a common axis, with base sizes in view.
- **Distribution** when the question is "how is it spread" or whenever a summary statistic is about to be quoted — the shape before the summary.
- **Cohort** when behavior over time depends on when an entity started — fix the cohort, follow it.
- **Funnel** when stages are ordered and drop-off is the question — counts per stage on a fixed denominator.
- **Forecast** when the question is "what might it become" — projection with stated assumptions and a range, never a single false-precise point.

### When a mean is misleading

**Never quote a mean without first checking the distribution and the outliers.** The mean is honest only for a roughly symmetric distribution with no dominating outliers; on skewed or outlier-heavy data it describes a value few entities actually have. A handful of very large `Order`s drags the "average order value" above almost every real order; one runaway `Report` generation time inflates the "average" until it no longer describes the typical run. The discipline:

- Look at the distribution first (the **distribution** type above). If it is skewed or has outliers that matter, **prefer the median and percentiles** (p50/p90/p99) — they describe the typical and the tail honestly.
- When the tail is the point (latency, cost), report a high percentile, not the mean — "p99 `Report` generation time is 8s" is actionable where "average 1.2s" hides the runs that hurt.
- Treat high percentiles as noisy over small samples or short windows — a p99 computed from a handful of events is unstable and should carry a sample-size caveat. And percentiles **do not aggregate**: you cannot average or sum per-bucket p99s to get an overall p99; recompute it from the pooled distribution.
- If a mean is genuinely the right summary, say why the distribution permits it. A mean reported without that check is a finding waiting to be wrong.

This check is mandatory, not optional, and the rigor rule enforces it: a mean over an unexamined distribution is a blocker, not a stylistic nit.

## Correlation vs Causation

**A correlation alone never establishes a cause** — and the diagnostic/root-cause type is exactly where this discipline is most load-bearing and most often abandoned. Two series moving together is a *fact*; the claim that one *drives* the other is, at most, a *hypothesis* until the alternatives are ruled out. Before any causal language enters a finding, examine:

- **Confounders** — a third factor driving both. `Report` failures and `Order` volume both rise on the same days, but a marketing campaign drove both up at once; neither causes the other. Naming the plausible confounder is the minimum bar before asserting a cause. A relationship that holds in aggregate can REVERSE within every subgroup when a confounder is unevenly distributed across groups (the Simpson paradox); before reporting an aggregate comparison, check whether the direction survives within the relevant segments.
- **Reverse causation** — the arrow may point the other way (does slow checkout reduce orders, or do high-volume periods slow checkout?).
- **Selection bias** — the data only covers a non-representative slice (analyzing only `Customer`s who completed checkout to explain why others abandoned it).
- **Missing variables** — the real driver was never measured, so it cannot appear in the correlation at all.
- **Coincidence** — over enough dimensions and periods, some series correlate by chance; a correlation found by searching many candidates is weak evidence.

The honest output is almost always a **hypothesis** tagged as such with the evidence for and against it, plus what would be needed to test it (an experiment, a controlled comparison, a missing variable to collect) — not a causal claim asserted as fact. Stating "X correlates with Y (fact); we hypothesize X contributes to Y, but a campaign confounds both and we have not isolated it (hypothesis)" is a correct, useful finding. "X caused Y" from a correlation is the error this section exists to prevent.

## Separating FACT / INFERENCE / HYPOTHESIS / RECOMMENDATION

This is the core discipline of the lens. Every finding is tagged with exactly what kind of statement it is, so the reader sees how far it is load-bearing and the rigor rule can check that each tag is justified by its evidence:

- **FACT** — what the data directly shows, traceable to a query or a number. *"`prod` `Order` volume in May was 12,480, down 7% from April's 13,420."* A fact links to the figure and the check that produced it. It carries the highest confidence the data quality allows.
- **INFERENCE** — a reasoned step beyond the data, still grounded in it but adding interpretation. *"The decline is concentrated in one region (its volume fell 22% while others held), so the drop is regional, not system-wide."* An inference names the facts it rests on; it is defensible but not directly observed, so it carries less weight than a fact.
- **HYPOTHESIS** — a candidate explanation not yet tested. *"The regional drop may follow the `PricingRule` change shipped there on May 3 — but we have not isolated it from the concurrent campaign."* A hypothesis is explicitly unproven and names what would test it. It must never be narrated as a fact or an inference.
- **RECOMMENDATION** — an action proposed on top of the above, tagged so it is not mistaken for a finding. *"Recommend an A/B test of the `PricingRule` change before rolling it to other regions."* A recommendation inherits the confidence of the weakest finding it rests on; one built on a hypothesis is a suggestion to investigate, not a directive.

The failure this prevents is the silent promotion of one tier to a stronger one — an inference narrated as a fact, a hypothesis stated as a cause, a recommendation resting on an untested hypothesis but phrased as a settled action. Each tag is a promise about evidence; the rigor rule checks the promise.

## Confidence

State, for each finding (or overall when uniform), **how much weight it can bear and why** — not a false-precise percentage, but an honest level (high / medium / low) tied to a reason. Confidence is *lowered*, explicitly, by:

- **Data quality** — any caveat carried forward from [`./data-engineering.md`](./data-engineering.md): stale data, known nulls or duplicates, a reconciliation gap, a dangerous join that may have multiplied rows. A finding can never be more confident than the data under it; if data-engineering flagged the source as unreliable, no analysis can launder it into a firm conclusion.
- **Sample size** — a difference between tiny groups, or a rate over few events, is fragile; a 50% jump from 2 to 3 is not a trend.

The minimal bar for calling a difference or movement **real** is that it exceeds the **normal variation** of the same measure — not merely that it is nonzero. Compare the observed change against the historical period-to-period variation: the standard deviation or interquartile range of past deltas, or a control-chart-style band drawn from them. For counts or rates over small denominators, hold this bar especially tightly — a couple of events can swing a rate by tens of percent, so a change well inside the spread of past changes is noise wearing the costume of a finding. A difference that falls **within** the band of normal variation is **not a finding** and must not be reported as one. Whichever criterion is chosen — a variation band, a confidence interval, or a fixed threshold — it is recorded in the AnalysisSpec so the reader can see what bar the finding cleared.
- **Period mismatch** — comparing an incomplete current period to full prior ones, or periods of different lengths, or across a definition change. Always warn before comparing incompatible periods; an unwarned mismatch is a manufactured finding.
- **Seasonality** — a month-over-month change that is really a recurring seasonal pattern is not the signal it appears to be; year-over-year or seasonally-aware comparison is needed to separate them. Calendar-shape effects beyond length matter too: the number of business days, the weekday mix, and moving holidays (Easter or Carnaval shifting between months) can make two equal-length complete periods non-comparable. Normalize per business day, or compare like calendar shapes, not merely like lengths.
- **Method fit** — a hypothesis not yet tested, a correlation not yet isolated from confounders, an inference resting on an assumption.

Low confidence is not a defect to hide — it is information the reader needs. **A clearly-labeled low-confidence finding, or an explicit "insufficient data to conclude", is more valuable than a confident wrong one**, and is the correct output when the data does not support more.

## Visualization Selection

The visual is chosen **last**, from the finding and its evidence — never first, and never as decoration. Each chart must state which question it answers; a chart that cannot name its question does not belong in the report. Match the chart to the shape of the evidence:

- **Trend over time** -> line (continuous time) or bar (discrete periods), with a values table so the chart is verifiable.
- **Comparison across groups** -> sorted or grouped bars on a single consistent axis.
- **Composition that truly sums to a whole** -> stacked bar, or a single pie only when the parts genuinely add to a meaningful total; otherwise a sorted bar. Pies mislead because humans compare angle and area far less accurately than length (the same perceptual issue behind the area / 3-D anti-pattern), they grow unreliable beyond ~4-5 slices, and they cannot show change over time — prefer a sorted bar in those cases.
- **Distribution** -> histogram or box/percentile view — never a single mean bar standing in for a spread.
- **Relationship between two measures** -> scatter; and label it a relationship, not a cause.
- **Cohort/retention** -> a cohort-by-period grid. **Funnel** -> an ordered stage chart. **Forecast** -> history continued into a projection with a marked uncertainty band.
- **A single key number** -> a large callout, not a one-bar chart that implies a comparison that is not there.

### Distorting-visualization anti-patterns

A chart that distorts is worse than a table, because it persuades the reader of something the data does not support. Avoid:

- **Truncated / non-zero baseline** on a magnitude comparison — it exaggerates a small movement into a cliff. Use a zero baseline for magnitude bars unless the *deviation itself* is the subject, and then say so explicitly.
- **Dual axes** — two series on two different y-axes manufacture a visual correlation by arbitrary scaling; prefer two aligned panels, or indexed series on one axis.
- **Inconsistent axes across panels** — panels meant to be compared must share a scale, or the comparison is an illusion.
- **Misleading area / 3-D** — a pie for parts that do not sum to a whole, a bubble whose area misrepresents the value, a 3-D effect that distorts proportion.
- **Cherry-picked window** — a start and end chosen to show the movement you want; the window must be honest to the question (the full comparable period, not the slice that flatters the story).

When the honest chart would be unclear or the data is too sparse to chart safely, **a plain values table is the correct choice** — it shows the evidence without bending it.

## Anti-Patterns

Each names the move, the harm, and the fix — and each encodes one of the mandatory rules the rigor rule enforces.

- **Inventing missing data** — *Diff:* a gap in the data filled with a plausible estimate, an interpolated value, or a "typical" figure, presented as part of the finding. *Harm:* the conclusion rests partly on fabrication that is indistinguishable from the real numbers, and a reader acts on data that was never observed. *Fix:* never invent; state the gap as a limitation and narrow the conclusion to what the data supports — a **limited** conclusion, not a creative one. If the gap is central, the honest finding is "insufficient data to conclude."

- **Hiding a relevant limitation** — *Diff:* a known caveat (stale data, a reconciliation gap, an excluded segment, a small sample) left out so the finding looks firmer. *Harm:* the reader over-trusts the conclusion and cannot judge how far to rely on it; the report's credibility collapses when the caveat surfaces later. *Fix:* surface every limitation that bears on the finding, next to the finding — freshness, sources, filters, and the quality caveats from the data-engineering stage.

- **Causation from correlation** — *Diff:* two series that move together narrated as one driving the other. *Harm:* a recommendation is built on a relationship that may be a confounder, reverse causation, or coincidence, and acting on it changes the wrong lever. *Fix:* tag the co-movement as a FACT and the causal explanation as a HYPOTHESIS; name the plausible confounders and what would test it before any causal language.

- **A mean over an unexamined distribution** — *Diff:* an average quoted with no look at skew or outliers. *Harm:* the "average" describes a value few entities have; a few large `Order`s or one runaway `Report` time make it actively misleading. *Fix:* check the distribution first; prefer median/percentiles on skewed or tailed data, and justify a mean only when the shape permits it.

- **Comparing incompatible periods without warning** — *Diff:* an incomplete current period set against full prior ones, periods of different lengths, or a comparison straddling a definition change — with no warning. *Harm:* a manufactured drop or jump that is an artifact of the window, not a real movement, and a decision made on a phantom. *Fix:* compare like with like; when periods are not comparable, warn explicitly and, where possible, normalize (run-rate, same-length window, seasonally-aware comparison).

- **A chart with no question** — *Diff:* a visual included because the report "needs a chart", answering no stated question. *Harm:* it adds visual weight and an implied claim with no analytical content; the reader infers significance that was never intended. *Fix:* every chart names the question it answers; if it cannot, cut it.

- **A distorting visualization** — *Diff:* a truncated axis, dual axes, inconsistent panel scales, a misleading area/3-D effect, or a cherry-picked window. *Harm:* the reader is persuaded of a movement, a correlation, or a proportion the data does not support, and acts on the distortion. *Fix:* honest baseline and axis, consistent scales, a chart type that matches the data's shape, and a window honest to the question — or a plain table.

- **A conclusion with no traceable evidence** — *Diff:* an important claim with no link to a query, a number, or a check. *Harm:* the claim cannot be verified or reproduced, and a wrong one cannot be caught. *Fix:* every important conclusion points to verifiable evidence; if none can be produced, the conclusion is not yet earned.

## How it feeds the AnalysisSpec

This lens produces exactly the analytical content the [`../templates/analysis-spec.md`](../templates/analysis-spec.md) contract requires, so the analysis is recorded before any HTML is derived from it — and the [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md) gate grades that contract:

- **`analysis_method`** — the method chosen from the question type (Method Selection), with the reason it fits the question.
- **`findings`** — each tagged FACT / INFERENCE / HYPOTHESIS / RECOMMENDATION per the core discipline above, with no silent promotion of one tier to a stronger one.
- **`evidence`** — each finding linked to verifiable evidence: the query, the number, or the check that produced it (the "traceable evidence" rule).
- **`confidence`** — per finding or overall, with the reason, lowered explicitly by data quality, sample size, period mismatch, seasonality, or method fit (Confidence above).
- **`limitations`** — every relevant caveat surfaced, including those carried forward from [`./data-engineering.md`](./data-engineering.md); never hidden.
- **`recommended_report_type`** — the analytical type recognized here (Analytical Types) maps to the report shape [`./reporting.md`](./reporting.md) will select — a trend question to Metric-Trend, a diagnosis to Analytical, a decision to Exec-Summary.

The contract cannot be filled without this lens's reasoning, and the HTML cannot be produced without the contract filled and passed — that is the hard gate the pipeline enforces.

## Integration (report skill)

The consuming skill uses this lens as the reasoning step between validated data and a shaped report, not as a format to enforce:

- **Run after data-engineering, before reporting.** This lens assumes the data is already validated by [`./data-engineering.md`](./data-engineering.md) and must carry that stage's quality caveats forward into confidence and limitations. It runs before [`./reporting.md`](./reporting.md) chooses any narrative or visual.
- **Classify the question type first.** Recognize what *kind* of question is being asked (Analytical Types) before choosing a method — the question, not the audience, selects the analysis.
- **Tag every finding and link every conclusion to evidence.** FACT / INFERENCE / HYPOTHESIS / RECOMMENDATION is mandatory; an important conclusion with no traceable evidence is not shippable.
- **Let the data lower the confidence.** A finding is never more confident than the data under it; an explicit "insufficient data to conclude" is a correct outcome, never a failure to be papered over.
- **Choose the visual last, from the finding.** A chart states the question it answers and never distorts scale, proportion, or trend; a plain table beats a misleading chart.
- **Fill and pass the contract before any HTML.** The analysis populates [`../templates/analysis-spec.md`](../templates/analysis-spec.md), and [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md) grades whether the conclusions are sustained by the evidence. No HTML until it passes.
- This lens reasons about *method, interpretation, evidence, and confidence* — it does not grade an existing artifact and carries no MUST/SHOULD severity rubric; that enforcement lives in [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md), and the narrative/render decisions live in [`./reporting.md`](./reporting.md).

## Packaging note

The `../rules/`, `../templates/`, `../lenses/`, and `../skills/` links above resolve while the lenses, rules, templates, and skills are checked out together in this repository. If a consuming skill is ever exported to ship standalone, the packaging step co-locates the lenses and rules it depends on into the skill so it stays self-contained — the same convention the other skills in this repo follow.
