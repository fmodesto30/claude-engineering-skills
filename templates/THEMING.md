# Theming the report templates

A **theme** is the *visual skin* of a report — palette, light/dark, fonts, an optional logo. It is
the **one cosmetic choice that is legitimately the user's (or the organisation's)**. Everything else
about a report — its **shape** (analytical / metric-trend / discovery-stories / exec-summary) and its
**chart types** (trend → line, composition → bars, distribution → histogram) — is decided **by the
data and the audience**, upstream in [`../lenses/data-analysis.md`](../lenses/data-analysis.md) and
[`../lenses/reporting.md`](../lenses/reporting.md), and is **not** part of the theme. Re-skinning a
report must never change which chart or which structure carries the finding.

## The theme-variable surface

Every report template exposes its colours as CSS custom properties in `:root`. To re-theme, override
these — in the template's `:root`, or via a `[data-theme="…"]` attribute, or by linking one of the
preset files in [`themes/`](themes/). The **shared core** every template uses:

| Variable | Role |
|---|---|
| `--ink` | primary text |
| `--muted` | secondary text / labels |
| `--line` | borders / gridlines |
| `--accent` | section accent (headings, rules) |
| `--soft` | soft surface (meta blocks, provenance) |

Recommended additions a theme should also set (the presets in `themes/` define them, and a themed
report should use them so the skin is complete and the charts re-skin too):

| Variable | Role |
|---|---|
| `--bg` | page / report background |
| `--brand` | brand/primary chart colour (the line, the lead bar) |
| `--brand-text` | brand colour legible as a label on `--bg` |
| `--up` / `--down` | positive / negative deltas |
| `--bar` | secondary bar / series colour |
| `--logo-bg` / `--logo-text` | optional logo mark (see below) |

## Charts must follow the theme

Inline-SVG charts are part of the skin, so their colours must come from the same variables — otherwise
a re-theme leaves the chart in the old palette. **Note:** the SVG `fill`/`stroke` *presentation
attributes do not accept `var()`. Use a `style` attribute or a CSS class instead:

```html
<polyline class="line" .../>            <!-- .line { stroke: var(--brand); } -->
<rect style="fill:var(--brand)" .../>   <!-- inline form -->
```

The example colours in the stock templates are literal hex (a fill-in starting point). When a report
is themed, render the chart colours from the variables, as the presets and the reference report do.

## Optional logo slot

A theme may carry a logo. Keep it **subordinate to the data**: a small mark in the header or footer,
never a cover page that delays the answer, never larger than the headline finding. Use `--logo-bg` /
`--logo-text` (or an `<img>`) so the mark is part of the theme, not hard-coded into the shape.

## Choosing a theme — a shared decision

The theme is a **preset selected at the render step**, not baked into the analysis. Several presets can
coexist (a dense dark dashboard, a clean light report, a minimal executive skin). The shaping skill
**suggests** a theme by the AnalysisSpec's audience / purpose and the **user confirms or changes it**:

| Purpose / audience | Suggested skin |
|---|---|
| ops · dashboard · dense analysis | a dark, information-dense theme |
| technical report for the team | a clean light theme |
| leadership · email · a decision | a minimal, high-whitespace theme |

The theme is the only thing offered as a menu. **The chart type and the report shape are never a
"pick what looks nice" menu** — choosing a chart that does not match the data (a pie for a trend) is
the dominant anti-pattern the dataviz discipline exists to prevent.

## Adding a theme

1. Copy a preset from [`themes/`](themes/), rename it, and override the variables.
2. Keep contrast accessible (text legible on `--bg` in the mode you target) and the brand colour from
   distorting a chart — a themed chart still obeys the honest-encoding rules (zero baseline for
   magnitude bars, consistent axes, a chart type that matches the data).
3. Keep the skin subordinate to the data: the conclusion still leads, the provenance still shows.

## Sanitization

The presets in `themes/` are **neutral** — no real organisation's brand, palette, or logo. A real
brand theme (a company's colours and mark) belongs in the **consuming environment**, never committed
here. This repo ships the *capability* to theme and neutral examples; it never carries a specific brand.
