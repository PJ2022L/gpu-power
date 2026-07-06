# Phase 06: Microbenchmark Plan

## Goal

Turn operator SASS coverage gaps into a concrete microbenchmark plan.

## Owner

Microbench Agent. 仔细查看： `.agents/knowledge/DYNAMIC_POWER_MODEL.md`

## Inputs

- `experiments/processed/operator_sass/missing_sass_classes.yaml`
- `experiments/reports/phase03_flashmla_profile.md`
- `experiments/reports/phase04_gemm_profile.md`
- `experiments/reports/phase05_fa3_profile.md`
- `.agents/knowledge/MICROBENCHMARK_CATALOG.md`
- `.agents/library/benchmarks/accelwattch-ubench/`

## Commands

```bash
scripts/02_plan_microbenchmarks.sh experiments/processed/operator_sass/missing_sass_classes.yaml
```

## Outputs

- `experiments/processed/microbench/microbench_plan.yaml`
- `experiments/reports/phase06_microbench_plan.md`

## Acceptance Criteria

- Each target SASS class has one of: direct benchmark, grouped benchmark, scaled estimate, bucketed fallback, or explicit deferral.
- The plan covers ALU/control/shared/global-memory/L2/HBM/tensor-WGMMA classes required by the first operator profiles.
- Expected ancillary instructions are listed; isolation is not assumed.
- Required SASS verification method is defined for each benchmark.

## Failure Handling

If a dominant operator instruction cannot be targeted, mark it as a bucketed risk and prioritize it in the next `xx-plan.md`.
