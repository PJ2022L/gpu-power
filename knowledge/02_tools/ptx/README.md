# PTX

## Role

PTX is NVIDIA's virtual/intermediate ISA. In this project it is useful for inline assembly and nudging the compiler toward target operations, but it is not the final modeling unit.

The final power model is SASS-class based.

## What To Record

For any inline PTX benchmark:

- PTX snippet,
- constraints,
- expected SASS opcode,
- actual SASS opcode after compilation,
- CUDA toolkit version,
- target `sm_` architecture.

## Key Caveat

PTX can lower to different SASS across GPU generations, CUDA versions, and flags. Therefore:

- PTX documentation helps understand intent,
- SASS dump confirms reality,
- Nsight Compute confirms dynamic execution counts.

## Boundary

PTX syntax and lowering notes belong here. Final opcode grouping and SASS taxonomy belong in `../sass/`.
