# Agent handoff — gt-be98-packages

You're working in the **proprietary source/blob hosting** repo for the GT-BE98
Buildroot build. Read `gt-be98-buildroot/ARCHITECTURE.md` first (canonical copy).

## State (2026-06-04)

- Manifest-driven. One example: `manifests/gt-be98-dhd-firmware.yaml`.
- `scripts/package-blob.sh` extracts a manifest's `source_paths` from a built
  `gt-be98-firmware` tree into a tarball + sha256.
- No blobs committed yet — they become **GitHub Release assets**.
- LFS available (`.gitattributes`) as a fallback only; prefer Releases.

## Workflow to add/produce a package

1. Ensure `../gt-be98-firmware` is **built** (it has the blobs under
   `vendor/.../targets/96813GW/fs.install/...`).
2. Write `manifests/<pkg>.yaml` (copy the dhd example): set `source_paths` to the
   paths inside the firmware tree, pick a `release_tag` + `asset` name.
3. Run `scripts/package-blob.sh manifests/<pkg>.yaml` → tarball in `output/` +
   sha256. Paste the sha256 back into the manifest.
4. Publish: `gh release create <tag> output/<asset> --repo nebuloss/gt-be98-packages`.
5. Add the matching recipe in `gt-be98-buildroot/package/<pkg>/` (see that repo's
   `package/README.md` template) with `<PKG>_SITE` = the release URL and the hash.

## Priority blobs (from the verified merlin image)

- **dhd firmware** — `rom/etc/wlan/dhd` (rtecdc.bin 6717a0/6726b0). [example exists]
- **wl / dhd drivers** — kernel modules + userspace `wl`, `dhd`.
- **httpd** — asus web UI + prebuilt `web-broadcom_private.o` (no source).
- **nvram** — `libnvram.so` + nvram defaults.
- bootloader/ATF + the `.itb`/`.pkgtb` tooling (may live with board support).

Use `gt-be98-firmware/tools/verify-artifact.sh` as the component checklist.

## Licensing — important

Proprietary, non-redistributable. Keep this repo **private** or host assets
access-controlled. Don't push these blobs to a public repo.
