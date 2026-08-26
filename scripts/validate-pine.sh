#!/usr/bin/env bash
# Validates .pine files against docs/STYLE_GUIDE.md: kebab-case filenames,
# the MPL 2.0 license header, the //@version=6 pragma, a Version: comment,
# and (for indicators/strategies) the Title:/Description: banner, or (for
# libraries) the @description/@function annotations.
#
# Run from the repo root: ./scripts/validate-pine.sh
set -euo pipefail

# Scripts that predate the style guide and are not yet migrated (skips every check).
LEGACY_EXCLUDES=(
  "indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine"
)

# JungleeFrogs-branded scripts intentionally keep the PascalCase filename that
# matches their TradingView publish name, rather than this repo's kebab-case
# convention - everything else about them (header, Version, Title/Description)
# still has to pass, so only the filename-format check is skipped for these.
FILENAME_ONLY_EXCLUDES=(
  "indicators/JungleeFrogs/EMA-HL-PRESSURE-MATRIX/JungleeFrogs_EMA_HighLow_Pressure_Matrix.pine"
)

is_excluded() {
  local f="$1"
  for ex in "${LEGACY_EXCLUDES[@]}"; do
    [[ "$f" == "$ex" ]] && return 0
  done
  return 1
}

is_filename_only_excluded() {
  local f="$1"
  for ex in "${FILENAME_ONLY_EXCLUDES[@]}"; do
    [[ "$f" == "$ex" ]] && return 0
  done
  return 1
}

fail=0
checked=0

while IFS= read -r -d '' file; do
  rel="${file#./}"
  is_excluded "$rel" && continue
  checked=$((checked + 1))

  base="$(basename "$rel")"
  name="${base%.pine}"

  if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] && ! is_filename_only_excluded "$rel"; then
    echo "::error file=$rel::filename must be kebab-case (e.g. my-script.pine)"
    fail=1
  fi

  if ! grep -q "Mozilla Public License 2.0" "$file"; then
    echo "::error file=$rel::missing MPL 2.0 license header"
    fail=1
  fi

  if ! grep -q "^//@version=6" "$file"; then
    echo "::error file=$rel::missing //@version=6 pragma"
    fail=1
  fi

  if ! grep -q "Version:" "$file"; then
    echo "::error file=$rel::missing a 'Version:' comment for changelog tracking"
    fail=1
  fi

  if [[ "$rel" == libraries/* ]]; then
    if ! grep -q "@description" "$file"; then
      echo "::error file=$rel::library is missing an @description annotation"
      fail=1
    fi
    if ! grep -q "@function" "$file"; then
      echo "::error file=$rel::library has no @function-documented exports"
      fail=1
    fi
  else
    for field in "Title:" "Description:"; do
      if ! grep -q "$field" "$file"; then
        echo "::error file=$rel::missing '$field' in header block"
        fail=1
      fi
    done
  fi
done < <(find indicators strategies libraries -name '*.pine' -print0)

echo "Checked $checked file(s), excluded ${#LEGACY_EXCLUDES[@]} legacy file(s) and ${#FILENAME_ONLY_EXCLUDES[@]} filename-only exception(s)."
if [[ $fail -eq 0 ]]; then
  echo "All Pine scripts follow docs/STYLE_GUIDE.md."
fi
exit $fail
