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
| 00 | Main Agent | Confirm routes, runtime session, GPU environment, and logging readiness. | `phase00_route_and_environment.md` accepted. |
| 01 | Main Agent + Modeling Agent | Lock MSAE definition, model boundary, and non-negative constraints. | `phase01_metric_and_model_boundary.md` accepted. |
| 02 | Modeling Agent | Collect static/constant baselines. | Valid `experiments/static_power/raw/` baselines and non-negative `P_const`, `P_static`. |
| 03 | Operator SASS Agent | Profile FlashMLA; no validation power ground truth. | FlashMLA kernel/SASS/cache report. |
| 04 | Operator SASS Agent | Profile GEMM; no validation power ground truth. | GEMM kernel/SASS/cache report. |
| 05 | Operator SASS Agent | Profile FlashAttention v3; no validation power ground truth. | FA3 kernel/SASS/cache report. |
| 06 | Microbench Agent | Convert missing SASS classes into a benchmark plan. | `microbench_plan.yaml`. |
| 07 | Microbench Agent | Build/adapt microbenchmarks and verify emitted SASS. | Build manifest and SASS verification. |
| 08 | Microbench Agent | Collect non-profiled microbenchmark power traces. | Repeatable non-negative power traces. |
| 09 | Microbench Agent + Modeling Agent | Extract SASS counts and NCU/cache metrics into matrix inputs. | `microbench_matrix_inputs.*`. |
| 10 | Modeling Agent | Fit non-negative dynamic SASS energy model. | Non-negative RHS, coefficients, predictions, and residual report. |
| 11 | Validation Agent | Collect non-profiled operator power ground truth. | Repeatable operator traces. |
| 12 | Validation Agent | Predict and validate operator power. | MSAE and per-operator error report. |
| 13 | Main Agent | Analyze error, update `QUALITY.md`, and write next plan. | `QUALITY.md` and `harness/exec-plans/<xx+1>-plan.md`. |

## Progression Rule

Do not advance to the next phase unless the current phase writes its handoff artifact and the Main Agent accepts it.

After every complete `micro-benchmark -> calibration/model fitting -> operator test` loop, the Main Agent must update `QUALITY.md` with an `xx-exp` entry.

## Failure Rule

If Phase 12 error exceeds 15%:

1. First inspect missing SASS coverage and high-energy unknown buckets.
2. Add or refine microbenchmarks in Phase 06-09.
3. Refit in Phase 10.
4. Retest in Phase 11-12.
5. If residual is low but operator error stays high, request human modeling intervention.

Negative power is not a tunable residual. If baseline subtraction produces negative dynamic power, or the solver/predictor emits negative coefficients or predictions, reject or quarantine the artifact and fix the measurement/model boundary before continuing.

## Next-Plan Rule

`xx-plan.md` is the plan that produces `xx-exp`. After analyzing `xx-exp`, Main Agent writes the next experiment plan to `harness/exec-plans/<xx+1>-plan.md`. The plan must explain whether the next experiment should add microbenchmarks, change calibration/modeling, collect more operator profiles, or stop for human review.
