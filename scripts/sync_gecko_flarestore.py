#!/usr/bin/env python3
"""Publish the newly built Gecko IPA into both FlareStore feed aliases.

Run only after GitHub has published the named IPA release asset.
Never modify the separate native MusicKit/WebKit prototype's app listing.
"""
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

BUNDLE_ID = "com.soum91.applemusictimbre.gecko"


def synchronize(path: Path, args: argparse.Namespace) -> None:
    catalog = json.loads(path.read_text(encoding="utf-8"))
    candidates = [app for app in catalog["apps"] if app.get("bundleIdentifier") == BUNDLE_ID]
    if len(candidates) != 1:
        raise ValueError(f"{path}: expected exactly one Gecko app, got {len(candidates)}")
    app = candidates[0]
    item = {
        "version": args.version,
        "buildVersion": args.build,
        "date": args.date,
        "localizedDescription": args.notes,
        "changelog": args.notes,
        "downloadURL": args.download_url,
        "size": args.size,
        "minOSVersion": "18.0",
    }
    previous = [v for v in app.get("versions", [])
                if not (v.get("version") == args.version and v.get("buildVersion") == args.build)]
    app["versions"] = [item] + previous
    app.update({
        "version": args.version,
        "buildVersion": args.build,
        "versionDate": args.date,
        "versionDescription": args.notes,
        "downloadURL": args.download_url,
        "size": args.size,
        "minOSVersion": "18.0",
    })
    catalog["sourceURL"] = "https://raw.githubusercontent.com/soum91/apple-music-with-timbre/main/repo.json"
    path.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--download-url", required=True)
    parser.add_argument("--size", required=True, type=int)
    parser.add_argument("--notes", required=True)
    parser.add_argument("--date", default=datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"))
    args = parser.parse_args()
    if args.size <= 0 or not args.download_url.startswith("https://github.com/soum91/apple-music-with-timbre/releases/download/"):
        parser.error("size must be positive and the asset URL must be a public GitHub release URL")
    for name in ("repo.json", "source.json"):
        synchronize(Path(name), args)
