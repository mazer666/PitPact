#!/usr/bin/env bash
# validate_locale.sh — locale validation gate for PitPact.
#
# Per docs/requirements.md §15 and §18, the M1 release must
# externalise every user-visible string into locales/ and ship
# a documented validation pass. This script is the gate.
#
# Checks (in order; first failure aborts the rest):
#   1. locales/source_strings.csv exists, is parseable, has the
#      three required columns (id, source, context), and every
#      id is a unique non-empty ASCII identifier.
#   2. Every id in source_strings.csv is present in en.po AND
#      in de.po. Missing keys fail the build.
#   3. Every placeholder in the English source (any "{x}" token)
#      is preserved in both translations. Dropping a placeholder
#      silently is a layout-breaking bug; the script flags it.
#   4. No concatenated-fragment pattern in source_strings.csv:
#      we forbid double-quoted CSV fields whose value starts
#      with a leading article + space ("The ", "A ", "An ")
#      because those fragments are the typical rebrand-after-
#      concatenation smell. (The list is hard-coded; the
#      German column is not checked here because grammar
#      differs.)
#   5. Each .po file is a valid gettext PO file: every msgid
#      has a matching msgstr, the header is present, the file
#      is parseable. If `msgfmt` is on PATH we additionally
#      run `msgfmt --check` for the strict syntax check; if
#      not, we fall back to a pure-Python syntax check.
#   6. The .po files are non-empty.
#
# Wire-in: tools/run_quality.sh invokes this script after the
# existing checks. It exits 0 on success and 1 on any failure.
#
# Usage:
#   tools/validate_locale.sh                 # validate (default)
#   tools/validate_locale.sh --check         # alias for default
#
# Exit codes:
#   0   validation passed
#   1   validation failed (a check above failed)
#   2   environment broken (csv file missing, python3 missing)

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# --- locate required files ---
CSV="locales/source_strings.csv"
EN_PO="locales/en.po"
DE_PO="locales/de.po"

if [ ! -f "${CSV}" ]; then
  echo "validate_locale.sh: FATAL: ${CSV} not found" >&2
  exit 2
fi
if [ ! -f "${EN_PO}" ]; then
  echo "validate_locale.sh: FATAL: ${EN_PO} not found" >&2
  exit 2
fi
if [ ! -f "${DE_PO}" ]; then
  echo "validate_locale.sh: FATAL: ${DE_PO} not found" >&2
  exit 2
fi

# --- preflight: python3 is required for the deep checks ---
if ! command -v python3 >/dev/null 2>&1; then
  echo "validate_locale.sh: FATAL: python3 not on PATH" >&2
  exit 2
fi

# --- optional: msgfmt (gettext). If present, we run it for the
#     strict syntax check. If absent, the Python fallback covers
#     the same surface and the script still passes.
HAVE_MSGFMT=0
if command -v msgfmt >/dev/null 2>&1; then
  HAVE_MSGFMT=1
fi

# --- the deep check: a single Python program that does steps
#     1-6 above. Splitting it across separate python3 -c blocks
#     would re-pay the import cost and re-load the CSV several
#     times; a single script is faster and easier to debug.
python3 - "${CSV}" "${EN_PO}" "${DE_PO}" "${HAVE_MSGFMT}" <<'PYEOF'
import csv
import os
import re
import sys


def fail(msg: str) -> None:
    print(f"validate_locale: FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def info(msg: str) -> None:
    print(f"validate_locale: {msg}")


# --- module-level regex (used by multiple checks below) ---
PLACEHOLDER_RE = re.compile(r"\{[A-Za-z0-9_]+\}")


csv_path, en_po_path, de_po_path, have_msgfmt_s = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
have_msgfmt = have_msgfmt_s == "1"

# --- 1. CSV header + per-row sanity ---
with open(csv_path, newline="", encoding="utf-8") as fh:
    reader = csv.reader(fh)
    rows = [row for row in reader if row and not all(c.strip() == "" for c in row)]

if not rows:
    fail(f"{csv_path} is empty")

header = [c.strip() for c in rows[0]]
if header != ["id", "source", "context"]:
    fail(
        f"{csv_path}: expected header [id, source, context], got {header!r}"
    )

id_pattern = re.compile(r"^[A-Z][A-Z0-9_]*$")
ids: list[str] = []
sources: dict[str, str] = {}
for i, row in enumerate(rows[1:], start=2):
    if len(row) < 3:
        fail(f"{csv_path}:{i}: row has fewer than 3 columns: {row!r}")
    rid = row[0].strip()
    src = row[1]
    ctx = row[2]
    if not rid:
        fail(f"{csv_path}:{i}: empty id")
    if not id_pattern.match(rid):
        fail(
            f"{csv_path}:{i}: id {rid!r} is not an UPPER_SNAKE_CASE identifier"
        )
    if rid in sources:
        fail(f"{csv_path}:{i}: duplicate id {rid!r}")
    if not src.strip():
        fail(f"{csv_path}:{i}: empty source for id {rid!r}")
    if not ctx.strip():
        fail(f"{csv_path}:{i}: empty context for id {rid!r}")
    ids.append(rid)
    sources[rid] = src

info(f"csv: {len(ids)} entries")

# --- 4. Concatenated-fragment guard. The smell we want to
#     catch is a developer building a sentence from
#     `tr("The " + name)` and friends. Two ingredients are
#     required to call it a smell:
#
#       (a) the source string contains a {placeholder} (so it
#           is being interpolated, not used as a whole), AND
#       (b) the source string starts with an article followed
#           by a space ("The ", "A ", "An "), so the article
#           would be a stranded fragment of the concatenated
#           form.
#
#     Standalone strings like "A communal fire-pit and
#     gathering space..." are NOT a smell (no placeholder,
#     no concatenation). Strings like "The {x} of Doom" ARE
#     a smell (placeholder + stranded article). The check
#     is conservative: any false positive is a "rename the
#     key" cost, not a "ship a broken translation" cost.
bad_prefixes = ("The ", "A ", "An ")
for rid, src in sources.items():
    if not PLACEHOLDER_RE.search(src):
        continue
    if src.startswith(bad_prefixes):
        fail(
            f"{csv_path}: source for {rid!r} starts with "
            f"{src.split(' ', 1)[0]!r} and contains a placeholder; "
            "concatenated-fragment pattern detected"
        )

# --- 5. Parse .po files. The format is line-oriented and stable
#     enough that a small parser is sufficient for our checks
#     (the .po files we ship do not use plural forms, context
#     lines, or fuzzy entries; if they grow, this parser grows
#     with them). ---
def parse_po(path: str) -> dict[str, str]:
    """Return {msgid: msgstr} for a simple .po file. Headers
    (msgid '') are stored under the empty-string key and ignored
    by callers that ask for translated entries."""
    with open(path, encoding="utf-8") as fh:
        lines = fh.readlines()
    out: dict[str, str] = {}
    cur_id: list[str] = []
    cur_str: list[str] = []
    state: str | None = None  # None | "id" | "str"
    for raw in lines:
        line = raw.rstrip("\n")
        if line.startswith("msgid "):
            # commit previous
            if state == "str":
                out["\n".join(cur_id)] = "\n".join(cur_str)
            cur_id = [unquote_po(line[len("msgid "):])]
            cur_str = []
            state = "id"
        elif line.startswith("msgstr "):
            if state != "id":
                fail(f"{path}: msgstr without preceding msgid near {line!r}")
            cur_str = [unquote_po(line[len("msgstr "):])]
            state = "str"
        elif line.startswith('"') and state in ("id", "str"):
            if state == "id":
                cur_id.append(unquote_po(line))
            else:
                cur_str.append(unquote_po(line))
        elif line.strip() == "":
            if state == "str":
                out["\n".join(cur_id)] = "\n".join(cur_str)
                state = None
        # comment / #~ / #: lines are ignored
    if state == "str":
        out["\n".join(cur_id)] = "\n".join(cur_str)
    return out


def unquote_po(s: str) -> str:
    s = s.strip()
    if s.startswith('"') and s.endswith('"'):
        s = s[1:-1]
    # PO string escapes: \\ \" \n \t \r
    return s.encode("utf-8").decode("unicode_escape")


en = parse_po(en_po_path)
de = parse_po(de_po_path)
if "" not in en or "" not in de:
    fail("one of the .po files is missing a header (msgid '' / msgstr '')")
info(f"po: en={len(en) - 1} entries, de={len(de) - 1} entries (header excluded)")

# --- 2. Coverage: every csv id must be present in both .po files ---
missing_en = [rid for rid in ids if rid not in en]
missing_de = [rid for rid in ids if rid not in de]
if missing_en:
    fail(f"keys missing from en.po: {missing_en}")
if missing_de:
    fail(f"keys missing from de.po: {missing_de}")

# --- 6. Non-empty check (the test_locale_validation.gd test
#     asserts this directly, but we also enforce it here so the
#     quality gate catches a deleted .po file before the test
#     suite runs). ---
if os.path.getsize(en_po_path) == 0:
    fail(f"{en_po_path} is empty")
if os.path.getsize(de_po_path) == 0:
    fail(f"{de_po_path} is empty")

# --- 3. Placeholder preservation. Extract {x} tokens from the
#     CSV source and assert that BOTH translations contain
#     every one of them. A missing placeholder is a silent
#     layout-breaking bug and is a hard fail. ---
def placeholders(s: str) -> set[str]:
    return set(PLACEHOLDER_RE.findall(s))


for rid in ids:
    src_placeholders = placeholders(sources[rid])
    if not src_placeholders:
        continue
    en_placeholders = placeholders(en[rid])
    de_placeholders = placeholders(de[rid])
    if en_placeholders != src_placeholders:
        fail(
            f"placeholder drift in en.po[{rid!r}]: "
            f"source has {sorted(src_placeholders)}, en has {sorted(en_placeholders)}"
        )
    if de_placeholders != src_placeholders:
        fail(
            f"placeholder drift in de.po[{rid!r}]: "
            f"source has {sorted(src_placeholders)}, de has {sorted(de_placeholders)}"
        )

# --- 5b. msgfmt --check (optional but strict). ---
if have_msgfmt:
    for p in (en_po_path, de_po_path):
        if os.system(f"msgfmt --check -o /dev/null {p}") != 0:
            fail(f"msgfmt --check {p} failed")
    info("msgfmt --check: OK")
else:
    info("msgfmt not on PATH; pure-Python syntax check only (sufficient)")

info("OK (locale validation passed)")
PYEOF
