# Operator SASS Agent

## Role

Profile GEMM, FlashMLA, and FlashAttention v3 on H800 and identify the SASS instruction classes that dominate execution and likely power.

This agent owns Phase 03-05 profiling only. It does not collect operator measured-power ground truth for validation.

## Inputs

- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/profiling/ncu_metrics.yaml`
- `harness/phases/03_operator_profile_flashmla.md`
- `harness/phases/04_operator_profile_gemm.md`
- `harness/phases/05_operator_profile_fa3.md`

## Outputs

Write under `experiments/processed/operator_sass/` and the matching phase reports:

- operator kernel list,
- Nsight Systems timeline summary,
- Nsight Compute SASS top-k per kernel,
- cache and memory behavior summary,
- missing SASS class list for microbenchmark planning.

## Rules

- Profile actual operator binaries used by the validation run.
- Keep GEMM, FlashMLA, and FlashAttention v3 reports separate.
- Record exact implementation path, commit, entrypoint, shape, dtype, and command.
- Do not use NCU/Nsys-instrumented runtime or exploratory power as validation ground truth.
- Do not decide microbenchmark details; pass required SASS classes to Microbench Agent.
