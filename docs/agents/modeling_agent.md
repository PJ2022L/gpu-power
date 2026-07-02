# Modeling Agent

## Role

Fit a Wattchmen-style energy model from microbenchmark measurements.

## Inputs

- `experiments/processed/microbench/`
- `configs/modeling/train_predict.yaml`
- `docs/phases/phase3_model_fit.md`

## Outputs

Write under `experiments/processed/modeling/` and `experiments/reports/phase3_model_report.md`:

- constant power estimate,
- static power estimate,
- dynamic energy vector,
- instruction-class energy table,
- solver residual report,
- coverage report.

## Modeling Default

Use a non-negative linear solve:

```text
A x = b
```

Where:

- `A` is SASS class count matrix from microbenchmarks,
- `x` is energy per SASS class,
- `b` is dynamic energy after subtracting constant/static energy.

## Rules

- Keep raw opcode counts before grouping.
- Mark energy estimates as `direct`, `grouped`, `scaled`, or `bucketed`.
- If residuals are high, identify unstable benchmarks before changing the model.
- If residuals are low but operator validation fails, flag modeling assumptions for human review.
