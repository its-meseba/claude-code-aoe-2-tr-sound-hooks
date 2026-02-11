#!/usr/bin/env python3
"""
Fix invalid hook keys in ~/.claude/settings.json

Removes SubAgentStart/SubAgentStop (wrong casing) that cause
Claude Code to reject the entire settings file.
"""

import json
import os
import sys

settings_path = os.path.expanduser("~/.claude/settings.json")

if not os.path.exists(settings_path):
    print("No settings.json found at", settings_path)
    sys.exit(1)

with open(settings_path, "r") as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})
invalid_keys = ["SubAgentStart", "SubAgentStop"]
removed = []

for key in invalid_keys:
    if key in hooks:
        del hooks[key]
        removed.append(key)

if removed:
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print(f"Removed invalid keys: {', '.join(removed)}")
    print(f"Valid alternatives (SubagentStart, SubagentStop) left intact.")
else:
    print("No invalid keys found. settings.json is clean.")
