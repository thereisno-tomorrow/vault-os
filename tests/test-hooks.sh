#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIENT="$ROOT/hooks/session-orient.sh"
CAPTURE="$ROOT/hooks/session-capture.sh"
STARTER="$ROOT/examples/starter-vault"
FAIL=0
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

bash -n "$ORIENT" && bash "$ORIENT" --selftest >/dev/null \
  && pass 'canonical orient syntax + selftest' \
  || fail 'canonical orient syntax + selftest'
bash -n "$CAPTURE" && bash "$CAPTURE" --selftest >/dev/null \
  && pass 'canonical capture syntax + selftest' \
  || fail 'canonical capture syntax + selftest'

cmp -s "$ORIENT" "$STARTER/.claude/hooks/session-orient.sh" \
  && cmp -s "$CAPTURE" "$STARTER/.claude/hooks/session-capture.sh" \
  && pass 'starter hook copies equal canonical hooks' \
  || fail 'starter hook copies drifted'

awk '
  /^### T-ORIENT:/ { section=1 }
  section && /^```bash$/ { capture=1; next }
  capture && /^```$/ { exit }
  capture { print }
' "$ROOT/skills/new-vault/SKILL.md" > "$TEMP/embedded-orient.sh"
awk '
  /^### T-CAPTURE:/ { section=1 }
  section && /^```bash$/ { capture=1; next }
  capture && /^```$/ { exit }
  capture { print }
' "$ROOT/skills/new-vault/SKILL.md" > "$TEMP/embedded-capture.sh"
cmp -s "$ORIENT" "$TEMP/embedded-orient.sh" \
  && cmp -s "$CAPTURE" "$TEMP/embedded-capture.sh" \
  && pass 'embedded scaffolder hooks equal canonical hooks' \
  || fail 'embedded scaffolder hook drift'

cp -R "$STARTER" "$TEMP/decision-vault"
cat > "$TEMP/decision-vault/ops/decisions.md" <<'EOF'
- [2026-07-28] Decision: Newest
  Decision-ID: 20260728-newest
  Because: newest
  Forecloses: none
  Governs: fixture/a
  Encoded in: fixture/a
  Completeness check: a
  State: encoded
- [2026-07-27] Decision: Second
  Decision-ID: 20260727-second
  Because: second
  Forecloses: none
  Governs: fixture/b
  Encoded in: fixture/b
  Completeness check: b
  State: encoded
- [2026-07-26] Decision: Third
  Decision-ID: 20260726-third
  Because: third
  Forecloses: none
  Governs: fixture/c
  Encoded in: fixture/c
  Completeness check: c
  State: encoded
- [2026-01-01] Decision: Old unresolved
  Decision-ID: 20260101-old-unresolved
  Because: old
  Forecloses: none
  Governs: fixture/old
  Encoded in: UNENCODED
  Completeness check: old
  State: unencoded
EOF
decision_output="$TEMP/decision-output.txt"
HOME="$TEMP/home" CLAUDE_PROJECT_DIR="$TEMP/decision-vault" bash "$ORIENT" > "$decision_output"
decision_bytes="$(wc -c < "$decision_output" | tr -d ' ')"
if [ "$decision_bytes" -le 15000 ] \
  && grep -q '4 total entries; 3 injected' "$decision_output" \
  && grep -q '20260728-newest' "$decision_output" \
  && grep -q '20260727-second' "$decision_output" \
  && grep -q '20260726-third' "$decision_output" \
  && grep -q '20260101-old-unresolved' "$decision_output"; then
  pass '15 KB decision window is atomic and old unencoded IDs stay visible'
else
  fail 'decision budget, atomic selection, or unencoded signal'
fi

cp -R "$STARTER" "$TEMP/conform"
CLAUDE_PROJECT_DIR="$TEMP/conform" bash "$ORIENT" --conformance >/dev/null \
  && pass 'conforming fixture passes' \
  || fail 'conforming fixture rejected'

cp -R "$STARTER" "$TEMP/no-exports"
sed -i 's/^exports:/export-surfaces:/' "$TEMP/no-exports/ops/vault-manifest.md"
if CLAUDE_PROJECT_DIR="$TEMP/no-exports" bash "$ORIENT" --conformance \
  | grep -q 'FAIL: manifest missing v4 exports contract'; then
  pass 'missing exports defect named'
else
  fail 'missing exports defect not named'
fi

cp -R "$STARTER" "$TEMP/no-updated"
sed -i '/^\*Updated:/d' "$TEMP/no-updated/compass.md"
if CLAUDE_PROJECT_DIR="$TEMP/no-updated" bash "$ORIENT" --conformance \
  | grep -q 'FAIL: compass missing'; then
  pass 'missing compass stamp defect named'
else
  fail 'missing compass stamp defect not named'
fi

cp -R "$STARTER" "$TEMP/no-permission"
sed -i '/Edit(\/ops\/vault-manifest.md)/d' "$TEMP/no-permission/.claude/settings.json"
if CLAUDE_PROJECT_DIR="$TEMP/no-permission" bash "$ORIENT" --conformance \
  | grep -q 'FAIL: settings missing'; then
  pass 'partial permission defect named'
else
  fail 'partial permission defect not named'
fi

cp -R "$STARTER" "$TEMP/retired"
touch "$TEMP/retired/knowledge.md"
if CLAUDE_PROJECT_DIR="$TEMP/retired" bash "$ORIENT" --conformance \
  | grep -q 'FAIL: retired control artifacts present'; then
  pass 'retired artifact defect named'
else
  fail 'retired artifact defect not named'
fi

cp -R "$STARTER" "$TEMP/old-version"
sed -i 's/vault-os-hook-version: 4.2.0/vault-os-hook-version: 4.1.1/' \
  "$TEMP/old-version/.claude/hooks/session-orient.sh"
if CLAUDE_PROJECT_DIR="$TEMP/old-version" bash "$ORIENT" --conformance \
  | grep -q 'FAIL: orient hook version'; then
  pass 'old hook version defect named'
else
  fail 'old hook version defect not named'
fi

cp -R "$STARTER" "$TEMP/bad-wiring"
sed -i 's/\$CLAUDE_PROJECT_DIR/./g' "$TEMP/bad-wiring/.claude/settings.json"
if CLAUDE_PROJECT_DIR="$TEMP/bad-wiring" bash "$ORIENT" --conformance \
  | grep -q 'FAIL: hook wiring'; then
  pass 'bad hook wiring defect named'
else
  fail 'bad hook wiring defect not named'
fi

if env PATH=/nonexistent /usr/bin/bash "$ORIENT" --conformance >/dev/null 2>&1; then
  fail 'missing checker dependency unexpectedly passed'
elif [ "$?" -eq 2 ]; then
  pass 'missing checker dependency exits 2'
else
  fail 'missing checker dependency used the wrong exit'
fi

if [ "$FAIL" -eq 0 ]; then
  echo 'TESTS: all checks passed'
  exit 0
fi
echo 'TESTS: one or more checks failed'
exit 1
