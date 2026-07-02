#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:?usage: $0 <operator_config.yaml>}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" experiments/raw/operator_profiles experiments/processed/operator_sass experiments/reports
LOG_FILE="${LOG_DIR}/01_profile_operators_$(basename "${CONFIG}" .yaml)_$(date +%Y%m%d_%H%M%S).log"

{
  echo "stage=01_profile_operators"
  echo "config=${CONFIG}"
  echo "command=$0 $*"
  echo "TODO: run operator implementation from config"
  echo "TODO: run Nsight Systems to list kernels"
  echo "TODO: run Nsight Compute to collect SASS top-k and memory metrics"
  echo "expected_outputs:"
  echo "  experiments/processed/operator_sass/<operator>_kernels.csv"
  echo "  experiments/processed/operator_sass/<operator>_sass_topk.csv"
  echo "  experiments/processed/operator_sass/missing_sass_classes.yaml"
  echo "  experiments/reports/phase1_operator_sass_report.md"
} | tee "${LOG_FILE}"
