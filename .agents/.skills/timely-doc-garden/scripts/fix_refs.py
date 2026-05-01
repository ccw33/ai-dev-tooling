#!/usr/bin/env python3
"""Doc Garden Phase 3: Auto-fix reference shifts and path renames.

Reads scan-result.json from Phase 1, attempts to fix broken/shifted
references by finding the correct line or path.

Usage:
    python3 fix_refs.py --project-root . --dry-run    # Preview fixes
    python3 fix_refs.py --project-root . --apply       # Apply fixes
"""

import argparse
import json
import re
import sys
from pathlib import Path


def find_best_line(file_path: Path, original_content: str) -> int | None:
    """Find the best matching line number for a reference whose line shifted."""
    if not file_path.exists():
        return None

    try:
        lines = file_path.read_text(encoding="utf-8", errors="replace").splitlines()
    except (OSError, UnicodeDecodeError):
        return None

    if not original_content:
        return None

    # Normalize for comparison
    normalized = original_content.strip()
    if len(normalized) < 10:
        return None  # Too short to match reliably

    # Exact match first
    for i, line in enumerate(lines):
        if line.strip() == normalized:
            return i + 1  # 1-indexed

    # Substring match
    for i, line in enumerate(lines):
        if normalized in line.strip() or line.strip() in normalized:
            return i + 1

    return None


def find_renamed_file(original_path: Path, project_root: Path) -> Path | None:
    """Try to find a file that was renamed/moved."""
    if original_path.exists():
        return original_path

    filename = original_path.name
    # Search for files with same name in project
    candidates = list(project_root.rglob(filename))
    if len(candidates) == 1:
        return candidates[0]

    # If multiple, prefer ones in similar directory structure
    if len(candidates) > 1:
        # Try to match parent directory name
        parent_name = original_path.parent.name
        for c in candidates:
            if parent_name in str(c):
                return c

    return None


def fix_shifted_ref(ref: dict, project_root: Path) -> dict | None:
    """Attempt to fix a shifted line reference. Returns fix info or None."""
    resolved = ref.get("resolved_path")
    if not resolved:
        resolved = str(project_root / ref["ref_file"])

    file_path = Path(resolved)
    if not file_path.exists():
        return None

    status = ref.get("status", "")
    if "shifted" not in status:
        return None

    if "out_of_range" in status:
        return None

    new_line = find_best_line(file_path, ref.get("actual_content", ""))
    if new_line is None:
        return None

    return {
        "type": "line_shift",
        "doc_file": ref["doc_file"],
        "old_ref": ref["ref_text"],
        "old_path": ref["ref_file"],
        "old_line": ref["ref_line"],
        "new_line": new_line,
        "new_ref": f"{ref['ref_file']}:{new_line}",
        "resolved": str(file_path),
    }


def fix_broken_path_ref(ref: dict, project_root: Path) -> dict | None:
    """Attempt to fix a broken path reference. Returns fix info or None."""
    original_path = project_root / ref["ref_file"]
    renamed = find_renamed_file(original_path, project_root)

    if renamed and renamed != original_path:
        new_rel = renamed.relative_to(project_root)
        return {
            "type": "path_rename",
            "doc_file": ref["doc_file"],
            "old_ref": ref["ref_text"],
            "old_path": ref["ref_file"],
            "new_path": str(new_rel),
            "new_ref": f"{new_rel}:{ref['ref_line']}",
            "resolved": str(renamed),
        }

    return None


def apply_fix_to_doc(doc_path: Path, old_text: str, new_text: str) -> bool:
    """Apply a single text replacement in a doc file."""
    try:
        content = doc_path.read_text(encoding="utf-8")
        if old_text not in content:
            return False
        new_content = content.replace(old_text, new_text, 1)
        doc_path.write_text(new_content, encoding="utf-8")
        return True
    except OSError:
        return False


def main():
    parser = argparse.ArgumentParser(description="Doc Garden: Phase 3 reference fixer")
    parser.add_argument("--project-root", required=True, help="Path to project root")
    parser.add_argument("--scan-result", default="scan-result.json", help="Scan result from Phase 1")
    parser.add_argument("--dry-run", action="store_true", help="Preview fixes without applying")
    parser.add_argument("--apply", action="store_true", help="Apply fixes")
    args = parser.parse_args()

    if not args.dry_run and not args.apply:
        print("Error: specify --dry-run or --apply", file=sys.stderr)
        sys.exit(1)

    project_root = Path(args.project_root).resolve()
    scan_path = Path(args.scan_result)
    if not scan_path.is_absolute():
        scan_path = project_root / scan_path

    if not scan_path.exists():
        print(f"Error: {scan_path} not found. Run scan.py first.", file=sys.stderr)
        sys.exit(1)

    scan_data = json.loads(scan_path.read_text(encoding="utf-8"))

    fixes = []

    # Process broken path refs
    for ref in scan_data.get("broken_refs", []):
        fix = fix_broken_path_ref(ref, project_root)
        if fix:
            fixes.append(fix)

    # Process shifted refs (limited — most need AI)
    for ref in scan_data.get("shifted_refs", []):
        fix = fix_shifted_ref(ref, project_root)
        if fix:
            fixes.append(fix)

    if not fixes:
        print("No automatic fixes available. All remaining issues need AI judgment (Phase 2).")
        sys.exit(0)

    # Apply or preview
    applied = 0
    for fix in fixes:
        doc_path = Path(fix["doc_file"])
        if not doc_path.is_absolute():
            doc_path = project_root / doc_path

        if args.dry_run:
            print(f"  WOULD FIX: {fix['doc_file']}")
            print(f"    {fix['old_ref']} → {fix['new_ref']}")
            print(f"    Reason: {fix['type']}")
        elif args.apply:
            success = apply_fix_to_doc(doc_path, fix["old_ref"], fix["new_ref"])
            if success:
                print(f"  FIXED: {fix['old_ref']} → {fix['new_ref']} in {fix['doc_file']}")
                applied += 1
            else:
                print(f"  SKIPPED: {fix['old_ref']} not found in {fix['doc_file']}")

    if args.dry_run:
        print(f"\n{len(fixes)} fixes previewed. Run with --apply to execute.")
    else:
        print(f"\n{applied}/{len(fixes)} fixes applied successfully.")

    sys.exit(0)


if __name__ == "__main__":
    main()
