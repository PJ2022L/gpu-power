# HANDOFF

This document is the handoff entrypoint for the next agent working on `/data1/user/peijun/work/gpu-power`.

## Mission

Reproduce Wattchmen-style SASS instruction-level power modeling on H800, then predict operator power for:

- GEMM
- FlashMLA
- FlashAttention v3

Target validation metric: `MSAE < 15%`.

Do not run real GPU experiments unless you are already in the approved H800 runtime session.

Use the runtime session's default `python`.

## Canonical Routes

Use these paths only:

| Path | Purpose |
| --- | --- |
| `.agents/library/` | Raw source library: papers, NVIDIA docs, benchmark repos, operator sources. |
| `.agents/knowledge/` | Only knowledge base: modeling notes, metrics, route map, measurement protocol, microbenchmark catalog. |
| `harness/` | Experiment management docs, phases, agent roles, design specs, execution plans. |
| `scripts/` | Phase entrypoints and logging wrappers. |
| `src/` | Implementation placeholders and power sampler. |
| `experiments/` | H800 run outputs only. |

Only use the canonical routes above.

## First Reading Order

Read these before changing code or running scripts:

1. `ARCHITECTURE.md`
2. `AGENTS.md`
3. `README.md`
4. `.agents/knowledge/INDEX.md`
5. `.agents/knowledge/ROUTE_MAP.md`
6. `.agents/knowledge/METRICS.md`
7. `harness/roadmap.md`
8. `harness/phases/README.md`
9. `harness/agents/handoff_contracts.md`
10. `harness/design-spec/modeling.md`
11. `harness/design-spec/power_measurement_environment.md`
12. `QUALITY.md`

## Hard Rules

- Do not invent paths, paper conclusions, benchmark functionality, profiler output, or experiment results.
- Every technical conclusion must trace to a paper, source file, official doc, experiment log, profiler report, or code.
- Keep profiling and power measurement separate. NCU/Nsys runs are not power ground truth.
- Short kernels must be loop-amplified before power measurement.
- Log exact command, hyperparameters, GPU ID/UUID, clocks, power limit, CUDA/driver/NCU/Nsys versions, and git commit.
- Power cannot be accepted as negative. Negative measured power, baseline-subtracted dynamic power, fitted SASS coefficient, or prediction must be quarantined and diagnosed.
- Real H800 outputs go under `experiments/`; raw source material goes under `.agents/library/`.

## Runtime Safety

- Do not manage the surrounding runtime from this repository: no start, stop, rebuild, remove, prune, or lifecycle operations.
- Do not run destructive filesystem commands outside `/data1/user/peijun/work/gpu-power`; preserve `.agents/library/` and raw experiment data unless the user gives an explicit cleanup request.
- Do not kill unrelated GPU processes. If the target GPU is not isolated, mark the run invalid or stop for operator action.
- Do not change GPU clocks, power limits, persistence mode, MIG, ECC, driver state, CUDA installation, or device files except through an approved phase protocol that records the command and result.
- Do not install or upgrade system packages, CUDA components, drivers, or global Python packages during an experiment. Record missing dependencies in the phase report.
- Do not write temporary outputs into `.agents/library/`; use `experiments/`, phase-defined build directories, or timestamped scratch paths.
- Do not log secrets, tokens, private environment variables, or host credentials.
- Do not overwrite raw traces or reports in place; use timestamped or experiment-ID paths.

## Agent Roles

Agent role documents live under `harness/agents/`.

| Agent | Read | Owns |
| --- | --- | --- |
| Main Agent | `harness/agents/main_agent.md` | Global plan, phase gates, `QUALITY.md`, next `harness/exec-plans/<xx+1>-plan.md`. |
| Operator SASS Agent | `harness/agents/operator_sass_agent.md` | Phase 03-05 operator profiling, kernel list, SASS top-k, cache/memory behavior. |
| Microbench Agent | `harness/agents/microbench_agent.md` | Phase 06-09 microbenchmark plan/build/power/profile extraction. |
| Modeling Agent | `harness/agents/modeling_agent.md` | Phase 02 baseline and Phase 10 non-negative dynamic model fitting. |
| Validation Agent | `harness/agents/validation_agent.md` | Phase 11 operator power ground truth and Phase 12 prediction validation. |

Use `harness/agents/handoff_contracts.md` to decide whether a phase handoff is acceptable.

## Start From Phase 00

Do not skip phases. Each phase has goal, inputs, commands, outputs, acceptance criteria, and failure handling under `harness/phases/`.

### Phase 00: Route And Environment

Read:

```text
harness/phases/00_route_and_environment.md
```

Run only in the approved H800 runtime session:

```bash
scripts/00_check_env.sh
scripts/00_collect_h800_environment.sh configs/power/nvml_policy.yaml
```

Expected outputs:

```text
experiments/environment/
experiments/logs/
experiments/reports/phase00_route_and_environment.md
```

Gate:

- routes confirmed: `.agents/library/`, `.agents/knowledge/`, `harness/`, `experiments/`
- GPU model/UUID, driver, CUDA, NCU, Nsys, clocks, power limit, temperature, process state logged
- target GPU isolated or run marked invalid/exploratory

### Phase 01: Metric And Model Boundary

Read:

```text
harness/phases/01_metric_and_model_boundary.md
```

No GPU run. Confirm:

- `MSAE = mean(|P_pred - P_meas| / P_meas) * 100%`
- `P_const`, `P_static`, `P_dynamic` boundary
- profiling/power separation
- non-negative constraints

### Phase 02: Static And Constant Baseline

Read:

```text
harness/phases/02_static_power_baseline.md
```

Run on H800:

```bash
GPU_ID=<gpu> scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml idle
GPU_ID=<gpu> scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml empty_kernel_active -- <empty-kernel-loop-command>
GPU_ID=<gpu> scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml low_activity_kernel -- <full-sm-low-switching-command>
```

Gate:

- `P_const >= 0`
- `P_static = P_active_noop - P_const >= 0`
- repeatability passes
- no silent clamping

### Phase 03-05: Operator Profiling

Read:

```text
harness/phases/03_operator_profile_flashmla.md
harness/phases/04_operator_profile_gemm.md
harness/phases/05_operator_profile_fa3.md
```

Run:

```bash
scripts/01_profile_operators.sh configs/operators/flashmla.yaml
scripts/01_profile_operators.sh configs/operators/gemm.yaml
scripts/01_profile_operators.sh configs/operators/flashattention_v3.yaml
```

These phases collect NCU/Nsys/SASS/cache profiles only. They do not collect validation power ground truth.

Current source caveat: GEMM and FlashAttention v3 real source repos are not yet imported under `.agents/library/operators/`. If their configs still contain `TBD`, Main Agent must first write a plan to import/define the real operator runner.

### Phase 06-09: Microbenchmarks

Read:

```text
harness/phases/06_microbench_plan.md
harness/phases/07_microbench_build.md
harness/phases/08_microbench_power_measure.md
harness/phases/09_sass_count_and_ncu_extract.md
```

Entry scripts:

```bash
scripts/02_plan_microbenchmarks.sh experiments/processed/operator_sass/missing_sass_classes.yaml
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml --build-only
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml --power-only
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml --profile-only
```

If script modes are still placeholders, implement the mode before accepting the phase.

Gate:

- emitted SASS matches target
- power trace, SASS counts, and cache metrics align
- repeatability passes
- baseline-subtracted dynamic power is non-negative
- invalid/exploratory runs are excluded from fitting inputs

### Phase 10: Dynamic Model Fit

Read:

```text
harness/phases/10_dynamic_model_fit.md
```

Run:

```bash
scripts/04_fit_model.sh configs/modeling/train_predict.yaml
```

Gate:

- baseline IDs recorded
- dynamic RHS non-negative
- SASS coefficients non-negative
- predictions non-negative
- residual, coverage, condition/rank, grouping/scaling/bucketing reports exist

### Phase 11-12: E2E Ground Truth And Validation

Read:

```text
harness/phases/11_e2e_power_ground_truth.md
harness/phases/12_e2e_prediction_validation.md
```

Ground truth:

```bash
scripts/05_collect_operator_power.sh configs/operators/gemm.yaml configs/power/nvml_policy.yaml -- <gemm-command>
scripts/05_collect_operator_power.sh configs/operators/flashmla.yaml configs/power/nvml_policy.yaml -- <flashmla-command>
scripts/05_collect_operator_power.sh configs/operators/flashattention_v3.yaml configs/power/nvml_policy.yaml -- <fa3-command>
```

Prediction and validation:

```bash
scripts/06_predict_operators.sh configs/modeling/train_predict.yaml
scripts/07_validate_error.sh experiments/reports/operator_predictions.*
```

Gate:

- ground truth comes from non-profiled NVML runs
- NCU/Nsys runtimes are not used as power ground truth
- MSAE, per-operator error, dynamic power error, energy error, and latency error are reported
- target is `MSAE < 15%`

### Phase 13: Error Review And Next Iteration

Read:

```text
harness/phases/13_error_review_next_iteration.md
```

Update:

```text
QUALITY.md
harness/exec-plans/<xx+1>-plan.md
experiments/reports/phase13_error_review_next_iteration.md
```

If error is high, classify the cause before running more experiments:

- missing SASS coverage
- unstable microbenchmark
- baseline/static mismatch
- memory hierarchy modeling gap
- WGMMA/TMA/barrier grouping gap
- unclear operator source or shape
- modeling issue requiring human review

## Experiment Iteration Rule

A complete experiment is:

```text
micro-benchmark -> calibration/model fitting -> operator test
```

Record it as `xx-exp` in `QUALITY.md`.

Numbering is fixed:

```text
01-plan.md -> 01-exp -> 02-plan.md -> 02-exp
```

Main Agent must update `QUALITY.md` after each complete experiment and write the next plan under `harness/exec-plans/`.

## Useful Initial Commands

```bash
cd /data1/user/peijun/work/gpu-power
find . -maxdepth 2 -type d | sort
sed -n '1,160p' ARCHITECTURE.md
sed -n '1,180p' AGENTS.md
sed -n '1,220p' harness/phases/README.md
sed -n '1,220p' .agents/knowledge/INDEX.md
```
