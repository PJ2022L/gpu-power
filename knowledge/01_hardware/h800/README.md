# H800 Hardware

H800 SXM/HGX is the primary target for this project.

## Purpose

This directory should collect:

- confirmed H800 hardware specifications,
- target machine `nvidia-smi` and CUDA device-query snapshots,
- H800 clock/power-limit policies,
- H800 memory hierarchy measurements,
- H800-specific notes that affect GEMM, FlashMLA, and FlashAttention power prediction.

## Current Status

The current working machine queried during initial exploration did not expose H800; it exposed RTX 5090 GPUs. Therefore all H800 numeric fields must be confirmed on the real H800 target machine before they are used in a model.

Start with `h800-hopper-notes.md`.
