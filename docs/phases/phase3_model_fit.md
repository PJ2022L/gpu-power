# Phase 3: Model Fitting And Calibration

## Goal

Fit the Wattchmen-style model using microbenchmark measurements.

## Owner

Modeling Agent.

## Inputs

- `experiments/processed/microbench/`
- `configs/modeling/train_predict.yaml`

## Command

```bash
scripts/04_fit_model.sh configs/modeling/train_predict.yaml
```

## Outputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/reports/phase3_model_report.md`

## Acceptance Criteria

- Constant/static estimates are recorded.
- Dynamic energy solve uses non-negative constraints by default.
- Residual report exists.
- Coverage report exists.
- Unknown, grouped, scaled, and bucketed classes are labeled.

## Failure Handling

High residuals should trigger benchmark quality inspection before changing the model.
