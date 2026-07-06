# ARCHITECTURE

This is the top-level map for the H800 Wattchmen reproduction project. Keep this file short; use it for routing, not deep explanations.

## Goal

Build a staged system that measures SASS-class power on H800 and predicts operator power for GEMM, FlashMLA, and FlashAttention v3 with about 15% error or lower.

## Top-Level Structure

| Path | Purpose | Go deeper |
| --- | --- | --- |
| `.agents/knowledge/` | Canonical H800 knowledge base: papers, modeling, metrics, route map, measurement protocol, microbenchmark catalog, operator decomposition. | `.agents/knowledge/INDEX.md` |
| `.agents/library/` | Canonical raw source library: PDFs, NVIDIA manuals, benchmark repos, operator sources. | `.agents/knowledge/SOURCE_INVENTORY.md` |
| `harness/agents/` | Multi-agent roles and handoff contracts. Main Agent owns global control and quality tracking. | `harness/agents/main_agent.md` |
| `harness/phases/` | Small executable phases from route/environment checks through E2E validation and next-iteration planning. | `harness/roadmap.md` |
| `harness/design-spec/` | Design documents: modeling, calibration, measurement assumptions, and experimental design rationale. | `harness/design-spec/README.md` |
| `harness/exec-plans/` | Per-experiment plans. `xx-plan.md` produces `xx-exp`; after analysis, write `<xx+1>-plan.md`. | `harness/exec-plans/README.md` |
| `configs/` | YAML configuration templates for operators, profiling, power, and modeling. | `configs/power/nvml_policy.yaml` |
| `scripts/` | Stage entrypoints and logging placeholders. | `scripts/00_check_env.sh` |
| `src/` | Future implementation placeholders for operators, microbenchmarks, profiling, power, and modeling. | `src/modeling/README.md` |
| `experiments/` | H800 run outputs: raw, processed, reports, figures, logs. | `experiments/README.md` |
| `QUALITY.md` | Quality ledger for completed `xx-exp` loops. | `QUALITY.md` |
| `AGENTS.md` | Repository operating instructions for agents. | `AGENTS.md` |

## Experiment Loop

```text
Phase 00 route/environment
  -> Phase 01 metric/model boundary
  -> Phase 02 static + constant baseline
  -> Phase 03-05 operator profiling
  -> Phase 06-09 microbenchmark plan/build/power/profile extraction
  -> Phase 10 non-negative dynamic model fit
  -> Phase 11 operator ground-truth power collection
  -> Phase 12 operator prediction and validation
  -> QUALITY.md update
  -> harness/exec-plans/<xx+1>-plan.md
```

If error is above target, Phase 13 decides whether to add microbenchmarks, adjust modeling, or request human intervention.

## Key Rules

- Experiments run on the H800 server, not on the current server.
- Experiments assume the agent is already inside the approved H800 runtime environment; this repository does not manage runtime startup or lifecycle.
- Power measurement must follow `harness/design-spec/power_measurement_environment.md`.
- Phase 03-05 are profile-only; Phase 11 collects operator measured-power ground truth.
- `P_const` and `P_static` baselines are collected explicitly under `experiments/static_power/raw/`.
- Negative power is never accepted silently: negative measured power, negative baseline-subtracted dynamic power, negative fitted SASS coefficients, and negative predictions are invalid unless quarantined as diagnostics.
- Every complete experiment is recorded as `xx-exp` in `QUALITY.md`.
- `xx-plan.md` produces `xx-exp`; after `xx-exp`, the next plan is `<xx+1>-plan.md`.
