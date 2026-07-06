# Phase 07: Microbenchmark Build

## Goal

Implement or adapt the planned microbenchmarks and verify that emitted SASS matches intent.

## Owner

Microbench Agent.

## Inputs

- `experiments/processed/microbench/microbench_plan.yaml`
- `src/microbench/`
- `.agents/library/benchmarks/gpuwattch-ubench/`
- `.agents/library/benchmarks/accelwattch-ubench/`

## Commands

```bash
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml --build-only
```

If the current placeholder script does not yet support `--build-only`, the H800 agent must implement that mode before accepting this phase.

## Outputs

- `experiments/processed/microbench/build_manifest.yaml`
- `experiments/processed/microbench/sass_verification/`
- `experiments/reports/phase07_microbench_build.md`

## Acceptance Criteria

- Source path, build command, compiler version, flags, target SM, and git commit are logged.
- Emitted SASS is saved for every benchmark.
- The target SASS class is present and its share is reported.
- Ancillary instruction classes are recorded for the linear system.
- Benchmarks with missing or optimized-away target instructions are rejected.

## Failure Handling

If inline PTX or CUDA source does not produce the desired SASS, adjust codegen strategy or mark the class for grouping/bucketing.
