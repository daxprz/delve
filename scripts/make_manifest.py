#!/usr/bin/env python3
"""Write the deployment manifest for a delve release (STO-TOOLS-008).

    scripts/make_manifest.py <version> <bundle-dir>

Describes a build so an installer can decide whether it already has
this version, fetch the right file for its platform, verify it, and
know what to run. The contract is documented in README.md under
"Deployment bundle" — treat that as the spec and this as its
implementation.
"""
import datetime
import hashlib
import json
import os
import sys

SCHEMA = 1

# platform -> (archive name, what to launch once unpacked)
PLATFORMS = {
    "linux": ("delve-linux.zip", "delve.x86_64"),
    "windows": ("delve-windows.zip", "delve.exe"),
    "macos": ("delve-macos.zip", "Delve.app"),
}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def build(version, bundle_dir):
    platforms = {}
    for plat, (fname, entry) in PLATFORMS.items():
        path = os.path.join(bundle_dir, fname)
        if not os.path.exists(path):
            continue  # a platform may be missing if its export failed
        platforms[plat] = {
            "file": fname,
            "sha256": sha256(path),
            "size": os.path.getsize(path),
            "entry": entry,
        }
    return {
        "schema": SCHEMA,
        "game": "delve",
        "version": version,
        "released": datetime.datetime.now(datetime.timezone.utc)
        .strftime("%Y-%m-%dT%H:%M:%SZ"),
        "default_port": 7777,
        "platforms": platforms,
    }


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    version, bundle_dir = sys.argv[1], sys.argv[2]
    manifest = build(version, bundle_dir)
    if not manifest["platforms"]:
        print("ERROR: no platform archives found in %s" % bundle_dir,
              file=sys.stderr)
        return 1
    out = os.path.join(bundle_dir, "manifest.json")
    with open(out, "w") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
