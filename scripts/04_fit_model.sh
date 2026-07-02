#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-configs/modeling/train_predict.yaml}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" experiments/processed/modeling experiments/reports
LOG_FILE="${LOG_DIR}/04_fit_model_$(date +%Y%m%d_%H%M%S).log"

{
  echo "stage=04_fit_model"
  echo "config=${CONFIG}"
  echo "command=$0 $*"
  echo "model_boundary_doc=docs/design-spec/modeling.md"
  echo "required_baseline_root=experiments/raw/baseline_power"
  echo "TODO: load microbenchmark matrix inputs"
  echo "TODO: estimate constant energy from idle baseline"
  echo "TODO: estimate static energy from full-SM active-no-op baseline minus idle"
  echo "TODO: solve non-negative linear system"
  echo "TODO: write SASS energy table and residual report"
  echo "expected_outputs:"
  echo "  experiments/processed/modeling/sass_energy_table.*"
  echo "  experiments/reports/phase3_model_report.md"
} | tee "${LOG_FILE}"
