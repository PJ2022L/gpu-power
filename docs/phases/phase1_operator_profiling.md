# Phase 1: Operator Profiling

## Goal

Run GEMM, FlashMLA, and FlashAttention v3 on H800 and collect their actual kernel and SASS profiles.

Phase 1 is profile-only. It collects Nsight Systems/Nsight Compute artifacts, SASS counts, and memory/cache behavior. It must not produce the operator measured-power ground truth used for validation.

If exploratory power samples are captured during Phase 1 for debugging, label them `exploratory` and do not use them in Phase 4 error calculation.

## Owner

Operator SASS Agent.

## Inputs

- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/profiling/ncu_metrics.yaml`

## Commands

```bash
scripts/01_profile_operators.sh configs/operators/gemm.yaml
scripts/01_profile_operators.sh configs/operators/flashmla.yaml
scripts/01_profile_operators.sh configs/operators/flashattention_v3.yaml
```

## Outputs

- `experiments/raw/operator_profiles/`
- `experiments/processed/operator_sass/`
- `experiments/reports/phase1_operator_sass_report.md`

## Acceptance Criteria

- Kernel list exists for each operator.
- SASS top-k exists for each kernel.
- Memory/cache behavior is summarized.
- Missing SASS classes are listed for Phase 2.
- Report states that Phase 1 did not generate validation power ground truth.

## Failure Handling

If an operator cannot run, record the implementation path, command, error log, and block Phase 2 for that operator.
