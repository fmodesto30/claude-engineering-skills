# discovery — `discovery_landscape.md`

A multi-source **discovery** scenario for the [`report`](../../skills/report/SKILL.md) skill. Unlike the
four single-file CSV fixtures in this directory (`sufficient`, `incomplete`, `duplicated`,
`contradictory`), the data here is **not in one place** — it is spread across four different systems,
accounts, and repositories, and the analysis must **discover and MAP the landscape before it can
analyze anything**. There is no single CSV to load; the inputs below describe *where the data lives*,
*who owns it*, and *how to reach it*, exactly as a real cross-system request would arrive.

Neutral synthetic domain only (`Order`, `Payment`, `Notification`, `Invoice`, `Customer`, `LineItem`,
`Money`, `TaxRule`; environments `dev` / `hom` / `prod`). The technology and source *types* named below
(AWS, Glue, Athena, S3, DynamoDB, CloudWatch, Java/Spring, Kafka, Postgres) are **illustrative source
types only** — the kinds of system an analysis should expect to enter and verify against the real
project, the same way `Debezium` / `Kafka` are named as illustrative tools in the CDC lens. They are
**not** any real company, account, or system, and carry no real account ids, ARNs, endpoints, or data.
`R$` figures are illustrative and rounded. Any credential or access path named is an **input only** —
it is used to *reach* a source and must never be written into a produced report.

---

## REQUEST

> The platform team asks for the **cost AND usage of the `Notification` service across
> `dev` / `hom` / `prod`**, with a **right-sizing recommendation**.

- **Decision it supports:** should the `Notification` service be re-provisioned (up or down) per
  environment, and by how much?
- **Audience:** the platform team (engineers who own provisioning) — they need the per-environment
  numbers and the method, not just a one-line verdict.
- **What "right-size" needs:** for each environment, the analysis must put **cost** next to **actual
  usage** next to **provisioned capacity**, at a consistent environment grain, and only then say
  whether capacity is over- or under-provisioned.

The request reads like a single number ("cost and usage of one service"), but the inputs that answer it
do not live together. The first task is therefore **not** analysis — it is **discovery**: find the
systems that hold each piece, learn who owns them and how to reach them, and decide which can be
trusted, before a single number is compared.

---

## LANDSCAPE — what exists and WHERE the data lives

Four distinct systems each hold *one* piece of the answer. None of them alone answers the request; the
answer only exists once cost, usage, and capacity are joined at a consistent `env` grain. The analysis
must enumerate all four — system, account, owner, access path, freshness — as its **source map**
before analyzing.

### Source A — AWS cost dataset `cur_daily` (cost)

- **What it holds:** daily cost broken down by service and environment — the **cost** half of the
  answer, for all three environments.
- **Where / how to reach it:** an AWS Cost-and-Usage-style dataset `cur_daily`, queried through
  **Glue / Athena** (a Glue table over cost data in S3, read with Athena SQL).
- **Account:** `platform-billing` (illustrative account *type* — a central billing account; not a real
  account id or ARN).
- **Owner:** **FinOps**.
- **Freshness / trust:** **fresh** and owned. Accessible.
- **Grain:** cost by `service` x `env` x `day` (rolls up to monthly per env).

### Source B — DynamoDB table `notification_usage` (usage)

- **What it holds:** request counts by environment — the **usage** half of the answer.
- **Where / how to reach it:** a **DynamoDB** table `notification_usage`.
- **Account:** `app-prod` (illustrative account *type* — the application's production account; not a
  real account id).
- **Owner:** the **`Notification` squad**.
- **Freshness / trust:** populated for **`prod` only**. **`dev` and `hom` are EMPTY** — there are *no*
  usage rows for those two environments. This is the planted gap: usage exists for one of three
  environments.
- **Grain:** request count by `env` (monthly).

### Source C — Java/Spring repo `notification-service` (provisioned capacity)

- **What it holds:** the **provisioned capacity per environment** — what the service is *configured to
  handle*, the denominator a right-sizing recommendation compares usage against.
- **Where / how to reach it:** a **Java / Spring** code repository `notification-service`; capacity is
  declared per environment in `application-<env>.yml` (e.g. `application-dev.yml`,
  `application-hom.yml`, `application-prod.yml`).
- **Owner:** the **`Notification` squad**.
- **Freshness / trust:** source-of-truth config in version control; read from the repo.
- **Grain:** configured capacity by `env`.

### Source D — old ops spreadsheet (stale, unowned, conflicting — a TRAP)

- **What it holds:** cost numbers for the same service — but they **DISAGREE with `cur_daily`**.
- **Where / how to reach it:** a loose ops spreadsheet, not in any owned system.
- **Account / owner:** **unowned** — no team claims it.
- **Freshness / trust:** **stale (~60 days old)**. Its cost figures conflict with the owned, fresh
  `cur_daily`. It is a tempting shortcut precisely because a spreadsheet is easy to read, but it is the
  *least* trustworthy source in the landscape.
- **Why it is here:** to test whether the analysis prefers the owned + fresh `cur_daily` and **flags
  the conflict**, rather than silently taking whichever cost number it found first.

---

## PARTIAL DATA (the few numbers that exist)

Only the numbers below are known; everything else must be discovered, and the missing pieces must be
named as gaps, not filled in.

| Source | Env | Figure | Notes |
|--------|-----|--------|-------|
| `cur_daily` (cost) | `prod` | ~R$ 42,000 / month | owned (FinOps), fresh, via Glue/Athena |
| `cur_daily` (cost) | `hom`  | ~R$ 9,000 / month  | owned (FinOps), fresh |
| `cur_daily` (cost) | `dev`  | ~R$ 6,000 / month  | owned (FinOps), fresh |
| `notification_usage` (usage) | `prod` | ~1.2M requests / month | DynamoDB, owned by Notification squad |
| `notification_usage` (usage) | `hom`  | **EMPTY** | no rows — usage unmeasured |
| `notification_usage` (usage) | `dev`  | **EMPTY** | no rows — usage unmeasured |
| `notification-service` (capacity) | `prod` | provisioned for ~3M / month | from `application-prod.yml` |
| old ops spreadsheet (cost) | — | **conflicts** with `cur_daily` | stale ~60 days, unowned |

What the partial data already makes computable **for `prod` only**:

- `prod` cost is known (~R$ 42,000/mo), `prod` usage is known (~1.2M req/mo), and `prod` capacity is
  known (~3M req/mo) — so `prod` runs at roughly **~40% of provisioned capacity** (1.2M of 3M). That is
  the one environment where cost, usage, and capacity all exist and can be joined, so a right-sizing
  read (looks over-provisioned, ~2.5x headroom) is *supportable for `prod`*.

What the partial data does **not** make computable:

- `dev` and `hom` **usage is missing** (the DynamoDB table is empty for them). Cost is known
  (~R$ 6,000 and ~R$ 9,000) and capacity is in the YAML, but with **no usage**, utilization for
  `dev` / `hom` cannot be computed — so a right-sizing recommendation for those two environments is
  **unmeasured** and must be an open question / limitation, never a guess.

---

## The shape of the answer (why this is a discovery + lineage analysis)

This request cannot be answered by reading one table. The answer only exists after:

1. **Discovering and mapping** the four sources above — system, account, owner, access path, freshness
   — and recording them as a source map in the AnalysisSpec, *before* analyzing.
2. **Joining** cost (`cur_daily`, Source A) + usage (`notification_usage`, Source B) + capacity
   (`notification-service`, Source C) **at a consistent `env` grain** — the three live in three
   different systems and only become a right-sizing answer when reconciled per environment.
3. **Detecting the missing usage** for `dev` / `hom` (Source B empty) so the recommendation is
   **prod-only**, with `dev` / `hom` carried as an unmeasured open question.
4. **Preferring** the owned + fresh `cur_daily` (Source A) over the stale unowned spreadsheet
   (Source D) for the cost figure, while **flagging** the conflict rather than hiding it.

Because the analysis **spans multiple sources and is partly about the data path itself** (where each
number comes from, and whether the pieces can be joined), it calls for a **data-flow / architecture
diagram**: the three trusted sources -> a reconcile/join node at `env` grain -> the per-`env`
cost/usage/utilization output, with the stale spreadsheet shown as a *rejected* / conflicting input.
The diagram is the visual answer to "where does each number come from, and how do they combine."
