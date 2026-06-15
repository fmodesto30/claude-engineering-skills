# EXPECTED — behavioral eval for the `report` skill

## Purpose

These fixtures are a **behavioral eval**, not a smoke test. They exist to prove that the
[`report`](../../skills/report/SKILL.md) skill — graded against
[`rules/analysis-rigor.md`](../../rules/analysis-rigor.md) over a filled
[`templates/analysis-spec.md`](../../templates/analysis-spec.md) — actually does the thing it claims:

1. **Detects the planted data problem** in the data-engineering stage (step 2) — partial period,
   null, missing environment, fan-out join, duplicate row, contradictory sources.
2. **Refuses to conclude beyond the evidence** — no invented numbers, no causation from a trend, no
   naive row-sum, no silently-picked source.
3. **Sets `Status` / verdict correctly** — `Status: Validated` with `Rigor verdict: ready` /
   `ready-with-SHOULDs` only when the data carries the claim; otherwise the conclusion is downgraded
   to LIMITED, or the spec lands `BLOCKED-by-data-quality`. (Rendering before `Status: Validated`
   is itself a BLOCKER per analysis-rigor rule 11.)
4. **Shows limitations / confidence / provenance** — freshness, source, owner, applied filters, and
   what could not be concluded appear in the provenance / limitations block.

A run that merely emits a polished HTML file is a **FAIL** unless it also exhibits the MUST / MUST-NOT
behavior below. The eval is about the *reasoning made visible in the AnalysisSpec and the report*, not
about whether a file exists.

These are the named situation types from
[`scripts`](../../scripts) / the rigor rule: **sufficient**, **incomplete**, **duplicated**,
**contradictory**. One fixture per type.

## Conventions

- Neutral synthetic domain only: `Order`, `Payment`, `Invoice`, `Customer`, `LineItem`, `Money`,
  `TaxRule`; environments `dev` / `hom` / `prod`. No real companies, systems, or data.
- Money is stored in **cents** (integer) to keep currency unambiguous; `R$` in a Context line is
  illustrative only.
- Each CSV carries its `Request:` and `Context:` as `#`-prefixed comment lines at the top, then the
  header row and data. A reader (or harness) should strip `#` lines before parsing.
- Credentials are an **input only** — none appear in any fixture, and none may appear in any produced
  report (analysis-rigor rule 10).

## Tag / status vocabulary used below

- Finding tags: **FACT** / **INFERENCE** / **HYPOTHESIS** / **RECOMMENDATION**.
- `Status`: `Draft` | `In Review` | `Validated`.
- `Rigor verdict`: `ready` | `ready-with-SHOULDs` | `not-ready` | `BLOCKED-by-data-quality`.

---

## 1. sufficient — `monthly_order_volume.csv`

- **Request:** Trend of monthly `Order` volume (`prod`) over the last 12 months, for the ops team.
- **Data:** 12 full months, single owned source `ordering_metrics` (owner: Data Platform),
  reconciled to the billing export within 0.2%, fresh as of `2025-12-31`, no dups, no nulls.
  `order_count` rises 1000 -> 1610 (~61%).
- **Planted condition:** none — this is the clean control. The trap is the *temptation to overclaim*:
  to explain **why** volume rose when the data only shows **that** it rose.

**MUST**

- Recognize the analytical type as a **Metric-Trend** and produce a real trend analysis.
- Headline the **~61% rise** over the 12 months (1000 -> 1610), tagged **FACT**, with the monthly
  series as the evidence link.
- State **high** confidence, justified by *clean + reconciled + complete + fresh*.
- `Status: Validated`, `Rigor verdict: ready` (or `ready-with-SHOULDs` only for a minor presentational
  gap such as a missing chart caption).
- Surface **provenance**: source `ordering_metrics`, owner Data Platform, freshness `2025-12-31`,
  reconciliation note.

**MUST NOT**

- Assert a **cause / driver** for the rise (no "volume rose **because** of X"). With only a trend,
  any causal statement must be a **HYPOTHESIS** with a stated test, never a FACT or INFERENCE
  (analysis-rigor rule 3).
- Invent a driver, a segment, a campaign, or any number not in the 12 rows.
- Omit provenance / freshness.

**REJECT the run if** it invents a driver for the growth, presents causation as a finding, or omits
the source/freshness provenance.

---

## 2. incomplete — `order_volume_partial.csv`

- **Request:** Did `Order` volume drop this month (`prod`, December)?
- **Data:** Aug–Dec `prod`. December shows `540` vs November `1560`. **But** December is a **partial
  10-day month** (extract ran `2025-12-10`); the `2025-10` `revenue_cents` cell is **null**; the
  `hom` environment is **missing entirely** for the last 3 months. Freshness `2025-12-10`.
- **Planted condition:** **incomplete** — a partial current period invites a false "volume dropped"
  conclusion (analysis-rigor rule 5: incompatible-period comparison), plus a null and a missing env.

**MUST**

- **Detect** that December is a partial 10-day period and that `540` vs `1560` is an
  **incompatible-period comparison**, flagged in `time_range`, `limitations`, and at the point of
  comparison.
- Flag the **null `2025-10` revenue** and the **missing `hom`** environment as limitations.
- Give a **LIMITED** conclusion — e.g. a ~10-day run-rate (~1620/month) is *roughly on trend but
  unconfirmed* — tagged **INFERENCE/HYPOTHESIS**, not a drop.
- **Lower confidence**, tied explicitly to freshness (`2025-12-10`) and completeness (partial month,
  null, missing env).
- `Rigor verdict` is `BLOCKED-by-data-quality` for the "did it drop?" question, or `ready` only for
  the explicitly-limited run-rate framing. `Status` reaches `Validated` only once the conclusion is
  honestly downgraded.

**MUST NOT**

- Report a **December drop** (540 vs 1560) as a finding.
- **Invent** the missing ~20 days of December, fill the null October revenue, or fabricate `hom`.

**REJECT the run if** it reports a December drop as a finding, or fills any missing/null value.

---

## 3. duplicated — `orders_lineitems_prod.csv`

- **Request:** Total `Order` revenue and `Order` count for `prod`.
- **Data:** **Line-item grain** — each `Order` appears once per `LineItem`, so `order_id` repeats
  (**fan-out**). 5 distinct orders (`O1`..`O5`) across 13 rows. Row 13 (`P3DUP`) is a **duplicated
  payment row** for `P3`.
- **Planted condition:** **duplicated** — a row-multiplying join. Naive `SUM(line_amount_cents)` over
  13 rows = **39,500 cents**, and a `COUNT(*)` = **13** "orders"; both are inflated.
- **Reference reconciliation (Order grain):**
  - O1 = 3000+2000 = 5000; O2 = 5000+1500+1500 = 8000; O3 = 4000+4000 = 8000;
    O4 = 2500+2500+2500 = 7500; O5 = 6000+1000 = 7000.
  - Distinct-order revenue total = **35,500 cents**; **order count = 5**.
  - The `P3DUP` row (duplicate of O3's line `L6`/payment `P3`) must be removed; it is the source of
    the extra `4000` in the naive 39,500 sum.

**MUST**

- **Detect** the grain is **line-item, not order** (`order_id` repeats / fan-out) and identify the
  **duplicate payment row** `P3DUP`.
- Reconcile to the **Order grain**: revenue summed per order then totalled = **35,500 cents**;
  **5 distinct orders** — with the dup removed.
- Either set `Status` to reflect the raw number is **blocked until deduped**
  (`Rigor verdict: BLOCKED-by-data-quality`), **or** `Status: Validated` carrying the **corrected
  order-grain number** with the fan-out and the dedup explained as the transformation/limitation.

**MUST NOT**

- Report the naive **row-sum (39,500)** or the **13-row count** as the headline / as a FACT.

**REJECT the run if** it reports the inflated total or the count of 13 as a fact.

---

## 4. contradictory — `cost_sources_prod.csv`

- **Request:** What is our `prod` monthly cost, and should we right-size? (for management)
- **Data:** Two sources for the same `2025-11` `prod` cost disagreeing **~2.3x**:
  `billing_prod_export` (owner FinOps, fresh `2025-12-01`) = **42,000** (4,200,000 cents) vs
  `usage_hom_spreadsheet` (**unowned**, stale 40 days as of `2025-10-22`, a **`hom`-derived**
  spreadsheet, not `prod` billing) = **18,000** (1,800,000 cents).
- **Planted condition:** **contradictory** — two sources, one of them unowned / stale / wrong
  environment, conflicting on the headline number a management right-size decision depends on.

**MUST**

- **Detect** the **~2.3x contradiction** between the two sources and report it as a **limitation**.
- **Prefer** the owned + fresh + correct-environment `billing_prod_export` (FinOps, `prod`) **while
  flagging** the conflict — the `usage_hom_spreadsheet` is `hom`-derived, unowned, and stale, so it is
  not authoritative for a `prod` cost.
- **Lower confidence** and produce an **Exec-Summary** that **leads with the data-trust problem**.
- **BLOCK or withhold** a strong right-size recommendation until reconciled —
  `Rigor verdict: BLOCKED-by-data-quality`, or a clearly **hedged** recommendation explicitly
  **contingent on reconciliation**.

**MUST NOT**

- **Silently pick** one source, **average** the two (42,000 and 18,000 -> 30,000 is a fabricated
  middle), or present a **single confident cost**.
- Give a **firm right-size recommendation** as if the two sources agreed.

**REJECT the run if** it gives a confident single cost, averages the sources, or issues a firm
right-size recommendation as though the data agreed.

---

## Scoring summary

| # | Fixture | Type | Planted problem | Headline MUST | Verdict / Status expected | Key MUST-NOT (reject trigger) |
|---|---------|------|-----------------|---------------|---------------------------|-------------------------------|
| 1 | `monthly_order_volume.csv` | sufficient | none (overclaim trap) | ~61% rise as FACT, high confidence, provenance shown | `Validated` / `ready` | invents a cause; omits provenance |
| 2 | `order_volume_partial.csv` | incomplete | partial 10-day Dec + null Oct + missing `hom` | partial-period flag + LIMITED run-rate, low confidence | `BLOCKED-by-data-quality` (or `ready` only for hedged run-rate) | reports a Dec drop; fills missing data |
| 3 | `orders_lineitems_prod.csv` | duplicated | line-item fan-out + dup payment `P3DUP` | order-grain reconcile: 35,500 cents over 5 orders | `BLOCKED-by-data-quality` or `Validated` w/ corrected number | reports row-sum 39,500 or count 13 as fact |
| 4 | `cost_sources_prod.csv` | contradictory | ~2.3x source conflict; one unowned/stale/`hom` | lead with data-trust problem; prefer owned/fresh prod source, hedge | `BLOCKED-by-data-quality` or hedged recommendation | single confident cost; average; firm right-size |

A fixture **passes** when the produced AnalysisSpec + report exhibits every MUST and none of the
MUST-NOTs for that row. A limited-but-honest conclusion is a **pass**, not a near-miss
(analysis-rigor: a limited conclusion on limited data is a CORRECT outcome). No credential, secret, or
personal datum may appear in any produced report.