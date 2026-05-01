#!/usr/bin/env python3
"""Doc Garden Phase 1: Deterministic reference scanner.

Extracts file:line references from AGENTS.md and docs/,
validates targets exist and line content matches.

Usage:
    python3 scan.py --project-root /path/to/project
    python3 scan.py --project-root . --output scan-result.json
"""

import argparse
import json
import re
import sys
from pathlib import Path

# Matches patterns like: src/config.ts:42, lib/auth.py:15, etc.
REF_PATTERN = re.compile(
    r"(?:^|[\s(`])"
    r"((?:[\w./-]+\.)+(?:py|ts|tsx|js|jsx|go|rs|java|rb|yaml|yml|json|toml|sql|sh|md|html|css|scss))"
    r":(\d+)"
)
# Strip code blocks to avoid false positives inside ```...```
CODE_BLOCK = re.compile(r"```[\s\S]*?```", re.MULTILINE)
# Strip inline code
INLINE_CODE = re.compile(r"`[^`\n]+`")


def extract_refs(md_path: Path, project_root: Path, src_prefixes: list[Path] | None = None) -> list[dict]:
    """Extract file:line references from a markdown file.

    Args:
        md_path: Path to the markdown file.
        project_root: Project root directory.
        src_prefixes: Additional source directories to search when resolving
            relative paths (e.g., [project_root / "src/quant/"]).
    """
    if src_prefixes is None:
        src_prefixes = []

    content = md_path.read_text(encoding="utf-8", errors="replace")
    # Remove code blocks first (they often contain example references)
    stripped = CODE_BLOCK.sub("", content)

    refs = []
    seen = set()
    for match in REF_PATTERN.finditer(stripped):
        ref_file = match.group(1)
        ref_line = int(match.group(2))

        # Deduplicate same reference in same file
        key = (ref_file, ref_line)
        if key in seen:
            continue
        seen.add(key)

        # Resolve relative to doc file's parent (usually project root)
        target = md_path.parent / ref_file
        # Also try project root
        if not target.exists():
            # Walk up to find the file
            for parent in md_path.parents:
                candidate = parent / ref_file
                if candidate.exists():
                    target = candidate
                    break
        # Try source prefixes (e.g., src/quant/ for AGENTS.md using module-relative paths)
        if not target.exists() and src_prefixes:
            for prefix in src_prefixes:
                candidate = prefix / ref_file
                if candidate.exists():
                    target = candidate
                    break
        # Try rglob as last resort
        if not target.exists():
            filename = Path(ref_file).name
            candidates = list(project_root.rglob(filename))
            if len(candidates) == 1:
                target = candidates[0]

        status = "healthy"
        actual_content = None

        try:
            target = target.resolve()
            if not target.exists():
                status = "broken_path"
            elif target.is_file():
                lines = target.read_text(encoding="utf-8", errors="replace").splitlines()
                if ref_line < 1 or ref_line > len(lines):
                    status = "shifted_line_out_of_range"
                else:
                    actual_content = lines[ref_line - 1].strip()
        except (OSError, UnicodeDecodeError):
            status = "unreadable"

        refs.append(
            {
                "doc_file": str(md_path),
                "ref_file": ref_file,
                "ref_line": ref_line,
                "ref_text": f"{ref_file}:{ref_line}",
                "status": status,
                "actual_content": actual_content,
                "resolved_path": str(target) if target.exists() else None,
            }
        )

    return refs


def _detect_src_prefixes(project_root: Path) -> list[Path]:
    """Detect common source directory prefixes from AGENTS.md STRUCTURE section.

    Looks for tree entries like '├── src/quant/' or '└── lib/myapp/' and
    returns [project_root / "src/quant/", project_root / "lib/myapp/"].
    """
    agents_md = project_root / "AGENTS.md"
    if not agents_md.exists():
        return []

    prefixes: list[Path] = []
    content = agents_md.read_text(encoding="utf-8", errors="replace")
    in_structure = False
    for line in content.splitlines():
        if line.strip().startswith("```"):
            in_structure = not in_structure
            continue
        if not in_structure:
            continue
        for entry in line.split("├──")[1:] if "├──" in line else line.split("└──")[1:] if "└──" in line else []:
            entry = entry.strip().rstrip("/")
            if entry and "/" in entry and not entry.startswith("."):
                candidate = project_root / entry
                if candidate.is_dir():
                    prefixes.append(candidate)
    return prefixes


def scan_project(project_root: Path) -> dict:
    """Scan all doc files in a project."""
    src_prefixes = _detect_src_prefixes(project_root)

    md_files = []
    agents_md = project_root / "AGENTS.md"
    if agents_md.exists():
        md_files.append(agents_md)

    # Subdirectory AGENTS.md files
    for agents in project_root.rglob("AGENTS.md"):
        if agents != agents_md:
            md_files.append(agents)

    # docs/ directory
    docs_dir = project_root / "docs"
    if docs_dir.exists():
        for md in docs_dir.rglob("*.md"):
            md_files.append(md)

    # Also check .sisyphus/rules/ if exists
    rules_dir = project_root / ".sisyphus" / "rules"
    if rules_dir.exists():
        for md in rules_dir.rglob("*.md"):
            md_files.append(md)

    # Deduplicate
    md_files = sorted(set(md_files))

    results = {
        "project_root": str(project_root),
        "files_scanned": len(md_files),
        "total_refs": 0,
        "healthy_count": 0,
        "broken_refs": [],
        "shifted_refs": [],
        "file_details": [],
    }

    for md in md_files:
        refs = extract_refs(md, project_root, src_prefixes)
        file_detail = {
            "file": str(md.relative_to(project_root)),
            "ref_count": len(refs),
            "refs": refs,
        }
        results["file_details"].append(file_detail)
        results["total_refs"] += len(refs)

        for ref in refs:
            if ref["status"] == "healthy":
                results["healthy_count"] += 1
            elif ref["status"] == "broken_path":
                results["broken_refs"].append(ref)
            elif ref["status"].startswith("shifted"):
                results["shifted_refs"].append(ref)

    results["health_pct"] = (
        round(results["healthy_count"] / results["total_refs"] * 100, 1) if results["total_refs"] > 0 else 100.0
    )

    return results


def main():
    parser = argparse.ArgumentParser(description="Doc Garden: Phase 1 reference scanner")
    parser.add_argument("--project-root", required=True, help="Path to project root")
    parser.add_argument("--output", default="scan-result.json", help="Output file path")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    if not project_root.exists():
        print(f"Error: {project_root} does not exist", file=sys.stderr)
        sys.exit(1)

    results = scan_project(project_root)

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = project_root / output_path
    output_path.write_text(json.dumps(results, indent=2, ensure_ascii=False))

    # Summary to stdout
    print(f"Scanned {results['files_scanned']} doc files")
    print(f"References: {results['total_refs']} total, {results['healthy_count']} healthy ({results['health_pct']}%)")
    print(f"Broken paths: {len(results['broken_refs'])}")
    print(f"Shifted lines: {len(results['shifted_refs'])}")
    print(f"Report written to: {output_path}")

    # Exit code: 0 if all healthy, 1 if issues found
    if results["broken_refs"] or results["shifted_refs"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
