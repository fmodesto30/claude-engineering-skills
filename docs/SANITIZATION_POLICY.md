# Sanitization Policy

This repository contains **only original, sanitized, domain-neutral, reusable** content. This
document states the rules that keep it that way — and the rules a corporate fork must add on top.

## What this repo must contain

- Original engineering knowledge written from general, common know-how.
- Synthetic, domain-neutral examples — `Order`, `Payment`, `Notification`, `Report`, `Customer`,
  `Invoice`, `PricingRule`, `Shipment`, `AuditEntry`, and similar — unrelated to any real system.
- Heuristics, checklists, and review lenses in our own words.

## Never commit

- Secrets, tokens, credentials, certificates, private keys, session tokens, cookies.
- Customer data, production data, real logs, real payloads.
- Internal endpoints, sensitive account IDs, unapproved real service names.
- Confidential business rules; copied internal documentation; code copied from corporate projects.
- PDFs, EPUBs, books, or other copyrighted material; raw study notes; temporary analysis/discovery
  outputs.

The `.gitignore` blocks the common offenders (PDFs/EPUBs, key/cert files, `.env`, raw notes,
logs/payloads), but `.gitignore` is a backstop, **not** the control — the pre-commit checklist is.

## Clean-room authoring (turning study material into original content)

When study material (a book, an article, an internal doc) informs a lens or rule:

1. Read it as **temporary context only**. The source never enters the repo.
2. Distill the **idea** in your **own words** — heuristics, review questions, anti-patterns.
   Methods and ideas are free; specific expression is not. Stay on the ideas side.
3. Do **not** reproduce sentences, examples, code listings, tables, didactic structure, or the
   source's class/method/domain names.
4. Write **synthetic, neutral** examples. If a point can only be made with a source-specific
   example, generalize it until neutral, or drop it.
5. Optionally keep a private **collision denylist** of the source's distinctive surface and check
   the output does not resemble it.

## Internal / corporate forks — additional rules

- Internal documentation is **temporary context**. Reference it by **title/path/link** if allowed;
  **summarize in original words, never copy** large sections. If a rule derives from an internal
  doc, cite the internal source path alongside the summary.
- Never commit anything from the "Never commit" list above, including internal code and confidential
  rules.
- Examples must be **synthetic or explicitly approved** — never real corporate data or identifiers.

## Pre-commit checklist & gate

Before any commit:

- [ ] No PDFs/books/EPUBs; no raw notes; no temporary discovery outputs.
- [ ] No secrets, tokens, credentials, certificates, keys.
- [ ] No customer/production data, real logs, or real payloads.
- [ ] No copied corporate docs or source code; no confidential business rules.
- [ ] Internal references cited by path/link, not copied wholesale.
- [ ] All examples synthetic and neutral (or approved).
- [ ] Encoding is clean (UTF-8, no mojibake).

Run the deterministic scan — [`scripts/sanitization-check.sh`](../scripts/sanitization-check.sh)
(forbidden file types/dirs, secret content patterns, and encoding/mojibake) — then present a
**checkpoint** — file tree, `git diff --stat`, changed files, sanitization checklist, proposed
commit message — and **wait for explicit approval** before committing. Work on a feature branch;
never commit straight to `main`.

The scan is enforced two ways, so it is the control and not merely a checklist:

- **Locally**, as a pre-commit hook. Create an executable `.git/hooks/pre-commit` containing
  `exec bash scripts/sanitization-check.sh --staged` (on Windows, run via git-bash). It scans only
  staged files and blocks the commit on any violation.
- **In CI**, via [`.github/workflows/sanitization.yml`](../.github/workflows/sanitization.yml),
  which runs the script — plus a detector self-test and a redundant gitleaks pass — on every PR
  and on pushes to `main`/`develop`/`feat/**`.

To suppress a verified false-positive secret match, append `# sanitization-allow` to the line.
