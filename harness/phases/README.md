# Phases

This directory breaks the H800 Wattchmen reproduction into small executable gates. A phase is accepted only when its outputs and acceptance criteria are satisfied.

| Phase | File | Purpose |
| --- | --- | --- |
| 00 | `00_route_and_environment.md` | Confirm routes, runtime session, GPU, tools, and logs. |
| 01 | `01_metric_and_model_boundary.md` | Lock metrics, const/static/dynamic boundary, and non-negative constraints. |
| 02 | `02_static_power_baseline.md` | Collect `P_const` and `P_static` baseline data. |
| 03 | `03_operator_profile_flashmla.md` | Profile FlashMLA SASS and memory/cache behavior. |
| 04 | `04_operator_profile_gemm.md` | Profile GEMM SASS and memory/cache behavior. |
| 05 | `05_operator_profile_fa3.md` | Profile FlashAttention v3 SASS and memory/cache behavior. |
| 06 | `06_microbench_plan.md` | Plan SASS-class microbenchmarks from operator gaps. |
| 07 | `07_microbench_build.md` | Build/adapt microbenchmarks and verify emitted SASS. |
| 08 | `08_microbench_power_measure.md` | Collect non-profiled microbenchmark power traces. |
| 09 | `09_sass_count_and_ncu_extract.md` | Produce matrix inputs from SASS counts, NCU metrics, and power summaries. |
| 10 | `10_dynamic_model_fit.md` | Fit the non-negative dynamic SASS energy model. |
| 11 | `11_e2e_power_ground_truth.md` | Collect non-profiled operator power ground truth. |
| 12 | `12_e2e_prediction_validation.md` | Predict and validate operator power. |
| 13 | `13_error_review_next_iteration.md` | Update `QUALITY.md` and write the next execution plan. |

Profile phases do not produce validation power ground truth. Power ground truth for E2E validation starts in Phase 11.
