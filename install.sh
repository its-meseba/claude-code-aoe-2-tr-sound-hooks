#!/usr/bin/env bash
# install.sh - Universal sound pack installer for Claude Code hooks
#
# Usage:
#   ./install.sh <pack-name>              Install a pack from ./packs/
#   ./install.sh --path /some/dir         Install from arbitrary path
#   ./install.sh --dry-run <pack-name>    Validate without installing
#   ./install.sh --force <pack-name>      Overwrite existing installation
#   ./install.sh --help                   Show help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ── Argument Parsing ───────────────────────────────────────────────────────────

PACK_NAME=""
PACK_PATH=""
DRY_RUN=false
FORCE=false

show_help() {
  cat <<'HELP'
Usage: ./install.sh [OPTIONS] <pack-name>

Install a sound pack for Claude Code hooks.

Arguments:
  <pack-name>         Name of a pack in ./packs/ directory

Options:
  --path <dir>        Install from an arbitrary directory instead of ./packs/
  --dry-run           Validate the pack without installing
  --force             Overwrite an existing installation
  --help              Show this help message

Examples:
  ./install.sh aoe2-turkish-villager
  ./install.sh --dry-run aoe2-turkish-villager
  ./install.sh --force aoe2-turkish-villager
  ./install.sh --path ~/my-custom-pack
HELP
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)    show_help ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --force)      FORCE=true; shift ;;
    --path)       PACK_PATH="$2"; shift 2 ;;
    -*)           fatal "Unknown option: $1. Use --help for usage." ;;
    *)            PACK_NAME="$1"; shift ;;
  esac
done

# Resolve pack directory
if [[ -n "$PACK_PATH" ]]; then
  PACK_DIR="$PACK_PATH"
elif [[ -n "$PACK_NAME" ]]; then
  PACK_DIR="$PACKS_DIR/$PACK_NAME"
else
  fatal "No pack specified. Usage: ./install.sh <pack-name>"
fi

# ── Validation ─────────────────────────────────────────────────────────────────

info "Validating pack..."

validate_pack_dir "$PACK_DIR"

PACK_JSON="$PACK_DIR/pack.json"
PACK_ID="$(read_pack_field "$PACK_JSON" "id")"
PACK_DISPLAY_NAME="$(read_pack_field "$PACK_JSON" "name")"
PACK_VERSION="$(read_pack_field "$PACK_JSON" "version")"

validate_pack_id "$PACK_ID"

# Verify ID matches directory name (when using packs/ dir)
if [[ -n "$PACK_NAME" && "$PACK_ID" != "$PACK_NAME" ]]; then
  fatal "Pack ID '$PACK_ID' in pack.json does not match directory name '$PACK_NAME'"
fi

# Validate all sound files exist and have valid extensions
SOUND_COUNT=0
ERRORS=0

while IFS='|' read -r key file label; do
  sound_path="$PACK_DIR/$file"
  if [[ ! -f "$sound_path" ]]; then
    error "Sound file not found: $file (key: $key)"
    ((ERRORS++))
  elif ! validate_sound_extension "$file"; then
    error "Unsupported format: $file (use mp3, wav, or ogg)"
    ((ERRORS++))
  else
    file_size=$(wc -c < "$sound_path")
    if [[ $file_size -gt $MAX_SOUND_FILE_SIZE ]]; then
      warn "Sound file '$file' is $(( file_size / 1024 ))KB (recommended max: 500KB)"
    fi
  fi
  ((SOUND_COUNT++))
done < <(read_pack_sounds "$PACK_JSON")

if [[ $SOUND_COUNT -eq 0 ]]; then
  fatal "No sounds defined in pack.json"
fi

# Validate hook event names and sound references
HOOK_COUNT=0
HOOK_EVENTS=""

while IFS='|' read -r event sounds matcher; do
  if ! validate_hook_event "$event"; then
    error "Invalid hook event: '$event'"
    ((ERRORS++))
  fi
  HOOK_EVENTS="${HOOK_EVENTS}${event},"
  ((HOOK_COUNT++))
done < <(read_pack_hooks "$PACK_JSON")

# Remove trailing comma
HOOK_EVENTS="${HOOK_EVENTS%,}"

if [[ $HOOK_COUNT -eq 0 ]]; then
  fatal "No hooks defined in pack.json"
fi

if [[ $ERRORS -gt 0 ]]; then
  fatal "Validation failed with $ERRORS error(s)"
fi

success "Validated: $PACK_DISPLAY_NAME v$PACK_VERSION ($SOUND_COUNT sounds, $HOOK_COUNT hooks)"

# ── Check Conflicts ────────────────────────────────────────────────────────────

TARGET_SOUND_DIR="$SOUNDS_DIR/$PACK_ID"

if is_pack_installed "$PACK_ID" 2>/dev/null && [[ "$FORCE" != true ]]; then
  fatal "Pack '$PACK_ID' is already installed. Use --force to reinstall."
fi

# ── Dry Run Exit ───────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" == true ]]; then
  info "Dry run complete. Pack is valid and ready to install."
  echo ""
  echo "  Pack:    $PACK_DISPLAY_NAME"
  echo "  ID:      $PACK_ID"
  echo "  Version: $PACK_VERSION"
  echo "  Sounds:  $SOUND_COUNT"
  echo "  Hooks:   $HOOK_EVENTS"
  echo ""
  echo "Run without --dry-run to install."
  exit 0
fi

# ── Detect Platform ────────────────────────────────────────────────────────────

PLAY_CMD="$(require_play_command)"
info "Audio player: $PLAY_CMD ($(detect_platform))"

# ── Copy Sound Files ───────────────────────────────────────────────────────────

info "Copying sounds to $TARGET_SOUND_DIR/"

mkdir -p "$TARGET_SOUND_DIR"

while IFS='|' read -r key file label; do
  src="$PACK_DIR/$file"
  dest_filename="$(basename "$file")"
  cp "$src" "$TARGET_SOUND_DIR/$dest_filename"
done < <(read_pack_sounds "$PACK_JSON")

success "Copied $SOUND_COUNT sound file(s)"

# ── Generate Hook Commands ─────────────────────────────────────────────────────

info "Generating hook commands..."

# Build a JSON object of hook entries for merge_settings.py
HOOKS_JSON=$(PACK_JSON="$PACK_JSON" PACK_ID="$PACK_ID" PLAY_CMD="$PLAY_CMD" python3 << 'PYEOF'
import json
import os

pack_json_path = os.environ["PACK_JSON"]
pack_id = os.environ["PACK_ID"]
play_cmd = os.environ["PLAY_CMD"]

sound_dir = "$HOME/.claude/hooks/sounds/" + pack_id

with open(pack_json_path) as f:
    pack = json.load(f)

sounds_map = {}
for key, val in pack.get("sounds", {}).items():
    sounds_map[key] = os.path.basename(val["file"])

hooks_json = {}
for event, cfg in pack.get("hooks", {}).items():
    sound_keys = cfg.get("sounds", [])
    files = [sounds_map[k] for k in sound_keys if k in sounds_map]

    files_str = " ".join('"' + f + '"' for f in files)
    command = (
        "bash -c 'f=(" + files_str + "); "
        + play_cmd + ' "' + sound_dir
        + '/${f[$RANDOM % ${#f[@]}]}" &' + "'"
    )

    entry = {"command": command}
    matcher = cfg.get("matcher", "")
    if matcher:
        entry["matcher"] = matcher

    hooks_json[event] = entry

print(json.dumps(hooks_json))
PYEOF
)

# ── Merge Into Settings ────────────────────────────────────────────────────────

info "Merging hooks into $SETTINGS_PATH..."

python3 "$LIB_DIR/merge_settings.py" install "$PACK_ID" "$HOOKS_JSON"

# ── Update Registry ────────────────────────────────────────────────────────────

registry_add "$PACK_ID" "$PACK_VERSION" "$HOOK_EVENTS"

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
success "Installed: ${BOLD}$PACK_DISPLAY_NAME${NC} v$PACK_VERSION"
echo ""
echo "  Sounds: $TARGET_SOUND_DIR/ ($SOUND_COUNT files)"
echo "  Hooks:  $HOOK_EVENTS"
echo ""
echo "  Restart Claude Code to activate."
echo -e "  Run ${BOLD}./uninstall.sh $PACK_ID${NC} to remove."
