#!/usr/bin/env bash
set -uo pipefail

GPU_ID="${GPU_ID:-0}"
POWER_POLICY="${1:-configs/power/nvml_policy.yaml}"
OUT_DIR="${OUT_DIR:-experiments/environment/$(date +%Y%m%d_%H%M%S)}"
mkdir -p "${OUT_DIR}" experiments/logs
LOG_FILE="${OUT_DIR}/environment_collection.log"
SUMMARY_FILE="${OUT_DIR}/summary.env"
COMMAND_STATUS="${OUT_DIR}/command_status.tsv"

printf -v ORIGINAL_COMMAND '%q ' "$0" "$@"

run_capture() {
  local name="$1"
  shift
  local outfile="${OUT_DIR}/${name}.txt"
  local status="0"
  {
    echo "## command"
    printf '%q ' "$@"
    echo
    echo "## output"
    "$@"
  } >"${outfile}" 2>&1 || status="$?"
  printf '%s\t%s\t%s\n' "${name}" "${status}" "$(printf '%q ' "$@")" >>"${COMMAND_STATUS}"
  if [[ "${status}" != "0" ]]; then
    echo "command_failed name=${name} status=${status} output=${outfile}" | tee -a "${LOG_FILE}"
  fi
}

{
  echo "stage=00_collect_h800_environment"
  echo "command=${ORIGINAL_COMMAND}"
  echo "date_iso=$(date -Is)"
  echo "hostname=$(hostname)"
  echo "pwd=$(pwd)"
  echo "gpu_id=${GPU_ID}"
  echo "power_policy=${POWER_POLICY}"
  echo "runtime_session=${HOSTNAME:-unknown}"
  echo "python=$(command -v python || true)"
  echo "python_version=$(python --version 2>&1 || true)"
  echo "git_commit=$(git rev-parse HEAD 2>/dev/null || true)"
} | tee "${SUMMARY_FILE}" "${LOG_FILE}"

: >"${COMMAND_STATUS}"
printf 'name\tstatus\tcommand\n' >"${COMMAND_STATUS}"

run_capture nvidia_smi_L nvidia-smi -L
run_capture nvidia_smi_query_gpu nvidia-smi -i "${GPU_ID}" --query-gpu=name,uuid,driver_version,persistence_mode,power.limit,power.draw,clocks.sm,clocks.mem,temperature.gpu,utilization.gpu,mig.mode.current,ecc.mode.current --format=csv
run_capture nvidia_smi_q_power_clock_temp_util nvidia-smi -i "${GPU_ID}" -q -d POWER,CLOCK,TEMPERATURE,UTILIZATION
run_capture nvidia_smi_q_full nvidia-smi -i "${GPU_ID}" -q
run_capture nvidia_smi_compute_apps nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
run_capture nvidia_smi_topo nvidia-smi topo -m
run_capture nvidia_smi_dmon nvidia-smi dmon -i "${GPU_ID}" -c 5
run_capture nvidia_smi_power_clock_query nvidia-smi -i "${GPU_ID}" --query-gpu=power.draw,clocks.sm,clocks.mem,temperature.gpu,utilization.gpu --format=csv

if command -v nvcc >/dev/null 2>&1; then
  run_capture nvcc_version nvcc --version
else
  echo "tool_missing nvcc" | tee -a "${LOG_FILE}"
fi
if command -v ncu >/dev/null 2>&1; then
  run_capture ncu_version ncu --version
  run_capture ncu_query_sass_metrics bash -lc "ncu --query-metrics | grep -E 'sass__inst_executed|l1tex__|lts__|dram__' | head -200"
else
  echo "tool_missing ncu" | tee -a "${LOG_FILE}"
fi
if command -v nsys >/dev/null 2>&1; then
  run_capture nsys_version nsys --version
else
  echo "tool_missing nsys" | tee -a "${LOG_FILE}"
fi

run_capture verify_persistence_mode nvidia-smi -i "${GPU_ID}" -pm 1

if [[ -n "${VERIFY_SM_CLOCK_RANGE:-}" ]]; then
  run_capture verify_lock_sm_clock nvidia-smi -i "${GPU_ID}" -lgc "${VERIFY_SM_CLOCK_RANGE}"
else
  echo "skipped verify_lock_sm_clock reason=VERIFY_SM_CLOCK_RANGE_not_set" | tee -a "${LOG_FILE}"
fi

if [[ -n "${VERIFY_MEM_CLOCK_RANGE:-}" ]]; then
  run_capture verify_lock_mem_clock nvidia-smi -i "${GPU_ID}" -lmc "${VERIFY_MEM_CLOCK_RANGE}"
else
  echo "skipped verify_lock_mem_clock reason=VERIFY_MEM_CLOCK_RANGE_not_set" | tee -a "${LOG_FILE}"
fi

if [[ -n "${VERIFY_POWER_LIMIT:-}" ]]; then
  run_capture verify_power_limit nvidia-smi -i "${GPU_ID}" -pl "${VERIFY_POWER_LIMIT}"
else
  echo "skipped verify_power_limit reason=VERIFY_POWER_LIMIT_not_set" | tee -a "${LOG_FILE}"
fi

echo "output_dir=${OUT_DIR}" | tee -a "${LOG_FILE}"
echo "command_status=${COMMAND_STATUS}" | tee -a "${LOG_FILE}"
