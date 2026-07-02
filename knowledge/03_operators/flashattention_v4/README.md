# FlashAttention v4

> **Status: Future Work.** FlashAttention v4 is not in the current H800 scope. This directory is kept for future extension. Current targets are GEMM, FlashMLA, and FlashAttention v3.

## Role

FlashAttention v4 is tracked as a future target operator family and likely a moving implementation target. Keep version, commit, and kernel identity explicit.

## What To Track

- Implementation source and exact commit.
- H800-supported code paths.
- Kernel launch decomposition for the operator call.
- Dominant SASS classes.
- Differences from v2/v3 in memory movement, tensor instructions, barriers, and reductions.
- Validation target: predicted power within 15% of measured FlashAttention v4 power (future work, not in current H800 scope).

## Initial Questions

- Which implementation is considered FlashAttention v4 for this project?
- Is the target forward-only inference, training forward/backward, or both?
- Which shapes and dtypes are mandatory for first validation?
