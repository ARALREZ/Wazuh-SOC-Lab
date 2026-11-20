#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MODE="${1:---dry-run}"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--apply" ]]; then
  echo "Usage: $0 [--dry-run|--apply]" >&2
  exit 2
fi

if [[ ! -f "$PROJECT_ROOT/README.md" || ! -d "$PROJECT_ROOT/evidence" || ! -d "$PROJECT_ROOT/wazuh" ]]; then
  echo "[ERROR] This does not look like Project 03: $PROJECT_ROOT" >&2
  exit 1
fi

if [[ "$MODE" == "--dry-run" ]]; then
  echo "[DRY-RUN] No files will be changed. Run with --apply after reviewing this plan."
else
  echo "[APPLY] Moving retired artifacts to archive and removing only generated/empty placeholders."
fi

move_archive() {
  local src="$1" dest="$2"
  [[ -e "$PROJECT_ROOT/$src" ]] || return 0
  if [[ -e "$PROJECT_ROOT/$dest" ]]; then
    echo "[STOP] Destination already exists; resolve manually: $dest" >&2
    exit 1
  fi
  echo "[MOVE] $src -> $dest"
  if [[ "$MODE" == "--apply" ]]; then
    mkdir -p -- "$PROJECT_ROOT/$(dirname -- "$dest")"
    mv -- "$PROJECT_ROOT/$src" "$PROJECT_ROOT/$dest"
  fi
}

remove_generated_cache() {
  local path="tests/integration/__pycache__"
  [[ -d "$PROJECT_ROOT/$path" ]] || return 0
  echo "[REMOVE GENERATED CACHE] $path"
  if [[ "$MODE" == "--apply" ]]; then
    rm -rf -- "$PROJECT_ROOT/$path"
  fi
}

remove_gitkeep_dir() {
  local dir="$1"
  [[ -d "$PROJECT_ROOT/$dir" ]] || return 0
  local unexpected
  unexpected="$(find "$PROJECT_ROOT/$dir" -mindepth 1 -maxdepth 1 ! -name .gitkeep -print -quit)"
  if [[ -n "$unexpected" ]]; then
    echo "[KEEP] $dir contains real content: ${unexpected#"$PROJECT_ROOT/"}"
    return 0
  fi
  if [[ -f "$PROJECT_ROOT/$dir/.gitkeep" ]]; then
    echo "[REMOVE PLACEHOLDER] $dir/.gitkeep"
    if [[ "$MODE" == "--apply" ]]; then rm -- "$PROJECT_ROOT/$dir/.gitkeep"; fi
  fi
  echo "[RMDIR IF EMPTY] $dir"
  if [[ "$MODE" == "--apply" ]]; then rmdir -- "$PROJECT_ROOT/$dir" 2>/dev/null || true; fi
}

move_archive "README-step4.md" "archive/step4-migration/README-step4-original.md"
move_archive "reports/test-results-step4.md" "archive/step4-migration/test-results-step4-original.md"
move_archive "reports/test-results-step4-template.md" "archive/step4-migration/test-results-step4-template-original.md"
move_archive "wazuh/rules/fim_system_tampering_rules.xml.pre-scope-fix" "archive/legacy-configuration/fim_system_tampering_rules.xml.pre-scope-fix"
move_archive "scripts/response/project03-quarantine" "archive/legacy-active-response/project03-quarantine-wrapper.py"
move_archive "sample-logs/README.md" "archive/step4-migration/sample-logs-README-original.md"

remove_generated_cache
remove_gitkeep_dir "tests/boundary"
remove_gitkeep_dir "tests/positive"
remove_gitkeep_dir "tests/negative"
remove_gitkeep_dir "evidence/screenshots"
remove_gitkeep_dir "tests/fixtures"
remove_gitkeep_dir "tests/integration"
remove_gitkeep_dir "evidence/alerts"
remove_gitkeep_dir "evidence/whodata"

for dir in scripts/maintenance scripts/simulation sample-logs; do
  if [[ -d "$PROJECT_ROOT/$dir" ]]; then
    echo "[RMDIR IF EMPTY] $dir"
    if [[ "$MODE" == "--apply" ]]; then rmdir -- "$PROJECT_ROOT/$dir" 2>/dev/null || true; fi
  fi
done

echo "[DONE] Cleanup plan complete. No rule XML, live quarantine script, test fixtures, screenshots or raw evidence were deleted."
