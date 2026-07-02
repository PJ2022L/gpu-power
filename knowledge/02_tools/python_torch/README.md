# Python And PyTorch

## Role

Python/PyTorch owns high-level operator harnesses: choosing shapes, dtypes, warmup policy, iteration counts, and calling GEMM, FlashMLA, and FlashAttention implementations.

It does not own CUDA compiler flags, PTX/SASS inspection, Nsight metric definitions, or NVML power sampling.

## Required Project Rules

Activate the environment before Python runs:

```bash
conda activate vla
```

Print the full command and hyperparameters into the log. Record package versions:

```bash
python - <<'PY'
import torch
print("torch", torch.__version__)
print("cuda", torch.version.cuda)
print("cuda_available", torch.cuda.is_available())
print("device", torch.cuda.get_device_name())
PY
```

## Harness Responsibilities

A Python harness should record:

- operator family,
- implementation name and version/commit,
- shape tuple,
- dtype,
- batch/head/sequence parameters for attention,
- warmup iterations,
- measured iterations,
- random seed,
- target GPU ID,
- whether CUDA graphs are used,
- whether TF32/FP8/autocast options are enabled.

## Boundary With Operators

Operator-specific shape choices belong in `03_operators/`. This directory only defines how Python should run and log them.
