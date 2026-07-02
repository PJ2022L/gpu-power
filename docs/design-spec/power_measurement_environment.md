# Power Measurement Environment

## Purpose

GPU power measurements are sensitive to frequency, voltage, temperature, other GPU processes, clock throttling, and profiler overhead. This document defines the environment required before trusting H800 power data.

## Required Environment

Run valid experiments only when:

- the target machine is an H800 server,
- the experiment runs inside `operatorsforge:h800-v1.0` / `l2_mla_study`,
- exactly one target GPU is selected for the experiment,
- no unrelated process is running on the target GPU,
- persistence mode is enabled if permitted,
- SM clock is locked or continuously recorded,
- memory clock is locked or continuously recorded,
- power limit is fixed or recorded,
- temperature is recorded before, during, and after measurement,
- thermal throttling and power throttling are absent or explicitly recorded,
- energy/power runs are separate from NCU profiler runs.

## Sources Of Measurement Drift

| Factor | Why it matters | Required action |
| --- | --- | --- |
| SM frequency | Dynamic power and runtime change with clock. | Lock with `nvidia-smi -lgc` if possible; otherwise record continuously. |
| Memory frequency | Memory instruction energy/runtime depends on HBM clock. | Lock with `nvidia-smi -lmc` if possible; otherwise record continuously. |
| Voltage | Voltage follows clock and power policy; it changes dynamic power. | Record clock and power-limit state; note that direct voltage may not be exposed. |
| Other GPU processes | They contaminate power traces and cache behavior. | Reject run unless target GPU is exclusive. |
| Temperature | Leakage/static power changes with temperature. | Warm up consistently and record temperature trace. |
| Power cap throttling | Runtime and power plateau become policy-limited. | Reject or mark invalid unless intentionally studying capped behavior. |
| Thermal throttling | Changes clocks and power behavior. | Reject or mark invalid. |
| Profiler overhead | NCU changes runtime and execution behavior. | Never use profiled runtime for energy measurement. |

## Pre-Run Checks

Run before every experiment:

```bash
nvidia-smi -L
nvidia-smi -i <GPU_ID>
nvidia-smi pmon -i <GPU_ID>
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
nvidia-smi --query-gpu=index,uuid,name,power.limit,power.draw,clocks.sm,clocks.mem,temperature.gpu,utilization.gpu --format=csv
```

Log all outputs under `experiments/logs/`.

## Recommended Control Policy

If permissions allow:

```bash
nvidia-smi -i <GPU_ID> -pm 1
nvidia-smi -i <GPU_ID> -pl <POWER_LIMIT_W>
nvidia-smi -i <GPU_ID> -lgc <SM_CLOCK_MHZ>,<SM_CLOCK_MHZ>
nvidia-smi -i <GPU_ID> -lmc <MEM_CLOCK_MHZ>,<MEM_CLOCK_MHZ>
```

If any command fails, record the failure and mark the run as less controlled.

## Valid Run Criteria

A run is valid only if:

- target GPU is isolated,
- the sampled NVML GPU matches the GPU used by the measured command,
- command and hyperparameters are logged,
- clock/power/temperature metadata exist,
- power trace reaches a steady plateau,
- no unplanned throttling occurs,
- energy run is not an NCU run,
- repeated runs are within expected variance.

## Repeatability Thresholds

Use these v1 thresholds for microbenchmark and operator power runs. If the H800 server shows a different stable noise floor, Main Agent may revise the thresholds in an execution plan, but the reason must be recorded in `QUALITY.md`.

| Metric | Default threshold | How to compute | Action if exceeded |
| --- | --- | --- | --- |
| Median power CV across repeats | <= 2% | `std(median_power_per_repeat) / mean(median_power_per_repeat)` | Rerun after checking isolation, clocks, power cap, and temperature. |
| Total energy CV across repeats | <= 2% | `std(total_energy_per_repeat) / mean(total_energy_per_repeat)` | Rerun; if still high, mark benchmark/operator measurement unstable. |
| Runtime CV across repeats | <= 1% | `std(runtime_per_repeat) / mean(runtime_per_repeat)` | Rerun; inspect synchronization, clock drift, and competing processes. |
| Steady-state power window CV within one repeat | <= 1.5% | `std(power_samples_in_plateau) / mean(power_samples_in_plateau)` | Exclude transient window or rerun with longer warmup. |
| Temperature drift during measured plateau | <= 3 C | `max(temp_plateau) - min(temp_plateau)` | Increase warmup/cooldown or mark run thermally unstable. |
| Start temperature spread across repeats | <= 5 C | `max(start_temp) - min(start_temp)` | Add cooldown or fixed warmup policy before comparing repeats. |
| SM clock drift during plateau | <= 1% or <= 15 MHz | max relative or absolute drift in `clocks.sm` | Reject unless clock locking is unavailable and drift is explicitly modeled. |
| Memory clock drift during plateau | <= 1% or <= 15 MHz | max relative or absolute drift in `clocks.mem` | Reject unless recorded and justified. |
| GPU utilization during active plateau | >= 95% for saturation microbenchmarks | median `utilization.gpu` during plateau | For saturation benchmarks, rerun or fix occupancy/launch shape. |

For operator validation, the same thresholds apply to measured operator power. If an operator is intentionally bursty or short-running, aggregate enough iterations to form a stable plateau before applying these thresholds.

The utilization threshold is only a failure criterion for runs marked as saturation runs. Idle baselines and active-no-op baselines should record utilization but should not use this threshold as a pass/fail gate.

## Repeatability Report

Every Phase 2 microbenchmark report and Phase 4 validation report must include:

- number of repeats,
- median power per repeat,
- total energy per repeat,
- runtime per repeat,
- power CV,
- energy CV,
- runtime CV,
- plateau temperature range,
- start temperature spread,
- SM/memory clock drift,
- pass/fail decision against the thresholds above.

The base implementation for these fields is `src/power/nvml_sampler.py`, which writes `power_trace.csv`, `summary.yaml`, and `repeatability.yaml` for each measurement directory.

## Invalid Run Criteria

Reject or quarantine a run if:

- another user process is present on the GPU,
- clocks drift without being recorded,
- power limit changes mid-run,
- thermal or power throttling occurs,
- NCU instrumentation was used for the power run,
- logs do not include command, hyperparameters, and GPU metadata.
- repeatability thresholds are exceeded after one rerun, unless the run is explicitly marked exploratory.
