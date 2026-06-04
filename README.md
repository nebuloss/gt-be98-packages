# gt-be98-packages

Hosting for **proprietary / custom package sources and firmware blobs** the
GT-BE98 Buildroot build needs but can't fetch from any public upstream — Broadcom
wireless firmware (`rtecdc.bin`), the `wl`/`dhd` drivers, the asus `httpd` +
prebuilt `web-broadcom_private.o`, nvram defaults, bootloader bits, etc.

Part of the GT-BE98 repo family (see **[ARCHITECTURE.md](ARCHITECTURE.md)**):

| Repo | Role |
|------|------|
| `gt-be98-firmware`   | Current merlin SDK build (source of the blobs). |
| `gt-be98-buildroot`  | Buildroot external tree; its `package/*` recipes fetch from here. |
| `gt-be98-toolchain`  | Prebuilt cross-toolchain. |
| **`gt-be98-packages`** | **This repo — custom source/blob hosting.** |

## How it works

- `manifests/<pkg>.yaml` — one per package: what it is, license, which paths in a
  **built** `gt-be98-firmware` tree it comes from, and its Release asset + sha256.
- `scripts/package-blob.sh manifests/<pkg>.yaml` — tars those paths into a
  versioned tarball and prints its sha256.
- The tarball is published as a **GitHub Release asset** (not committed). The
  matching Buildroot recipe in `gt-be98-buildroot/package/<pkg>/` sets
  `<PKG>_SITE` to the release URL and `<PKG>_HASH` to the sha256.

> Why Releases, not Git LFS: Buildroot fetches by URL, and Releases avoid LFS
> bandwidth quotas. `.gitattributes` keeps LFS available as a fallback only.

## Licensing

These are **proprietary, non-redistributable** Broadcom/ASUS artifacts extracted
from the vendor SDK. Keep this repo **private** (or host the assets somewhere
access-controlled). Each manifest records `license:` and `redistribute:`.

## First package

`manifests/gt-be98-dhd-firmware.yaml` — the dhd wireless firmware (rtecdc.bin for
6717a0 + 6726b0). See `AGENTS.md` for the workflow.
