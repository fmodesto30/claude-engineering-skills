---
name: eval-harness
description: >-
  Builds a repeatable evaluation harness for non-deterministic or judgment outputs — an LLM feature,
  an agent, a classifier, a ranker, an extractor — where a pass/fail unit test does not fit. Use when
  shipping or changing a prompt, model, or agent and "looks good" is the only evidence; when asked to
  "evaluate", "measure quality", "build an eval set", "is the new model better", or "set up regression
  testing for the AI feature"; or when comparing model tiers for cost vs. quality. Defines the success
  criteria and the dataset, picks the strongest grader the criterion allows (deterministic > reference
  metric > validated LLM-as-judge), pins and records the run config, and compares against a baseline
  with n and variance. Advisory on methodology — it designs and runs the measurement, it does not
  bless a model. Not for deterministic code (use the testing lens / java-pr-review) — only outputs
  with no single right answer to assert.
---

# eval-harness

A meta/ops + quality skill that brings measurement to work whose output is **not deterministic** — an
LLM feature, an agent, a classifier, a ranker, an extractor. Its subject is *whether the output is
good enough, repeatably and on evidence*, in the space where the
[`../../lenses/testing.md`](../../lenses/testing.md) discipline ("does this code fail for the right
reason?") doesn't reach because there is no single correct answer to assert. It pairs with
[`../effort-budget/SKILL.md`](../effort-budget/SKILL.md): effort-budget right-sizes the model to the
task; this skill proves the right-sized model still clears the bar — and catches the regression when a
prompt or model changes.

## Core stance

- **Eval before vibes.** A non-deterministic feature with no eval set is *unmeasured*. "It looked
  good on the three examples I tried" is not a metric and will not survive a model upgrade or a prompt
  edit.
- **The dataset is the asset, not the prompt.** A curated set of representative + edge + adversarial
  cases, each with a gradeable expectation, is what makes quality measurable and a change comparable.
  Version it and hold out a test slice you never tune against — an eval you tune on is a *train* set,
  and a score on it is leakage that stops predicting production.
- **Grade with the strongest grader the criterion allows.** Deterministic check (exact match, schema
  valid, contains-the-fact) > reference-based metric > LLM-as-judge with an explicit rubric. An LLM
  judge is itself a model: it must be validated against human labels before its score drives a
  decision, and controlled for position, verbosity, and self-preference bias.
- **Determinism in the harness, not the model.** Pin and record the model id, prompt version,
  temperature, and seed with every result. A score you cannot attribute to a specific config is noise
  — you won't know what moved it.
- **A score is meaningless without a baseline, an n, and a spread.** "87%" alone says nothing. Report
  n, the baseline, and the variance/confidence; a two-point move on twenty examples is not an
  improvement (per [`../../lenses/data-analysis.md`](../../lenses/data-analysis.md)). Never claim a win
  that sits inside the noise.
- **Measure cost and latency next to quality.** The right model is the *cheapest one that clears the
  bar*, not the top score regardless of spend — the same asymmetry as
  [`../../lenses/model-and-effort-economy.md`](../../lenses/model-and-effort-economy.md). Track
  tokens/cost and latency per run as first-class metrics, not afterthoughts.

## When to run

- A **prompt, model, or agent is being shipped or changed** and the only evidence is "it looks good".
- The user asks to **"evaluate", "measure quality", "build an eval set", "is the new model better",
  "set up regression testing for the AI feature"**.
- **Comparing model tiers** for a feature — to find the cheapest tier that still passes (hand the
  tier decision itself to `effort-budget`; this skill supplies the evidence).
- Evaluating the **agent's own skills/outputs**, not just a product feature.

Do **not** run it for deterministic code whose behavior an ordinary test asserts — that is `testing` /
`java-pr-review` territory, and an eval harness there is overhead, not rigor.

## How to run

1. **Define "good" before looking at outputs.** Write the criteria and the bar per criterion
   (accuracy, faithfulness/groundedness, format validity, refusal-correctness, latency, cost) up
   front, so the eval is not reverse-engineered from whatever the current model happens to do.
2. **Curate and version the dataset.** Representative cases + the edges (empty, ambiguous, very long,
   multilingual) + adversarial / known-failure cases. Hold out a test slice. Treat it as data —
   lineage and grain matter, per [`../../lenses/data-engineering.md`](../../lenses/data-engineering.md);
   a skewed or leaky set produces a confident wrong number.
3. **Pick the grader per criterion, strongest first.** Deterministic > reference metric >
   LLM-as-judge. If you use a judge, validate it against a sample of human labels and **report that
   agreement**; control bias by randomizing position and hiding which system produced which output.
4. **Pin the run config.** Record model id, prompt/version, temperature, seed, and date alongside the
   results — so a later score change is attributable to one variable, not a mystery.
5. **Run, score, compare to baseline.** Report each metric with n and spread against the prior
   baseline; mark results inside the noise as *inconclusive*, not wins. Include the cost/latency delta.
6. **Make it a gate.** A prompt or model change ships only if it does not regress the eval; wire the
   harness into CI or a pre-merge check so the regression is caught before release, not by users.
   Borrow the testing lens's discipline — an eval that *cannot fail* proves nothing.

## Output format

```
Eval: <feature / agent under test>
  Dataset: n=<count>, held-out=<count>, slices=<representative|edge|adversarial>, version=<id/date>
  Config:  model=<id>  prompt=<version>  temp=<t>  seed=<s>
  Grader:  <criterion> -> <deterministic | metric | llm-judge (judge-vs-human agreement=<x>)>

  Metric             baseline    this run    n      verdict
  <accuracy>         <…>         <…>         <…>    improved | regressed | within noise
  <faithfulness>     <…>         <…>         <…>    …
  cost / 1k calls    <…>         <…>                <delta>
  p95 latency        <…>         <…>                <delta>

Verdict: ship | regression (blocks) | inconclusive (n too small / within noise)
```

## Restraint rules

- **Don't impose an eval where a unit test fits.** A deterministic feature belongs to `testing` /
  `java-pr-review`; an eval harness there is ceremony — `NO_COMMENT`.
- **Never claim an improvement inside the noise.** Within-variance is "inconclusive", not "better".
- **Don't ship an unvalidated LLM judge as truth.** A judge never checked against human labels is an
  opinion with a number on it; do not let it drive a ship decision unexamined.
- **Don't tune against the test set.** Tuning on held-out data is leakage; the score stops predicting
  production.
- **Stay advisory on the verdict.** The skill designs, runs, and reports the measurement honestly;
  whether to ship under that result is the team's call.

## Severity

Classify every finding `MUST` / `SHOULD` / `NIT` / `NO_COMMENT` per
[`../../rules/severity-rubric.md`](../../rules/severity-rubric.md), and obey the overriding rule:
every finding names a concrete consequence.

- **MUST** — a non-deterministic change shipped with **no eval** (or with a grader that cannot fail);
  an improvement **claimed from a move inside the noise**; or an **unvalidated LLM-judge** score
  driving a ship / no-ship decision. Failure mode: a quality regression reaches users undetected, or a
  false "it's better" justifies a costly rollout.
- **SHOULD** — no held-out set (train/test leak); the eval set unversioned (results not reproducible);
  or cost/latency not tracked alongside quality, so a "better" model that doubles spend ships
  unexamined.
- **NIT** — harness ergonomics, report layout, metric naming.
- **NO_COMMENT** — a deterministic feature adequately covered by ordinary tests. Do not manufacture an
  eval harness where the testing lens already answers the question.
