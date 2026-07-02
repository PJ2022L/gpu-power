# Hardware Knowledge

This directory stores GPU architecture and memory hierarchy knowledge needed to predict H800 operator performance and power.

## Layout

- `h800/`: target GPU for measurement and model training.
- `b200/`: future comparison target for Blackwell-generation systems.
- `hopper/`: Hopper architecture concepts shared by H100/H800 class GPUs.
- `blackwell/`: Blackwell architecture concepts shared by B200 class GPUs.
- `memory_hierarchy/`: cross-generation notes on HBM, L2, L1/shared memory, TMA, cache hit/miss modeling, and bandwidth microbenchmarks.

## Rule

Keep target-card facts separate from architecture-family facts:

- H800-specific fields such as enabled SM count, power limit, clocks, HBM size, and topology belong in `h800/`.
- Hopper concepts such as WGMMA, TMA, thread-block clusters, and async barriers belong in `hopper/`.
- Cache and memory modeling concepts that apply across H800/B200 belong in `memory_hierarchy/`.
