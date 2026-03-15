#!/usr/bin/env bash
# lint-report.sh — Validates a deep-researcher report against quality gates.
# Called automatically via PostToolUse hook on Write to output/*/report.md.
# Also runnable manually: ./scripts/lint-report.sh output/topic-slug/report.md
#
# Exit 0 = pass, exit 1 = issues found (prints warnings to stderr).

set -euo pipefail

FILE="${1:?Usage: lint-report.sh <path-to-report.md>}"

if [[ ! -f "$FILE" ]]; then
  echo "LINT ERROR: File not found: $FILE" >&2
  exit 1
fi

ERRORS=0
WARNINGS=0

# --- 1. File naming ---
BASENAME=$(basename "$FILE")
if [[ "$BASENAME" != "report.md" ]]; then
  echo "LINT ERROR: Report must be named 'report.md', got '$BASENAME'" >&2
  ((ERRORS++))
fi

# --- 2. YAML frontmatter ---
if ! head -1 "$FILE" | grep -q '^---$'; then
  echo "LINT ERROR: Missing YAML frontmatter (file must start with ---)" >&2
  ((ERRORS++))
else
  # Check required fields
  # Extract frontmatter (between first and second ---)
  FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$FILE")

  for FIELD in title depth sources date; do
    if ! echo "$FRONTMATTER" | grep -q "^${FIELD}:"; then
      echo "LINT ERROR: Missing frontmatter field: $FIELD" >&2
      ((ERRORS++))
    fi
  done

  # Check depth is valid
  DEPTH=$(echo "$FRONTMATTER" | grep '^depth:' | sed 's/depth: *//' | tr -d '"' | tr -d "'")
  if [[ -n "$DEPTH" ]] && [[ "$DEPTH" != "Deep" && "$DEPTH" != "Deeper" && "$DEPTH" != "Deepest" ]]; then
    echo "LINT ERROR: Invalid depth tier: '$DEPTH' (must be Deep, Deeper, or Deepest)" >&2
    ((ERRORS++))
  fi

  # Check source count meets tier minimum
  SOURCE_COUNT=$(echo "$FRONTMATTER" | grep '^sources:' | sed 's/sources: *//' | tr -d '"' | tr -d "'")
  if [[ -n "$DEPTH" && -n "$SOURCE_COUNT" ]]; then
    case "$DEPTH" in
      Deep)
        if (( SOURCE_COUNT < 10 )); then
          echo "LINT WARNING: Source count ($SOURCE_COUNT) below Deep tier minimum (10)" >&2
          ((WARNINGS++))
        fi
        ;;
      Deeper)
        if (( SOURCE_COUNT < 20 )); then
          echo "LINT WARNING: Source count ($SOURCE_COUNT) below Deeper tier minimum (20)" >&2
          ((WARNINGS++))
        fi
        ;;
      Deepest)
        if (( SOURCE_COUNT < 40 )); then
          echo "LINT WARNING: Source count ($SOURCE_COUNT) below Deepest tier minimum (40)" >&2
          ((WARNINGS++))
        fi
        ;;
    esac
  fi
fi

# --- 3. Source type annotations ---
# Check that at least some sources have type annotations (Evidence/Orientation/Heuristic)
TYPE_ANNOTATIONS=$(grep -oE '(Evidence|Orientation|Heuristic)' "$FILE" 2>/dev/null | wc -l | tr -d ' ')
if (( TYPE_ANNOTATIONS < 3 )); then
  echo "LINT WARNING: Few source type annotations found ($TYPE_ANNOTATIONS). Sources should be classified as Evidence/Orientation/Heuristic." >&2
  ((WARNINGS++))
fi

# --- 4. Inline citations ---
# Count URLs in markdown link format [text](url)
CITATION_COUNT=$(grep -oE '\[[^]]+\]\(https?://[^)]+\)' "$FILE" 2>/dev/null | wc -l | tr -d ' ')
if (( CITATION_COUNT < 5 )); then
  echo "LINT WARNING: Very few inline citations found ($CITATION_COUNT). Every factual claim needs a source." >&2
  ((WARNINGS++))
fi

# --- 5. Under-sourced flags ---
# Not an error if absent, but check the pattern is correct when present
if grep -q '\[Under-sourced\]' "$FILE" && ! grep -qE '>\s*\*\*\[Under-sourced\]\*\*' "$FILE"; then
  echo "LINT WARNING: Under-sourced flags found but not in correct format. Use: > **[Under-sourced]** claim text" >&2
  ((WARNINGS++))
fi

# --- 6. Export filename consistency ---
# If exports exist, verify they match the source filename
DIR=$(dirname "$FILE")
BASE=$(basename "$FILE" .md)
for EXT in pdf docx; do
  # Check if any export of this type exists in the directory
  EXPORT_COUNT=$(find "$DIR" -maxdepth 1 -name "*.${EXT}" 2>/dev/null | wc -l | tr -d ' ')
  if (( EXPORT_COUNT > 0 )); then
    # Exports exist — check they match the source filename
    if [[ ! -f "${DIR}/${BASE}.${EXT}" ]]; then
      ACTUAL=$(find "$DIR" -maxdepth 1 -name "*.${EXT}" -exec basename {} \;)
      echo "LINT ERROR: Export filename mismatch — expected '${BASE}.${EXT}' but found '${ACTUAL}'" >&2
      ((ERRORS++))
    fi
  fi
done

# --- 7. Sources section ---
if ! grep -qiE '^#+ *(Sources|Quellen|References|Source Index|Source Summary)' "$FILE"; then
  echo "LINT WARNING: No Sources/References section found at the end of the report." >&2
  ((WARNINGS++))
fi

# --- Summary ---
if (( ERRORS > 0 )); then
  echo "LINT FAILED: $ERRORS error(s), $WARNINGS warning(s)" >&2
  exit 1
elif (( WARNINGS > 0 )); then
  echo "LINT PASSED with $WARNINGS warning(s)" >&2
  exit 0
else
  echo "LINT PASSED: All checks passed." >&2
  exit 0
fi
