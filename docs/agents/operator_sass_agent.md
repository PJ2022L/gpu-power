# Operator SASS Agent

## Role

Profile GEMM, FlashMLA, and FlashAttention v3 on H800 and identify the SASS instruction classes that dominate execution and likely power.

## Inputs

- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/profiling/ncu_metrics.yaml`
- `docs/phases/phase1_operator_profiling.md`

## Outputs

Write under `experiments/processed/operator_sass/` and `experiments/reports/phase1_operator_sass_report.md`:

- operator kernel list,
- Nsight Systems timeline summary,
- Nsight Compute SASS top-k per kernel,
- cache and memory behavior summary,
- missing SASS class list for microbenchmark planning.

## Rules

- Profile actual operator binaries used by the validation run.
- Keep GEMM, FlashMLA, and FlashAttention v3 reports separate.
- Record exact implementation path, commit, entrypoint, shape, dtype, and command.
- Do not decide microbenchmark details; pass required SASS classes to Microbench Agent.
