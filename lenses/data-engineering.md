# Data-Engineering Lens

Reusable knowledge for validating the **data behind an analytical report** before any analysis or chart is produced: where the data came from and who owns it, what its grain and keys are, whether its quality actually supports the conclusion someone wants to draw, and — when it does not — how to make the data block that conclusion instead of papering over it. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This lens is consumed by the [`report`](../skills/report/SKILL.md) skill at the **DATA-ENGINEERING stage** of its pipeline — step (2), *before* any analysis ([`./data-analysis.md`](./data-analysis.md)), before the [`analysis-spec`](../templates/analysis-spec.md) contract is filled, and long before a line of HTML is written. The pipeline is deliberate: a request first becomes a *decision being supported*, then the data is **discovered, modelled, and validated here**, then it is analysed, then the analytical contract is filled and graded by [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md), and only then is a narrative and an HTML shape chosen ([`./reporting.md`](./reporting.md)) and rendered. This lens owns the second step and feeds the contract's `sources`, `grain`, `transformations`, `quality_checks`, `freshness`, and `limitations` fields. It could later serve any other data-consuming skill (a dashboard generator, a metric exporter) the same way — each supplies its own intent, the lens supplies the validation discipline.

A consuming skill loads this lens whenever it is about to turn data into a claim a reader will act on — never to perform a ritual schema dump for its own sake. The point is not to catalogue the data; it is to decide, honestly, *how far the data lets the conclusion go*.

## Purpose

This lens exists to stop one specific class of failure: a confident analytical conclusion resting on data nobody validated — a cost comparison across `dev` / `hom` / `prod` where a fan-out join silently doubled the `prod` rows, a "revenue is up 12%" headline computed over a period the new source does not yet cover, a mean that two outliers dragged somewhere no actual `Order` sits. Its job is to give the consuming skill a consistent way to discover sources and their owners, model the grain and the keys, check the quality against the question being asked, and — this is the load-bearing part — **convert insufficient data quality into a constraint on the conclusion** rather than letting the conclusion proceed as if the data were clean. The default bias is honesty over completeness: a `LIMITED` finding with its reason stated is worth more than a strong finding the data cannot carry. When the data does not support the claim, the correct output is a downgraded or blocked conclusion, said out loud — never creative filling of the gap.

## When to Use

Consult this lens when a skill is about to build an analytical claim on data, including:

- A request to analyse a system or dataset — usage, cost, volume, errors — often compared across environments (`dev` / `hom` / `prod`) or across time.
- Any comparison between two periods, two environments, or two sources, where the comparison is only valid if the things compared are actually compatible.
- A join, an aggregation, or a deduplication step that sits between a raw source and a reported number — the place where rows get multiplied, dropped, or collapsed.
- A reported total, mean, rate, or trend that a reader will treat as fact and act on.
- Any situation where two sources disagree, a source is fresher or staler than the question assumes, or the data does not cover the full period the report claims.

Do NOT engage this lens to produce a schema inventory for its own sake, to validate data that no conclusion depends on, or because the word "data" appears in a request. The trigger is *a claim about to be built on data that a reader will act on* — not the presence of a dataset.

## Core Principle

**You cannot trust an analysis you have not validated the data for.** A number is only as sound as the grain, keys, freshness, and lineage beneath it, and most analytical errors are not analytical at all — they are data errors wearing a chart. The discipline this lens enforces is that validation comes *first* and that its results have teeth:

- **Bad data must BLOCK strong conclusions, not be papered over.** When the grain is wrong, a join multiplied rows, a source is stale, or two sources disagree and the discrepancy is unresolved, the conclusion is downgraded to what the data can actually support — or blocked — and the reason is stated. The failure mode this lens exists to prevent is a clean-looking conclusion silently built on dirty data.
- **Never invent missing data.** Insufficient data yields a `LIMITED` conclusion, never a creative fill. A gap is recorded as a limitation, not interpolated, extrapolated, or assumed away.
- **Never hide a relevant limitation.** Every constraint that bounds how far the reader should trust the result is surfaced, not buried — freshness, partial coverage, a known duplicate, a reconciliation that did not tie out.
- **Validate against the question, not in the abstract.** The same dataset can be clean enough for "is volume roughly trending up?" and far too dirty for "exactly how much did `prod` cost last month?". Quality is judged relative to the decision the report supports, which is why this lens runs after the decision is framed and before the analysis.

A data finding here is not graded `MUST` / `SHOULD` / `NIT` — this is a **judgment and construction lens, not a review lens**, so it carries no severity rubric (that machinery belongs to the Java/Spring review lenses and [`../rules/severity-rubric.md`](../rules/severity-rubric.md)). Instead each finding produces a **quality verdict that gates the analysis**: it either clears a conclusion, downgrades it to `LIMITED` with a stated reason, or blocks it outright. The enforceable encoding of those gates lives in [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md); this lens supplies the knowledge that finds the problems, the rigor rule grades whether the conclusion survives them.

## Heuristics

Each heuristic gives **what to look for**, **why it matters**, **how to check**, **what it blocks** (the gate — the conclusion it downgrades or stops when it fails), and a neutral **example**.

### Source & Context Discovery

**What to look for:** Before validating anything, the **landscape** — every place each piece of data the question needs actually lives, and the decision the question serves. Concretely, enumerate the accounts/projects, the services/stores, the repositories, and the catalogs that hold the data, and for each the **access path** (how it is queried or pulled) and the **owner** (the role or team who controls it). Recognise the illustrative source *types* the data tends to sit in — an AWS account and its services (a Glue/Athena-queryable dataset, an S3 location, a DynamoDB table, CloudWatch metrics), a Java/Spring service repository where config and business rules live in code, a relational database, a message broker (Debezium/Kafka), a spreadsheet or export — and verify which actually apply to *this* project rather than assuming. The smell is starting to validate or aggregate before answering "where does the data live, and what do I need to enter to get it?"

**Why it matters:** A question is usually answered only by **joining several sources across different tools** — a per-`Order` cost figure may need a billing dataset in one account, the `Order` count from a service's relational database, and a `TaxRule` definition that lives only in a Java/Spring repository. You cannot validate or analyse what you have not located, and you cannot reach a source you have no access path or owner for. Skipping discovery is how an analysis runs confidently against the *one* store that was easy to reach and silently omits the half of the answer that lived elsewhere. Discovery also fixes the decision context: what the number is *for* bounds which sources are even in scope.

**How to check:** Map each piece of data the `business_question` needs to a concrete source: which account/project, which service/store, which repository, which catalog. For each, record the access path (the query, the export, the API call and its window) and a named owner — and whether you can actually reach it. **Access and credentials are inputs only: record the method and the owner, never the secret, and never write it into the contract or the report.** A needed source you cannot access, or one with no owner who controls it, is itself a discovery finding. Tie the map back to the decision the report supports so the scope is exactly what the question needs — no more, no less.

**What it blocks:** A conclusion that depends on a source you never located does not clear — it is blocked until the landscape is mapped, because an unlocated source is an unvalidated one. A needed source you cannot access or that no one owns downgrades the conclusion to `LIMITED` ("the `prod` figure could be validated; the `hom` side sits in a store no one could grant access to") or blocks it — and that constraint is carried forward, never papered over. Discovery is the first move: every later heuristic operates on the sources this one located.

**Example:** A question asks for per-`Order` cost across `dev` / `hom` / `prod`. Discovery maps it to three places: a billing dataset queried via Glue/Athena in one AWS account (owner: Platform), the `Order` count in a relational database behind a Java/Spring service (owner: Ordering), and the cost-allocation `TaxRule` that exists only as code in that service's repository (owner: Ordering). The `prod` and `dev` billing partitions are reachable; the `hom` partition lives in an account no one present can grant access to. That gap is recorded as a discovery limitation up front — the cross-environment claim is constrained before a single number is aggregated, rather than discovered missing halfway through analysis.

### Sources & Ownership

**What to look for:** Every source feeding the report named explicitly — which system, which table or export or API, which environment — and *who owns it*, plus how the report obtained it. Watch for sources that appear in the conclusion but never in the lineage ("the numbers came from the database" with no table named), and for an owner nobody can point to when the number is questioned.

**Why it matters:** An unnamed source cannot be re-queried, reconciled, or trusted, and an unowned source has no one to confirm what a field means or when it last loaded. The concrete cost is a conclusion no one can defend: when a reader asks "where does the `prod` cost figure come from?", the answer is a shrug, and the whole report loses its footing. Ownership also decides authority when two sources disagree (see Reconciliation) — without it, the tie cannot be broken.

**How to check:** List each source with its system, object, environment, and a named owner (a role or team, not "the database"). Record *how* the data was pulled — the query, the export, the API call and its window — so the path is reproducible. **Credentials, tokens, and connection strings used to reach a source are inputs only: record the method, never the secret, and never write it into the contract or the report.**

**What it blocks:** A conclusion whose source cannot be named or whose owner is unknown does not clear — it is downgraded to `LIMITED` ("figure derived from an unidentified extract; owner unconfirmed") or blocked until the source is pinned down. No important conclusion clears without a verifiable source behind it.

**Example:** A cost report compares `prod` and `hom` spend. `prod` comes from a named billing export owned by the Platform team with a stated extraction date; `hom` is "from a spreadsheet someone sent." The `hom` side is downgraded to `LIMITED` and flagged for ownership before any side-by-side claim is made — an unowned spreadsheet cannot anchor a comparison the reader will act on.

### Lineage & Transformations

**What to look for:** The path from raw source to reported number, and every transformation along it — filters applied, rows excluded, fields derived, units converted, records aggregated, duplicates removed. The smell is a number that "fell out of a query" with no record of what the query did to the rows between the source and the result.

**Why it matters:** Most surprising numbers are explained by a transformation no one wrote down — a `WHERE status = 'COMPLETED'` filter that quietly dropped a third of the `Order`s, a currency conversion applied twice, an aggregation that changed the grain. If the lineage is undocumented, the number cannot be reproduced or audited, and a reader cannot tell whether a movement is real or an artifact of a filter that changed between two runs.

**How to check:** Trace each reported figure back to its source through every step, and write the steps down in order: source -> filter -> derivation -> aggregation -> result. For each filter, state what it excludes and roughly how much. For each derivation, state the formula and the units. This documented chain becomes the contract's `transformations` field.

**What it blocks:** A conclusion built on an undocumented transformation chain does not clear — the reader cannot know what was filtered or derived, so the number is downgraded to `LIMITED` until the lineage is recorded. A comparison between two figures computed with *different* (undocumented) transformations is blocked outright: it is not a comparison, it is two unrelated numbers placed side by side.

**Example:** "Average `Order` value rose 8%." The lineage reveals the current period filters out cancelled orders and the prior period did not. The 8% is partly an artifact of the filter change. The conclusion is blocked until both periods are recomputed under the same filter, and the filter is recorded in `transformations`.

### Grain, Keys & Relationships

**What to look for:** The **grain** of each dataset — what one row actually represents (one `Order`? one `LineItem`? one `Order`-per-day? one `Payment` attempt?) — and the primary key that makes a row unique, plus the foreign keys that relate datasets. The classic confusion is treating a `LineItem`-grain table as if one row were one `Order`.

**Why it matters:** Grain is the foundation of every count, sum, and average; get it wrong and every aggregate is wrong. Counting rows in a `LineItem` table and calling it "number of `Order`s" overcounts by the average basket size. Summing a value that is repeated across child rows double-counts it. A primary key you cannot name means you cannot tell duplicates from legitimate repeats; a foreign key you misunderstand produces a join that multiplies or drops rows (see Dangerous Joins). Grain errors are invisible in the output — the number looks plausible, it is just measuring the wrong thing.

**How to check:** For each dataset, state in one sentence what one row is, then verify the claimed primary key is actually unique (`COUNT(*)` vs `COUNT(DISTINCT key)` — if they differ, the key is not unique at that grain). Confirm the foreign keys and their cardinality (one-to-one, one-to-many, many-to-many) before any join. When you aggregate, state the grain you are aggregating *to* and confirm the measure is additive at that grain.

**What it blocks:** A count, sum, or average whose grain is unconfirmed does not clear — there is no way to know it is counting the intended thing. A measure summed across a grain where it is non-additive (a per-`Order` total repeated on every `LineItem` row) is blocked until it is summed at the grain where it appears once. A join across keys whose cardinality was not checked is blocked pending the fan-out check below.

**Example:** "We processed 50,000 `Order`s last month." The source is a `LineItem` export at line-item grain; 50,000 is the row count. `COUNT(DISTINCT order_id)` is 18,400. The headline overcounts by 2.7x. The conclusion is blocked and recomputed at `Order` grain before it goes anywhere near a chart.

### Schema, Types, Units & Timezone

**What to look for:** What each field actually is versus what it is assumed to be — its type, its unit, and (for timestamps) its timezone and how it handles DST. Watch for amounts with no stated currency, numbers stored as text that sort and compare lexically, mixed units in one column (some rows in cents, some in dollars), and timestamps with no zone that get compared across sources captured in different zones.

**Why it matters:** A unit or type mismatch corrupts every arithmetic operation on the field, silently. Money summed across rows where some are in cents and some in dollars produces a total that is meaningless and looks fine. A timestamp stored without a timezone, compared between a source logging UTC and one logging local time, shifts events by hours — enough to move an event across a day boundary and into the wrong reporting period. **DST is the sharpest edge:** a daily aggregation bucketed by local midnight produces one 23-hour day (spring-forward) and one 25-hour day (fall-back) each year; if a per-day RATE divides those buckets by an assumed 24 hours, the rate is distorted about 4% on those two days. Worse, naive wall-clock elapsed-time arithmetic is unreliable across both transitions: across fall-back the repeated hour can make a naive end-minus-start difference negative, zero, or ambiguous; across spring-forward the skipped hour inflates a naive difference by an hour. Compute elapsed time on zone-aware instants (or in UTC), never on wall-clock strings.

**How to check:** For each numeric field, confirm the unit and that it is consistent across all rows (and all sources being combined). For each money field, confirm a single currency or an explicit conversion. For each timestamp, establish the stored timezone, whether it is zone-aware, and how the analysis buckets it — prefer bucketing in a single explicit zone (often UTC) and converting once at the edge, and flag any local-time bucketing that crosses a DST boundary.

**What it blocks:** An arithmetic result over a field of unconfirmed or mixed units does not clear — the total is uninterpretable, so it is blocked until units are normalised. A time-bucketed comparison across sources in different (or unstated) zones is downgraded to `LIMITED` until the zone is reconciled, and a daily/hourly rate spanning a DST change is flagged with a caveat rather than presented as exact.

**Example:** A `Money` column in the `prod` export is in cents; the `hom` export of the same measure is in whole currency units. Summed together as-is, `prod` looks 100x larger. The mismatch is caught at the schema check, the units are normalised, and only then is the comparison allowed — otherwise the report would have shown a 100x cost gap that does not exist.

### Duplicates, Nulls & Inconsistencies

**What to look for:** Rows that should be unique but are not (the same `Payment` recorded twice), nulls in fields the analysis treats as always-present, and values that contradict each other within or across rows (an `Order` marked both `CANCELLED` and `SHIPPED`, a `LineItem` whose amount does not match its quantity times unit price). Watch especially for nulls silently dropped by a filter or an aggregate so the denominator quietly shrinks.

**Why it matters:** Duplicates inflate counts and sums; the duplicated `Payment` makes revenue look higher than it is. Nulls treated as zero (or silently excluded) bias an average and shrink a denominator without anyone noticing — a "completion rate" computed over only the rows that had a value is not the rate the reader thinks it is. Contradictory values mean a rule somewhere is broken upstream, and any aggregate over them inherits the inconsistency.

**How to check:** Count duplicates on the supposed key (`COUNT(*)` vs `COUNT(DISTINCT key)`); inspect a sample to decide whether they are true duplicates or a grain misunderstanding. Profile null rates per field and decide explicitly how each null is handled (excluded? treated as zero? a category of its own?) — and state that decision. Run consistency checks on fields that should agree (status transitions, derived totals) and quantify the contradictions.

**What it blocks:** A count or sum over a dataset with unresolved duplicates does not clear — it is inflated by an unknown amount, so it is blocked or downgraded until the duplicates are removed or explained. A mean or rate over a field with material nulls is downgraded to `LIMITED` with the null-handling decision stated. A conclusion drawn over contradictory records is blocked until the contradiction is quantified and bounded.

**Example:** A `Payment` export has 4% duplicate transaction ids from a retry that wrote twice. Summed as-is, captured revenue is overstated ~4%. The duplicates are collapsed on transaction id before any revenue figure is reported, and the dedup step is recorded in `transformations`.

### Freshness, Completeness & Temporal Coverage

**What to look for:** When each source was last loaded (freshness), whether it contains all the rows it should (completeness), and whether it actually covers the full time range the report claims (temporal coverage). Watch for a "this month" report run before the month closed, a source that lags ingestion by a day so the latest period is partial, and **late-arriving data** — records that belong to a past period but only land after that period was already reported.

**Why it matters:** A partial latest period looks like a decline that is really just incomplete data — the classic "revenue fell off a cliff" that is just today's rows not loaded yet. A source that does not cover the early part of the claimed range makes a baseline period look artificially low. Late-arriving data means a period's number changes after it was first reported, so two runs of the same report disagree and the reader loses trust. Freshness and coverage are the difference between "the number is down" and "the data is not all here yet."

**How to check:** State each source's last-load timestamp and its ingestion lag. Confirm the data's actual min/max timestamp covers the claimed range, and check the most recent period for partial-period effects (is the latest day/week/month complete?). Identify late-arriving patterns by checking whether prior periods' counts have shifted since a previous run. Because late-arriving data can REVISE an already-closed prior period, even a complete-vs-complete period comparison can shift between runs — re-check such comparisons, or mark them provisional, until the late-arrival window for those periods has elapsed. Compare expected vs actual row counts per period to spot gaps.

**What it blocks:** A trend or period-over-period claim whose latest period is partial does not clear — it is blocked, or the partial period is clearly marked as incomplete and excluded from the trend conclusion. A comparison over a range the source does not fully cover is downgraded to `LIMITED` ("source begins mid-period; baseline understated"). A number subject to material late-arriving data carries a freshness caveat and is presented as provisional, never final.

**Example:** A monthly `Order`-volume trend shows the current month down 60%. The source loaded this morning and the month is only one-third elapsed; the drop is a partial-period artifact. The current month is marked incomplete and excluded from the trend line, and the freshness/coverage note goes into `limitations` — otherwise the report would announce a collapse that is not happening.

### Dangerous Joins & Row-Multiplication (Fan-Out)

**What to look for:** Any join between datasets of different grain, especially a one-to-many or many-to-many relationship, followed by an aggregate (a `SUM` or `COUNT`) on the side that got multiplied. The signature is a total that jumped after a join was added, or a row count that is larger than the parent table. This is **fan-out**: a join to a child table replicates each parent row once per matching child, so any parent-level measure is now counted multiple times.

**Why it matters:** Fan-out is the single most common way an analytical number silently becomes wrong, and it is invisible — the query runs, the rows look reasonable, the total is simply inflated by the average number of children. Joining `Order` to its `LineItem`s and then summing the `Order` total double-, triple-, n-counts the order value by the basket size. Joining through two one-to-many relationships multiplies by the product of both fan-outs. The reader sees a revenue figure that is several times reality and has no way to know it from the output alone.

**How to check:** Before any join, state the cardinality of the relationship (one-to-one is safe to aggregate across; one-to-many and many-to-many are not, for parent-level measures). After a join, compare the post-join row count to the parent row count — if it grew, the parent side fanned out. Aggregate parent-level measures *before* joining to the child, or aggregate the child measures up to the parent grain first, or use a distinct/window technique so each parent value is counted once. Re-run the reconciliation (below) after any join to confirm the total did not move.

**What it blocks:** A `SUM` or `COUNT` of a parent-level measure taken *after* a one-to-many or many-to-many join is blocked outright — it is inflated by the fan-out factor and is simply wrong. The conclusion does not clear until the measure is aggregated at the grain where each value appears exactly once, and the post-join reconciliation ties back to the source.

**Example:** A cost report joins `Order` to `LineItem` to attribute spend by product category, then sums the per-`Order` `total` column. Each order's total is now repeated once per line item, so the reported total spend is 2.7x the true figure (the average basket size). The fix: sum line-level amounts (which are at line grain) for the category breakdown, and take the `Order` total from the `Order` table alone. The inflated figure is blocked and reconciled against the billing source before any category claim is made.

### Reconciliation (Source vs Result)

**What to look for:** A check that the reported result still ties back to an independent, trusted figure from the source — total reported revenue against the billing system's own total, reported `Order` count against the source-of-truth count. Watch for results that are *only* ever seen post-transformation, with no tie-back to anything authoritative.

**Why it matters:** Reconciliation is the safety net that catches every error the individual checks missed — a fan-out that slipped through, a filter that dropped too much, a duplicate set that was not fully collapsed. If the transformed total does not match the source-of-truth total within an explainable tolerance, *something* is wrong even if you cannot yet say what. A report that reconciles is one you can defend; one that has never been tied back to source is a number floating free of its origin.

**How to check:** Pick an independent control total the source can produce directly (the billing system's stated `prod` total, the order service's own count) and compare it to the report's figure. Make the reconciliation **deterministic and reproducible** — running it twice on the same inputs gives the same result — so it can be re-run after any pipeline change. (Separately, the load/dedup steps it checks should be **idempotent**: re-running a load or a deduplication does not double-apply.) Explain every gap: a known, quantified difference (a documented filter) is fine; an unexplained gap is a blocker. Record the reconciliation and its result in `quality_checks`.

**What it blocks:** Any headline total that does not reconcile to a trusted source within a stated, explained tolerance does not clear — it is blocked until the gap is explained or closed. An unreconciled figure may at best be reported as `LIMITED` with the discrepancy disclosed, never as a clean fact. Reconciliation is the final gate before a number is allowed to be a headline.

**Example:** After the fan-out fix above, reported total spend is reconciled against the billing export's own stated total: they tie within 0.3%; the gap is fully attributed to events on the timezone day-boundary (N rows identified), is bounded, and is stable across the last 3 runs. PASS. A residual that cannot be mechanistically attributed, or that is unbounded, or that varies run-to-run, is a blocker — not a tolerance to wave through. Before the fix, the figure was off by 170% — the reconciliation is what would have caught the fan-out even if the cardinality check had not.

### Documenting Filters, Aggregations & Business Rules

**What to look for:** Whether the filters, aggregations, and business-rule definitions baked into the numbers are written down where the reader can see them — what counts as a "completed" `Order`, which statuses are excluded, how a "month" is bounded, what "active `Customer`" means. The smell is a number whose definition lives only in the query and never in the report.

**Why it matters:** Two analysts asking "how many `Order`s?" with different definitions of "Order" (does a cancelled one count? a draft? a test order in `hom`?) get different answers, and both are right under their definition. A reader who does not know the definition cannot compare the number to anyone else's or to a past report. Undocumented business rules are how two reports of "the same metric" disagree and no one can say which is correct.

**How to check:** For every figure, write the operating definition in one line: the filters applied, the grain aggregated to, and the business rule that bounds the concept ("`Order` = status in (PLACED, SHIPPED, DELIVERED), excluding `hom`/test, bounded by `placed_at` in the calendar month, in the source's timezone"). These definitions populate the contract's `filters` and `transformations` fields and must appear in the report when they affect interpretation.

**What it blocks:** A figure whose definition is undocumented does not clear as a comparable fact — it is downgraded to `LIMITED` until the definition is stated, because no reader can know what it counts. A comparison between two figures with *different or unstated* definitions is blocked: they are not the same metric.

**Example:** A volume figure counts only `DELIVERED` orders; the prior report counted all placed orders. Presented side by side without the definitions, the new figure looks like a sharp drop. Both definitions are written into the report and the figures are recomputed on a common definition before any trend claim is made.

### The Quality Gate

**What to look for:** The aggregate question across all the heuristics above — *given everything found, does the data actually support the conclusion the report wants to draw, at the strength it wants to draw it?* This is the synthesis step where the individual findings become a verdict.

**Why it matters:** Individual checks find individual problems; the gate decides what those problems mean for the conclusion. The failure this lens exists to prevent is reaching this point, having found real problems, and proceeding with the strong conclusion anyway — letting a known fan-out, a stale source, or an unreconciled total ride into a confident headline. The gate is where validation gets its teeth.

**How to check:** Roll up every finding into one of three verdicts, per conclusion the report wants to make: **clears** (the data supports it at full strength — sources owned, grain right, reconciled, fresh enough, definitions stated); **`LIMITED`** (the data supports a weaker or caveated version — state exactly what limitation bounds it and what the reader may still safely conclude); or **blocked** (the data cannot support this conclusion at all — say why, and downgrade the report to what the data *can* support). Always record the verdict and its reason; never silently upgrade a `LIMITED` to clear. This verdict is exactly what [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md) grades.

**What it blocks:** This *is* the block. A conclusion that does not clear is either downgraded to `LIMITED` with its bounding reason stated, or blocked entirely, and the report proceeds only with conclusions the data sustains. A report whose every interesting conclusion is blocked becomes a `LIMITED` report that says honestly what little the data supports — which is the correct outcome, not a failure.

**Example:** A cross-environment cost analysis wanted to conclude "`prod` is 3x more expensive than `hom` per `Order`." Findings: `prod` source owned and fresh; `hom` source an unowned spreadsheet (Sources); units mismatched and now normalised (Schema); `prod` total reconciled, `hom` did not (Reconciliation). Verdict: the per-`Order` cost *within* `prod` clears; the `prod`-vs-`hom` ratio is blocked (the `hom` side is unowned and unreconciled). The report leads with the validated `prod` figure and records the `hom` comparison as an open limitation — instead of publishing a 3x claim half of which the data cannot defend.

## Anti-Patterns

- **Analysing before validating** — *Diff:* the skill jumps from a data request straight to aggregates and charts, treating the source as clean. *Harm:* every downstream number inherits whatever grain error, duplicate, fan-out, or staleness was in the source, and the polish of the chart disguises it — the reader trusts a figure no one checked. *Fix:* run this lens first; no aggregate is computed until grain, keys, units, duplicates, freshness, and lineage are established, and no headline ships until it reconciles.

- **Inventing or interpolating missing data** — *Diff:* a gap in coverage is filled by extrapolating a trend, carrying forward the last value, or assuming the missing period "looks like" the others. *Harm:* a fabricated number is presented with the same confidence as a measured one, and the reader cannot tell which is which; a decision is made on data that does not exist. *Fix:* never fill a gap. Record it as a limitation, downgrade the conclusion to `LIMITED`, and report only over the range actually covered.

- **Summing a parent measure after a fan-out join** — *Diff:* `Order` joined to `LineItem` (or two one-to-many joins chained), then a `SUM` or `COUNT` of a parent-level column. *Harm:* the parent value is counted once per child, inflating the total by the average fan-out factor — a revenue or cost figure several times reality, invisible in the output. *Fix:* aggregate parent measures at the parent grain before joining, or roll child measures up to the parent grain first; reconcile the post-join total against the source.

- **Reporting a mean over a distribution that makes it misleading** — *Diff:* a single mean (average `Order` value, average latency) reported with no check of the distribution. *Harm:* two outliers or a heavy skew drag the mean to a value no real record sits near, and the reader treats a number that describes nobody as typical. *Fix:* inspect the distribution; when it is skewed or has outliers, report the median (and spread) or segment, and say why the mean was not used. (The full method-selection discipline lives in [`./data-analysis.md`](./data-analysis.md); this lens only insists the distribution be *checked* before a mean is trusted.)

- **Comparing incompatible periods or environments without a warning** — *Diff:* a current period filtered differently from the prior one, a partial latest month placed beside complete months, or `prod` (cents) summed with `hom` (whole units), presented as a clean comparison. *Harm:* the reader reads an artifact of the mismatch (a filter change, an incomplete month, a unit error) as a real movement and acts on it. *Fix:* normalise the things being compared to a common definition, grain, unit, and complete period — or mark the comparison `LIMITED` and state exactly what makes the two sides not comparable.

- **Burying or omitting a known limitation** — *Diff:* a stale source, a partial period, a known duplicate set, or a reconciliation that did not tie out is left out of the report so the conclusion reads cleaner. *Harm:* the reader trusts the conclusion past where the data can carry it and is blindsided when a later, corrected run disagrees. *Fix:* surface every limitation that bounds the conclusion — freshness, coverage, duplicates, unresolved discrepancies — in the report itself; a hidden limitation is the same failure as inventing data, in reverse.

- **A clean headline on an unreconciled number** — *Diff:* a total is reported as fact having never been tied back to an independent source-of-truth figure. *Harm:* every silent upstream error survives into the headline, and the number cannot be defended when questioned. *Fix:* reconcile every headline total against a trusted control total within a stated, explained tolerance before it is allowed to be a headline; an unreconciled figure is `LIMITED` at best.

## How it feeds the AnalysisSpec

This lens fills the data-provenance and data-quality fields of the [`analysis-spec`](../templates/analysis-spec.md) contract — the fields the analysis and the HTML are forbidden to proceed without:

- **`sources`** (each with the **system/account/service/repo** it lives in, its **access path**, its **owner**, and a **freshness** attribute) — from Source & Context Discovery, Sources & Ownership, and Freshness: every account/project, service/store, repository, and catalog that holds a needed piece of data, located before validation; the access path by which each was reached (the query, export, or API call and its window — method, never the secret); its owner; and its freshness (last-load time and lag). A needed source that could not be located, accessed, or owned is carried here as a constraint, not omitted.
- **`grain`** — from Grain, Keys & Relationships: what one row of each dataset represents, and the grain every aggregate is computed at.
- **`transformations`** — from Lineage, Documenting Filters, Duplicates, and the fan-out fixes: the ordered chain of filters, derivations, deduplications, unit normalisations, and aggregations from source to result.
- **`filters`** — from Documenting Filters & Business Rules: the operating definitions (what counts, what is excluded, how a period is bounded) that make each figure comparable.
- **`quality_checks`** (what was checked + result) — from every heuristic: the duplicate/null/consistency profile, the cardinality and fan-out checks, the schema/unit/timezone confirmation, and the reconciliation and its outcome.
- **`limitations`** and the **freshness/coverage caveats that constrain `confidence`** — from Freshness, Reconciliation, and the Quality Gate: every constraint that downgrades or bounds a conclusion, stated so the analysis stage cannot claim more confidence than the data supports.

The Quality Gate's verdict per conclusion (clears / `LIMITED` / blocked) is what determines whether a finding may be tagged `FACT` in the contract or must be softened to `INFERENCE`/`HYPOTHESIS` or dropped — and it is exactly what [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md) grades as a hard gate before any HTML is produced.

## Integration (report skill)

The [`report`](../skills/report/SKILL.md) skill uses this lens as the **second step** of its pipeline, with discipline:

- **Validate before analysing, always.** This lens runs after the decision/question is framed and *before* [`./data-analysis.md`](./data-analysis.md), the contract, and any HTML. A chart is the last step, derived from a validated contract — never the first.
- **Bad data blocks strong conclusions.** The lens does not merely note problems; its Quality Gate downgrades or blocks conclusions the data cannot sustain, and the report proceeds only with what clears. A `LIMITED` report that states honestly what little the data supports is the correct outcome, not a failure.
- **Never invent, never hide.** Missing data becomes a recorded limitation, never a fill; every limitation that bounds a conclusion is surfaced in the output, never buried to make the headline read cleaner.
- **Credentials and secrets are inputs only.** The method by which a source was reached is recorded; the secret used to reach it is never written into the contract or the report and never committed — mirroring the same rule in [`./reporting.md`](./reporting.md) and the `report` skill.
- **Findings here are gates, not severities.** This lens produces quality verdicts that feed the contract and are graded by [`../rules/analysis-rigor.md`](../rules/analysis-rigor.md); it deliberately carries no `MUST`/`SHOULD`/`NIT` rubric, because it constructs and gates an analysis rather than reviewing an existing artifact. The downstream narrative and visual-shape decisions belong to [`./reporting.md`](./reporting.md), which runs only after the analysis the data here has validated.

## Packaging note

The `../` and `../..` links above resolve while this lens, its sibling lens [`./data-analysis.md`](./data-analysis.md), the [`analysis-spec`](../templates/analysis-spec.md) template, the [`analysis-rigor`](../rules/analysis-rigor.md) rule, and the [`report`](../skills/report/SKILL.md) skill are checked out together in this repository. If the `report` skill is ever exported to ship standalone, the packaging step co-locates this lens and its siblings into the skill so the pipeline stays self-contained — the same convention the other skills and lenses in this repo follow.
