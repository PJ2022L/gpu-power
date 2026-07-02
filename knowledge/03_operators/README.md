# Operators

This directory exists because the final project target is operator-level prediction, not just reproducing Wattchmen in isolation.

## Project Target

For five operator families on H800:

- predict performance,
- measure the SASS instruction classes that construct the operators,
- train or extend the SASS-class power model,
- predict operator power from SASS-class counts and memory behavior,
- compare predicted operator power with measured operator power,
- control prediction error within 10%.

Target operator families:

- `gemm/`
- `flashmla/`
- `flashattention_v2/`
- `flashattention_v3/`
- `flashattention_v4/`

## Operator-Level Workflow

For each operator family:

1. Define representative shapes and dtypes.
2. Identify implementation sources, e.g. CUTLASS, cuBLAS, FlashAttention kernels, FlashMLA kernels, or local kernels.
3. Measure performance on H800.
4. Measure operator-level power/energy on H800.
5. Profile SASS opcode counts and cache/memory behavior.
6. Map dominant SASS classes to the Wattchmen-style instruction energy table.
7. Add missing SASS-class microbenchmarks.
8. Predict total operator energy/power.
9. Compare predicted vs measured operator power.
10. Record whether error is <= 10%.

## Common Data Template

Each operator subdirectory should eventually contain:

```text
README.md
shapes.md
implementation_notes.md
sass_profile_notes.md
power_validation.md
open_questions.md
```

## Important Rule

The SASS power model is trained from microbenchmarks, but the coverage priority is driven by these operators. If an opcode is common in GEMM/FlashAttention but absent from the microbenchmark suite, it must become a benchmark target.
