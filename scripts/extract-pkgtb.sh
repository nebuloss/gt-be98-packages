#!/usr/bin/env bash
# Extract the bootfs (.itb) and rootfs (squashfs) out of a GT-BE98 .pkgtb
# bundle into a staging dir, so package-blob.sh can package them as Release
# assets. This is how blobs are derived from a VALIDATED flashable artifact
# (e.g. gt-be98-firmware/artifacts-0031/) instead of from a loose vendor-tree
# build, guaranteeing the packaged blobs are byte-identical to what the device
# actually runs.
#
# Usage:
#   scripts/extract-pkgtb.sh <image.pkgtb> <staging_dir> [dumpimage]
#
#   <staging_dir> receives:
#     bcm96813GW_uboot_linux.itb   (bootfs FIT: ATF+U-Boot+kernel+DTBs+OP-TEE)
#     rootfs.img                   (squashfs root filesystem)
#   (names match what the gt-be98-bootfs / gt-be98-rootfs Buildroot recipes
#    look for). Pass the staging dir's PARENT as FIRMWARE_ROOT to
#   package-blob.sh, with manifest source_paths pointing inside it.
#
#   [dumpimage] defaults to $DUMPIMAGE, then a Buildroot host dumpimage if
#   found next door, then PATH.
set -euo pipefail

PKGTB="${1:?usage: extract-pkgtb.sh <image.pkgtb> <staging_dir> [dumpimage]}"
STAGE="${2:?usage: extract-pkgtb.sh <image.pkgtb> <staging_dir> [dumpimage]}"
DI="${3:-${DUMPIMAGE:-}}"

if [[ -z "$DI" ]]; then
    for c in "$(dirname "$0")/../../buildroot/output/host/bin/dumpimage" dumpimage; do
        if command -v "$c" >/dev/null 2>&1; then DI="$c"; break; fi
    done
fi
[[ -n "$DI" ]] || { echo "ERROR: no dumpimage found (install u-boot-tools or pass one)" >&2; exit 1; }
[[ -f "$PKGTB" ]] || { echo "ERROR: pkgtb not found: $PKGTB" >&2; exit 1; }

mkdir -p "$STAGE"

# Locate the image indices by type rather than trusting fixed positions.
LIST="$("$DI" -l "$PKGTB")"
idx_of() { # $1 = Type substring
    echo "$LIST" | awk -v t="$1" '
        /^ Image [0-9]+/ {i=$2+0}
        /^  Type:/ && index($0,t) {print i; exit}'
}
BOOT_IDX="$(idx_of 'Multi-File')"
ROOT_IDX="$(idx_of 'Filesystem')"
[[ -n "$BOOT_IDX" && -n "$ROOT_IDX" ]] || {
    echo "ERROR: could not locate bootfs/rootfs images in FIT:" >&2
    echo "$LIST" >&2; exit 1; }

"$DI" -T flat_dt -p "$BOOT_IDX" -o "$STAGE/bcm96813GW_uboot_linux.itb" "$PKGTB" >/dev/null
"$DI" -T flat_dt -p "$ROOT_IDX" -o "$STAGE/rootfs.img" "$PKGTB" >/dev/null

echo "Extracted from $(basename "$PKGTB") (image $BOOT_IDX=bootfs, $ROOT_IDX=rootfs):"
sha256sum "$STAGE/bcm96813GW_uboot_linux.itb" "$STAGE/rootfs.img"
