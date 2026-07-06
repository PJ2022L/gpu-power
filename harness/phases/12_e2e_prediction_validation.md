# Phase 12: E2E Prediction Validation

## Goal

Predict operator power from the fitted SASS energy table and compare against Phase 11 measured ground truth.

## Owner

Validation Agent.

## Inputs

- `experiments/processed/modeling/sass_energy_table.*`
- `experiments/processed/operator_sass/`
- `experiments/raw/operator_power/`
- `configs/modeling/train_predict.yaml`
- `.agents/knowledge/METRICS.md`

## Commands

```bash
scripts/06_predict_operators.sh configs/modeling/train_predict.yaml
scripts/07_validate_error.sh experiments/reports/operator_predictions.*
```

## Outputs

- `experiments/reports/operator_predictions.*`
- `experiments/reports/phase12_e2e_prediction_validation.md`

## Acceptance Criteria

- GEMM, FlashMLA, and FlashAttention v3 have measured and predicted power when valid ground truth exists.
- `P_pred >= 0`, `P_dynamic_pred >= 0`, and `P_pred >= P_const_static`.
- MSAE, per-sample error, max error, energy error, and latency error are reported.
- Missing and bucketed SASS contributions are reported.
- `MSAE <= 15%` is the first reproduction acceptance target.

## Failure Handling

If `MSAE > 15%`, proceed to Phase 13. If predictions become negative, reject the model output and return to Phase 10.
