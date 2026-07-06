# Execution Plans

This directory stores per-experiment plans.

## Naming

Use:

```text
xx-plan.md
```

Examples:

- `01-plan.md`: plan for `01-exp`.
- `02-plan.md`: plan for `02-exp`, written after analyzing `01-exp`.

The numbering relationship is fixed:

```text
01-plan.md -> 01-exp -> 02-plan.md -> 02-exp -> 03-plan.md
```

In other words, `xx-plan.md` is the plan that produces `xx-exp`. After `xx-exp` is complete and analyzed in `QUALITY.md`, Main Agent writes `<xx+1>-plan.md`.

## When To Write A Plan

After each completed experiment (`xx-exp` in `QUALITY.md`), Main Agent analyzes:

- why error is high or low,
- which SASS classes are missing,
- whether microbenchmarks are unstable,
- whether calibration/modeling should change,
- what the next experiment should test.

Then Main Agent writes the next `<xx+1>-plan.md`.

## Plan Template

```markdown
# xx-plan

## Goal

What this experiment is trying to improve.

## Reason From Previous Experiment

Why this plan exists. Reference `QUALITY.md` and previous phase reports.

## Micro-benchmarks

What to add, remove, rerun, or validate.

## Modeling Changes

What to change in const/static/dynamic handling, grouping, scaling, bucketing, or solver settings.

## Operator Tests

Which GEMM/FlashMLA/FlashAttention v3 shapes to test.

## Expected Outcome

What error or diagnostic change would count as success.

## Stop Conditions

When to stop and request human intervention.
```
