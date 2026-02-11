#!/usr/bin/env bash
# common.sh - Shared utilities for Awesome Claude Code Sounds
# Sourced by install.sh, uninstall.sh, and list.sh

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────

SOUNDS_DIR="$HOME/.claude/hooks/sounds"
SETTINGS_PATH="$HOME/.claude/settings.json"
REGISTRY_PATH="$SOUNDS_DIR/.registry.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKS_DIR="$SCRIPT_DIR/packs"
LIB_DIR="$SCRIPT_DIR/lib"

VALID_HOOK_EVENTS=(
  "SessionStart"
  "UserPromptSubmit"
  "PreToolUse"
  "PermissionRequest"
  "PostToolUse"
  "PostToolUseFailure"
  "Notification"
  "SubagentStart"
  "SubagentStop"
  "Stop"
  "TeammateIdle"
  "TaskCompleted"
  "PreCompact"
  "SessionEnd"
)

VALID_SOUND_EXTENSIONS=("mp3" "wav" "ogg")

MAX_SOUND_FILE_SIZE=512000  # 500KB in bytes

# ── Colors ─────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Logging ────────────────────────────────────────────────────────────────────

info() {
  echo -e "${BLUE}info${NC}  $*"
}

success() {
  echo -e "${GREEN}ok${NC}    $*"
}

warn() {
  echo -e "${YELLOW}warn${NC}  $*"
}

error() {
  echo -e "${RED}err${NC}   $*" >&2
}

fatal() {
  error "$@"
  exit 1
}

# ── Platform Detection ─────────────────────────────────────────────────────────

detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

detect_play_command() {
  local platform
  platform="$(detect_platform)"

  case "$platform" in
    macos)
      echo "afplay"
      ;;
    linux|wsl)
      if command -v paplay &>/dev/null; then
        echo "paplay"
      elif command -v aplay &>/dev/null; then
        echo "aplay"
      elif command -v mpg123 &>/dev/null; then
        echo "mpg123"
      elif command -v ffplay &>/dev/null; then
        echo "ffplay -nodisp -autoexit"
      else
        echo ""
      fi
      ;;
    *)
      echo ""
      ;;
  esac
}

require_play_command() {
  local play_cmd
  play_cmd="$(detect_play_command)"

  if [[ -z "$play_cmd" ]]; then
    local platform
    platform="$(detect_platform)"
    error "No supported audio player found."
    echo ""
    echo "Install one of: paplay, aplay, mpg123, ffplay"
    case "$platform" in
      linux)
        echo "  Ubuntu/Debian: sudo apt install pulseaudio-utils"
        echo "  Fedora:        sudo dnf install pulseaudio-utils"
        echo "  Arch:          sudo pacman -S libpulse"
        ;;
      wsl)
        echo "  WSL: sudo apt install pulseaudio-utils"
        ;;
    esac
    exit 1
  fi

  echo "$play_cmd"
}

# ── Validation ─────────────────────────────────────────────────────────────────

validate_pack_id() {
  local pack_id="$1"
  if [[ ! "$pack_id" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
    fatal "Invalid pack ID '$pack_id'. Must be lowercase alphanumeric with hyphens, min 2 chars."
  fi
}

validate_pack_dir() {
  local pack_dir="$1"

  if [[ ! -d "$pack_dir" ]]; then
    fatal "Pack directory not found: $pack_dir"
  fi

  if [[ ! -f "$pack_dir/pack.json" ]]; then
    fatal "No pack.json found in $pack_dir"
  fi
}

validate_hook_event() {
  local event="$1"
  for valid in "${VALID_HOOK_EVENTS[@]}"; do
    if [[ "$event" == "$valid" ]]; then
      return 0
    fi
  done
  return 1
}

validate_sound_extension() {
  local file="$1"
  local ext="${file##*.}"
  ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  for valid in "${VALID_SOUND_EXTENSIONS[@]}"; do
    if [[ "$ext" == "$valid" ]]; then
      return 0
    fi
  done
  return 1
}

# ── Pack JSON Helpers ──────────────────────────────────────────────────────────

read_pack_field() {
  local pack_json="$1"
  local field="$2"
  python3 -c "
import json, sys
with open('$pack_json') as f:
    data = json.load(f)
val = data.get('$field', '')
if isinstance(val, list):
    print(' '.join(val))
else:
    print(val)
"
}

read_pack_sounds() {
  local pack_json="$1"
  python3 -c "
import json
with open('$pack_json') as f:
    data = json.load(f)
for key, val in data.get('sounds', {}).items():
    print(f\"{key}|{val['file']}|{val.get('label', '')}\")
"
}

read_pack_hooks() {
  local pack_json="$1"
  python3 -c "
import json
with open('$pack_json') as f:
    data = json.load(f)
for event, cfg in data.get('hooks', {}).items():
    sounds = ','.join(cfg.get('sounds', []))
    matcher = cfg.get('matcher', '')
    print(f'{event}|{sounds}|{matcher}')
"
}

# ── Hook Command Generation ───────────────────────────────────────────────────

generate_hook_command() {
  local play_cmd="$1"
  local sound_dir="$2"
  shift 2
  local files=("$@")

  local files_str=""
  for f in "${files[@]}"; do
    files_str+="\"${f}\" "
  done

  # Background playback with & so the hook exits immediately
  echo "bash -c 'f=(${files_str}); ${play_cmd} \"${sound_dir}/\${f[\$RANDOM % \${#f[@]}]}\" &'"
}

# ── Registry ───────────────────────────────────────────────────────────────────

ensure_registry() {
  mkdir -p "$(dirname "$REGISTRY_PATH")"
  if [[ ! -f "$REGISTRY_PATH" ]]; then
    echo '{}' > "$REGISTRY_PATH"
  fi
}

registry_add() {
  local pack_id="$1"
  local version="$2"
  local hooks_list="$3"  # comma-separated

  ensure_registry
  python3 -c "
import json
from datetime import datetime, timezone

path = '$REGISTRY_PATH'
with open(path) as f:
    reg = json.load(f)

reg['$pack_id'] = {
    'version': '$version',
    'installed_at': datetime.now(timezone.utc).isoformat(),
    'hooks': '$hooks_list'.split(',')
}

with open(path, 'w') as f:
    json.dump(reg, f, indent=2)
    f.write('\n')
"
}

registry_remove() {
  local pack_id="$1"

  [[ ! -f "$REGISTRY_PATH" ]] && return 0

  python3 -c "
import json

path = '$REGISTRY_PATH'
with open(path) as f:
    reg = json.load(f)

reg.pop('$pack_id', None)

with open(path, 'w') as f:
    json.dump(reg, f, indent=2)
    f.write('\n')
"
}

registry_list() {
  [[ ! -f "$REGISTRY_PATH" ]] && return 0

  python3 -c "
import json

path = '$REGISTRY_PATH'
with open(path) as f:
    reg = json.load(f)

for pack_id, info in reg.items():
    version = info.get('version', '?')
    hooks = info.get('hooks', [])
    installed = info.get('installed_at', '?')[:10]
    print(f'{pack_id}|{version}|{len(hooks)}|{installed}')
"
}

is_pack_installed() {
  local pack_id="$1"
  [[ -f "$REGISTRY_PATH" ]] || return 1

  python3 -c "
import json, sys
with open('$REGISTRY_PATH') as f:
    reg = json.load(f)
sys.exit(0 if '$pack_id' in reg else 1)
"
}
