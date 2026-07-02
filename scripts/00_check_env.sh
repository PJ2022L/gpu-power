#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-configs/container.yaml}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/00_check_env_$(date +%Y%m%d_%H%M%S).log"

{
  echo "stage=00_check_env"
  echo "config=${CONFIG}"
  echo "command=$0 $*"
  echo "expected_container_image=operatorsforge:h800-v1.0"
  echo "expected_container_name=l2_mla_study"
  echo "note=This is a placeholder environment check for the H800 agent."
  echo "TODO: collect nvidia-smi -L"
  echo "TODO: collect nvidia-smi -q"
  echo "TODO: collect nvcc --version"
  echo "TODO: collect ncu --version"
  echo "TODO: collect nsys --version"
  echo "TODO: verify no unrelated process on target GPU"
} | tee "${LOG_FILE}"
