#!/usr/bin/env bash
set -euo pipefail

PREDICTIONS="${1:-experiments/e2e_testset/pred_vs_measured.csv}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" experiments/reports experiments/e2e_testset/processed
LOG_FILE="${LOG_DIR}/07_validate_error_$(date +%Y%m%d_%H%M%S).log"

{
  echo "stage=07_validate_error"
  echo "predictions=${PREDICTIONS}"
  echo "command=$0 $*"
  echo "target_msae_percent=15"
  echo "required_ground_truth=experiments/e2e_testset/raw"
  echo "ground_truth_rule=Phase_11_non_profiled_NVML_runs_only"
  echo "metric_definition=MSAE_mean_abs_P_pred_minus_P_meas_over_P_meas_times_100"
  echo "TODO: compare predicted vs measured average power, dynamic power, energy, and latency"
  echo "TODO: reject Phase 03-05 profiler runtimes or exploratory power as validation ground truth"
  echo "TODO: reject negative measured power, dynamic power, fitted coefficients, or predictions"
  echo "TODO: verify repeatability thresholds before reporting error"
  echo "TODO: if MSAE >= 15, generate .agents/knowledge/NEXT_ITERATION_PLAN.md"
  echo "expected_outputs:"
  echo "  experiments/e2e_testset/pred_vs_measured.csv"
  echo "  experiments/reports/phase12_e2e_prediction_validation.md"
  echo "  .agents/knowledge/E2E_EVALUATION_REPORT.md"
} | tee "${LOG_FILE}"
