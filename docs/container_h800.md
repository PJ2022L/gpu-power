# H800 Container Runtime

## Target Container

```text
image: operatorsforge:h800-v1.0
container name: l2_mla_study
```

Experiments should be run by the H800 server agent, not on the current server.

## Expected Runtime Properties

The container should expose:

- H800 GPU devices,
- CUDA toolkit,
- `nvcc`,
- Nsight Compute CLI `ncu`,
- Nsight Systems CLI `nsys`,
- NVML through NVIDIA driver libraries,
- Python environment with required operator packages.

## Required Startup Checks

The first H800 command should run:

```bash
scripts/00_check_env.sh configs/container.yaml
```

The log must include:

- hostname,
- container name if available,
- GPU list,
- driver version,
- CUDA version,
- `nvcc --version`,
- `ncu --version`,
- `nsys --version`,
- power limit,
- current clocks,
- target GPU process list.

## Logging Rule

Every stage command must write to `experiments/logs/` and include the exact command and config path.
