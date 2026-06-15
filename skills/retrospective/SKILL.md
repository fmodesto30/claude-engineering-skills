---
name: retrospective
description: >-
  Turns a lesson — especially a mistake that recurred — into a durable change so it does not happen
  again: capture the gotcha, classify it by how reliably it must be prevented, and persist it to the
  right home (a hook for mechanically-preventable repeats, CLAUDE.md / .claude/rules for standing
  judgment, memory for cross-session facts), then verify it will actually fire next time. Use after a
  non-trivial task, after hitting the same error twice, at a handoff, or when asked to "save this
  lesson", "don't repeat this", "configure so this can't happen again", or "what did we learn".
  Proposes the changes as a checkpoint and writes config only on approval. Prefers prevention (a hook)
  over a note no one reads. Not for reviewing code (java-pr-review / architecture-review) and not for
  auditing an existing setup (claude-setup-audit).
---

# retrospective

A meta/ops workflow that closes the loop between *learning* something and *not repeating it*. Its
subject is not code — it is the agent's own working memory and configuration. It takes a lesson
(most valuably, a mistake that has now happened more than once), decides the most reliable place to
persist it, writes it there on approval, and confirms the change will actually take effect next time.
It is the sibling of [`../claude-setup-audit/SKILL.md`](../claude-setup-audit/SKILL.md): that skill
asks *is the setup correct?*; this one asks *what did we just learn, and where must it live so it
sticks?*

## Core stance

- **A lesson you don't persist is one you'll relearn.** The goal is to stop the *repeat*, not to keep
  a journal. The only reason to capture a lesson is that repeating it has a concrete cost.
- **Prevent over document.** There is a durability ladder, strongest first: a **hook** that makes the
  mistake mechanically impossible → a **rule / CLAUDE.md** the agent reads every session → a
  **memory** note → nothing. Climb as high as the mistake allows; a note that relies on someone
  remembering to read it is the weakest rung.
- **Specific or useless.** "Be careful with git" prevents nothing. "Before a remote decision, fetch
  then compare HEADs, because acting on a stale ref reverted the work last time" prevents the repeat.
  Every lesson names a **trigger**, an **action**, and a **reason**.
- **Consequence-driven capture.** Apply the overriding rule from
  [`../../rules/severity-rubric.md`](../../rules/severity-rubric.md): a lesson whose repeat has no
  nameable cost is not worth persisting — it is the `NO_COMMENT` of retrospectives. Skip the trivial.
- **Config is load-bearing — checkpoint, never silently.** Writing a hook, CLAUDE.md, a rule, or
  global memory changes how every future session behaves. Propose the exact change and write it only
  on approval, exactly as `claude-setup-audit` does.

## When to run

- After a **non-trivial task**, to bank what was learned before the context is lost.
- After hitting the **same error twice** — the strongest trigger. A repeat is proof the lesson has a
  real cost and that nothing durable is yet preventing it.
- At a **handoff or session end**, to separate the one-off (goes in the handoff) from the recurring
  (goes in durable config).
- When the user asks to **"save this lesson", "don't repeat this", "configure so this can't happen
  again", or "what did we learn"**.

Do **not** run it to log routine, expected outcomes, or to document a one-off that will never recur.

## How to run a retrospective

1. **Surface the lesson(s).** From the task just finished (or the error that recurred), state for
   each: *what happened*, *why*, and *the fix or avoidance*. Be concrete and drop the trivial — a few
   real lessons, not a transcript.

2. **Classify each by its durable home.** Pick the highest rung of the ladder the lesson allows:

   | If the lesson is… | Home | Why this home |
   |---|---|---|
   | mechanically detectable and must **never** recur (a secret committed, the wrong branch, a skipped gate, an unformatted file) | a **hook** — `.claude/settings.json` (`PreToolUse`/pre-commit) or a repo pre-commit hook | deterministic *prevention*; it does not depend on the agent remembering. Consult [`../../lenses/agent-skills.md`](../../lenses/agent-skills.md) for placement. |
   | a **standing judgment** about how to work in this repo/area (do X, never Y) | **CLAUDE.md** (short, strategic) or **`.claude/rules/<area>.md`** (path-scoped) | read into context every session; the agent obeys it without being told again |
   | a **cross-session fact or preference**, or context not derivable from the code | **memory** (if the CLI supports it) | persists across sessions and projects; survives outside any one repo |
   | relevant only to the **current** continuation | the **handoff**, not durable config | it is a one-off, not a recurring lesson — durable config would just accumulate noise |

3. **Write it enforceably.** Phrase each lesson as **trigger** ("when X") + **action** ("do / don't
   Y") + **reason** ("because Z"). Keep CLAUDE.md short and push detail down to a rule; a global rule
   buried in prose is as good as unwritten.

4. **Checkpoint and persist on approval.** Show the exact file and the exact change (the hook, the
   rule line, the CLAUDE.md edit, the memory entry). Write only what the user approves; never edit
   global config or user-scope memory silently.

5. **Verify it will fire next time.** A lesson written where the next session won't load it is
   theater. Confirm it:
   - **hook** → trigger it on a planted sample so you see it block (the repo's own
     `scripts/sanitization-check.sh --selftest` is the model: prove the detector fires);
   - **rule / CLAUDE.md** → confirm the file is in the precedence chain the next session loads
     (managed > user > project > local);
   - **memory** → confirm the index points to the new entry.
   Hand the config change to [`../claude-setup-audit/SKILL.md`](../claude-setup-audit/SKILL.md) if you
   want it judged against current best practice.

6. **(Optional) graduate a reusable lesson.** If a lesson is a general engineering pattern rather than
   project-specific, it can become a sanitized **field-note** and, when the pattern recurs, a
   **lens** — the capture → distill → promote path this repo already uses for its field notes.

## Output format

```
Lesson — <what recurred or was learned>
  Trigger:  when <X>
  Action:   <do / don't Y>
  Reason:   <Z — the concrete cost of repeating>
  Home:     <hook | CLAUDE.md | .claude/rules/<area> | memory | handoff>
  Verified: <how you confirmed it will take effect next time>
```

Close with a one-line summary of what was persisted (after approval) and what was intentionally left
as a one-off.

## Restraint rules

- **Don't journal the trivial.** Capture only a lesson whose repeat has a named cost; a wall of vague
  lessons is ignored exactly like a flood of nits in a review, and buries the one that mattered.
- **A lesson you can't make specific and enforceable is `NO_COMMENT`** — drop it rather than write a
  note that prevents nothing.
- **Climb the ladder.** Prefer a hook that makes the mistake impossible over a rule, and a rule over a
  note no one rereads. Match the mechanism to how reliably the mistake must not recur.
- **Never write global config or user-scope memory silently** — checkpoint first, write on approval.
- **Keep CLAUDE.md short and strategic.** Path-specific rules belong in `.claude/rules/`; do not bloat
  the always-loaded context with detail a scoped rule should hold.
- **Stay in your lane.** Reviewing code is `java-pr-review` / `architecture-review`; auditing whether
  the setup is correct is `claude-setup-audit`. This skill turns a lesson into the durable change that
  keeps the mistake from coming back.
