# SASS

## Role

SASS is the final machine instruction layer and the main modeling unit for the H800 power model.

This directory owns:

- opcode taxonomy,
- modifier handling policy,
- instruction class grouping,
- SASS dump conventions,
- mapping from operator profiles to SASS classes.

It does not own how metrics are collected; that belongs in `../ncu_nsight_compute/`.

## Inspection Commands

Use SASS dumps to verify what the binary contains:

```bash
cuobjdump --dump-sass ./binary > binary.sass
nvdisasm ./binary > binary.nvdisasm.sass
```

Record the tool version if available.

## Modeling Policy

The H800 model should keep raw SASS opcode keys before grouping. Grouping can be applied later for energy-table coverage:

- direct: measured exact opcode/modifier,
- grouped: modifier variants considered equivalent,
- scaled: derived from width or hierarchy scaling,
- bucketed: fallback by instruction family.

## Important Hopper Classes

Track at least:

- integer ALU,
- FP ALU,
- predicate/control,
- global/shared/local/constant memory,
- `LDSM`,
- `LDGSTS` or async-copy paths,
- WGMMA/HGMMA tensor instructions,
- `MBARRIER` and related async barriers,
- TMA-related emitted instructions if visible.
