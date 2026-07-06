# Phase 09: SASS Count And NCU Extract

## Goal

Produce the processed matrix inputs required by model fitting from microbenchmark SASS counts, NCU metrics, and power summaries.

## Owner

Microbench Agent with Modeling Agent review.

## Inputs

- `experiments/raw/microbench_power/`
- `experiments/processed/microbench/sass_verification/`
- `configs/profiling/ncu_metrics.yaml`

## Commands

```bash
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml --profile-only
```

If the current placeholder script does not yet support `--profile-only`, the H800 agent must implement that mode before accepting this phase.

## Outputs

- `experiments/processed/microbench/microbench_matrix_inputs.*`
- `experiments/processed/microbench/sass_counts.*`
- `experiments/processed/microbench/cache_metrics.*`
- `experiments/reports/phase09_sass_count_and_ncu_extract.md`

## Acceptance Criteria

- SASS count rows align with valid power measurement rows.
- Cache hit/miss or memory-traffic metrics are present when used by the model.
- Raw opcode counts are preserved before grouping/scaling/bucketing.
- Invalid or exploratory runs are excluded from `microbench_matrix_inputs.*`.
- Matrix rows include baseline IDs needed for dynamic energy subtraction.

## Failure Handling

If NCU metrics are unavailable or renamed, record `ncu --query-metrics` output and update `configs/profiling/ncu_metrics.yaml`.
