# Phase 4: Operator Prediction And Validation

## Goal

Predict operator power from the fitted SASS energy table and compare against measured operator power.

## Owner

Validation Agent.

## Inputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/operator_sass/`
- `experiments/raw/operator_power/`
- `configs/modeling/train_predict.yaml`

## Commands

```bash
scripts/05_predict_operators.sh configs/modeling/train_predict.yaml
scripts/06_validate_error.sh experiments/reports/operator_predictions.*
```

## Outputs

- `experiments/reports/phase4_validation_report.md`

## Acceptance Criteria

- GEMM, FlashMLA, and FlashAttention v3 each have measured and predicted power.
- Error percentage is reported.
- Unknown/bucketed contribution is reported.
- Error <= 15% is considered acceptable for the first full reproduction target.

## Failure Handling

If error exceeds 15%, enter Phase 5.
