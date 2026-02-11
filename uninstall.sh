#!/usr/bin/env bash
# uninstall.sh - Universal sound pack uninstaller for Claude Code hooks
#
# Usage:
#   ./uninstall.sh <pack-name>           Uninstall a specific pack
#   ./uninstall.sh --all                 Uninstall all sound packs
#   ./uninstall.sh --dry-run <pack-name> Show what would be removed
#   ./uninstall.sh --help                Show help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ── Argument Parsing ───────────────────────────────────────────────────────────

PACK_NAME=""
UNINSTALL_ALL=false
DRY_RUN=false

show_help() {
  cat <<'HELP'
Usage: ./uninstall.sh [OPTIONS] <pack-name>

Uninstall a sound pack from Claude Code hooks.

Arguments:
  <pack-name>         ID of the installed pack to remove

Options:
  --all               Uninstall all installed sound packs
  --dry-run           Show what would be removed without removing
  --help              Show this help message

Examples:
  ./uninstall.sh aoe2-turkish-villager
  ./uninstall.sh --dry-run aoe2-turkish-villager
  ./uninstall.sh --all
HELP
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)    show_help ;;
    --all)        UNINSTALL_ALL=true; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    -*)           fatal "Unknown option: $1. Use --help for usage." ;;
    *)            PACK_NAME="$1"; shift ;;
  esac
done

if [[ "$UNINSTALL_ALL" != true && -z "$PACK_NAME" ]]; then
  fatal "No pack specified. Usage: ./uninstall.sh <pack-name> or --all"
fi

# ── Uninstall Logic ────────────────────────────────────────────────────────────

uninstall_pack() {
  local pack_id="$1"
  local sound_dir="$SOUNDS_DIR/$pack_id"

  # Check if pack is installed
  if ! is_pack_installed "$pack_id" 2>/dev/null && [[ ! -d "$sound_dir" ]]; then
    warn "Pack '$pack_id' is not installed."
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    info "Would remove: $sound_dir/"
    if [[ -d "$sound_dir" ]]; then
      local file_count
      file_count=$(find "$sound_dir" -type f | wc -l | tr -d ' ')
      info "Would remove $file_count sound file(s)"
    fi
    info "Would remove hook entries from $SETTINGS_PATH"
    return 0
  fi

  # Remove hook entries from settings.json
  info "Removing hook entries for '$pack_id'..."
  python3 "$LIB_DIR/merge_settings.py" uninstall "$pack_id"

  # Remove sound files
  if [[ -d "$sound_dir" ]]; then
    local file_count
    file_count=$(find "$sound_dir" -type f | wc -l | tr -d ' ')
    rm -rf "$sound_dir"
    success "Removed $file_count sound file(s) from $sound_dir/"
  fi

  # Update registry
  registry_remove "$pack_id"

  # Clean up empty sounds directory
  if [[ -d "$SOUNDS_DIR" ]] && [[ -z "$(ls -A "$SOUNDS_DIR" 2>/dev/null | grep -v '.registry.json')" ]]; then
    rm -rf "$SOUNDS_DIR"
    info "Cleaned up empty sounds directory"
  fi

  success "Uninstalled: ${BOLD}$pack_id${NC}"
}

# ── Execute ────────────────────────────────────────────────────────────────────

if [[ "$UNINSTALL_ALL" == true ]]; then
  info "Uninstalling all sound packs..."
  echo ""

  FOUND_ANY=false

  while IFS='|' read -r pack_id version hooks_count installed; do
    FOUND_ANY=true
    uninstall_pack "$pack_id"
    echo ""
  done < <(registry_list)

  # Also check for orphaned directories not in registry
  if [[ -d "$SOUNDS_DIR" ]]; then
    for dir in "$SOUNDS_DIR"/*/; do
      [[ -d "$dir" ]] || continue
      local_id="$(basename "$dir")"
      if ! is_pack_installed "$local_id" 2>/dev/null; then
        FOUND_ANY=true
        warn "Found orphaned sound directory: $local_id"
        uninstall_pack "$local_id"
        echo ""
      fi
    done
  fi

  if [[ "$FOUND_ANY" != true ]]; then
    info "No sound packs installed."
  fi
else
  uninstall_pack "$PACK_NAME"
fi

echo ""
echo "Restart Claude Code to apply changes."
