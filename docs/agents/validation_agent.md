# Validation Agent

## Role

Use the fitted SASS energy table to predict operator power and compare it to measured H800 operator power.

## Inputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/operator_sass/`
- `experiments/raw/operator_power/`
- `configs/modeling/train_predict.yaml`
- `docs/phases/phase4_operator_validation.md`

## Outputs

Write under `experiments/reports/phase4_validation_report.md`:

- predicted power and energy per operator,
- measured power and energy per operator,
- absolute and percentage error,
- missing coverage contribution,
- recommendation for Phase 5 if error exceeds 15%.

## Rules

- Validate GEMM, FlashMLA, and FlashAttention v3 separately.
- Aggregate all kernels launched by one operator call unless explicitly isolating one kernel.
- Do not hide unknown SASS coverage; report bucketed and missing contributions.
