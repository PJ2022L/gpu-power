# Validation Agent

## Role

Use the fitted SASS energy table to predict operator power and compare it to measured H800 operator power.

Validation Agent also owns Phase 11 operator measured-power ground truth collection. Ground truth must come from non-profiled NVML runs, separate from Phase 03-05 NCU/Nsys profiling.

## Inputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/operator_sass/`
- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/power/nvml_policy.yaml`
- `configs/modeling/train_predict.yaml`
- `harness/phases/11_e2e_power_ground_truth.md`
- `harness/phases/12_e2e_prediction_validation.md`

## Outputs

Write under `experiments/reports/phase11_e2e_power_ground_truth.md` and `experiments/reports/phase12_e2e_prediction_validation.md`:

- measured operator power/energy source paths under `experiments/raw/operator_power/`,
- `experiments/reports/phase11_e2e_power_ground_truth.md` summary from ground-truth collection,
- predicted power and energy per operator,
- measured power and energy per operator,
- absolute and percentage error,
- repeatability pass/fail summary,
- missing coverage contribution,
- recommendation for Phase 13 if error exceeds 15%.

## Rules

- Validate GEMM, FlashMLA, and FlashAttention v3 separately.
- Collect ground truth with `scripts/05_collect_operator_power.sh` or an equivalent non-profiled runner before validation.
- Aggregate all kernels launched by one operator call unless explicitly isolating one kernel.
- Do not hide unknown SASS coverage; report bucketed and missing contributions.
- Do not use profiler-instrumented runtimes or Phase 03-05 exploratory power samples as measured power ground truth.
- Apply `harness/design-spec/power_measurement_environment.md` repeatability thresholds before accepting measured operator power.
- Reject negative measured power, negative dynamic power, and negative predictions.
