# H800 Measurement Protocol

## Sources

- Wattchmen paper: `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf`, Sections 3.3, 4, and 6.
- AccelWattch paper and hardware profiler scripts for reference measurement flow.
- NVIDIA `nvidia-smi` documentation.
- NVIDIA NVML API documentation.
- NVIDIA Nsight Compute profiling guide.

## Measurement Principle

Energy measurement and profiler collection should be separated:

- Energy mode: run long, steady-state kernels without Nsight Compute instrumentation; collect NVML power/energy, temperature, clocks, and utilization.
- Profiler mode: run shorter kernels with Nsight Compute to collect SASS opcode counts and cache behavior.

Do not use profiler-instrumented runtime as the energy runtime.

For operator validation, measure the complete operator call path used in the benchmark harness. If an operator launches multiple kernels, record each kernel and aggregate energy to the operator level.

## Baseline Defaults

Initial H800 defaults:

- target GPU: one H800 SXM/HGX GPU, exclusive use,
- repetitions: 5 energy runs per microbenchmark,
- energy duration: around 180 seconds per microbenchmark,
- cooldown: around 60 seconds after each run,
- profiler duration: reduced iterations, then scale opcode counts to energy-mode iteration count after verifying linear scaling,
- fixed or recorded SM and memory clocks,
- fixed or recorded power limit,
- no other process on the target GPU.

These defaults follow Wattchmen's paper setup and should be adjusted only with a logged reason.

## Pre-Run Isolation

Before a run:

```bash
nvidia-smi -i <GPU_ID>
nvidia-smi pmon -i <GPU_ID>
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
```

Requirements:

- No unrelated process on the target GPU.
- Persistence mode state recorded.
- MIG/MPS state recorded if applicable.
- GPU temperature recorded before warmup.
- Current clocks, max clocks, and power limit recorded.

If other processes exist, do not run the measurement unless the run is explicitly marked invalid/test-only.

## Clock And Power Controls

Preferred setup:

```bash
nvidia-smi -i <GPU_ID> -pm 1
nvidia-smi -i <GPU_ID> -pl <POWER_LIMIT_W>
nvidia-smi -i <GPU_ID> -lgc <SM_CLOCK_MHZ>,<SM_CLOCK_MHZ>
nvidia-smi -i <GPU_ID> -lmc <MEM_CLOCK_MHZ>,<MEM_CLOCK_MHZ>
```

If clock locking is unsupported or permission is missing:

- record the failure,
- record current and max clocks throughout the run,
- mark the run as not fully controlled.

Useful query:

```bash
nvidia-smi -i <GPU_ID> \
  --query-gpu=index,uuid,name,persistence_mode,power.limit,power.draw,clocks.sm,clocks.mem,clocks.max.sm,clocks.max.memory,temperature.gpu,utilization.gpu \
  --format=csv
```

Reset after experiments only if the script owns the setting:

```bash
nvidia-smi -i <GPU_ID> -rgc
nvidia-smi -i <GPU_ID> -rmc
```

## NVML Measurements

Use NVML APIs where possible:

- `nvmlDeviceGetPowerUsage`: instantaneous power in milliwatts.
- `nvmlDeviceGetTotalEnergyConsumption`: total energy counter in millijoules when supported.
- `nvmlDeviceGetUtilizationRates`: GPU and memory utilization.
- `nvmlDeviceGetClockInfo`: current clocks.
- `nvmlDeviceGetTemperature` or newer temperature APIs: device temperature.

Recommended energy-mode record:

```text
timestamp_ns,gpu_id,uuid,power_mw,total_energy_mj,temperature_c,sm_clock_mhz,mem_clock_mhz,gpu_util_pct,mem_util_pct
```

If `nvmlDeviceGetTotalEnergyConsumption` is unavailable, integrate power samples:

```text
E ~= sum_j power_w[j] * delta_t[j]
```

Wattchmen reports that integrated NVML power samples were within about 1% of the NVML energy counter in their setup, but this must be rechecked on H800.

## Steady-State Window

For every energy run:

1. Start sampling before kernel launch to capture idle baseline.
2. Launch the microbenchmark.
3. Ignore startup transients.
4. Use only the stable plateau for dynamic energy.
5. Stop sampling after kernel completion.
6. Record cooldown period.

Steady-state criteria:

- GPU utilization near target saturation.
- SM/memory clocks stable.
- No thermal or power throttling event.
- Power trace plateau has low variance.
- Temperature has reached a stable or slowly varying range.

Do not use the entire trace blindly if startup/shutdown transients are large.

## Constant And Static Baselines

Collect these at the beginning of each session and after major thermal changes:

1. Idle baseline:
   - no kernel running,
   - target GPU selected,
   - record power for a fixed window.
2. Active-no-op baseline:
   - NANOSLEEP or low-switching kernel,
   - all SMs active if possible,
   - record power plateau.
3. NOP loop:
   - high-activity instruction issue with minimal data movement,
   - used to constrain loop/control overhead and active static behavior.

Do not copy Wattchmen's V100/A100/H100 static numbers to H800. Measure them.

## Nsight Compute Profiling

Required instruction metrics:

- preferred: `sass__inst_executed_per_opcode_with_modifier_all`,
- fallback: `sass__inst_executed_per_opcode_with_modifier_selective`,
- fallback: `sass__inst_executed_per_opcode`,
- fallback: `sass__inst_executed_per_opcode_category`.

Useful memory instruction metrics:

- `sass__inst_executed_global_loads`,
- `sass__inst_executed_global_stores`,
- `sass__inst_executed_shared_loads`,
- `sass__inst_executed_shared_stores`,
- local load/store and spilling metrics when relevant.

Cache metrics vary by architecture and Nsight Compute version. Use `ncu --query-metrics` on the target system to choose exact `l1tex__*`, `lts__*`, and `dram__*` metrics for L1/L2/DRAM behavior.

Example profiler command:

```bash
ncu --target-processes all \
  --metrics sass__inst_executed_per_opcode_with_modifier_all,l1tex__t_sectors_pipe_lsu_mem_global_op_ld.sum,lts__t_sectors_op_read.sum,dram__sectors_read.sum \
  --csv --log-file <profile.csv> \
  ./benchmark_binary <args>
```

Metric availability must be confirmed before standardizing the script.

## Logging Requirements

Every run must write a metadata header before measurements:

```text
date_time_iso=
hostname=
git_commit=
command=
args=
benchmark_name=
target_opcode=
gpu_id=
gpu_uuid=
gpu_name=
driver_version=
cuda_version=
ncu_version=
nvcc_version=
power_limit_w=
locked_sm_clock_mhz=
locked_mem_clock_mhz=
actual_sm_clock_mhz_before=
actual_mem_clock_mhz_before=
temperature_c_before=
iterations=
unroll_factor=
grid_dim=
block_dim=
data_size_bytes=
warmup_seconds=
measurement_seconds=
cooldown_seconds=
repeat_index=
notes=
```

User-specific rule:

- Python scripts run with the H800 Docker container's default `python`.
- Experimental shell scripts must print the run command and hyperparameters into the log for reproducibility.

## Run Order

Recommended session sequence:

1. Capture system metadata.
2. Confirm GPU isolation.
3. Lock or record clocks and power limit.
4. Measure idle baseline.
5. Warm up GPU to stable temperature if using a fixed-temperature policy.
6. Measure active-no-op baseline.
7. Run microbenchmark energy repetitions with cooldown.
8. Run profiler mode for the same microbenchmark.
9. Dump SASS.
10. Validate trace, opcode counts, cache behavior, and variance.

## Data Quality Checks

Reject or flag a run if:

- target GPU has another process,
- clocks are unstable outside a defined tolerance,
- power cap or thermal slowdown occurs,
- GPU utilization is much lower than expected,
- runtime is too short for steady-state energy,
- SASS opcode mix does not match benchmark intent,
- cache hit/miss behavior is wrong,
- repeated runs differ beyond tolerance,
- NVML energy counter wraps or is unsupported without proper integration fallback.

## Suggested Directory Layout For Future Measurements

```text
experiments/
  h800_wattchmen/
    logs/
    raw_power/
    raw_ncu/
    sass/
    metadata/
    processed/
```

Do not mix energy-mode and profiler-mode outputs without explicit naming.
