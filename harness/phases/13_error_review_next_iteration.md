# Phase 13: Error Review And Next Iteration

## Goal

Decide whether the next experiment should add microbenchmarks, adjust grouping/scaling/bucketing, revise the model boundary, or request human intervention.

## Owner

Main Agent.

## Inputs

- `experiments/reports/phase08_microbench_power.md`
- `experiments/reports/phase09_sass_count_and_ncu_extract.md`
- `experiments/reports/phase10_dynamic_model_fit.md`
- `experiments/reports/phase12_e2e_prediction_validation.md`
- `QUALITY.md`

## Commands

No GPU command is required. This is a review and planning phase.

## Outputs

- Updated `QUALITY.md` entry for `xx-exp`
- `harness/exec-plans/<xx+1>-plan.md`
- `experiments/reports/phase13_error_review_next_iteration.md`

## Acceptance Criteria

- The `xx-exp` record lists microbenchmarks, model adjustments, problems, next guidance, and current MSAE.
- Any ablation or removed component is recorded in the simplified experiment log.
- The next plan follows `01-plan.md -> 01-exp -> 02-plan.md`.
- If error remains high, the plan states whether the dominant cause is missing SASS coverage, unstable measurement, baseline/static mismatch, memory hierarchy modeling, tensor/WGMMA/TMA grouping, or another modeling issue.
- Negative power, negative dynamic power, or negative coefficients are never accepted as a normal result.

## Failure Handling

If Phase 10 residual is low, coverage is high, repeatability passes, and Phase 12 error is still above target, stop and request human modeling review instead of only adding more microbenchmarks.
