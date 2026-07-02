# Roadmap

## Objective

Reproduce the Wattchmen methodology on H800 and extend it to operator-level prediction:

```text
SASS instruction classes -> microbenchmark energy table -> operator power prediction
```

Initial target operators:

- GEMM
- FlashMLA
- FlashAttention v3

Target validation error: about 15% or lower against measured H800 operator power.

## Phase Overview

| Phase | Owner | Goal | Gate |
| --- | --- | --- | --- |
| 0 | Main Agent | Lock Wattchmen modeling interpretation. | Modeling checklist complete. |
| 1 | Operator SASS Agent | Profile target operators and identify dominant SASS classes; no validation power ground truth. | Kernel list, SASS top-k, memory behavior, missing class list. |
| 2 | Microbench Agent | Build and run microbenchmarks for target SASS classes. | Power traces, SASS counts, cache metrics for each benchmark. |
| 3 | Modeling Agent | Collect idle/active-no-op baselines, then fit const/static/dynamic and instruction-class energy table. | Baseline IDs, non-negative solution, residual report, coverage report. |
| 4 | Validation Agent | Collect non-profiled operator power ground truth, predict operator power, and compare. | Repeatable ground truth traces, prediction report, and error table for GEMM, FlashMLA, FlashAttention v3. |
| 5 | Main Agent | Iterate if error is above 15%, update quality history, and write the next execution plan. | `QUALITY.md` update, `docs/exec-plans/<xx+1>-plan.md`, or human modeling intervention. |

## Progression Rule

Do not advance to the next phase unless the current phase writes its handoff artifact and the Main Agent accepts it.

After every complete `micro-benchmark -> calibration/model fitting -> operator test` loop, the Main Agent must update `QUALITY.md` with an `xx-exp` entry.

## Failure Rule

If Phase 4 error exceeds 15%:

1. First inspect missing SASS coverage and high-energy unknown buckets.
2. Add or refine microbenchmarks in Phase 2.
3. Refit in Phase 3.
4. Retest in Phase 4.
5. If residual is low but operator error stays high, request human modeling intervention.

## Next-Plan Rule

`xx-plan.md` is the plan that produces `xx-exp`. After analyzing `xx-exp`, Main Agent writes the next experiment plan to `docs/exec-plans/<xx+1>-plan.md`. The plan must explain whether the next experiment should add microbenchmarks, change calibration/modeling, collect more operator profiles, or stop for human review.
