# Phase 10: Dynamic Model Fit

## Goal

Fit the non-negative Wattchmen-style dynamic SASS energy model.

## Owner

Modeling Agent.

## Inputs

- `experiments/static_power/raw/`
- `experiments/static_power/processed/static_power_samples.csv`
- `experiments/processed/microbench/microbench_matrix_inputs.*`
- `configs/modeling/train_predict.yaml`
- `harness/design-spec/modeling.md`

## Commands

```bash
scripts/04_fit_model.sh configs/modeling/train_predict.yaml
```

## Outputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/modeling/model_matrix.*`
- `experiments/processed/modeling/model_rhs.*`
- `experiments/reports/phase10_dynamic_model_fit.md`

## Acceptance Criteria

- `P_const`, `P_static`, and baseline IDs are recorded.
- Dynamic RHS values are non-negative. Rows with negative dynamic energy are rejected or quarantined with a reason.
- Final SASS coefficients are non-negative.
- Predictions generated for training diagnostics are non-negative.
- Residual, coverage, condition/rank, grouping/scaling/bucketing, and missing-class diagnostics are reported.

## Failure Handling

If many rows become negative after baseline subtraction, inspect baseline quality before adding microbenchmarks. If residual is high with valid rows, return to Phase 06.
