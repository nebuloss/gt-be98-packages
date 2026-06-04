#!/usr/bin/env bash
# Package a proprietary blob/source out of a built gt-be98-firmware tree into a
# tarball (a future GitHub Release asset for gt-be98-packages), using a manifest.
#
# Usage:
#   scripts/package-blob.sh manifests/<pkg>.yaml [FIRMWARE_ROOT] [OUT_DIR]
#
#   FIRMWARE_ROOT  path to a gt-be98-firmware checkout that has been BUILT
#                  (default: ../gt-be98-firmware)
#   OUT_DIR        where to write the tarball (default: ./output)
#
# Reads `source_paths:`, `asset:` and `sha256:` keys from the manifest (simple
# line grep — no YAML lib). Prints the sha256 to paste back into the manifest.
set -euo pipefail

MANIFEST="${1:?usage: package-blob.sh manifests/<pkg>.yaml [FIRMWARE_ROOT] [OUT_DIR]}"
FW="${2:-$(cd "$(dirname "$0")/../../gt-be98-firmware" 2>/dev/null && pwd)}"
OUT_DIR="${3:-$(cd "$(dirname "$0")/.." && pwd)/output}"

[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found: $MANIFEST" >&2; exit 1; }
[[ -d "$FW" ]]       || { echo "ERROR: firmware root not found: $FW" >&2; exit 1; }

ASSET="$(grep -E '^asset:' "$MANIFEST" | head -1 | sed 's/^asset:[[:space:]]*//')"
[[ -n "$ASSET" ]] || { echo "ERROR: manifest has no asset:" >&2; exit 1; }

# Collect source_paths (lines after 'source_paths:' starting with '- ').
mapfile -t PATHS < <(awk '
    /^source_paths:/ {grab=1; next}
    grab && /^[[:space:]]*-[[:space:]]/ {sub(/^[[:space:]]*-[[:space:]]*/,""); print; next}
    grab && /^[^[:space:]-]/ {grab=0}
' "$MANIFEST")
[[ ${#PATHS[@]} -gt 0 ]] || { echo "ERROR: no source_paths in manifest" >&2; exit 1; }

mkdir -p "$OUT_DIR"
STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT

echo "Firmware : $FW"
echo "Asset    : $ASSET"
for p in "${PATHS[@]}"; do
    src="${FW}/${p}"
    if [[ ! -e "$src" ]]; then
        echo "ERROR: source path missing (is the firmware built?): $p" >&2
        exit 1
    fi
    echo "  + $p"
    mkdir -p "${STAGE}/$(dirname "$p")"
    cp -a "$src" "${STAGE}/${p}"
done

TARBALL="${OUT_DIR}/${ASSET}"
# Reproducible tarball: fixed mtime/owner and sorted names + gzip -n (no name/
# timestamp) so the sha256 is stable across machines and matches the committed
# recipe hash. (Requires GNU tar.)
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -C "$STAGE" -cf - . | gzip -n > "$TARBALL"
SHA="$(sha256sum "$TARBALL" | cut -d' ' -f1)"

echo
echo "Wrote: $TARBALL ($(du -h "$TARBALL" | cut -f1))"
echo "sha256: $SHA"
echo
echo "Next: set 'sha256: ${SHA}' in ${MANIFEST}, then upload as a Release asset:"
echo "  gh release create <tag> '$TARBALL' --repo nebuloss/gt-be98-packages"
