# NVCC

## Role

NVCC owns compilation reproducibility: architecture target, optimization flags, debug/line-info flags, and compiler version tracking.

It does not own PTX instruction semantics or final SASS taxonomy.

## Required Metadata

Log this for every compiled binary:

```bash
nvcc --version
```

Also log:

- CUDA toolkit path,
- compile command,
- `-arch` or `-gencode`,
- optimization flags,
- include/library paths,
- git commit of source code,
- output binary path and hash.

## H800 Baseline

For Hopper/H800, compile for the exact target architecture supported by the installed CUDA toolkit, typically an `sm_90` class target. Confirm on the actual H800 system.

Example pattern:

```bash
nvcc -O3 -lineinfo -arch=sm_90 -o bench bench.cu
```

## Reproducibility Notes

- Inline PTX does not guarantee final SASS.
- CUDA version changes can alter SASS instruction selection.
- Always pair NVCC logs with SASS dumps from the produced binary.
