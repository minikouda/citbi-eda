# ciTBI EDA — PECARN Pediatric Traumatic Brain Injury

Exploratory data analysis and classification modeling on the PECARN Pediatric TBI dataset.
Lab 1 for STAT 214, UC Berkeley, Spring 2026.

---

## Overview

When a child presents to an emergency department after blunt head trauma, clinicians face a critical triage decision: order a CT scan (gold standard for detecting intracranial injury, but exposes a developing brain to ionizing radiation) or discharge without imaging (risking a missed clinically important TBI).

This project rigorously analyzes the PECARN dataset — a prospective multicenter study of 43,399 pediatric patients across 25 U.S. emergency departments (2004–2006) — to uncover clinical patterns beyond the published Kuppermann clinical decision rule (CDR) and to compare rule-based versus statistical learning approaches to the triage problem.

**Target variable:** `PosIntFinal` — clinically important TBI (ciTBI), defined as death from TBI, neurosurgical intervention, intubation >24 hours, or hospitalization ≥2 nights associated with a CT abnormality. Prevalence: **0.89%** in the GCS 14–15 analytic cohort (376 of 42,412 patients).

---

## Key Findings

### Finding 1: ciTBI Risk Is Clustered, Not Gradual

Risk does not accumulate linearly with the number of positive PECARN predictors. Instead:
- Neurological deficit and palpable skull fracture elevate risk >10× the baseline.
- A step-function pattern emerges: near-baseline risk at 0–1 predictors, then a sharp jump at ≥2.
- Specific feature pairs (AMS × SFxPalp; Vomiting × Severe Headache) show **synergistic** risk — the double-positive rate is roughly triple what independent addition would predict.

**Implication:** A refined score weighting feature co-occurrence would better stratify the intermediate-risk population than the CDR's binary positive/negative output.

### Finding 2: Feature Predictive Meaning Changes With Age

The 24-month PECARN cutoff is clinically motivated but compresses meaningful heterogeneity:
- **Structural exam findings** (palpable skull fracture, scalp hematoma) dominate infant risk (<2 yr), where pre-verbal patients cannot self-report.
- **Verbal-report symptoms** (headache severity) only appear and carry signal in older children (5–18 yr).
- The top-3 most age-variable features each peak in a different developmental window.

**Implication:** Age-adaptive feature weighting — rather than a single binary stratum boundary — would improve discrimination across developmental stages.

### Finding 3: Clinician CT Ordering Encodes Hidden Signal

Physicians incorporate information not captured in the nine structured PECARN predictors. Within strata of AMS status, patients who received a CT had a substantially higher ciTBI rate than those who did not, even controlling for recorded features.

**Implication:** The CT ordering decision is itself a latent predictor. Models trained only on structured features underestimate the information available at the bedside.

---

## Models

Three classifiers are implemented and compared (all evaluated at the threshold achieving ≥95% sensitivity, the clinically appropriate operating point for a screening rule):

| Model | Description |
|---|---|
| **Kuppermann CDR** | Rule-based: age-stratified "any-predictor-positive triggers CT" rule from Kuppermann et al. 2009 |
| **Age-Stratified Logistic Regression** | Two separate LR models (one per PECARN age stratum), L2 regularization, class-weighted loss |
| **Random Forest** | 200-tree ensemble, class-weighted, median imputation for missing values |

All models use the same 27 clinically motivated features (GCS, AMS sub-indicators, LOC, vomiting, headache, skull fracture signs, hematoma, injury mechanism, neurological deficit, and derived composites).

---

## Repository Structure

```
.
├── code/
│   ├── clean.py          # Data cleaning pipeline (8-step, documented)
│   ├── analysis.py       # EDA findings + all figure generation
│   ├── models.py         # KuppermannCDR, AgeStratifiedLR, RandomForestModel
│   ├── lab1.ipynb        # Interactive notebook (mirrors analysis.py)
│   ├── run.sh            # One-command reproduction script
│   ├── environment.yaml  # Conda environment (Python 3.11)
│   └── ruff.toml         # Style configuration
├── report/
│   ├── lab1.tex          # LaTeX report source
│   ├── lab1.pdf          # Compiled report
│   └── figures/          # All generated figures (PNG, 300 dpi)
└── README.md
```

> **Note:** The raw data (`data/`) and course instructions (`instructions/`) are not included in this repository. The dataset is the PECARN TBI Public Use Dataset (released 2013).

---

## Reproducing Results

### 1. Set up the environment

```bash
conda env create -f code/environment.yaml
conda activate stat214
```

### 2. Place the data

Download the PECARN TBI Public Use Dataset and place it at:
```
data/TBI PUD 10-08-2013.csv
```

### 3. Run everything

```bash
bash code/run.sh
```

This will:
1. Run `ruff` style checks
2. Execute `clean.py` (data cleaning)
3. Execute `models.py` (model training and evaluation)
4. Execute `analysis.py` (figure generation)
5. Compile the LaTeX report to `report/lab1.pdf` (requires `pdflatex`)

Alternatively, run steps individually from `code/`:
```bash
python clean.py
python models.py
python analysis.py
```

---

## Data Cleaning Summary

The pipeline (`clean.py`) applies 8 ordered steps to the raw CSV:

1. **Special-code imputation** — PECARN codes 91 (refused), 92 (not applicable), 99 (unknown) replaced with `NaN` for all categorical columns; the four genuinely numeric columns (`AgeInMonth`, `AgeinYears`, `GCSTotal`, `PosIntFinal`) are exempted.
2. **GCS Total validation** — values outside [3, 15] set to `NaN`.
3. **GCS subscale validation** — Eye [1,4], Verbal [1,5], Motor [1,6]; out-of-range values set to `NaN`.
4. **Age validation** — ages outside [0, 216] months set to `NaN`.
5. **Outcome coercion** — `PosIntFinal` cast to numeric.
6. **Logical contradiction resolution** — 12 parent-child variable relationships audited; GCS totals inconsistent with component sums corrected.
7. **Age grouping and PECARN eligibility** — five developmental bands derived; `pecarn_eligible` flag marks GCS 14–15 patients.
8. **Derived features** — `ams_any` (binary OR of 4 AMS sub-indicators), `severe_mechanism` (high-energy injury mechanisms per Kuppermann et al.).

**Analytic cohort:** 42,412 patients (43,399 total − 969 GCS ≤13 − 18 missing outcome).

---

## Dependencies

| Package | Version |
|---|---|
| Python | 3.11 |
| pandas | 3.0.0 |
| numpy | 2.4.1 |
| scikit-learn | 1.8.0 |
| matplotlib | 3.10.8 |
| seaborn | 0.13.2 |
| scipy | 1.17.0 |

---

## Reference

Kuppermann N, et al. (2009). Identification of children at very low risk of clinically-important brain injuries after head trauma: a prospective cohort study. *The Lancet*, 374(9696), 1160–1170.
