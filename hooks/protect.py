#!/usr/bin/env python3
"""
protect.py — Fires on PostToolUse Write.
Warns when a file listed in .claude/protected-files.txt is written to.
"""

import sys
import json
import os

VAULT = os.environ.get("CLAUDE_PROJECT_DIR", "")
PROTECTED_LIST = os.path.join(VAULT, ".claude", "protected-files.txt")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = data.get("tool_input", {}).get("file_path", "")
    if not file_path:
        sys.exit(0)

    # Load protected paths
    try:
        with open(PROTECTED_LIST, "r", encoding="utf-8") as f:
            protected = [
                line.strip() for line in f
                if line.strip() and not line.startswith("#")
            ]
    except FileNotFoundError:
        sys.exit(0)

    if not protected:
        sys.exit(0)

    # Resolve written file relative to vault root
    norm_vault = VAULT.replace("\\", "/").rstrip("/")
    norm_written = file_path.replace("\\", "/")
    if norm_written.startswith(norm_vault + "/"):
        relative = norm_written[len(norm_vault) + 1:]
    else:
        relative = norm_written

    if relative in protected:
        print(f"\n  PROTECTED FILE — {relative}")
        print("   Requires explicit user permission before modifying.")


if __name__ == "__main__":
    main()
