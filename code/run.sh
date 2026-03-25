#!/usr/bin/env bash
# run.sh – Reproduce all results for Lab 1.
#
# Usage (from lab1/code/ or lab1/ root):
#   bash lab1/code/run.sh        # from repo root
#   bash run.sh                  # from lab1/code/
#
# The grader should manually place the data folder at lab1/data/ before running.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/../report"
REPORT_FIG_DIR="$REPORT_DIR/figures"
ENV_NAME="stat214"

echo "=== PECARN TBI Lab 1 – Reproducing results ==="
echo ""

mkdir -p "$REPORT_FIG_DIR"

# ── Activate conda environment ─────────────────────────────────────────────
echo "Activating conda environment: $ENV_NAME …"
# shellcheck source=/dev/null
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

# ── Step 1: Style check ────────────────────────────────────────────────────
echo ""
echo "Step 1/4: Running ruff style check …"
cd "$SCRIPT_DIR"
ruff check . --output-format json | python3 -c "
import json, sys
errs = json.load(sys.stdin)
if errs:
    for e in errs:
        f = e['filename'].split('/')[-1]
        r = e['location']['row']
        print(f'  {f}:{r} [{e[\"code\"]}] {e[\"message\"]}')
    print(f'  {len(errs)} style error(s) found.')
else:
    print('  No style errors.')
"

# ── Step 2: Data cleaning ──────────────────────────────────────────────────
echo ""
echo "Step 2/4: Running clean.py …"
python clean.py

# ── Step 3: Modelling ──────────────────────────────────────────────────────
echo ""
echo "Step 3/4: Running models.py …"
python models.py

# ── Step 4: Generate all figures and compile report ────────────────────────
echo ""
echo "Step 4/4: Running analysis.py (figures) and compiling report …"
python analysis.py

cd "$REPORT_DIR"
if command -v pdflatex &> /dev/null; then
    pdflatex -interaction=nonstopmode lab1.tex > /dev/null 2>&1
    pdflatex -interaction=nonstopmode lab1.tex > /dev/null 2>&1
    echo "  Report compiled: $REPORT_DIR/lab1.pdf"
else
    echo "  pdflatex not found – skipping PDF compilation."
fi

# ── Deactivate conda environment ───────────────────────────────────────────
conda deactivate
echo ""
echo "=== Done. Conda environment deactivated. ==="
echo "  Figures : $REPORT_FIG_DIR"
echo "  Report  : $REPORT_DIR/lab1.pdf"
