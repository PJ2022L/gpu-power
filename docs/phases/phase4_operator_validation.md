# Phase 4: Operator Prediction And Validation

## Goal

Predict operator power from the fitted SASS energy table and compare against measured operator power.

Phase 4 owns operator measured-power ground truth. This must be collected as non-profiled NVML energy runs using the same operator harness and shape set being predicted. Do not reuse Nsight-instrumented Phase 1 runtimes or any exploratory Phase 1 power samples as validation ground truth.

## Owner

Validation Agent.

## Inputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/operator_sass/`
- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/power/nvml_policy.yaml`
- `configs/modeling/train_predict.yaml`

## Commands

```bash
scripts/05_collect_operator_power.sh configs/operators/gemm.yaml configs/power/nvml_policy.yaml
scripts/05_collect_operator_power.sh configs/operators/flashmla.yaml configs/power/nvml_policy.yaml
scripts/05_collect_operator_power.sh configs/operators/flashattention_v3.yaml configs/power/nvml_policy.yaml
scripts/06_predict_operators.sh configs/modeling/train_predict.yaml
scripts/07_validate_error.sh experiments/reports/operator_predictions.*
```

Command roles:

- `05_collect_operator_power.sh`: Phase 4 ground truth only; wraps `src/power/nvml_sampler.py`; no NCU/Nsys. It sets `CUDA_VISIBLE_DEVICES=$GPU_ID` by default so the measured command runs on the sampled GPU.
- `06_predict_operators.sh`: prediction only; no power sampling.
- `07_validate_error.sh`: compare prediction against Phase 4 ground truth.

## Outputs

- `experiments/raw/operator_power/`
- `experiments/reports/phase4_operator_power_report.md`
- `experiments/reports/phase4_validation_report.md`

## Acceptance Criteria

- GEMM, FlashMLA, and FlashAttention v3 each have measured and predicted power.
- Measured operator power comes from Phase 4 non-profiled runs, not Phase 1 NCU/Nsys runs.
- Each measured operator power artifact has `metadata.yaml`, `power_trace.csv`, `summary.yaml`, and `repeatability.yaml`.
- Error percentage is reported.
- Unknown/bucketed contribution is reported.
- Operator measured-power repeatability passes thresholds in `docs/design-spec/power_measurement_environment.md`.
- Error <= 15% is considered acceptable for the first full reproduction target.

## Failure Handling

If error exceeds 15%, enter Phase 5.
