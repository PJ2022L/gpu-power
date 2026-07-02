#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-configs/power/nvml_policy.yaml}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" experiments/raw/microbench experiments/processed/microbench experiments/reports
LOG_FILE="${LOG_DIR}/03_run_microbenchmarks_$(date +%Y%m%d_%H%M%S).log"

{
  echo "stage=03_run_microbenchmarks"
  echo "config=${CONFIG}"
  echo "command=$0 $*"
  echo "TODO: build microbenchmark binaries"
  echo "TODO: run energy mode with NVML collection"
  echo "TODO: run profiler mode with NCU"
  echo "TODO: dump SASS for each binary"
  echo "expected_outputs:"
  echo "  experiments/raw/microbench/"
  echo "  experiments/processed/microbench/microbench_matrix_inputs.*"
  echo "  experiments/reports/phase2_microbench_report.md"
} | tee "${LOG_FILE}"
