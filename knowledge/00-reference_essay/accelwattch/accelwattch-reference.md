# AccelWattch Reference Notes

## Sources

- Paper: `knowledge/library/PDF/essay/2021-MICRO-AccelWattch-Kandiah.pdf`
- Repository URLs are listed below.
- Accel-Sim framework: `https://github.com/accel-sim/accel-sim-framework`
- GPU App Collection: `https://github.com/accel-sim/gpu-app-collection`

## Role In This Project

AccelWattch is not the reproduction target. It is useful because its artifact is public and contains:

- CUDA microbenchmarks,
- hardware power profiling scripts,
- NVML measurement code,
- validation workflow,
- instruction-to-component mapping ideas.

The H800 operator power project should borrow engineering patterns, not the AccelWattch model abstraction.

## What AccelWattch Models

AccelWattch is a cycle-level power model with:

- constant power modeling,
- static power modeling,
- dynamic power modeling,
- component-level power breakdowns,
- PTX/SASS simulation modes,
- hardware-counter and hybrid variants,
- DVFS-aware calibration.

It uses microbenchmarks and quadratic optimization to tune component power factors. This is different from Wattchmen, which solves for SASS instruction dynamic energy values directly from measured energy and opcode counts.

## Public Code Locations

Relevant repositories:

```text
https://github.com/accel-sim/accel-sim-framework
https://github.com/accel-sim/gpu-app-collection
```

Relevant paths observed in the public repositories:

```text
accel-sim-framework/AccelWattch.md
accel-sim-framework/util/accelwattch/accelwattch_hw_profiler/
accel-sim-framework/util/accelwattch/accelwattch_hw_profiler/measureGpuPower.cpp
accel-sim-framework/util/accelwattch/accelwattch_hw_profiler/profile_ubench_power.sh
accel-sim-framework/gpu-simulator/ISA_Def/accelwattch_component_mapping.h
gpu-app-collection/src/cuda/accelwattch-ubench/
```

Useful microbenchmark categories in `accelwattch-ubench`:

- `functional_benchmarks`: ALU, SFU, MOV, register-file style benchmarks.
- `memories_benchmarks`: L1/L2/DRAM/shared/constant/texture-style access benchmarks.
- `branching_benchmarks`: divergence and active-lane style benchmarks.
- `static_power_modeling`: static/idle power modeling support.

## Useful Ideas To Borrow

### Measurement Harness

`measureGpuPower.cpp` demonstrates a simple NVML-based sampler:

- initializes NVML,
- selects a GPU by index,
- samples power with `nvmlDeviceGetPowerUsage`,
- samples utilization with `nvmlDeviceGetUtilizationRates`,
- optionally monitors temperature,
- writes reports for later collation.

For the H800 operator power project, extend this idea to log:

- total energy counter if available,
- timestamps for integration,
- clocks,
- temperature,
- power limit,
- GPU UUID,
- process/kernel metadata.

### Repeated Runs

AccelWattch's profiling script repeats measurements and collates them. Wattchmen also uses repeated long runs. Reuse the repeated-run discipline, but make the output more metadata-rich for H800.

### Microbenchmark Organization

AccelWattch separates functional, memory, branching, and static-power microbenchmarks. Use a similar directory structure later:

```text
microbench/
  baseline/
  alu/
  control/
  memory/
  tensor/
  async/
```

### Buckets

AccelWattch maps instructions to microarchitectural components. Wattchmen uses buckets as a fallback for unknown instruction energy. Borrow the grouping intuition, but compute H800 bucket values from the Wattchmen instruction energy table, not from AccelWattch component power factors.

## What Not To Copy

Do not copy these as the H800 model target:

- V100-tuned power tables,
- AccelWattch quadratic optimization objective,
- component-level power breakdown as the final attribution,
- fixed assumptions about component power gating,
- PTX-level attribution when SASS counts are available.

Wattchmen requires measured SASS instruction energy on the target system.

## AccelWattch Lessons For H800

- Microbenchmarks can be public and source-level even when final SASS is architecture-specific.
- Inline PTX is only a hint. Always verify SASS.
- Hardware power measurement scripts need strict GPU isolation.
- Temperature and clocks materially affect measured power.
- Public profiler workflows are useful, but they must be updated for modern Hopper/H800 metric names.

## Future Use

Repository references should be recorded as links in `knowledge/library/repo/README.md`. Do not copy or clone repositories into the knowledge library.

If implementation later needs local checkouts outside `knowledge/`, record the repository URL, branch, commit, command, and environment in the experiment log.
