# Nsight Compute

## Role

Nsight Compute owns kernel-level profiling metrics: SASS opcode counts, memory hierarchy counters, occupancy, and per-kernel execution details.

It does not own timeline decomposition across a full Python process; that belongs in `../nsight_systems/`. It does not own power measurement; that belongs in `../nvml/`.

## Required Metric Families

Instruction counts:

- `sass__inst_executed_per_opcode_with_modifier_all`
- fallback: `sass__inst_executed_per_opcode_with_modifier_selective`
- fallback: `sass__inst_executed_per_opcode`
- fallback: `sass__inst_executed_per_opcode_category`

Memory instruction counts:

- `sass__inst_executed_global_loads`
- `sass__inst_executed_global_stores`
- `sass__inst_executed_shared_loads`
- `sass__inst_executed_shared_stores`

Cache and memory metrics are version-dependent. Confirm with:

```bash
ncu --query-metrics | grep -E 'sass__inst_executed|l1tex__|lts__|dram__'
```

## Profiling Rule

Run Nsight Compute separately from energy measurement. Profiling changes runtime and should not be used as the power run.

## Minimal Command Pattern

```bash
ncu --target-processes all \
  --metrics sass__inst_executed_per_opcode_with_modifier_all \
  --csv --log-file profile.csv \
  ./target_binary <args>
```

For Python operator harnesses, use kernel filters after identifying kernel names with Nsight Systems.
