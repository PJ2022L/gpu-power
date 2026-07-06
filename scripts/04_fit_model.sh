#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-configs/modeling/train_predict.yaml}"
ITER_ID="${ITER_ID:-iter_001}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" "experiments/dynamic_power/${ITER_ID}" experiments/processed/modeling experiments/reports
LOG_FILE="${LOG_DIR}/04_fit_model_$(date +%Y%m%d_%H%M%S).log"

{
  echo "stage=04_fit_model"
  echo "iter_id=${ITER_ID}"
  echo "config=${CONFIG}"
  echo "command=$0 $*"
  echo "model_boundary_doc=harness/design-spec/modeling.md"
  echo "required_static_model=.agents/knowledge/STATIC_POWER_MODEL.md"
  echo "required_baseline_root=experiments/static_power/raw"
  echo "TODO: load microbenchmark matrix inputs"
  echo "TODO: estimate constant energy from idle baseline"
  echo "TODO: estimate static energy from full-SM active-no-op baseline minus idle"
  echo "TODO: reject or quarantine rows with negative baseline-subtracted dynamic energy"
  echo "TODO: solve non-negative linear system"
  echo "TODO: reject negative fitted coefficients and negative predictions"
  echo "TODO: write SASS energy table and residual report"
  echo "expected_outputs:"
  echo "  experiments/processed/modeling/sass_energy_table.*"
  echo "  experiments/processed/modeling/model_matrix.*"
  echo "  experiments/processed/modeling/model_rhs.*"
  echo "  experiments/dynamic_power/${ITER_ID}/model_coefficients.csv"
  echo "  experiments/reports/phase10_dynamic_model_fit.md"
  echo "  .agents/knowledge/DYNAMIC_POWER_MODEL.md"
} | tee "${LOG_FILE}"
