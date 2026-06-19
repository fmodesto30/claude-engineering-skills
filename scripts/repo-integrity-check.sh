#!/usr/bin/env bash
#
# scripts/repo-integrity-check.sh
#
# Deterministic STRUCTURAL-integrity gate for claude-engineering-skills — the
# drift the sanitization gate cannot see:
#   (A) index sync   — every skills/*/ and lenses/*.md is listed in CLAUDE.md
#                      AND README.md (a file the structure map forgets is
#                      invisible to a session's absorption).
#   (B) frontmatter  — every SKILL.md starts with YAML frontmatter carrying a
#                      name (== its directory) and a description (the description
#                      IS the entire auto-discovery trigger surface; a broken one
#                      silently never fires).
#   (C) links        — every relative Markdown link resolves (these are
#                      load-bearing twice: human navigation AND the learn-protocol
#                      packaging step copies referenced lenses by following them).
#   (D) release      — VERSION matches the top CHANGELOG.md entry (the whole
#                      "new patch" delta model depends on the two agreeing).
#
# Usage:
#   scripts/repo-integrity-check.sh            # check the repo (CI + pre-commit)
#   scripts/repo-integrity-check.sh --selftest # prove each detector fires
#
# Exit 0 = clean (or self-test passed), exit 1 = a violation (or failed self-test).
# Portable bash (3.2+); uses only git, grep, sed, awk, printf, mktemp, find, dirname.

set -u

MODE="check"
case "${1:-}" in
  --selftest) MODE="selftest" ;;
  "")         MODE="check" ;;
  *)          echo "usage: $0 [--selftest]" >&2; exit 2 ;;
esac

VIOLATIONS=""
COUNT=0
add_violation() {
  VIOLATIONS="${VIOLATIONS}${1}"$'\t'"${2}"$'\t'"${3}"$'\n'
  COUNT=$((COUNT + 1))
}

# List markdown files under a root (tracked-or-not; the repo is all-tracked md).
list_md() {
  find "$1" -name '*.md' -type f -not -path '*/.git/*' 2>/dev/null
}

# --- (A) index sync ---------------------------------------------------------
check_index_sync() {
  root="$1"
  claude="$root/CLAUDE.md"; readme="$root/README.md"
  [ -f "$claude" ] || { add_violation "index" "CLAUDE.md" "file missing"; return; }
  [ -f "$readme" ] || { add_violation "index" "README.md" "file missing"; return; }

  if [ -d "$root/skills" ]; then
    for d in "$root"/skills/*/; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      grep -q "skills/$name/SKILL.md" "$claude" || add_violation "index" "$name" "skill not referenced in CLAUDE.md structure map"
      grep -q "$name/" "$readme"               || add_violation "index" "$name" "skill not in README tree"
    done
  fi

  if [ -d "$root/lenses" ]; then
    for f in "$root"/lenses/*.md; do
      [ -f "$f" ] || continue
      name="$(basename "$f" .md)"
      if ! grep -q "\`$name\`" "$claude" && ! grep -q "lenses/$name.md" "$claude"; then
        add_violation "index" "$name" "lens not referenced in CLAUDE.md"
      fi
      grep -q "$name.md" "$readme" || add_violation "index" "$name" "lens not in README tree"
    done
  fi
}

# --- (B) SKILL.md frontmatter ----------------------------------------------
check_frontmatter() {
  root="$1"
  [ -d "$root/skills" ] || return
  for d in "$root"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    f="${d}SKILL.md"
    if [ ! -f "$f" ]; then add_violation "frontmatter" "$name" "missing SKILL.md"; continue; fi
    first="$(sed -n '1p' "$f")"
    if [ "$first" != "---" ]; then
      add_violation "frontmatter" "$name" "SKILL.md does not open with YAML frontmatter (---)"; continue
    fi
    # Frontmatter block: lines after line 1 up to the next '---'.
    fm="$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$f")"
    fmname="$(printf '%s\n' "$fm" | grep -E '^name:' | head -1 | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -z "$fmname" ]; then
      add_violation "frontmatter" "$name" "no 'name:' key in frontmatter"
    elif [ "$fmname" != "$name" ]; then
      add_violation "frontmatter" "$name" "frontmatter name '$fmname' != directory '$name'"
    fi
    printf '%s\n' "$fm" | grep -qE '^description:' || add_violation "frontmatter" "$name" "no 'description:' key in frontmatter"
  done
}

# --- (C) relative-link resolution ------------------------------------------
# Writes dangling hits to a scratch file (pipe subshells can append to a file;
# they cannot mutate VIOLATIONS), then folds them in from the current shell.
check_links() {
  root="$1"; scratch="$2"
  : > "$scratch"
  list_md "$root" | while IFS= read -r mf; do
    [ -f "$mf" ] || continue
    d="$(dirname "$mf")"
    grep -oE '\]\([^)]+\)' "$mf" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r t; do
      [ -n "$t" ] || continue
      case "$t" in http://*|https://*|mailto:*|\#*|/*) continue ;; esac
      p="${t%%#*}"
      [ -n "$p" ] || continue
      [ -e "$d/$p" ] || printf '%s\t%s\n' "$mf" "$t" >> "$scratch"
    done
  done
  while IFS="$(printf '\t')" read -r mf t; do
    [ -n "$mf" ] || continue
    add_violation "link" "$mf" "dangling relative link -> $t"
  done < "$scratch"
}

# --- (D) release consistency -----------------------------------------------
check_release() {
  root="$1"
  v="$(sed -n '1p' "$root/VERSION" 2>/dev/null | tr -d '[:space:]')"
  if [ -z "$v" ]; then add_violation "release" "VERSION" "missing or empty"; return; fi
  cv="$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$root/CHANGELOG.md" 2>/dev/null | head -1 | sed -E 's/^## \[//; s/\]$//')"
  if [ -z "$cv" ]; then add_violation "release" "CHANGELOG.md" "no '## [X.Y.Z]' version heading found"; return; fi
  if [ "$v" != "$cv" ]; then
    add_violation "release" "VERSION/CHANGELOG" "VERSION=$v but top CHANGELOG entry=$cv"
  fi
}

# --- self-test: prove each detector fires on a planted fixture --------------
run_selftest() {
  tmp="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/integ.$$")"
  mkdir -p "$tmp/skills/ghost-skill" "$tmp/lenses" "$tmp/docs"
  # CLAUDE/README that DON'T mention the planted skill/lens -> index drift.
  printf '# CLAUDE\nstructure map with nothing useful\n' > "$tmp/CLAUDE.md"
  printf '# README\ntree with nothing useful\n' > "$tmp/README.md"
  # SKILL.md with WRONG name and NO description -> frontmatter violations.
  printf -- '---\nname: not-ghost-skill\n---\n# body\n' > "$tmp/skills/ghost-skill/SKILL.md"
  printf 'x\n' > "$tmp/lenses/ghost-lens.md"
  # a dangling relative link -> link violation.
  printf '[broken](./nope.md)\n' > "$tmp/docs/page.md"
  # VERSION != top CHANGELOG -> release violation.
  printf '9.9.9\n' > "$tmp/VERSION"
  printf '# Changelog\n\n## [1.0.0] - 2026-01-01\n' > "$tmp/CHANGELOG.md"

  VIOLATIONS=""; COUNT=0
  check_index_sync "$tmp"
  check_frontmatter "$tmp"
  check_links "$tmp" "$tmp/.scratch"
  check_release "$tmp"
  rm -rf "$tmp" 2>/dev/null

  fails=0
  for rule in index frontmatter link release; do
    if ! printf '%s' "$VIOLATIONS" | grep -q "^${rule}$(printf '\t')"; then
      echo "  selftest FAIL: '${rule}' detector did not fire"; fails=1
    fi
  done

  VIOLATIONS=""; COUNT=0
  if [ "$fails" -ne 0 ]; then
    echo "repo-integrity-check: SELFTEST FAILED — a detector is broken; the gate cannot be trusted."
    exit 1
  fi
  echo "repo-integrity-check: SELFTEST PASS — all detectors fire on planted samples."
  exit 0
}

[ "$MODE" = "selftest" ] && run_selftest

# --- run against the repo ---------------------------------------------------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
SCRATCH="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/integ.links.$$")"

check_index_sync "$ROOT"
check_frontmatter "$ROOT"
check_links "$ROOT" "$SCRATCH"
check_release "$ROOT"
rm -f "$SCRATCH" 2>/dev/null

if [ "$COUNT" -eq 0 ]; then
  echo "repo-integrity-check: PASS — indexes, frontmatter, links, and release marker are consistent."
  exit 0
fi

echo "repo-integrity-check: FAIL — $COUNT integrity violation(s)."
echo
for group in "index:Index out of sync (skills/lenses vs CLAUDE.md & README.md)" \
             "frontmatter:SKILL.md frontmatter (the auto-discovery trigger surface)" \
             "link:Dangling relative links" \
             "release:VERSION / CHANGELOG release marker"; do
  key="${group%%:*}"; title="${group#*:}"
  body="$(printf '%s' "$VIOLATIONS" | grep -E "^${key}$(printf '\t')" || true)"
  if [ -n "$body" ]; then
    echo "[$title]"
    printf '%s\n' "$body" | while IFS="$(printf '\t')" read -r r ff d; do
      [ -n "$ff" ] || continue
      echo "  - $ff :: $d"
    done
    echo
  fi
done
echo "Every addition must move the indexes with it (CLAUDE.md structure map + README tree +"
echo "CHANGELOG + VERSION + consuming-skill wiring). See the skill-author skill."
exit 1
