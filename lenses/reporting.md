# Reporting Lens

Reusable knowledge for shaping an HTML report by its **purpose** and its **audience**: which of the four report shapes fits the situation, what each shape leads with, what it omits, and why one-template-for-everything is the dominant failure. **The intent of using this lens comes from the consuming skill, not from the lens itself.**

## How skills use this lens

This is a **construction / judgment** lens, not a review lens — it carries no severity rubric, because nothing here grades an artifact that already exists. Its job is to help a skill *decide a shape before generating output*. Its consumer today is the [`report`](../skills/report/SKILL.md) skill, which reads it to **classify** a reporting situation and pick the matching template before it writes a line of HTML. It could later serve other output-producing skills (a dashboard generator, a release-notes writer) the same way — each supplies its own intent, the lens supplies the taxonomy and the classification discipline.

A consuming skill loads this lens whenever it is asked to produce a report and must decide what shape that report should take — never to enforce a house format, because there is no single house format. The whole point is the opposite: the shape is chosen from the situation.

## Purpose

This lens exists to kill one specific failure: a single report shape applied to every situation, so an infrastructure cost analysis, a monthly-volume trend, a docs-to-backlog learning trail, and a one-page management summary all come out structurally identical and none of them serves its reader well. It gives the consuming skill a small, concrete taxonomy of report types, a way to classify a situation into one of them by asking what the report is *for* and *who reads it*, and a per-type description of what to lead with and what to leave out. The default bias is restraint: a report carries only what its audience needs to act, and leads with the thing that audience came for — the finding, the number, the backlog, or the decision — not with a throat-clearing preamble. When the situation is genuinely ambiguous, the right move is to **ask**, not to default to a familiar shape.

## When to Use

Consult this lens when a skill is asked to **generate or write a report** and must decide its shape, including:

- A request to analyze a system, a dataset, or a service — often across environments (`dev` / `hom` / `prod`) — and present what was found.
- A request to track one quantity over time and show where it is heading.
- A request to read source documents and turn them into a backlog, a set of stories, or a learning trail (a *trilha*).
- A request to summarize an initiative, an analysis, or a decision for management or a steering group.
- Any request where the word "report" is used but the purpose and audience are not yet pinned down — the trigger to classify (or to ask) before generating.

Do NOT engage this lens to impose a fixed corporate template, to add chrome (logos, cover pages, boilerplate) that serves no reader, or because a request merely contains the word "report" in passing. The trigger is a real decision about *what shape best serves this purpose and this audience*, not the vocabulary used to ask for it.

## Core Principle

**Shape follows function.** A report is not a document format; it is an instrument that serves a specific purpose for a specific audience, and its structure is correct only when it matches both. The dominant failure mode is two-fold and worth naming directly:

1. **One template for everything.** Reusing a single structure — usually whichever one was built first — for analyses, trends, backlogs, and summaries alike. The structure then fits at most one of them and quietly fails the rest: the trend report has no trend, the management summary buries its conclusion under method, the backlog has no acceptance criteria.
2. **Burying the conclusion.** Leading with context, method, and scaffolding when the reader came for a finding, a number, a backlog, or a decision. Every shape leads with what *its* audience needs first; the supporting material comes after, not before.

A report earns its structure only when that structure does concrete work for the reader: it puts the thing the audience came for at the top, carries exactly the supporting detail that audience can act on, and omits the rest. A correct report for an engineer is the wrong report for a steering committee, and vice versa — same facts, different shape. **Credentials, secrets, and personal data are inputs to producing a report, never content of it:** a report shows results, not the keys used to obtain them.

## Report Types

Four types. Each has a distinct structure, a distinct audience, and a distinct thing it leads with. Classifying into one of these — by purpose and audience — is the first and most important decision; everything else follows from it.

### 1. Analytical

A diagnostic or exploratory analysis of a system or dataset, often compared across environments — the report that answers "what is going on here, and what does it cost / imply?"

- **When it applies:** the purpose is to investigate a system or a dataset and present what was found, with enough method that a peer trusts the numbers. Usually spans environments or dimensions and ends in recommendations.
- **Audience:** engineers and tech leads — readers who can and will scrutinize the method and the data.
- **Lead with:** the question being answered and the headline finding — the answer first, the build-up after.
- **Structure:** Context & scope -> Data sources & method (*how* the numbers were obtained — the queries, the time window, the sampling; never the credentials themselves) -> Findings (tables, simple charts) -> Cost / impact breakdown -> Recommendations -> Appendix / raw detail.
- **What to OMIT:** management-level hand-holding, motivational framing, and any restating of basics the engineering audience already knows. Keep the appendix for raw detail rather than inlining it.
- **Visual:** comparison tables across environments or dimensions; a simple bar or grouped-bar chart for the cost/impact breakdown.
- **Neutral example:** usage and cost of a datastore or messaging service across `dev` / `hom` / `prod`, with a recommendation on right-sizing.

### 2. Metric-Trend

One quantity tracked over time — the report that answers "what is this number, and which way is it moving?"

- **When it applies:** the purpose is to follow a *single* quantity across a period and show its direction and any notable movement. If there is more than one headline quantity or the goal is diagnosis rather than tracking, it is probably Analytical, not this.
- **Audience:** operations and business readers who watch the number routinely and want the movement at a glance.
- **Lead with:** the headline number for the current period and its period-over-period delta — up or down, by how much.
- **Structure:** Headline number + period-over-period delta -> Trend over time (a simple line/bar chart or a values table) -> Breakdown by a dimension -> Notable movements / anomalies -> Notes & caveats.
- **What to OMIT:** deep method, recommendations, and exploratory analysis — those belong in an Analytical report. Do not turn a trend into a diagnosis.
- **Visual:** a single clear time-series (line or bar); a small table of the underlying values so the chart is verifiable.
- **Neutral example:** monthly `Order` volume over the last twelve months, broken down by region, with a note on a one-month spike.

### 3. Discovery-Stories

Reading source documents and producing a backlog or learning trail (a *trilha*) — the report that answers "given these documents, what should we build and in what order?"

- **When it applies:** the purpose is to consume source material (a feature document, a set of requirements, meeting notes) and turn it into epics, stories, and a sequence the team can work through.
- **Audience:** a product owner and the delivery team — readers who will refine, estimate, and pull the items into work.
- **Lead with:** a source map — what was read — so the reader can trust the backlog is grounded in the documents and see what it is derived from.
- **Structure:** Source map (what was read, by title / path) -> Epics / themes -> Stories (each with a title, an *As a ... / I want ... / So that ...* line, and acceptance criteria) -> Sequence & dependencies (the *trilha* / ordering) -> Open questions.
- **What to OMIT:** cost analysis, trend charts, and management framing — none of those is what a backlog is for. Do not invent stories the sources do not support; record gaps as open questions instead.
- **Visual:** the epic -> stories grouping itself (cards or a nested list); a simple ordered list or dependency arrows for the sequence.
- **Neutral example:** read a `Notification` feature document and produce epics, stories with acceptance criteria, and a suggested build order.

### 4. Exec-Summary

A short, decision-oriented summary for management — the report that answers "what should we decide, and why?"

- **When it applies:** the purpose is to drive or inform a management decision, compressing a larger body of work into the few things a busy decision-maker needs. Short by design.
- **Audience:** management / a steering group — readers who want the conclusion and the trade-offs, not the derivation.
- **Lead with:** the recommendation / TL;DR — the conclusion is the *first* thing on the page, never the last.
- **Structure:** Recommendation / TL;DR **first** -> 3 to 5 key numbers -> Risks & trade-offs -> Decision needed / next steps. Keep it to roughly a page.
- **What to OMIT:** method, raw data, appendices, and engineering depth — link to or reference the underlying Analytical report rather than reproducing it. If it does not help a decision, it does not belong here.
- **Visual:** at most a few large key-number callouts; no dense tables, no exploratory charts.
- **Neutral example:** summarize a `PricingRule` migration initiative for a steering committee — recommend go / no-go, with three key numbers and the main risk.

## How to Classify

Decide the shape by answering two questions, in order:

1. **What is the PURPOSE?**
   - Analyze a system or dataset and explain what is going on -> **Analytical**.
   - Track one quantity over time and show its direction -> **Metric-Trend**.
   - Turn source documents into a backlog / learning trail -> **Discovery-Stories**.
   - Drive or inform a management decision -> **Exec-Summary**.
2. **Who is the AUDIENCE?** Confirm the purpose answer against the reader. An engineer wanting to scrutinize numbers points to Analytical; an ops reader watching a number points to Metric-Trend; a product owner points to Discovery-Stories; a steering group points to Exec-Summary. If purpose and audience disagree (e.g. a deep analysis requested *for* management), the usual resolution is an Exec-Summary that *references* an Analytical report — two shapes, not one hybrid that serves neither.

If the situation is **genuinely ambiguous** — the purpose or the audience cannot be inferred from the request and the inputs — **ASK** which it is rather than defaulting to whichever template is most familiar. Defaulting silently is exactly the one-template-for-everything failure this lens exists to prevent.

## Audience Adaptation

The same facts are shaped differently for different readers. Adapt depth, jargon, and what is foregrounded:

- **Engineer / tech lead (Analytical):** maximum depth; domain and technical jargon is fine; foreground method and the data so the reader can trust and reproduce the finding. An appendix of raw detail is welcome, not noise.
- **Ops / business (Metric-Trend):** moderate depth; minimal jargon; foreground the number and its direction. The reader wants the movement at a glance and the caveat that stops them over-reading a blip.
- **Product owner / team (Discovery-Stories):** foreground actionable, well-formed stories with acceptance criteria and a clear order; tie everything back to the sources so the backlog is trustworthy; surface gaps as open questions rather than filling them with guesses.
- **Management / steering (Exec-Summary):** minimum depth; no unexplained jargon; foreground the conclusion and the trade-offs. Compress ruthlessly — a second page is usually a sign the wrong shape was chosen.

The failure to avoid in every direction is mismatch: analytical depth dumped on management, or a one-line summary handed to an engineer who needed the method.

## Anti-Patterns

- **One template for every situation** — *Diff:* a single report structure (usually whichever was built first) reused for an analysis, a trend, a backlog, and a summary alike. *Harm:* the structure fits at most one of them; the trend report has no trend, the backlog has no acceptance criteria, the management summary opens with method. Each reader has to dig past scaffolding that was meant for someone else, and most give up. *Fix:* classify by purpose and audience first, then pick the matching shape from the four types; there is no default.

- **The conclusion buried at the bottom of an exec summary** — *Diff:* a management summary that opens with context, scope, and method and reaches its recommendation only on the last screen. *Harm:* the one reader with the least time has to read the most to find the one thing they came for, and the decision the report exists to drive is the hardest part to locate. *Fix:* lead with the recommendation / TL;DR; put the supporting numbers, risks, and next steps after it.

- **Analytical depth dumped on management** — *Diff:* an Exec-Summary request answered with full method, raw tables, and an appendix because that material already existed in an Analytical report. *Harm:* the decision-maker cannot see the decision through the derivation, and the report fails its purpose despite containing more information. *Fix:* produce the Exec-Summary shape — conclusion, key numbers, trade-offs, next step — and *reference* the Analytical report for anyone who wants the depth.

- **A metric report with a number but no trend or caveat** — *Diff:* a Metric-Trend report that states the current value and stops, with no period-over-period delta, no time series, and no note on what could distort it. *Harm:* a number with no direction is unactionable, and a number with no caveat invites over-reading a blip as a trend or a data gap as a drop. *Fix:* always pair the headline number with its delta, a trend over time, and a notes/caveats line that bounds how far the reader should trust it.

- **Credentials, secrets, or PII written into the report** — *Diff:* a connection string, an API key, a token, or personal data pasted into the report because it was part of the input used to gather the data. *Harm:* the report becomes a leak — a deliverable that is shared, printed, and committed now carries a secret or personal data, and the blast radius is everyone who receives it. *Fix:* treat credentials and PII as **inputs only**. Describe *how* the data was obtained (the query, the source, the window) without ever reproducing the secret; a report shows results, not the keys used to get them. Never commit a report that contains them.

- **Charts that mislead** — *Diff:* a truncated or non-zero baseline that exaggerates a movement, an inconsistent axis between panels, a pie chart for parts that do not sum to a whole, or a 3-D effect that distorts proportion. *Harm:* the reader draws a conclusion the data does not support — a 2% change looks like a cliff, two panels look comparable when their axes differ — and acts on the distortion. *Fix:* use a baseline and axis honest to the data (zero baseline for magnitude comparisons unless the deviation itself is the subject, and say so), keep axes consistent across panels, and choose a chart type that matches the data's shape. A plain values table is better than a chart that misleads.

## Integration (report skill)

The consuming skill uses this lens as a classification aid, not a format to enforce:

- **Classify before generating.** The first action on any report request is to decide its type by purpose and audience using "How to Classify" above — not to reach for a default structure.
- **There is no house template.** The four shapes exist precisely so that no single one is the answer; applying one shape to every situation is the failure this lens names first.
- **Lead with what the audience needs, omit the rest.** Each type's "Lead with" and "What to OMIT" are the operative guidance once the type is chosen.
- **Ask when genuinely ambiguous.** If purpose or audience cannot be inferred, ask rather than default — a wrong shape produced confidently is worse than a clarifying question.
- **Credentials and PII are inputs only.** Never write a secret, token, connection string, or personal datum into the report output, and never commit a report that contains one. Describe the method, not the keys.
- This lens reasons about *shape, audience, and what to lead with*. It does not grade an existing artifact and carries no MUST/SHOULD severity rubric — that machinery belongs to the review lenses, not here.
