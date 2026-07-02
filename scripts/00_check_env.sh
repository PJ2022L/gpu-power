#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-configs/container.yaml}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/00_check_env_$(date +%Y%m%d_%H%M%S).log"
printf -v ORIGINAL_COMMAND '%q ' "$0" "$@"

{
  echo "stage=00_check_env"
  echo "config=${CONFIG}"
  echo "command=${ORIGINAL_COMMAND}"
  echo "expected_container_image=operatorsforge:h800-v1.0"
  echo "expected_container_name=l2_mla_study"
  echo "date_iso=$(date -Is)"
  echo "hostname=$(hostname)"
  echo "user=$(id -un)"
  echo "pwd=$(pwd)"
  echo "container_name=${HOSTNAME:-unknown}"
  echo "python=$(command -v python || true)"
  echo "python_version=$(python --version 2>&1 || true)"
  echo "git_commit=$(git rev-parse HEAD 2>/dev/null || true)"
  echo

  echo "## Python packages"
  python - <<'PY' 2>&1 || true
import importlib.util
for name in ("yaml", "pynvml"):
    print(f"{name}={'ok' if importlib.util.find_spec(name) else 'missing'}")
PY
  echo

  echo "## NVIDIA tools"
  for tool in nvidia-smi nvcc ncu nsys; do
    if command -v "${tool}" >/dev/null 2>&1; then
      echo "${tool}=$(command -v "${tool}")"
      case "${tool}" in
        nvidia-smi) nvidia-smi --version || true ;;
        nvcc) nvcc --version || true ;;
        ncu) ncu --version || true ;;
        nsys) nsys --version || true ;;
      esac
    else
      echo "${tool}=missing"
    fi
    echo
  done

  echo "## GPU inventory"
  nvidia-smi -L 2>&1 || true
  echo

  echo "## GPU state"
  nvidia-smi --query-gpu=index,uuid,name,persistence_mode,power.limit,power.draw,clocks.sm,clocks.mem,clocks.max.sm,clocks.max.memory,temperature.gpu,utilization.gpu --format=csv 2>&1 || true
  echo

  echo "## Compute processes"
  nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv 2>&1 || true
} | tee "${LOG_FILE}"
