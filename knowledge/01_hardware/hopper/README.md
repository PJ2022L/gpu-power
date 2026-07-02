# Hopper Architecture

This directory stores Hopper architecture concepts that apply to H100/H800 class GPUs.

Topics to track:

- WGMMA/HGMMA tensor instructions.
- Tensor Memory Accelerator (TMA).
- Thread-block clusters.
- Async transaction barriers and `mbarrier`.
- `LDSM`, `LDGSTS`, async copy, and tensor operand movement.
- Hopper memory hierarchy behavior relevant to L1/L2/HBM modeling.

H800-specific enabled counts and limits belong in `../h800/`, not here.
