# NVML

## Role

NVML owns hardware telemetry for power modeling: power, total energy if supported, clocks, temperature, utilization, and device identity.

It does not own SASS counts or cache metrics.

## Required APIs

Use these APIs where available:

- `nvmlDeviceGetPowerUsage`
- `nvmlDeviceGetTotalEnergyConsumption`
- `nvmlDeviceGetUtilizationRates`
- `nvmlDeviceGetClockInfo`
- `nvmlDeviceGetTemperature` or newer temperature APIs

## Required Samples

For energy runs, sample:

```text
timestamp_ns
gpu_id
uuid
power_mw
total_energy_mj
temperature_c
sm_clock_mhz
mem_clock_mhz
gpu_util_pct
mem_util_pct
```

## Measurement Rule

Prefer the total energy counter when supported. If unsupported, integrate timestamped power samples and record the sampling interval.

NVML measurement should run during non-profiled energy mode. Nsight Compute profiling and NVML energy measurement should be separate runs.
