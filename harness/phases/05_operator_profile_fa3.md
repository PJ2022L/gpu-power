# Phase 05: Profile FlashAttention v3

## Goal

Collect FlashAttention v3 kernel, SASS, and memory/cache profiles on H800. This phase is profiling only.

## Owner

Operator SASS Agent.

## Inputs

- `configs/operators/flashattention_v3.yaml`
- `configs/profiling/ncu_metrics.yaml`

## Commands

```bash
scripts/01_profile_operators.sh configs/operators/flashattention_v3.yaml
```

## Outputs

- `experiments/raw/operator_profiles/flashattention_v3/`
- `experiments/processed/operator_sass/flashattention_v3/`
- `experiments/reports/phase05_fa3_profile.md`

## Acceptance Criteria

- FA3 forward target shapes are profiled on Hopper/H800.
- Kernel names, shapes, dtypes, commands, implementation path, and commit are logged.
- SASS top-k, WGMMA/TMA/barrier candidates, and memory/cache behavior are summarized.
- Missing SASS classes are appended to `experiments/processed/operator_sass/missing_sass_classes.yaml`.
- No validation power ground truth is collected in this phase.

## Failure Handling

If FA3 is unavailable in the runtime session, mark it unavailable in the phase report and continue with GEMM/FlashMLA only if the execution plan allows partial coverage.
