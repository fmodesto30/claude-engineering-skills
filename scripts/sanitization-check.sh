#!/usr/bin/env bash
#
# scripts/sanitization-check.sh
#
# Deterministic sanitization gate for claude-engineering-skills.
# Mechanizes docs/SANITIZATION_POLICY.md (backed by .gitignore): it is the
# control, not the .gitignore. Checks for forbidden file types/dirs, secret
# content patterns, and encoding hygiene across tracked (or staged) files.
#
# Usage:
#   scripts/sanitization-check.sh            # scan all tracked files (CI default)
#   scripts/sanitization-check.sh --staged   # scan staged files (pre-commit hook)
#   scripts/sanitization-check.sh --selftest # prove the detectors actually fire
#
# Exit 0 = clean (or self-test passed), exit 1 = a violation (or failed self-test).
# Portable bash (bash 3.2+; avoids bash-4 features like ${var,,}).
# Uses only widely-available tools: git, grep, file, od, printf, mktemp.

set -u

MODE="tracked"
case "${1:-}" in
  --staged)   MODE="staged" ;;
  --selftest) MODE="selftest" ;;
  "")         MODE="tracked" ;;
  *)          echo "usage: $0 [--staged|--selftest]" >&2; exit 2 ;;
esac

# Violation accumulator. Each entry: "RULE\tfile\tdetail".
VIOLATIONS=""
COUNT=0

add_violation() {
  # $1 rule, $2 file, $3 detail
  VIOLATIONS="${VIOLATIONS}${1}"$'\t'"${2}"$'\t'"${3}"$'\n'
  COUNT=$((COUNT + 1))
}

# Lowercase helper (portable; avoids ${var,,} which needs bash 4).
to_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# ---------------------------------------------------------------------------
# Rule (1): forbidden file types.
# ---------------------------------------------------------------------------
BOOK_EXTS="pdf epub mobi azw azw3 djvu cbz cbr fb2"          # book/copyright formats
CRED_EXTS="pem key p12 pfx jks keystore crt cer der token"   # credential/cert files

check_file_type() {
  f="$1"
  base="$(basename -- "$f")"
  lf="$(to_lower "$f")"
  lbase="$(to_lower "$base")"

  for ext in $BOOK_EXTS; do
    case "$lf" in
      *.$ext) add_violation "forbidden-filetype" "$f" "book/copyright format .$ext"; return ;;
    esac
  done
  for ext in $CRED_EXTS; do
    case "$lf" in
      *.$ext) add_violation "forbidden-filetype" "$f" "credential/cert file .$ext"; return ;;
    esac
  done

  # Private-key material by name prefix.
  case "$lbase" in
    id_rsa*|id_ed25519*)
      add_violation "forbidden-filetype" "$f" "private key file ($lbase)"; return ;;
  esac

  # .env and .env.* except .env.example.
  case "$lbase" in
    .env.example) ;;
    .env|.env.*)
      add_violation "forbidden-filetype" "$f" "environment file (only .env.example allowed)"; return ;;
  esac
}

# ---------------------------------------------------------------------------
# Rule (2): forbidden directories with tracked content.
# ---------------------------------------------------------------------------
FORBIDDEN_DIRS="notes _work _synthesis scratch logs real-payloads captured"

check_forbidden_dir() {
  f="$1"
  for d in $FORBIDDEN_DIRS; do
    case "/$f/" in
      */"$d"/*)
        add_violation "forbidden-dir" "$f" "tracked content under $d/"; return ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Helpers for content checks.
# ---------------------------------------------------------------------------
is_binary() {
  # Returns 0 (true) if the file looks binary.
  f="$1"
  [ -s "$f" ] || return 1   # empty file is not binary
  if command -v file >/dev/null 2>&1; then
    case "$(file --mime "$f" 2>/dev/null)" in
      *charset=binary*) return 0 ;;
      *) return 1 ;;
    esac
  fi
  # Fallback: -I makes grep report binary; if it finds text, not binary.
  if LC_ALL=C grep -qI . "$f" 2>/dev/null; then return 1; fi
  return 0
}

# ---------------------------------------------------------------------------
# Rule (3): secret CONTENT patterns. An inline "# sanitization-allow" comment
# on the matched line suppresses it.
# ---------------------------------------------------------------------------
RE_PRIVKEY='-----BEGIN ([A-Z0-9]+ )?PRIVATE KEY-----'   # private-key header
RE_AWS='AKIA[A-Z0-9]{16}'                               # AWS access key id
QUOTES="\"'"                                            # the two quote chars: " and '
# identifier containing a secret word, then = or :, then a long (>=16) quoted literal
RE_TOKEN="(secret|token|passwd|password|apikey|api_key)[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*[$QUOTES][^$QUOTES]{16,}[$QUOTES]"  # sanitization-allow

scan_secret_pattern() {
  # $1 file, $2 regex, $3 label. Always pass the pattern via -e so a leading
  # '-' (e.g. the private-key header) is not parsed as an option, and -- so a
  # filename starting with '-' is safe.
  f="$1"; re="$2"; label="$3"
  matches="$(LC_ALL=C grep -nEi -e "$re" -- "$f" 2>/dev/null)" || return 0
  [ -n "$matches" ] || return 0
  # Iterate in the current shell (here-doc, not a pipe) so add_violation sticks.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      *"# sanitization-allow"*) continue ;;
    esac
    lineno="${line%%:*}"
    add_violation "SECRET" "$f" "${label} (line ${lineno})"
  done <<EOT
$matches
EOT
}

# ---------------------------------------------------------------------------
# Rule (4): encoding hygiene.
#   - reject UTF-8 BOM (EF BB BF) at file start.
#   - reject UTF-8 encoding of U+FFFD replacement char (EF BF BD) = mojibake.
# ---------------------------------------------------------------------------
has_utf8_bom() {
  f="$1"
  first3="$(od -An -N3 -tx1 "$f" 2>/dev/null | tr -d ' \n')"
  [ "$first3" = "efbbbf" ]
}

has_replacement_char() {
  f="$1"
  if printf 'x' | LC_ALL=C grep -qP 'x' 2>/dev/null; then
    LC_ALL=C grep -qaP '\xEF\xBF\xBD' "$f" 2>/dev/null
    return $?
  fi
  od -An -tx1 "$f" 2>/dev/null | tr -d ' \n' | grep -q 'efbfbd'
}

# ---------------------------------------------------------------------------
# Self-test: prove every detector fires on a planted sample. Guards against a
# regression that silently turns the gate into a no-op.
# ---------------------------------------------------------------------------
run_selftest() {
  tmp="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/sanit.$$")"
  mkdir -p "$tmp"
  fails=0
  check() { # $1 description, $2 = 0 if detector fired
    if [ "$2" -ne 0 ]; then echo "  selftest FAIL: $1 detector did not fire"; fails=1; fi
  }

  printf 'x = AKIAABCDEFGHIJKLMNOP\n' > "$tmp/aws.txt"  # sanitization-allow
  [ -n "$(LC_ALL=C grep -nEi -e "$RE_AWS" -- "$tmp/aws.txt")" ]; check "AWS key" $?

  printf -- '-----BEGIN RSA PRIVATE KEY-----\n' > "$tmp/key.txt"  # sanitization-allow
  [ -n "$(LC_ALL=C grep -nEi -e "$RE_PRIVKEY" -- "$tmp/key.txt")" ]; check "private key" $?

  printf 'password = "abcdefghijklmnop1234"\n' > "$tmp/tok.txt"  # sanitization-allow
  [ -n "$(LC_ALL=C grep -nEi -e "$RE_TOKEN" -- "$tmp/tok.txt")" ]; check "token assignment" $?

  printf '\xEF\xBB\xBFhello\n' > "$tmp/bom.txt"
  has_utf8_bom "$tmp/bom.txt"; check "UTF-8 BOM" $?

  printf 'a\xEF\xBF\xBDb\n' > "$tmp/moji.txt"
  has_replacement_char "$tmp/moji.txt"; check "mojibake (U+FFFD)" $?

  rm -rf "$tmp" 2>/dev/null
  if [ "$fails" -ne 0 ]; then
    echo "sanitization-check: SELFTEST FAILED — a detector is broken; the gate cannot be trusted."
    exit 1
  fi
  echo "sanitization-check: SELFTEST PASS — all detectors fire on planted samples."
  exit 0
}

[ "$MODE" = "selftest" ] && run_selftest

# ---------------------------------------------------------------------------
# File list: stream NUL-separated paths straight from git into the loop via
# process substitution. NEVER round-trip NUL data through "$(...)" — command
# substitution strips NUL bytes and the loop would silently scan nothing.
# ---------------------------------------------------------------------------
git_files() {
  if [ "$MODE" = "staged" ]; then
    git diff --cached --name-only --diff-filter=ACM -z
  else
    git ls-files -z
  fi
}

any=0
while IFS= read -r -d '' f; do
  any=1
  [ -n "$f" ] || continue

  check_file_type "$f"
  check_forbidden_dir "$f"

  if [ -f "$f" ] && ! is_binary "$f"; then
    scan_secret_pattern "$f" "$RE_PRIVKEY" "private key header"
    scan_secret_pattern "$f" "$RE_AWS" "AWS access key id"
    scan_secret_pattern "$f" "$RE_TOKEN" "token assignment with long literal"
    if has_utf8_bom "$f"; then
      add_violation "encoding" "$f" "UTF-8 BOM at file start"
    fi
    if has_replacement_char "$f"; then
      add_violation "encoding" "$f" "U+FFFD replacement char (mojibake)"
    fi
  fi
done < <(git_files)

# ---------------------------------------------------------------------------
# Report.
# ---------------------------------------------------------------------------
SCANNED_DESC="tracked files"
[ "$MODE" = "staged" ] && SCANNED_DESC="staged files"

if [ "$any" -eq 0 ]; then
  echo "sanitization-check: no files to scan (clean)."
  exit 0
fi

if [ "$COUNT" -eq 0 ]; then
  echo "sanitization-check: PASS — no violations across $SCANNED_DESC."
  exit 0
fi

echo "sanitization-check: FAIL — $COUNT violation(s) across $SCANNED_DESC."
echo

for group in "forbidden-filetype:Forbidden file types" \
             "forbidden-dir:Forbidden directories with tracked content" \
             "SECRET:Secret content patterns" \
             "encoding:Encoding hygiene"; do
  key="${group%%:*}"
  title="${group#*:}"
  body="$(printf '%s' "$VIOLATIONS" | grep -E "^${key}"$'\t' || true)"
  if [ -n "$body" ]; then
    echo "[$title]"
    printf '%s\n' "$body" | while IFS=$'\t' read -r r ff d; do
      [ -n "$ff" ] || continue
      echo "  - $ff :: $d"
    done
    echo
  fi
done

echo "See docs/SANITIZATION_POLICY.md. To suppress a false-positive secret match,"
echo "append '# sanitization-allow' to the offending line."
exit 1
