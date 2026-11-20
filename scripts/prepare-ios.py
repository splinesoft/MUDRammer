#!/usr/bin/env python3
"""Restore vendored header links when a checkout was copied from Windows."""
from pathlib import Path

RETIRED = {
    "Keys", "ARAnalytics", "HockeySDK-Source", "uservoice-iphone-sdk",
    "TOWebViewController", "SPLUserActivity", "IFTTTLaunchImage", "DAKeyboardControl",
}


def prepare(root):
    pods = (root / "src" / "Pods").resolve()
    repaired = 0
    for header in (pods / "Headers").rglob("*.h"):
        if RETIRED.intersection(header.relative_to(pods / "Headers").parts):
            continue
        if header.is_symlink() or header.stat().st_size > 1024:
            continue
        target = header.read_text(encoding="utf-8").strip()
        if not target.startswith("../") or "\n" in target:
            continue
        resolved = (header.parent / target).resolve()
        if pods not in resolved.parents or not resolved.is_file():
            raise RuntimeError(f"Invalid vendored header link: {header}")
        header.unlink()
        header.symlink_to(target)
        repaired += 1
    for script in (pods / "Target Support Files").rglob("*.sh"):
        content = script.read_bytes()
        if b"\r\n" in content:
            script.write_bytes(content.replace(b"\r\n", b"\n"))
        script.chmod(script.stat().st_mode | 0o111)
    print(f"Vendored dependencies ready ({repaired} header links restored).")


if __name__ == "__main__":
    prepare(Path(__file__).resolve().parent.parent)
