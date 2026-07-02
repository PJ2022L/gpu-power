#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage:
  scripts/collect_baselines.sh <power_policy.yaml> idle
  scripts/collect_baselines.sh <power_policy.yaml> active_noop -- <active-no-op command...>

environment overrides:
  GPU_ID                 NVML GPU index, default: 0
  BASELINE_ID            output id override, default: <kind>_<timestamp>
  OUTPUT_DIR             output directory override
  DURATION_SEC           fixed-duration sampling for idle, default: policy measurement_seconds
  REPEAT                 repeat count override
  SAMPLE_INTERVAL_MS     sampling interval override
  COOLDOWN_SEC           cooldown override
  TIMEOUT_SEC            command timeout per repeat
  ALLOW_EXISTING_PROCESS set to 1 for exploratory non-exclusive runs
  FAIL_ON_REPEATABILITY  set to 1 to return non-zero if thresholds fail
  SET_CUDA_VISIBLE_DEVICES
                         default: 1 for active_noop; set to 0 to avoid exporting CUDA_VISIBLE_DEVICES
USAGE
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

ORIGINAL_ARGS=("$@")
printf -v ORIGINAL_COMMAND '%q ' "$0" "${ORIGINAL_ARGS[@]}"

POWER_CONFIG="$1"
BASELINE_KIND="$2"
shift 2

case "${BASELINE_KIND}" in
  idle|active_noop) ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ "${BASELINE_KIND}" == "active_noop" ]]; then
  if [[ "${1:-}" != "--" ]]; then
    usage
    exit 2
  fi
  shift
  if [[ $# -eq 0 ]]; then
    usage
    exit 2
  fi
else
  if [[ $# -ne 0 ]]; then
    usage
    exit 2
  fi
fi

GPU_ID="${GPU_ID:-0}"
BASELINE_ID="${BASELINE_ID:-${BASELINE_KIND}_$(date +%Y%m%d_%H%M%S)}"
OUTPUT_DIR="${OUTPUT_DIR:-experiments/raw/baseline_power/${BASELINE_ID}}"
LOG_DIR="experiments/logs"
mkdir -p "${LOG_DIR}" "${OUTPUT_DIR}" experiments/reports
LOG_FILE="${LOG_DIR}/collect_baselines_${BASELINE_ID}_$(date +%Y%m%d_%H%M%S).log"

if [[ "${BASELINE_KIND}" == "active_noop" && "${SET_CUDA_VISIBLE_DEVICES:-1}" == "1" ]]; then
  export CUDA_VISIBLE_DEVICES="${GPU_ID}"
fi

SAMPLER_ARGS=(
  --config "${POWER_CONFIG}"
  --gpu-id "${GPU_ID}"
  --output-dir "${OUTPUT_DIR}"
  --label "baseline_${BASELINE_KIND}"
  --metadata "baseline_kind=${BASELINE_KIND}"
  --metadata "cuda_visible_devices=${CUDA_VISIBLE_DEVICES:-}"
)

if [[ "${BASELINE_KIND}" == "idle" ]]; then
  if [[ -n "${DURATION_SEC:-}" ]]; then
    SAMPLER_ARGS+=(--duration-sec "${DURATION_SEC}")
  else
    POLICY_DURATION="$(
      python - "${POWER_CONFIG}" <<'PY' 2>/dev/null || true
import sys
try:
    import yaml
except ImportError:
    raise SystemExit(0)
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}
print(data.get("run_policy", {}).get("measurement_seconds", ""))
PY
    )"
    SAMPLER_ARGS+=(--duration-sec "${POLICY_DURATION:-180}")
  fi
fi
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
if [[ "${FAIL_ON_REPEATABILITY:-0}" == "1" ]]; then
  SAMPLER_ARGS+=(--fail-on-repeatability)
fi

printf -v WRAPPED_COMMAND '%q ' "$@"
printf -v SAMPLER_ARGS_RENDERED '%q ' "${SAMPLER_ARGS[@]}"

{
  echo "stage=collect_baselines"
  echo "power_config=${POWER_CONFIG}"
  echo "baseline_kind=${BASELINE_KIND}"
  echo "baseline_id=${BASELINE_ID}"
  echo "gpu_id=${GPU_ID}"
  echo "output_dir=${OUTPUT_DIR}"
  echo "cuda_visible_devices=${CUDA_VISIBLE_DEVICES:-}"
  echo "command=${ORIGINAL_COMMAND}"
  echo "wrapped_command=${WRAPPED_COMMAND}"
  echo "sampler=src/power/nvml_sampler.py"
  echo "sampler_args=${SAMPLER_ARGS_RENDERED}"
  echo "expected_outputs:"
  echo "  ${OUTPUT_DIR}/metadata.yaml"
  echo "  ${OUTPUT_DIR}/power_trace.csv"
  echo "  ${OUTPUT_DIR}/summary.yaml"
  echo "  ${OUTPUT_DIR}/repeatability.yaml"
} | tee "${LOG_FILE}"

python src/power/nvml_sampler.py "${SAMPLER_ARGS[@]}" -- "$@" 2>&1 | tee -a "${LOG_FILE}"
