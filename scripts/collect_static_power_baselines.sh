#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage:
  scripts/collect_static_power_baselines.sh <power_policy.yaml> <state> [-- <benchmark command...>]

states:
  idle
  persistence_idle
  locked_clock_idle
  empty_kernel_active
  low_activity_kernel
  temp_stabilized
  sm_clock_sweep
  mem_clock_sweep
  power_limit_sweep

environment overrides:
  GPU_ID                 NVML GPU index, default: 0
  STATIC_RUN_ID          output id override, default: <state>_<timestamp>
  OUTPUT_DIR             output directory override
  DURATION_SEC           fixed-duration sampling for states without command
  REPEAT                 repeat count override
  SAMPLE_INTERVAL_MS     sampling interval override
  COOLDOWN_SEC           cooldown override
  TIMEOUT_SEC            command timeout per repeat
  ALLOW_EXISTING_PROCESS set to 1 for exploratory non-exclusive runs
USAGE
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

POWER_CONFIG="$1"
STATE="$2"
shift 2

case "${STATE}" in
  idle|persistence_idle|locked_clock_idle|empty_kernel_active|low_activity_kernel|temp_stabilized|sm_clock_sweep|mem_clock_sweep|power_limit_sweep) ;;
  *)
    usage
    exit 2
    ;;
esac

COMMAND=()
if [[ $# -gt 0 ]]; then
  if [[ "${1}" != "--" ]]; then
    usage
    exit 2
  fi
  shift
  COMMAND=("$@")
fi

GPU_ID="${GPU_ID:-0}"
STATIC_RUN_ID="${STATIC_RUN_ID:-${STATE}_$(date +%Y%m%d_%H%M%S)}"
OUTPUT_DIR="${OUTPUT_DIR:-experiments/static_power/raw/${STATIC_RUN_ID}}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" "${OUTPUT_DIR}" experiments/static_power/processed experiments/static_power/plots
LOG_FILE="${LOG_DIR}/collect_static_power_${STATIC_RUN_ID}.log"
printf -v ORIGINAL_COMMAND '%q ' "$0" "$@"

SAMPLER_ARGS=(
  --config "${POWER_CONFIG}"
  --gpu-id "${GPU_ID}"
  --output-dir "${OUTPUT_DIR}"
  --label "static_power_${STATE}"
  --metadata "static_state=${STATE}"
  --metadata "static_run_id=${STATIC_RUN_ID}"
)

if [[ -n "${REPEAT:-}" ]]; then
  SAMPLER_ARGS+=(--repeat "${REPEAT}")
fi
if [[ -n "${SAMPLE_INTERVAL_MS:-}" ]]; then
  SAMPLER_ARGS+=(--sample-interval-ms "${SAMPLE_INTERVAL_MS}")
fi
if [[ -n "${COOLDOWN_SEC:-}" ]]; then
  SAMPLER_ARGS+=(--cooldown-sec "${COOLDOWN_SEC}")
fi
if [[ -n "${TIMEOUT_SEC:-}" ]]; then
  SAMPLER_ARGS+=(--timeout-sec "${TIMEOUT_SEC}")
fi
if [[ "${ALLOW_EXISTING_PROCESS:-0}" == "1" ]]; then
  SAMPLER_ARGS+=(--allow-existing-process)
fi

if [[ ${#COMMAND[@]} -eq 0 ]]; then
  SAMPLER_ARGS+=(--duration-sec "${DURATION_SEC:-180}")
fi

{
  echo "stage=collect_static_power_baselines"
  echo "state=${STATE}"
  echo "gpu_id=${GPU_ID}"
  echo "power_config=${POWER_CONFIG}"
  echo "output_dir=${OUTPUT_DIR}"
  echo "command=${ORIGINAL_COMMAND}"
  echo "sampler=python src/power/nvml_sampler.py ${SAMPLER_ARGS[*]} ${COMMAND[*]:-}"
  echo "required_followup=process into experiments/static_power/processed/static_power_samples.csv"
} | tee "${LOG_FILE}"

if [[ ${#COMMAND[@]} -gt 0 ]]; then
  python src/power/nvml_sampler.py "${SAMPLER_ARGS[@]}" -- "${COMMAND[@]}" 2>&1 | tee -a "${LOG_FILE}"
else
  python src/power/nvml_sampler.py "${SAMPLER_ARGS[@]}" 2>&1 | tee -a "${LOG_FILE}"
fi
