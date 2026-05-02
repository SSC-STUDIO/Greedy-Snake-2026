#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
OUT="_git_status.txt"
: > "$OUT"
git status -sb >> "$OUT" 2>&1
git add -A
echo "--- after add ---" >> "$OUT"
git status -sb >> "$OUT" 2>&1
MSG='feat: waves, hazards, forest/obsidian UI, i18n, docs and tooling

- Add WaveCatalog, TerrainHazardRenderer, LocaleText and language setting
- Forest 2.5d and Obsidian UI assets; CJK font; smoke test asset checks
- Update Main scene, Arena, data catalogs, UI menus, AudioBus, SceneRouter
- Neon snake body textures; responsive layout and UI theme helpers
- tools/build_forest_25d_assets.py; ignore Python __pycache__
- Refresh CLAUDE.md and README for Autoload, settings, run/verify commands'
if git diff --cached --quiet; then
  echo "NOTHING_TO_COMMIT" >> "$OUT"
else
  git commit -m "$MSG" >> "$OUT" 2>&1
  echo "--- after commit ---" >> "$OUT"
  git log -1 --oneline >> "$OUT" 2>&1
fi
