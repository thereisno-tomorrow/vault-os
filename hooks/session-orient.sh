#!/bin/bash
# session-orient.sh — Vault OS v4.2
# vault-os-hook-version: 4.2.0
# Fires at SessionStart. Output is bounded; compact may re-inject it safely.

set -u

HOOK_BASE_VERSION="4.2.0"
ORIENTATION_BUDGET_BYTES="${VAULT_OS_ORIENTATION_BUDGET_BYTES:-15000}"
NON_DECISION_BUDGET_BYTES="${VAULT_OS_NON_DECISION_BUDGET_BYTES:-12000}"
OPERATOR_BUDGET_BYTES="${VAULT_OS_OPERATOR_BUDGET_BYTES:-500}"
DECISION_LIMIT="${VAULT_OS_DECISION_LIMIT:-3}"
STALE_DAYS=30

byte_count() {
  wc -c < "$1" | tr -d '[:space:]'
}

hook_version() {
  grep -m1 'vault-os-hook-version:' "$1" 2>/dev/null | sed -E 's/.*vault-os-hook-version:[[:space:]]*//'
}

find_compass() {
  local vault="$1" candidate
  for candidate in ops/compass.md compass.md notes/compass.md; do
    if [ -f "$vault/$candidate" ]; then
      printf '%s\n' "$vault/$candidate"
      return 0
    fi
  done
  return 1
}

frontmatter_status() {
  awk '
    NR == 1 && $0 != "---" { exit 3 }
    NR == 1 { in_fm=1; next }
    in_fm && $0 == "---" { exit found ? 0 : 4 }
    in_fm && $0 ~ /^status:[[:space:]]*/ {
      sub(/^status:[[:space:]]*/, "")
      gsub(/[[:space:]\r]+$/, "")
      print tolower($0)
      found=1
    }
    END {
      if (NR == 0) exit 3
    }
  ' "$1"
}

manifest_intakes() {
  awk '
    function clean(value) {
      sub(/[[:space:]]*#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]\r]+$/, "", value)
      return value
    }
    /^intake:[[:space:]]*/ {
      value=$0
      sub(/^intake:[[:space:]]*/, "", value)
      value=clean(value)
      if (value != "") print value
      in_intake=1
      next
    }
    in_intake && /^[^[:space:]#-]/ { in_intake=0 }
    in_intake && /^  [A-Za-z0-9_-]+:[[:space:]]*/ {
      value=$0
      sub(/^  [A-Za-z0-9_-]+:[[:space:]]*/, "", value)
      value=clean(value)
      if (value != "") print value
    }
  ' "$1" 2>/dev/null | sort -u
}

build_decision_records() {
  local file="$1" format="$2" record_dir="$3" index="$4"
  mkdir -p "$record_dir"
  : > "$index"
  awk -v format="$format" -v out="$record_dir" -v index_file="$index" '
    function flush_record(  path) {
      if (record == "") return
      path=sprintf("%s/%06d.md", out, count)
      print record > path
      close(path)
      printf "%s\t%06d\t%s\n", record_date, count, path >> index_file
      record=""
    }
    function is_start(line) {
      if (format == "heading") return line ~ /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/
      return line ~ /^- \[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\]/
    }
    function extract_date(line) {
      if (format == "heading") return substr(line, 4, 10)
      return substr(line, 4, 10)
    }
    {
      sub(/\r$/, "")
      if (is_start($0)) {
        flush_record()
        count++
        record_date=extract_date($0)
        record=$0
      } else if (count > 0) {
        record=record ORS $0
      }
    }
    END { flush_record() }
  ' "$file"
}

render_decisions() {
  local file="$1" available="$2" work="$3" out="$4"
  local heading_count bullet_count total_count format index sorted selected injected
  local date order path record_bytes current first_line

  : > "$out"
  heading_count=$(grep -cE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' "$file" 2>/dev/null || true)
  bullet_count=$(grep -cE '^- \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]' "$file" 2>/dev/null || true)
  total_count=$((heading_count + bullet_count))

  {
    echo "--- DECISIONS (bounded) ---"
    if [ ! -s "$file" ]; then
      echo "decisions.md: 0 entries, 0 source bytes"
      echo "full log: ops/decisions.md — grep it"
      return
    fi
    if [ "$heading_count" -gt 0 ] && [ "$bullet_count" -gt 0 ]; then
      echo "⚠ decisions.md mixes heading and bullet schemas — body omitted; normalize the file."
      echo "decisions.md: ${total_count} detected entries, $(byte_count "$file") source bytes"
      echo "full log: ops/decisions.md — grep it"
      return
    elif [ "$heading_count" -gt 0 ]; then
      format="heading"
    elif [ "$bullet_count" -gt 0 ]; then
      format="bullet"
    else
      echo "⚠ decisions.md is non-empty but matches no supported date-keyed schema — body omitted."
      echo "decisions.md: 0 detected entries, $(byte_count "$file") source bytes"
      echo "full log: ops/decisions.md — grep it"
      return
    fi
  } >> "$out"

  index="$work/decision-index.tsv"
  sorted="$work/decision-index-sorted.tsv"
  build_decision_records "$file" "$format" "$work/decision-records" "$index"
  sort -t $'\t' -k1,1r -k2,2n "$index" > "$sorted"

  selected=0
  injected=0
  while IFS=$'\t' read -r date order path; do
    [ "$selected" -lt "$DECISION_LIMIT" ] || break
    record_bytes=$(byte_count "$path")
    current=$(byte_count "$out")
    if [ $((current + record_bytes + 240)) -gt "$available" ]; then
      first_line=$(sed -n '1p' "$path" | cut -c1-160)
      {
        echo "⚠ newest remaining decision does not fit the orientation budget; body omitted."
        echo "  ${date} · ${record_bytes} B · ${first_line}"
      } >> "$out"
      break
    fi
    echo "" >> "$out"
    cat "$path" >> "$out"
    echo "" >> "$out"
    selected=$((selected + 1))
    injected=$((injected + record_bytes))
  done < "$sorted"

  {
    echo "decisions.md: ${total_count} total entries; ${selected} injected; ${injected} record bytes"
    echo "full log: ops/decisions.md — grep it"
  } >> "$out"
}

run_selftest() {
  local fail=0 temp
  if date -d "2026-01-01" +%s >/dev/null 2>&1; then
    echo "PASS: GNU date parses ISO dates — compass staleness available"
  else
    echo "FAIL: GNU date unavailable — compass staleness unavailable"
    fail=1
  fi
  for dependency in grep git stat xargs awk sort wc mktemp sed find head cut cat tr rm rmdir; do
    if command -v "$dependency" >/dev/null 2>&1; then
      echo "PASS: ${dependency} available"
    else
      echo "FAIL: ${dependency} unavailable"
      fail=1
    fi
  done
  if stat -c %Y "$0" >/dev/null 2>&1; then
    echo "PASS: stat reads this hook — recent-file ranking available"
  else
    echo "FAIL: stat cannot read this hook"
    fail=1
  fi
  if printf 'x\0' | xargs -0 -r printf '%s' | grep -q '^x$'; then
    echo "PASS: xargs preserves NUL-delimited paths"
  else
    echo "FAIL: xargs NUL handling broken"
    fail=1
  fi
  temp=$(mktemp -d 2>/dev/null || true)
  if [ -n "$temp" ] && [ -d "$temp" ]; then
    printf '## 2026-01-01 — Older\nold body\n## 2026-01-02 — Newer\nnew body\n' > "$temp/headings.md"
    build_decision_records "$temp/headings.md" heading "$temp/heading-records" "$temp/heading-index.tsv"
    printf '%s\n' \
      '- [2026-01-01] Decision: Older' \
      '  Decision-ID: 20260101-older' \
      '  State: encoded' \
      '- [2026-01-02] Decision: Newer' \
      '  Decision-ID: 20260102-newer' \
      '  State: unencoded' > "$temp/bullets.md"
    build_decision_records "$temp/bullets.md" bullet "$temp/bullet-records" "$temp/bullet-index.tsv"
    if [ "$(wc -l < "$temp/heading-index.tsv")" -eq 2 ] \
      && [ "$(wc -l < "$temp/bullet-index.tsv")" -eq 2 ] \
      && grep -q 'new body' "$temp/heading-records/000002.md" \
      && grep -q 'Decision-ID: 20260102-newer' "$temp/bullet-records/000002.md"; then
      echo "PASS: heading and multiline-bullet decisions parse as complete records"
    else
      echo "FAIL: decision record parser lost or split a record"
      fail=1
    fi
    rm -rf "$temp"
    echo "PASS: temporary workspace available"
  else
    echo "FAIL: temporary workspace unavailable"
    fail=1
  fi
  if [ "$fail" -eq 0 ]; then
    echo "SELFTEST: all checks passed"
    return 0
  fi
  echo "SELFTEST: one or more checks failed"
  return 1
}

run_conformance() {
  local vault="${CLAUDE_PROJECT_DIR:-$PWD}" fail=0 internal=0 compass manifest settings
  local orient capture version retired

  if ! command -v grep >/dev/null 2>&1 || ! command -v find >/dev/null 2>&1; then
    echo "ERROR: conformance checker dependencies unavailable"
    return 2
  fi

  manifest="$vault/ops/vault-manifest.md"
  settings="$vault/.claude/settings.json"
  orient="$vault/.claude/hooks/session-orient.sh"
  capture="$vault/.claude/hooks/session-capture.sh"

  if [ -f "$vault/CLAUDE.md" ]; then
    echo "PASS: CLAUDE.md present"
  else
    echo "FAIL: CLAUDE.md missing — vault contract unavailable"
    fail=1
  fi

  compass=$(find_compass "$vault" 2>/dev/null || true)
  if [ -n "$compass" ] && grep -qE '^\*Updated: [0-9]{4}-[0-9]{2}-[0-9]{2}\*' "$compass"; then
    echo "PASS: compass has Updated stamp"
  else
    echo "FAIL: compass missing or has no Updated stamp — staleness unjudgeable"
    fail=1
  fi

  if [ -f "$manifest" ] && grep -q '^exports:' "$manifest"; then
    echo "PASS: manifest has v4 exports contract"
  else
    echo "FAIL: manifest missing v4 exports contract"
    fail=1
  fi

  if [ -f "$settings" ] &&
     grep -Fq 'Edit(/CLAUDE.md)' "$settings" &&
     grep -Fq 'Edit(/ops/vault-manifest.md)' "$settings"; then
    echo "PASS: both protected files use Edit ask rules"
  else
    echo "FAIL: settings missing one or both Edit ask rules"
    fail=1
  fi

  version=$(hook_version "$orient")
  if [[ "$version" == "$HOOK_BASE_VERSION" || "$version" == "$HOOK_BASE_VERSION"+* ]]; then
    echo "PASS: orient hook version ${version}"
  else
    echo "FAIL: orient hook version '${version:-missing}' does not derive from ${HOOK_BASE_VERSION}"
    fail=1
  fi
  version=$(hook_version "$capture")
  if [[ "$version" == "$HOOK_BASE_VERSION" || "$version" == "$HOOK_BASE_VERSION"+* ]]; then
    echo "PASS: capture hook version ${version}"
  else
    echo "FAIL: capture hook version '${version:-missing}' does not derive from ${HOOK_BASE_VERSION}"
    fail=1
  fi

  if [ -f "$settings" ] &&
     grep -Fq '"SessionStart"' "$settings" &&
     grep -Fq 'session-orient.sh' "$settings" &&
     grep -Fq '"SessionEnd"' "$settings" &&
     grep -Fq 'session-capture.sh' "$settings" &&
     [ "$(grep -Fc '$CLAUDE_PROJECT_DIR' "$settings")" -ge 2 ]; then
    echo "PASS: SessionStart/SessionEnd use CLAUDE_PROJECT_DIR"
  else
    echo "FAIL: hook wiring missing or not rooted in CLAUDE_PROJECT_DIR"
    fail=1
  fi

  retired=""
  for path in "$vault/knowledge.md" "$vault/guide.md" "$vault/.claude/protected-files.txt" "$vault/ops/protected-files.txt"; do
    [ -e "$path" ] && retired="${retired}${retired:+, }${path#$vault/}"
  done
  if [ -z "$retired" ]; then
    echo "PASS: no retired root control artifacts"
  else
    echo "FAIL: retired control artifacts present: ${retired}"
    fail=1
  fi

  if [ "$internal" -ne 0 ]; then
    return 2
  elif [ "$fail" -ne 0 ]; then
    return 1
  fi
  return 0
}

if [ "${1:-}" = "--selftest" ]; then
  run_selftest
  exit $?
elif [ "${1:-}" = "--conformance" ]; then
  run_conformance
  exit $?
fi

VAULT="${CLAUDE_PROJECT_DIR:?ERROR: CLAUDE_PROJECT_DIR not set — hook must be invoked by Claude Code}"
[[ -f "$VAULT/CLAUDE.md" ]] || { echo "ERROR: VAULT root invalid at $VAULT (no CLAUDE.md)"; exit 1; }

VAULT_NAME=$(basename "$VAULT")
MANIFEST="$VAULT/ops/vault-manifest.md"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

HEADER="$WORK/header"
OPERATOR="$WORK/operator"
DERIVED="$WORK/derived"
DECLARED="$WORK/declared"
PLANS="$WORK/plans"
INTAKES="$WORK/intakes"
UNENCODED="$WORK/unencoded"
MIGRATION="$WORK/migration"
DECISIONS_OUT="$WORK/decisions"
OUT="$WORK/orientation"

VERSION=$(hook_version "$0")
{
  echo "╔══════════════════════════════════════════════════════════╗"
  printf "║  %-56s║\n" "${VAULT_NAME} ORIENTATION"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo "Date: $(date +%Y-%m-%d)   hook ${VERSION:-unknown}"
  echo ""
} > "$HEADER"

: > "$OPERATOR"
if [ -f "$HOME/.claude/operator.md" ]; then
  operator_size=$(byte_count "$HOME/.claude/operator.md")
  echo "--- OPERATOR PROFILE ---" >> "$OPERATOR"
  if [ "$operator_size" -le "$OPERATOR_BUDGET_BYTES" ]; then
    cat "$HOME/.claude/operator.md" >> "$OPERATOR"
  else
    head -c "$OPERATOR_BUDGET_BYTES" "$HOME/.claude/operator.md" >> "$OPERATOR"
    echo "" >> "$OPERATOR"
    echo "⚠ operator.md is ${operator_size} B; excerpt capped at ${OPERATOR_BUDGET_BYTES} B." >> "$OPERATOR"
    echo "full profile: $HOME/.claude/operator.md" >> "$OPERATOR"
  fi
  echo "" >> "$OPERATOR"
fi

{
  echo "════════════════════════════════════════════════════════════"
  echo "DERIVED — live from git + disk"
  echo "════════════════════════════════════════════════════════════"
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git not on PATH — branch, history, and recovery posture unavailable"
  elif ! git -C "$VAULT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Git: NONE — no local history and no git-derived recovery"
  else
    branch=$(git -C "$VAULT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    echo "Branch: ${branch:-<unknown>}"
    echo "Last 5 commits:"
    if git -C "$VAULT" rev-parse HEAD >/dev/null 2>&1; then
      git -C "$VAULT" log -5 --oneline 2>/dev/null | sed 's/^/  /'
      local_history=yes
    else
      echo "  (no commits yet)"
      local_history=no
    fi

    tracked_changes=$(git -C "$VAULT" status --porcelain 2>/dev/null | grep -cE '^[ MARCUD?!][MDARC]' || true)
    untracked_count=$(git -C "$VAULT" ls-files --others --exclude-standard 2>/dev/null | grep -c . || true)
    untracked_bytes=$(
      cd "$VAULT" || exit 1
      git ls-files --others --exclude-standard -z 2>/dev/null |
        xargs -0 -r stat -c %s 2>/dev/null |
        awk '{total += $1} END {print total+0}'
    )
    remote_count=$(git -C "$VAULT" remote 2>/dev/null | grep -c . || true)
    upstream=$(git -C "$VAULT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    if [ -n "$upstream" ]; then
      unpushed=$(git -C "$VAULT" rev-list --count "${upstream}..HEAD" 2>/dev/null || true)
      upstream_state="${upstream}; ${unpushed:-?} unpushed"
    else
      upstream_state="NONE; push status unknown"
    fi
    echo "Recovery posture: local-history=${local_history}; remotes=${remote_count}; upstream=${upstream_state}; tracked-changes=${tracked_changes}; untracked=${untracked_count} files/${untracked_bytes} B"

    echo "Recently modified (non-ignored, top 5):"
    recent=$(
      cd "$VAULT" || exit 1
      git ls-files --cached --others --exclude-standard -z 2>/dev/null |
        xargs -0 -r stat -c '%Y %n' 2>/dev/null |
        sort -rn |
        head -5 |
        cut -d' ' -f2-
    )
    if [ -n "$recent" ]; then
      printf '%s\n' "$recent" | sed 's/^/  /'
    else
      echo "  (none)"
    fi
  fi

  last="$VAULT/ops/sessions/last-active.md"
  if [ -f "$last" ]; then
    last_epoch=$(stat -c %Y "$last" 2>/dev/null || true)
    now_epoch=$(date +%s)
    age_days=$(( (now_epoch - last_epoch) / 86400 ))
    echo "Last session record: ${age_days} day(s) old — ops/sessions/last-active.md"
    sed -n '1,12p' "$last" | sed 's/^/  /'
  else
    echo "Last session record: MISSING"
  fi
  echo ""
} > "$DERIVED"

: > "$DECLARED"
COMPASS=$(find_compass "$VAULT" 2>/dev/null || true)
if [ -n "$COMPASS" ]; then
  compass_size=$(byte_count "$COMPASS")
  {
    echo "════════════════════════════════════════════════════════════"
    echo "DECLARED — compass intent"
    echo "════════════════════════════════════════════════════════════"
  } >> "$DECLARED"
  updated=$(grep -m1 -oE '\*Updated: [0-9]{4}-[0-9]{2}-[0-9]{2}\*' "$COMPASS" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
  if [ -n "$updated" ]; then
    updated_epoch=$(date -d "$updated" +%s 2>/dev/null || true)
    if [ -n "$updated_epoch" ]; then
      compass_age=$(( ($(date +%s) - updated_epoch) / 86400 ))
      if [ "$compass_age" -gt "$STALE_DAYS" ]; then
        echo "⚠ intent last declared ${compass_age} days ago — treat as HISTORICAL" >> "$DECLARED"
      fi
    fi
  else
    echo "⚠ compass has no '*Updated: YYYY-MM-DD*' stamp — staleness unknown" >> "$DECLARED"
  fi
  if [ "$compass_size" -le 5000 ]; then
    cat "$COMPASS" >> "$DECLARED"
  else
    echo "⚠ compass is ${compass_size} B; body omitted above the 5000 B source cap." >> "$DECLARED"
    echo "full compass: ${COMPASS#$VAULT/}" >> "$DECLARED"
  fi
  echo "" >> "$DECLARED"
fi

: > "$PLANS"
if [ -d "$VAULT/docs/plans" ]; then
  open_count=0
  unknown_count=0
  while IFS= read -r plan; do
    status=$(frontmatter_status "$plan" 2>/dev/null || true)
    case "$status" in
      draft|active|blocked)
        if [ "$open_count" -eq 0 ]; then echo "--- OPEN PLANS ---" >> "$PLANS"; fi
        plan_epoch=$(stat -c %Y "$plan" 2>/dev/null || true)
        plan_age=$(( ($(date +%s) - plan_epoch) / 86400 ))
        echo "  $(basename "$plan") · status=${status} · mtime-age=${plan_age}d" >> "$PLANS"
        open_count=$((open_count + 1))
        ;;
      done|closed) ;;
      *)
        if [ "$unknown_count" -eq 0 ]; then echo "--- PLAN METADATA WARNINGS ---" >> "$PLANS"; fi
        echo "  ⚠ $(basename "$plan") · status=${status:-UNKNOWN}" >> "$PLANS"
        unknown_count=$((unknown_count + 1))
        ;;
    esac
  done < <(find "$VAULT/docs/plans" -maxdepth 1 -type f -name '*.md' | sort)
  [ -s "$PLANS" ] && echo "" >> "$PLANS"
fi

: > "$INTAKES"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r intake; do
    case "$intake" in
      /*|[A-Za-z]:*|*'..'*)
        echo "⚠ invalid intake path in manifest: ${intake}" >> "$INTAKES"
        continue
        ;;
    esac
    intake_dir="$VAULT/${intake%/}"
    if [ ! -d "$intake_dir" ]; then
      echo "⚠ declared intake missing: ${intake}" >> "$INTAKES"
      continue
    fi
    intake_count=$(find "$intake_dir" -maxdepth 1 -type f ! -name 'README.md' | wc -l | tr -d '[:space:]')
    if [ "$intake_count" -gt 0 ]; then
      echo "--- INTAKE: ${intake} (${intake_count} pending) ---" >> "$INTAKES"
      find "$intake_dir" -maxdepth 1 -type f ! -name 'README.md' -printf '%T@ %f\n' |
        sort -rn |
        head -5 |
        cut -d' ' -f2- |
        sed 's/^/  /' >> "$INTAKES"
    fi
  done < <(manifest_intakes "$MANIFEST")
  [ -s "$INTAKES" ] && echo "" >> "$INTAKES"
fi

: > "$UNENCODED"
DECISIONS="$VAULT/ops/decisions.md"
if [ -f "$DECISIONS" ] && grep -qE '^[[:space:]]*State:[[:space:]]*unencoded[[:space:]]*$' "$DECISIONS"; then
  echo "--- UNENCODED DECISIONS ---" >> "$UNENCODED"
  awk '
    /^[[:space:]]*Decision-ID:[[:space:]]*/ {
      id=$0; sub(/^[[:space:]]*Decision-ID:[[:space:]]*/, "", id)
    }
    /^[[:space:]]*Governs:[[:space:]]*/ {
      governs=$0; sub(/^[[:space:]]*Governs:[[:space:]]*/, "", governs)
    }
    /^[[:space:]]*State:[[:space:]]*unencoded[[:space:]]*$/ {
      printf "  %s · %s\n", (id ? id : "<missing-id>"), (governs ? governs : "<missing-governs>")
      id=""; governs=""
    }
  ' "$DECISIONS" >> "$UNENCODED"
  echo "" >> "$UNENCODED"
fi

: > "$MIGRATION"
if [ -f "$MANIFEST" ] && ! grep -q '^exports:' "$MANIFEST" 2>/dev/null; then
  {
    echo "--- MIGRATION ---"
    echo "⚠ PRE-V4 VAULT: manifest has no exports contract. Offer v4.2 migration."
    echo ""
  } > "$MIGRATION"
fi

: > "$OUT"
cat "$HEADER" >> "$OUT"

append_section() {
  local section="$1" key="$2" limit="$3" size used
  size=$(byte_count "$section")
  used=$(byte_count "$OUT")
  if [ "$size" -eq 0 ]; then
    printf -v "${key}_INJECTED" '%s' 0
  elif [ $((used + size)) -le "$limit" ]; then
    cat "$section" >> "$OUT"
    printf -v "${key}_INJECTED" '%s' "$size"
  else
    echo "⚠ ${key,,} section omitted: ${size} B would exceed the non-decision budget." >> "$OUT"
    printf -v "${key}_INJECTED" '%s' 0
  fi
}

append_section "$OPERATOR" OPERATOR "$NON_DECISION_BUDGET_BYTES"
append_section "$DERIVED" DERIVED "$NON_DECISION_BUDGET_BYTES"
append_section "$DECLARED" DECLARED "$NON_DECISION_BUDGET_BYTES"
append_section "$PLANS" PLANS "$NON_DECISION_BUDGET_BYTES"
append_section "$INTAKES" INTAKES "$NON_DECISION_BUDGET_BYTES"
append_section "$UNENCODED" UNENCODED "$NON_DECISION_BUDGET_BYTES"
append_section "$MIGRATION" MIGRATION "$NON_DECISION_BUDGET_BYTES"

DECISIONS_INJECTED=0
if [ -f "$DECISIONS" ]; then
  used=$(byte_count "$OUT")
  available=$((ORIENTATION_BUDGET_BYTES - used - 700))
  if [ "$available" -gt 260 ]; then
    render_decisions "$DECISIONS" "$available" "$WORK" "$DECISIONS_OUT"
    decision_size=$(byte_count "$DECISIONS_OUT")
    if [ "$decision_size" -le "$available" ]; then
      cat "$DECISIONS_OUT" >> "$OUT"
      DECISIONS_INJECTED="$decision_size"
    else
      echo "⚠ decisions section omitted: bounded renderer exceeded its allowance." >> "$OUT"
    fi
  else
    echo "⚠ decisions body omitted: no orientation budget remains; full log: ops/decisions.md" >> "$OUT"
  fi
fi

pre_footer=$(byte_count "$OUT")
{
  echo ""
  echo "--- ORIENTATION COST ---"
  echo "operator=${OPERATOR_INJECTED:-0}B derived=${DERIVED_INJECTED:-0}B declared=${DECLARED_INJECTED:-0}B plans=${PLANS_INJECTED:-0}B intakes=${INTAKES_INJECTED:-0}B decisions=${DECISIONS_INJECTED:-0}B"
  echo "pre-footer=${pre_footer}B budget=${ORIENTATION_BUDGET_BYTES}B"
} >> "$OUT"

total=$(byte_count "$OUT")
if [ "$total" -gt "$ORIENTATION_BUDGET_BYTES" ]; then
  echo "ERROR: orientation renderer produced ${total} B above the ${ORIENTATION_BUDGET_BYTES} B budget; body suppressed."
  echo "Run: CLAUDE_PROJECT_DIR=\"$VAULT\" bash \"$0\" --selftest"
  exit 1
fi

cat "$OUT"
