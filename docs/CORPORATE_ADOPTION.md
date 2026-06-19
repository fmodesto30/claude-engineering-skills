# Corporate Adoption — Claude Engineering Skills

## What this file is

A ready-to-use **prompt** for a Claude Code instance running **inside a corporate environment**.
Point that instance at this public repository *plus* this file; it reads this sanitized
reference model and proposes/creates an **internal** corporate version of the skills repo —
without ever copying internal secrets, data, or documentation back into this public repo.

This file contains **no corporate content**. It is a generic process and guardrail document.

## How to use it

1. In your corporate Claude Code, provide this repository URL as a **read-only** reference:
   `https://github.com/fmodesto30/claude-engineering-skills`
2. Give Claude the prompt in the **"Corporate Adoption Prompt"** section below.
3. Claude must respond with a **plan first** (no files). You review and approve.
4. Only then does Claude implement, **in the internal repo**, behind the corporate
   sanitization gate (checkpoint + explicit approval before each commit).

## Current public reference (snapshot — verify against the live repo)

- **Architecture:** Skill = workflow/type of work (`skills/`) · Lens = reusable engineering
  knowledge (`lenses/`) · Rule = global rule/policy (`rules/`, e.g. the severity rubric) ·
  Reference = skill-local material (`skills/<name>/references/`) · Template = output format ·
  Hook = deterministic enforcement (CI + `scripts/sanitization-check.sh` & `scripts/repo-integrity-check.sh`).
- **Two skill tracks, one shared lens set:** **review** skills consume the lenses *evaluatively* —
  `java-pr-review` (diff/PR) and `architecture-review` (system/design), both using
  `rules/severity-rubric.md`; the **construction** skill consumes the *same* lenses *generatively* —
  `spec-author` (`skills/spec-author/SKILL.md`) produces a prescriptive spec via `templates/spec.md`,
  graded by `rules/spec-rubric.md`.
- **Lenses (17, growing):** `design-patterns`, `clean-code`, `testing`, `solid`, `spring-production-readiness`,
  `ddd`, `saga`, `cqrs`, `cdc`, `event-driven`, `security`, `observability`, `data-engineering`,
  `data-analysis`, `reporting`, `agent-skills`, `model-and-effort-economy`.
- **Branching:** **main-only** (`main` + short-lived `feat/*`; no `develop`); checkpoint + explicit
  approval before every commit and push.

Treat the list above as illustrative; read the repo for the authoritative current set.

---

## Corporate Adoption Prompt

> You are running inside a corporate Claude Code environment. Your task is to read the public
> reference repository as a **sanitized reference model** and create an **internal** corporate
> version adapted to our company environment.
>
> Public reference repository: `https://github.com/fmodesto30/claude-engineering-skills`
>
> **Important:** the public repository is only a generic, sanitized, non-corporate base. Do not
> modify it with internal information. Do not push internal content back to it.

### Objective

Create or propose an internal corporate repository of Claude Code skills, lenses, rules,
templates, and playbooks based on the **structure and philosophy** of the public reference —
not its specific text. The internal version should be able to support, over time:

- Java/Spring PR review · architecture review · production readiness · testing review ·
  observability review · security review · internal platform discovery · internal
  pipeline/repository onboarding · corporate documentation discovery · safe handoff & report
  generation.

### Core architecture (preserve the conceptual model)

- **Skill** = workflow / type of work.
- **Lens** = reusable engineering knowledge.
- **Template** = output format.
- **Rule** = global rule or policy.
- **Hook** = deterministic enforcement.
- **Reference** = skill-specific supporting material.

Do **not** create one giant skill for everything. Do **not** create one skill per book, pattern,
or concept. Create skills **by type of work** (e.g. `java-pr-review`, `architecture-review`,
`app-bootstrap`, `infra-discovery`, `enterprise-discovery`, `report-core`). Lenses are by subject
(e.g. `clean-code`, `design-patterns`, `testing`, `solid`, `ddd`, `hexagonal-architecture`,
`event-driven`, `observability`, `security`, `spring-production-readiness`). A lens lives in
`lenses/` only when it has real potential to be used by more than one skill.

### Corporate safety rules

**Never commit to any repository:** secrets, tokens, credentials, certificates, private keys,
session tokens, cookies, customer data, real logs, real payloads, production data, internal
endpoints, sensitive account IDs, real service names if not approved, confidential business
rules, copied internal documentation, or code copied from corporate projects.

**Using internal documentation:** use it as **temporary context only**. Internal skills may
reference internal docs **by title/path/link** if allowed, but must not copy large sections. If a
rule is derived from an internal doc, **summarize it in original words and cite the internal
source path**. No PDFs/books/raw notes/temporary discovery outputs in the repo.

### Step 1 — Audit (read-only, no files)

Inspect the public reference: its skills, lenses, rules, and README philosophy. Output:
**Public Repository Summary · Reusable Concepts · What Must Be Adapted · What Must Not Be Copied
· Corporate Risks · Recommended Internal Structure · Implementation Plan.** Do not create files.

### Step 2 — Corporate discovery

Search internal documentation and reference repositories for: coding standards; Java/Spring
standards; testing standards; PR-review expectations; security standards; observability /
logging / tracing standards; pipeline standards; repository templates; application
acronym/app-code/sigla requirements; deployment standards; cloud/platform onboarding; incident
and operational standards.

For **every important finding**, record: the internal source **path/link**; a **summary in your
own words**; the **impact** on the internal skills repo; and whether it is **mandatory /
recommended / optional / unclear.** If access is missing, mark it a **blocker**.

### Step 3 — Proposed internal repository (start small)

Do not scaffold dozens of empty files. Recommended MVP:

```
internal-claude-engineering-skills/
  README.md
  .gitignore
  rules/
    severity-rubric.md
  skills/
    java-pr-review/
      SKILL.md
    architecture-review/
      SKILL.md
  lenses/
    clean-code.md
    design-patterns.md
    ddd.md
    testing.md
    spring-production-readiness.md
  docs/
    CORPORATE_USAGE.md
    SANITIZATION_POLICY.md
```

Add more skills only when there is a real workflow.

### Step 4 — Corporate adaptation

Adapt the model to internal standards. For `java-pr-review`, calibrate: severity levels; PR
comment style; what **blocks** a PR; what is only a suggestion; what belongs to
linters/formatters and **which internal tools own** formatting/static analysis; what must be
reviewed by humans; what Claude can safely suggest.

Do **not** make Claude dogmatic. Every finding must explain a **concrete consequence**.
Style-only issues are delegated to linters unless the internal standard says otherwise.

### Step 5 — Validation (before any commit)

Run a safety checklist: no secrets · no credentials · no internal logs · no internal payloads ·
no copied corporate docs · no customer data · no copied source code · no temporary-analysis
outputs · no PDFs/books · no raw notes · examples synthetic or approved · internal references
cited by path/link, not copied wholesale.

Show: **file tree · diff stat · changed files · sanitization checklist · proposed commit
message.** Wait for **explicit approval** before committing.

### Expected output (first response = a plan, not implementation)

**Executive Summary · Public Repo Concepts to Reuse · Corporate Discovery Needed · Risks and
Guardrails · Proposed Internal Repository Structure · MVP Scope · Files to Create · Validation
Plan · Questions Before Implementation.** Do not implement until approved.
