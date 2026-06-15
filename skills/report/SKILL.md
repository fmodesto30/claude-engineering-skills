---
name: report
description: >-
  Produces a self-contained HTML report by first CLASSIFYING the situation and then selecting the
  shape that fits — never one fixed format for everything. Covers four distinct shapes: an analytical
  / cost analysis of a system or dataset across environments (engineers); a metric / trend of one
  quantity over time (ops / business); a docs-to-stories backlog or learning trail / trilha read out
  of source documents (product owner / team); and a short decision-oriented management summary
  (steering). Use when asked to generate or write an HTML report, build a report, or turn data or
  documents into a report deliverable. Classifies by purpose and audience before generating, asks when
  genuinely ambiguous, and treats any credentials or secrets as inputs only — never written into the
  output or committed. General-purpose; not tied to Java/Spring.
---

# report

A construction workflow that produces a self-contained HTML report in a target directory. Its first
and most important act is to **classify the situation** — what is this report *for*, and *who* reads
it — and only then to select the report shape that fits. It exists to replace the failure it most
often sees: a single "make an HTML report" routine that emits the *same* structure for every
situation, so an infrastructure cost analysis, a monthly-volume trend, a docs-to-backlog learning
trail, and a one-page management summary all come out identical and none serves its reader. This
skill consumes [`../../lenses/reporting.md`](../../lenses/reporting.md) to decide the shape, then
fills the matching template — the shape follows the function, never the other way round.

## Core stance

- **Shape follows function.** A report serves a specific purpose for a specific audience; its
  structure is correct only when it matches both. There is no single house format to apply.
- **Classify before generating.** The first action is to decide the report type by purpose and
  audience — not to reach for whichever structure was used last. The shape is chosen from the
  situation, every time.
- **Never one template for everything.** Reusing one structure for an analysis, a trend, a backlog,
  and a summary alike fails at least three of the four. Applying one shape to every situation is the
  exact failure this skill is built to stop.
- **Lead with what the audience needs; omit the rest.** Each shape leads with the thing its reader
  came for — the headline finding, the number and its trend, the backlog, or the decision — and
  carries only the supporting detail that audience can act on.
- **Credentials and secrets are inputs only, never output.** A connection string, an API key, a
  token, or personal data may be needed to *gather* the data; none of it is ever written into the
  report or committed. A report shows results, not the keys used to obtain them.
- **Inspect the real request and data.** Never assume the purpose, the audience, the data shape, or
  the environment. Establish what is actually being asked and what data actually exists before
  choosing a shape; a report built on an assumed purpose is the wrong shape by default.

## How to write a report

1. **CLASSIFY the purpose and audience**, consulting [`../../lenses/reporting.md`](../../lenses/reporting.md).
   Ask the two questions the lens defines: what is this report *for* (analyze a system / track a
   number over time / turn documents into a backlog / drive a management decision), and *who* is the
   audience (engineer / ops or business / product owner / management)? The pair decides the type.
2. **Pick the matching template** from [`../../templates/reports/`](../../templates/reports/) — one of
   `analytical.html` (a diagnostic/cost analysis for engineers, often across `dev` / `hom` / `prod`),
   `metric-trend.html` (one quantity over time for ops/business), `discovery-stories.html` (a
   docs-to-stories backlog / *trilha* for a product owner and team), or `exec-summary.html` (a short
   decision-oriented summary for management). Do not pick a default; pick the one the classification
   selected.
3. **Gather the data.** Run the queries, read the source documents, or use the inputs provided —
   whatever the chosen shape needs. **Treat any credentials, tokens, or secrets as inputs only:**
   use them to obtain the data, describe *how* the data was obtained (the query, the source, the time
   window), and never write the secret itself into the report or commit it.
4. **Fill the template with situation-appropriate content** and simple, self-contained visuals.
   Lead with what the chosen shape leads with and omit what it omits (per the lens). Visuals are
   inline and offline — no external JS/CSS/CDN, no web fonts, no remote images — so the report is a
   single file that renders the same offline and prints cleanly.
5. **Write the finished HTML to the target reports directory** the caller specified (or the project's
   conventional reports location). The output is one self-contained `.html` file in the chosen shape.
6. **If the report type is genuinely ambiguous, ASK** rather than defaulting to one shape. When the
   purpose or the audience cannot be inferred from the request and the inputs, a clarifying question
   is correct; a confidently-produced wrong shape is the failure to avoid.

## Output

A single self-contained HTML file in the shape the classification selected, written to the target
reports directory:

- **Analytical** — leads with the question and headline finding; context & scope, data sources &
  method (how, never the credentials), findings, cost/impact breakdown, recommendations, appendix.
- **Metric-Trend** — leads with the headline number and its period-over-period delta; trend over
  time, breakdown by a dimension, notable movements, notes & caveats.
- **Discovery-Stories** — leads with the source map; epics/themes, stories (title, *As a … / I want
  … / So that …*, acceptance criteria), sequence & dependencies (the *trilha*), open questions.
- **Exec-Summary** — leads with the recommendation / TL;DR; 3–5 key numbers, risks & trade-offs,
  decision needed / next steps. Short by design.

The file is offline-ready (no external dependencies), print-friendly, and contains no credentials,
secrets, or personal data.

## Restraint rules

- **Never apply one shape to everything.** Classify first; the four shapes exist precisely so that no
  single one is the answer.
- **Lead with what the audience needs, and omit the rest.** Do not pad an exec summary with method,
  and do not strip an analytical report to a headline — match the shape's depth to its reader.
- **Never embed credentials, secrets, or PII.** They are inputs to gathering the data, never content
  of the deliverable, and a report carrying one must never be committed.
- **If the data is missing or the type unclear, ask.** A recorded open question or a clarifying
  question beats a confident report built on a guess.
- **A report is a deliverable — scale it to the audience.** A one-page exec summary for a steering
  group and a deep analytical report for engineers are both correct when they match their reader;
  the wrong size for the audience is the defect.

## Packaging note

The `../../` links above resolve while this skill, the lens, and the templates are checked out
together in the repository. If this skill is ever exported to ship standalone, the packaging step
co-locates [`../../lenses/reporting.md`](../../lenses/reporting.md) and the
[`../../templates/reports/`](../../templates/reports/) templates into the skill so it stays
self-contained — the same convention the other skills in this repo follow.
