# Reproduction Checklist

## Sources

- Wattchmen paper measurement and limitation sections.
- AccelWattch artifact workflow.
- NVIDIA `nvidia-smi`, NVML, and Nsight Compute documentation.
- Project-specific user instructions from `AGENTS.md` prompt.

## Before Writing Experiment Code

- Confirm the target machine is actually H800 SXM/HGX.
- Capture `nvidia-smi -L`.
- Capture `nvidia-smi -q`.
- Capture `nvidia-smi topo -m`.
- Capture CUDA, driver, `nvcc`, and `ncu` versions.
- Confirm `ncu --query-metrics` contains required SASS opcode metrics or document fallbacks.
- Decide the first microbenchmark suite from `wattchmen/03-microbenchmark-design.md`.

## Environment Rules

- Use the H800 Docker container's default `python`; do not require an external environment activation step.
- Shell scripts must print commands and hyperparameters to log files.
- Plotting scripts must be placed under the corresponding figure directory.
- Do not run measurement scripts without logging GPU ID, clocks, power limit, and exact command.

## GPU Isolation

Before each run:

- Check target GPU processes with `nvidia-smi` and `nvidia-smi pmon`.
- Confirm no unrelated process uses the GPU.
- Record GPU UUID and PCI bus ID.
- Record MIG/MPS state if relevant.
- Use a single target GPU unless the experiment explicitly studies multi-GPU behavior.

## Clock And Power Control

- Enable persistence mode if permitted.
- Set or record power limit.
- Lock SM clock if permitted.
- Lock memory clock if permitted.
- Record actual clocks before, during, and after the run.
- Record any failure to lock clocks.
- Reject runs with thermal or power throttling unless intentionally studying those effects.

## Energy Measurement

- Collect idle baseline.
- Collect active-no-op/NANOSLEEP baseline.
- Run each microbenchmark long enough to reach steady-state power.
- Use around 180 seconds per energy run for the baseline protocol.
- Repeat each energy run 5 times.
- Cool down around 60 seconds after each run.
- Log timestamped power, total energy if available, temperature, clocks, and utilization.
- Integrate power only if the NVML total energy counter is unavailable.

## Profiler Measurement

- Run Nsight Compute separately from energy runs.
- Use shorter iteration counts after verifying linear scaling.
- Collect SASS opcode metrics with modifiers when available.
- Collect cache metrics for L1/L2/DRAM behavior.
- Store the exact metric names and `ncu` command.
- Dump SASS for every benchmark binary.
- Reject benchmarks whose emitted SASS does not match their target.

## Data Validation

- Confirm target opcode count scales with iteration count.
- Confirm cache hit/miss behavior matches benchmark intent.
- Confirm GPU utilization is near expected saturation.
- Confirm power reaches a stable plateau.
- Check repeated-run variance.
- Check solver residuals after adding benchmark data.
- Keep raw data, processed data, and solver outputs separate.

## Minimum First Milestone

The first complete reproduction milestone should produce:

- H800 hardware metadata snapshot.
- Microbenchmark source for baseline, ALU, control, shared memory, global memory, and one tensor path.
- Energy traces for the first suite.
- Nsight Compute opcode/cache profiles for the same suite.
- SASS dumps for all binaries.
- A first non-negative linear solve.
- An instruction energy table with source labels: `direct`, `grouped`, `scaled`, or `bucketed`.
- A short validation report listing coverage, residuals, and unstable benchmarks.

## Do Not Do

- Do not hard-code H800 specs that have not been confirmed.
- Do not use AccelWattch's V100 component power table as an H800 table.
- Do not merge profiler runtime into energy measurement.
- Do not silently accept compiler-generated SASS changes.
- Do not run on a shared GPU and treat the result as valid.
- Do not omit clock, power, and temperature metadata.
