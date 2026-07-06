# Phase 03: Profile FlashMLA

## Goal

Collect FlashMLA kernel, SASS, and memory/cache profiles on H800. This phase is profiling only.

## Owner

Operator SASS Agent.

## Inputs

- `configs/operators/flashmla.yaml`
- `configs/profiling/ncu_metrics.yaml`
- `.agents/library/operators/FlashMLA/`

## Commands

```bash
scripts/01_profile_operators.sh configs/operators/flashmla.yaml
```

## Outputs

- `experiments/raw/operator_profiles/flashmla/`
- `experiments/processed/operator_sass/flashmla/`
- `experiments/reports/phase03_flashmla_profile.md`

## Acceptance Criteria

- Dense decoding, sparse decoding, and sparse prefill coverage is recorded or explicitly marked unavailable.
- Kernel names, shapes, dtypes, commands, implementation path, and commit are logged.
- SASS top-k and memory/cache counter summaries exist for each profiled kernel.
- Missing SASS classes are appended to `experiments/processed/operator_sass/missing_sass_classes.yaml`.
- No NCU/Nsys runtime or exploratory power is used as validation ground truth.

## Failure Handling

If FlashMLA cannot run, record the exact command, error log, build state, and missing dependency. Continue only with operators that can produce valid profiles.
