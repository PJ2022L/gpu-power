#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage:
  GPU_ID=0 SHAPE_ID=<shape_id> scripts/05_collect_operator_power.sh <operator_config.yaml> [power_policy.yaml] -- <operator command...>

environment overrides:
  GPU_ID                 NVML GPU index, default: 0
  SHAPE_ID               output shape id, default: manual_shape
  OUTPUT_DIR             output directory override
  REPEAT                 repeat count override
  SAMPLE_INTERVAL_MS     sampling interval override
  COOLDOWN_SEC           cooldown override
  TIMEOUT_SEC            command timeout per repeat
  PRE_SAMPLE_SEC         seconds to sample before command starts
  POST_SAMPLE_SEC        seconds to sample after command exits
  ALLOW_EXISTING_PROCESS set to 1 for exploratory non-exclusive runs
  FAIL_ON_REPEATABILITY  set to 1 to return non-zero if thresholds fail
  REQUIRE_SATURATION     set to 1 to require configured GPU utilization threshold
  SET_CUDA_VISIBLE_DEVICES
                         default: 1; set to 0 to avoid exporting CUDA_VISIBLE_DEVICES
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

ORIGINAL_ARGS=("$@")
printf -v ORIGINAL_COMMAND '%q ' "$0" "${ORIGINAL_ARGS[@]}"
OPERATOR_CONFIG="$1"
shift

POWER_CONFIG="configs/power/nvml_policy.yaml"
if [[ $# -gt 0 && "${1:-}" != "--" ]]; then
  POWER_CONFIG="$1"
  shift
fi

if [[ "${1:-}" != "--" ]]; then
  usage
  exit 2
fi
shift

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

GPU_ID="${GPU_ID:-0}"
SHAPE_ID="${SHAPE_ID:-manual_shape}"
OPERATOR_NAME="$(basename "${OPERATOR_CONFIG}" .yaml)"
OUTPUT_DIR="${OUTPUT_DIR:-experiments/raw/operator_power/${OPERATOR_NAME}/${SHAPE_ID}}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" "${OUTPUT_DIR}" experiments/reports
LOG_FILE="${LOG_DIR}/05_collect_operator_power_$(basename "${OPERATOR_CONFIG}" .yaml)_$(date +%Y%m%d_%H%M%S).log"

if [[ "${SET_CUDA_VISIBLE_DEVICES:-1}" == "1" ]]; then
  export CUDA_VISIBLE_DEVICES="${GPU_ID}"
fi

SAMPLER_ARGS=(
  --config "${POWER_CONFIG}"
  --gpu-id "${GPU_ID}"
  --output-dir "${OUTPUT_DIR}"
  --label "operator_${OPERATOR_NAME}_${SHAPE_ID}"
  --metadata "operator_config=${OPERATOR_CONFIG}"
  --metadata "operator=${OPERATOR_NAME}"
  --metadata "shape_id=${SHAPE_ID}"
  --metadata "cuda_visible_devices=${CUDA_VISIBLE_DEVICES:-}"
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
if [[ -n "${PRE_SAMPLE_SEC:-}" ]]; then
  SAMPLER_ARGS+=(--pre-sample-sec "${PRE_SAMPLE_SEC}")
fi
if [[ -n "${POST_SAMPLE_SEC:-}" ]]; then
  SAMPLER_ARGS+=(--post-sample-sec "${POST_SAMPLE_SEC}")
fi
if [[ "${ALLOW_EXISTING_PROCESS:-0}" == "1" ]]; then
  SAMPLER_ARGS+=(--allow-existing-process)
fi
if [[ "${FAIL_ON_REPEATABILITY:-0}" == "1" ]]; then
  SAMPLER_ARGS+=(--fail-on-repeatability)
fi
if [[ "${REQUIRE_SATURATION:-0}" == "1" ]]; then
  SAMPLER_ARGS+=(--require-saturation)
fi
printf -v WRAPPED_COMMAND '%q ' "$@"
printf -v SAMPLER_ARGS_RENDERED '%q ' "${SAMPLER_ARGS[@]}"

{
  echo "stage=05_collect_operator_power"
  echo "operator_config=${OPERATOR_CONFIG}"
  echo "power_config=${POWER_CONFIG}"
  echo "gpu_id=${GPU_ID}"
  echo "operator=${OPERATOR_NAME}"
  echo "shape_id=${SHAPE_ID}"
  echo "output_dir=${OUTPUT_DIR}"
  echo "cuda_visible_devices=${CUDA_VISIBLE_DEVICES:-}"
  echo "command=${ORIGINAL_COMMAND}"
  echo "wrapped_command=${WRAPPED_COMMAND}"
  echo "sampler=src/power/nvml_sampler.py"
  echo "sampler_args=${SAMPLER_ARGS_RENDERED}"
  echo "measurement_boundary=phase11_non_profiled_operator_power_ground_truth"
  echo "expected_outputs:"
  echo "  ${OUTPUT_DIR}/metadata.yaml"
  echo "  ${OUTPUT_DIR}/power_trace.csv"
  echo "  ${OUTPUT_DIR}/summary.yaml"
  echo "  ${OUTPUT_DIR}/repeatability.yaml"
  echo "  experiments/reports/phase11_e2e_power_ground_truth.md"
} | tee "${LOG_FILE}"

python src/power/nvml_sampler.py "${SAMPLER_ARGS[@]}" -- "$@" 2>&1 | tee -a "${LOG_FILE}"
