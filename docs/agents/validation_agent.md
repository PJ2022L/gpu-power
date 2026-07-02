# Validation Agent

## Role

Use the fitted SASS energy table to predict operator power and compare it to measured H800 operator power.

Validation Agent also owns Phase 4 operator measured-power ground truth collection. Ground truth must come from non-profiled NVML runs, separate from Phase 1 NCU/Nsys profiling.

## Inputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/operator_sass/`
- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/power/nvml_policy.yaml`
- `configs/modeling/train_predict.yaml`
- `docs/phases/phase4_operator_validation.md`

## Outputs

Write under `experiments/reports/phase4_validation_report.md`:

- measured operator power/energy source paths under `experiments/raw/operator_power/`,
- `experiments/reports/phase4_operator_power_report.md` summary from ground-truth collection,
- predicted power and energy per operator,
- measured power and energy per operator,
- absolute and percentage error,
- repeatability pass/fail summary,
- missing coverage contribution,
- recommendation for Phase 5 if error exceeds 15%.

## Rules

- Validate GEMM, FlashMLA, and FlashAttention v3 separately.
- Collect ground truth with `scripts/05_collect_operator_power.sh` or an equivalent non-profiled runner before validation.
- Aggregate all kernels launched by one operator call unless explicitly isolating one kernel.
- Do not hide unknown SASS coverage; report bucketed and missing contributions.
- Do not use profiler-instrumented runtimes or Phase 1 exploratory power samples as measured power ground truth.
- Apply `docs/design-spec/power_measurement_environment.md` repeatability thresholds before accepting measured operator power.
