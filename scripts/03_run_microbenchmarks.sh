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
  echo "TODO: run energy mode with src/power/nvml_sampler.py"
  echo "example_energy_command:"
  echo "  GPU_ID=0 SHAPE_ID=<bench_id> python src/power/nvml_sampler.py --config ${CONFIG} --gpu-id 0 --output-dir experiments/raw/microbench_power/<bench_id> --label microbench_<bench_id> -- ./<microbench_binary> <args>"
  echo "TODO: run profiler mode with NCU"
  echo "TODO: dump SASS for each binary"
  echo "expected_outputs:"
  echo "  experiments/raw/microbench_power/<bench_id>/power_trace.csv"
  echo "  experiments/raw/microbench_power/<bench_id>/metadata.yaml"
  echo "  experiments/raw/microbench_power/<bench_id>/summary.yaml"
  echo "  experiments/raw/microbench_power/<bench_id>/repeatability.yaml"
  echo "  experiments/processed/microbench/microbench_matrix_inputs.*"
  echo "  experiments/reports/phase2_microbench_report.md"
} | tee "${LOG_FILE}"
