# Phase 04: Profile GEMM

## Goal

Collect GEMM kernel, SASS, and memory/cache profiles on H800. This phase is profiling only.

## Owner

Operator SASS Agent.

## Inputs

- `configs/operators/gemm.yaml`
- `configs/profiling/ncu_metrics.yaml`

## Commands

```bash
scripts/01_profile_operators.sh configs/operators/gemm.yaml
```

## Outputs

- `experiments/raw/operator_profiles/gemm/`
- `experiments/processed/operator_sass/gemm/`
- `experiments/reports/phase04_gemm_profile.md`

## Acceptance Criteria

- At least one Tensor Core or CUDA Core GEMM path is profiled.
- Shape, dtype, layout, command, implementation path, and commit are logged.
- SASS top-k and tensor/memory/cache metrics are summarized.
- Missing SASS classes are appended to `experiments/processed/operator_sass/missing_sass_classes.yaml`.
- No validation power ground truth is collected in this phase.

## Failure Handling

If the configured GEMM entrypoint is ambiguous, stop this phase and require the execution plan to specify the library/kernel path.
