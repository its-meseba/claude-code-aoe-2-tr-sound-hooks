#!/usr/bin/env python3
"""
merge_settings.py - Safe JSON merge/unmerge for Claude Code settings.json

Handles installing and uninstalling sound pack hook entries without
destroying existing hooks or other settings.

Usage:
    python3 merge_settings.py install <pack_id> <hooks_json>
    python3 merge_settings.py uninstall <pack_id>

hooks_json is a JSON string like:
    {"SessionStart": {"command": "bash -c '...'"}, "Stop": {"command": "bash -c '...'"}}
"""

import json
import os
import shutil
import sys
from datetime import datetime, timezone

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")
BACKUP_SUFFIX = ".bak"

PACK_PATH_MARKER = ".claude/hooks/sounds/"


def load_settings():
    if os.path.exists(SETTINGS_PATH):
        with open(SETTINGS_PATH) as f:
            return json.load(f)
    return {}


def save_settings(settings):
    os.makedirs(os.path.dirname(SETTINGS_PATH), exist_ok=True)
    with open(SETTINGS_PATH, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")


def backup_settings():
    if os.path.exists(SETTINGS_PATH):
        backup_path = SETTINGS_PATH + BACKUP_SUFFIX
        shutil.copy2(SETTINGS_PATH, backup_path)
        return backup_path
    return None


def belongs_to_pack(hook_group, pack_id):
    """Check if a hook group belongs to a pack via command path matching."""
    marker = f"{PACK_PATH_MARKER}{pack_id}/"
    for hook in hook_group.get("hooks", []):
        cmd = hook.get("command", "")
        if marker in cmd:
            return True
    return False


def install_pack_hooks(pack_id, hook_entries):
    """
    Merge pack hook entries into settings.json.

    hook_entries: dict of event_name -> {"command": "...", "matcher": "..."}
    """
    backup = backup_settings()
    if backup:
        print(f"Backup: {backup}")

    settings = load_settings()
    hooks = settings.setdefault("hooks", {})

    for event_name, entry in hook_entries.items():
        event_hooks = hooks.get(event_name, [])

        # Remove any existing entry for this pack (idempotent reinstall)
        event_hooks = [h for h in event_hooks if not belongs_to_pack(h, pack_id)]

        # Build the new hook group
        hook_group = {
            "hooks": [{"type": "command", "command": entry["command"]}]
        }

        matcher = entry.get("matcher", "")
        if matcher:
            hook_group["matcher"] = matcher

        event_hooks.append(hook_group)
        hooks[event_name] = event_hooks

    settings["hooks"] = hooks
    save_settings(settings)
    print(f"Merged {len(hook_entries)} hook(s) into {SETTINGS_PATH}")


def uninstall_pack_hooks(pack_id):
    """Remove all hook entries belonging to a pack from settings.json."""
    if not os.path.exists(SETTINGS_PATH):
        print("No settings.json found. Nothing to clean.")
        return 0

    backup = backup_settings()
    if backup:
        print(f"Backup: {backup}")

    settings = load_settings()
    hooks = settings.get("hooks", {})
    removed_count = 0

    for event_name in list(hooks.keys()):
        original_len = len(hooks[event_name])
        hooks[event_name] = [
            h for h in hooks[event_name] if not belongs_to_pack(h, pack_id)
        ]
        removed_count += original_len - len(hooks[event_name])

        # Clean up empty arrays
        if not hooks[event_name]:
            del hooks[event_name]

    if hooks:
        settings["hooks"] = hooks
    elif "hooks" in settings:
        del settings["hooks"]

    save_settings(settings)
    print(f"Removed {removed_count} hook entry/entries for '{pack_id}'")
    return removed_count


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} install <pack_id> <hooks_json>")
        print(f"       {sys.argv[0]} uninstall <pack_id>")
        sys.exit(1)

    action = sys.argv[1]
    pack_id = sys.argv[2]

    if action == "install":
        if len(sys.argv) < 4:
            print("Error: Missing hooks_json argument")
            sys.exit(1)
        hook_entries = json.loads(sys.argv[3])
        install_pack_hooks(pack_id, hook_entries)

    elif action == "uninstall":
        uninstall_pack_hooks(pack_id)

    else:
        print(f"Unknown action: {action}")
        sys.exit(1)


if __name__ == "__main__":
    main()
