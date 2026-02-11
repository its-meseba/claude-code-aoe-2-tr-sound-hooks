#!/usr/bin/env bash
# list.sh - List installed and available sound packs
#
# Usage:
#   ./list.sh               Show all installed and available packs
#   ./list.sh --installed   Show only installed packs
#   ./list.sh --available   Show only available (not installed) packs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ── Argument Parsing ───────────────────────────────────────────────────────────

SHOW_INSTALLED=true
SHOW_AVAILABLE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --installed)   SHOW_AVAILABLE=false; shift ;;
    --available)   SHOW_INSTALLED=false; shift ;;
    --help|-h)
      echo "Usage: ./list.sh [--installed | --available]"
      exit 0
      ;;
    *) fatal "Unknown option: $1" ;;
  esac
done

# ── Installed Packs ───────────────────────────────────────────────────────────

if [[ "$SHOW_INSTALLED" == true ]]; then
  echo -e "${BOLD}Installed sound packs:${NC}"
  echo ""

  FOUND=false
  while IFS='|' read -r pack_id version hooks_count installed; do
    FOUND=true
    printf "  %-30s v%-8s %s hook(s)  installed %s\n" "$pack_id" "$version" "$hooks_count" "$installed"
  done < <(registry_list)

  if [[ "$FOUND" != true ]]; then
    echo "  (none)"
  fi

  echo ""
fi

# ── Available Packs ───────────────────────────────────────────────────────────

if [[ "$SHOW_AVAILABLE" == true ]]; then
  echo -e "${BOLD}Available packs (in this repo):${NC}"
  echo ""

  FOUND=false
  for pack_dir in "$PACKS_DIR"/*/; do
    [[ -d "$pack_dir" ]] || continue
    pack_json="$pack_dir/pack.json"
    [[ -f "$pack_json" ]] || continue

    FOUND=true
    local_id="$(basename "$pack_dir")"
    name="$(read_pack_field "$pack_json" "name")"
    version="$(read_pack_field "$pack_json" "version")"
    description="$(read_pack_field "$pack_json" "description")"

    if is_pack_installed "$local_id" 2>/dev/null; then
      status="${GREEN}installed${NC}"
    else
      status="not installed"
    fi

    printf "  %-30s v%-8s [%b]\n" "$local_id" "$version" "$status"
    echo "    $description"
    echo ""
  done

  if [[ "$FOUND" != true ]]; then
    echo "  (no packs found in $PACKS_DIR/)"
  fi
fi
