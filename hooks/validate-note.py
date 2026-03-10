#!/usr/bin/env python3
"""
validate-note.py — Module A knowledge graph schema validator.
Fires on PostToolUse Write. Checks any note written to notes/ for:
  1. Required frontmatter fields (configurable per vault)
  2. Prose wikilinks — wikilinks must not be exclusively in the Topics footer
  3. Description length (~150 chars; warn if < 50 or > 200)
  4. Broken wikilinks — [[targets]] that don't resolve to existing .md files
  5. Date format — published and created must be YYYY-MM-DD
  6. source-url must begin with configured URL prefix
  7. source-video must be wikilink format [[...]]
  8. Topics: footer section present (bidirectional MOC link)
  9. Soft warning if type: contradiction but no contradicts: field
"""

import sys
import json
import os
import re

REQUIRED_FIELDS = {
    "description:":  "description  (~150 chars — adds scope/mechanism beyond the title, not a restatement)",
    "type:":         "type         (insight | framework | tactic | distinction | contradiction)",
    "source-video:": "source-video (wikilink to archived transcript: [[slug]])",
    "source-url:":   "source-url   (URL to original source)",
    "published:":    "published    (YYYY-MM-DD — date of source material)",
    "created:":      "created      (YYYY-MM-DD — date this note was created)",
}

# Infrastructure files — skip validation
SKIP_NAMES = {
    "compass.md", "methods.md", "index.md", "dedup-index.md",
}


def is_moc_file(basename):
    return basename.endswith("-moc.md")


def find_vault_root(file_path):
    normalised = file_path.replace("\\", "/")
    idx = normalised.find("/notes/")
    if idx >= 0:
        return normalised[:idx]
    return None


def load_type_vocabulary(vault_root):
    """Load type vocabulary from ops/validate-config.yaml.
    Returns (vocab_set, error_msg). On success: (set, None). On failure: (None, msg).
    """
    if not vault_root:
        return None, "MISSING CONFIG: ops/validate-config.yaml required for Module A. Check 7 cannot run (vault root not found)."
    config_path = os.path.join(vault_root, "ops", "validate-config.yaml")
    if not os.path.exists(config_path):
        return None, "MISSING CONFIG: ops/validate-config.yaml required for Module A. Check 7 cannot run."
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            raw = f.read()
        match = re.search(r'type-vocabulary:\s*\[([^\]]+)\]', raw)
        if not match:
            return None, "MISSING CONFIG: ops/validate-config.yaml has no type-vocabulary field. Check 7 cannot run."
        types = {t.strip() for t in match.group(1).split(",")}
        return types, None
    except Exception as e:
        return None, f"MISSING CONFIG: ops/validate-config.yaml could not be read ({e}). Check 7 cannot run."


def check_description_length(content, violations):
    match = re.search(r'^description:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    desc = match.group(1).strip().strip('"').strip("'")
    length = len(desc)
    if length < 50:
        violations.append(
            f"Description too short ({length} chars, aim for ~150)."
            " A vague description fails progressive disclosure — future sessions can't filter-before-read."
        )
    elif length > 200:
        violations.append(
            f"Description too long ({length} chars, cap ~200)."
            " Trim to a single sharp claim that adds scope or mechanism beyond the title."
        )


def check_date_field(content, field_name, violations):
    match = re.search(rf'^{re.escape(field_name)}:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    date_val = match.group(1).strip()
    if not re.match(r'^\d{4}-\d{2}-\d{2}$', date_val):
        violations.append(
            f"{field_name} format invalid ('{date_val}'). Must be YYYY-MM-DD."
        )


def check_source_url(content, violations):
    match = re.search(r'^source-url:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    url = match.group(1).strip()
    if not url.startswith("https://"):
        violations.append(
            f"source-url must start with 'https://' (got: '{url}')."
            " Every note must trace to a specific source."
        )


def check_source_video_format(content, violations):
    match = re.search(r'^source-video:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    val = match.group(1).strip().strip('"').strip("'")
    if not (val.startswith("[[") and val.endswith("]]")):
        violations.append(
            f"source-video must be a wikilink (e.g. [[transcript-slug]]), got: '{val}'."
            " This creates the graph edge back to the source transcript."
        )


def check_type_field(content, valid_types, violations):
    match = re.search(r'^type:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return
    type_val = match.group(1).strip()
    if type_val not in valid_types:
        violations.append(
            f"type '{type_val}' is not valid. Must be one of: {', '.join(sorted(valid_types))}."
        )


def check_topics_footer(content, violations):
    """Check that note has a Topics: body section (bidirectional MOC link)."""
    body = content
    fm_match = re.match(r'^---\n.*?\n---\n', content, re.DOTALL)
    if fm_match:
        body = content[fm_match.end():]
    if not re.search(r'^Topics:', body, re.MULTILINE):
        violations.append(
            "Missing Topics: footer section. Every note must declare its MOC membership:"
            "\n   ---"
            "\n   Topics:"
            "\n   - [[domain-moc]]"
            "\n   This is the bidirectional link that makes the graph traversable."
        )


def check_contradiction_field(content, violations):
    """Soft warning: type: contradiction should have contradicts: field."""
    if re.search(r'^type:\s*contradiction', content, re.MULTILINE):
        if not re.search(r'^contradicts:', content, re.MULTILINE):
            violations.append(
                "type: contradiction set but no contradicts: field found."
                " Add: contradicts: '[[note-slug]]' to create an explicit contradiction link."
            )


def check_broken_wikilinks(content, vault_root, violations):
    if not vault_root:
        return
    links = re.findall(r'\[\[([^\]|]+)', content)
    if not links:
        return
    known_files = set()
    for root, dirs, files in os.walk(vault_root):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for fname in files:
            if fname.endswith('.md'):
                known_files.add(fname[:-3])
    broken = []
    seen = set()
    for link in links:
        target = link.strip()
        if target in seen:
            continue
        seen.add(target)
        if target not in known_files:
            broken.append(target)
    if broken:
        violations.append("Broken wikilinks (no matching .md file in vault):")
        for b in broken[:5]:
            violations.append(f"   [[{b}]]")
        if len(broken) > 5:
            violations.append(f"   ... and {len(broken) - 5} more")
        violations.append(
            "   Create the target note or correct the link name."
            " Broken links corrupt graph traversal."
        )


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = data.get("tool_input", {}).get("file_path", "")

    if not file_path:
        sys.exit(0)

    normalised = file_path.replace("\\", "/")
    if "/notes/" not in normalised or not normalised.endswith(".md"):
        sys.exit(0)

    basename = os.path.basename(file_path)

    if basename in SKIP_NAMES or is_moc_file(basename):
        sys.exit(0)

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        sys.exit(0)

    vault_root = find_vault_root(file_path)
    valid_types, type_config_error = load_type_vocabulary(vault_root)

    if not content.startswith("---"):
        print(f"\n  SCHEMA VIOLATION — {basename}")
        print("   No frontmatter block found. Notes require YAML frontmatter.")
        sys.exit(0)

    violations = []

    # 1. Required fields
    missing = []
    for field, label in REQUIRED_FIELDS.items():
        if not re.search(f"^{re.escape(field)}", content, re.MULTILINE):
            missing.append(f"   {label}")
    if missing:
        violations.append("Missing required frontmatter fields:")
        for m in missing:
            violations.append(m)

    # 2. Description length
    check_description_length(content, violations)

    # 3. Date formats
    check_date_field(content, "published", violations)
    check_date_field(content, "created", violations)

    # 4. source-url check
    check_source_url(content, violations)

    # 5. source-video wikilink format
    check_source_video_format(content, violations)

    # 6. type field validation
    if valid_types is None:
        violations.append(type_config_error)
    else:
        check_type_field(content, valid_types, violations)

    # 7. Topics: footer present
    check_topics_footer(content, violations)

    # 8. Contradiction soft warning
    check_contradiction_field(content, violations)

    # 9. Prose wikilinks — must not be exclusively in the Topics footer
    body = content
    fm_match = re.match(r'^---\n.*?\n---\n', content, re.DOTALL)
    if fm_match:
        body = content[fm_match.end():]

    # Split off the Topics: footer section
    topics_split = re.split(r'^---\s*\nTopics:', body, flags=re.MULTILINE)
    pre_topics = topics_split[0] if topics_split else body

    all_links = re.findall(r'\[\[[^\]]+\]\]', body)
    prose_links = re.findall(r'\[\[[^\]]+\]\]', pre_topics)

    if all_links and not prose_links:
        violations.append("Wikilinks are footer-only (all in Topics: section).")
        violations.append("   Embed at least one [[link]] in body prose explaining *why* you'd follow it.")
        violations.append("   Wrong: body with no links, then '- [[note]]' in footer")
        violations.append("   Right: '...since [[other-note]], the mechanism here is...'")
        violations.append("   Prose links implement spreading activation. Footer links are addresses.")

    # 10. Broken wikilinks
    check_broken_wikilinks(content, vault_root, violations)

    if violations:
        print(f"\n  VAULT VIOLATION — {basename}")
        for v in violations:
            print(f"   {v}" if v and not v.startswith("   ") else v)
        print("\n   Fix before moving on.")


if __name__ == "__main__":
    main()
