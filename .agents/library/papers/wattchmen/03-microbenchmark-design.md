# SASS-Level Microbenchmark Design

## Sources

- Main source: `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf`, especially Sections 3.1, 3.2, 3.3, 3.4, and 6.
- Reference source: `knowledge/library/PDF/essay/2021-MICRO-AccelWattch-Kandiah.pdf`.
- Public reference code: GPU App Collection `src/cuda/accelwattch-ubench`.
- NVIDIA Nsight Compute profiling guide for SASS opcode metrics.
- NVIDIA PTX ISA documentation for Hopper instructions, including WGMMA and async copy/barrier forms.

## Design Goal

Each microbenchmark should maximize the count of a target SASS opcode or target instruction family while still being valid, stable, and repeatable. It does not need to contain only the target opcode. Ancillary instructions are expected and should be handled by the global equation system.

The benchmark suite, not a single benchmark, is the unit of model construction.

For this project, the benchmark suite should be operator-driven: profile GEMM, FlashMLA, and FlashAttention v3 first, identify their dominant SASS instruction classes, then prioritize microbenchmarks for those classes.

## Required Output From Every Microbenchmark

Each microbenchmark must be able to run in two modes:

- energy mode: long steady-state run for NVML power/energy measurement.
- profiler mode: shorter run for SASS opcode counts and cache metrics.

The benchmark must report or log:

- benchmark name and target opcode family,
- CUDA source version and compile flags,
- GPU ID and UUID,
- grid/block dimensions,
- loop iteration count,
- unroll factor,
- data size and access pattern,
- expected target SASS opcode,
- output checksum or sink value to prevent dead-code elimination.

## General Kernel Shape

A typical benchmark should use this pattern:

```cuda
__global__ void target_kernel(..., unsigned long long iters) {
    int tid = blockDim.x * blockIdx.x + threadIdx.x;
    // Load seed data so the compiler cannot fold everything into constants.
    // Initialize registers.
    #pragma unroll UNROLL
    for (unsigned long long i = 0; i < iters; ++i) {
        // Repeated target operation or instruction sequence.
        // Use inline PTX where needed.
    }
    // Store sink result.
}
```

Implementation notes:

- Use a sink store or checksum so the target operations survive optimization.
- Prefer data dependencies only when needed to prevent elimination; excessive dependencies may serialize pipelines and distort energy.
- Use enough independent registers to keep issue slots busy for throughput-style instructions.
- Use `volatile` or inline assembly constraints only where necessary.
- Always verify emitted SASS with `cuobjdump --dump-sass` or `nvdisasm`.

## Saturating The GPU

Wattchmen training assumes all SMs and SIMT lanes are active.

Initial H800 policy:

- Choose enough blocks to cover all SMs, then oversubscribe by at least 2x to hide scheduling variation.
- Use block sizes that occupy full warps, e.g. 128, 256, or 512 threads depending on register/shared-memory pressure.
- Avoid branch divergence unless the benchmark is explicitly studying divergence/control flow.
- For ALU and memory throughput benchmarks, keep all 32 lanes active.
- Record occupancy with Nsight Compute or CUDA occupancy APIs in profiler mode.

Do not compare benchmarks that use different active-SM policies unless the model explicitly includes SM activity.

## Loop Count And Unrolling

The loop must run long enough for steady-state power and temperature.

Baseline from Wattchmen:

- 5 repetitions per microbenchmark.
- Around 180 seconds per energy run.
- Around 60 seconds cooldown after each run.

For early H800 bring-up:

- Tune `iters` so the kernel runs for at least the planned steady-state window.
- Use high unroll factors such as 64 or 100 to reduce loop overhead.
- Keep loop overhead visible in opcode counts; it will be solved as part of the system.
- For profiler mode, run fewer iterations and scale counts to the energy-mode iteration count only after confirming counts scale linearly.

## Opcode Verification Procedure

For every benchmark:

1. Compile for the exact target architecture, e.g. `-arch=sm_90` for Hopper-class H800.
2. Dump SASS:

```bash
cuobjdump --dump-sass ./benchmark_binary > sass.log
```

3. Check that target opcodes are present.
4. Run Nsight Compute with opcode metrics:

```bash
ncu --metrics sass__inst_executed_per_opcode_with_modifier_all ./benchmark_binary
```

5. If that metric is unavailable, fall back in this order:
   - `sass__inst_executed_per_opcode_with_modifier_selective`
   - `sass__inst_executed_per_opcode`
   - `sass__inst_executed_per_opcode_category`

6. Store the exact metric used.
7. Reject or rename a benchmark if the emitted SASS differs from its target.

## ALU Benchmarks

Initial ALU categories:

- integer: `MOV`, `IADD3`, `IMAD`, `IMAD.IADD`, `LOP3`, `PRMT`.
- FP32: `FADD`, `FMUL`, `FFMA`.
- FP64: `DADD`, `DMUL`, `DFMA`.
- conversion: `F2F`, `I2F`, `F2I` variants if they appear in target workloads.
- special function: `MUFU` or equivalent transcendental path if target workloads use it.

Design rules:

- Use independent register chains to avoid a pure latency benchmark unless latency behavior is the target.
- Include separate benchmarks for pure add/mul/fma and mixed sequences so the solver can distinguish coupled opcodes.
- For instructions that the compiler fuses, use inline PTX constraints or source patterns to encourage the desired SASS, then verify.
- Do not assume PTX opcode identity equals SASS opcode identity.

## Control-Flow And Predicate Benchmarks

Target opcodes:

- `BRA`,
- `ISETP` variants,
- predicate logic such as `PLOP3`,
- synchronization/control opcodes emitted around loops or barriers.

Design rules:

- Start with uniform branches where all lanes take the same path.
- Add divergence benchmarks only after the base model works.
- Use simple loop and predicate structures so branch instruction counts scale with iteration count.
- Keep target branch and predicate opcodes represented in other non-control benchmarks as ancillary instructions.

## Shared Memory Benchmarks

Target opcodes:

- `LDS`,
- `STS`,
- `LDSM` for tensor operand loading,
- shared-memory bank-conflict variants if needed.

Design rules:

- Create conflict-free load/store patterns first.
- Add bank-conflict patterns separately because they can change latency, issue behavior, and energy.
- Benchmark data widths: 32, 64, and 128 bits first; add 8/16-bit if target workloads use them heavily.
- For `LDSM`, design tensor-style shared-memory layouts rather than scalar shared loads.

## Global Memory Hierarchy Benchmarks

Target opcodes:

- `LDG` variants,
- `STG` variants,
- `LDGSTS` or async global-to-shared copy forms,
- local memory spill loads/stores if workloads show register spilling.

Required memory behaviors:

- L1 hit,
- L1 miss and L2 hit,
- DRAM access,
- coalesced access,
- selected uncoalesced or stride patterns after base cases.

Design rules:

- Control working-set size relative to L1 and L2 capacity.
- Use pointer chasing or large strides where needed to defeat cache hits.
- Use repeated small working sets for L1-hit cases.
- Use intermediate working sets for L2-hit cases.
- Use large streaming working sets for DRAM cases.
- Collect cache metrics in profiler mode and reject runs that do not produce the intended hit/miss behavior.

Memory instruction energy must be modeled by data width and hierarchy behavior. The SASS opcode alone does not reveal whether a load hit L1, hit L2, or went to HBM.

## Constant, Texture, And Local Memory

Include these only after global/shared memory base cases work:

- constant memory loads if target workloads use `LDC` or equivalent,
- texture/surface loads if target workloads use texture path,
- local memory loads/stores if spills are common.

For each path, build a hit/miss-style benchmark where the architecture exposes meaningful cache behavior.

## Tensor Core And Hopper WGMMA/HGMMA Benchmarks

Hopper introduces warp-group level matrix multiply behavior. Wattchmen's H100 evaluation explicitly encountered new warp-group matrix multiply instructions such as HGMMA/WGMMA-like forms and used bucketing to improve coverage when direct benchmarks were absent.

For H800, tensor benchmarks are mandatory because many target workloads will use Tensor Cores.

Target instruction families:

- `HMMA`/`MMA` compatibility paths,
- `WGMMA` or SASS-displayed `HGMMA` forms,
- `LDSM`,
- `LDGSTS`/async copy forms used to feed shared memory,
- `MBARRIER` and related async transaction barriers,
- `CP.ASYNC` or TMA-related generated instructions when present.

Design rules:

- Start from a minimal CUTLASS/CUDA inline PTX kernel that emits one stable WGMMA/HGMMA shape.
- Prefer one data type at a time: FP16, BF16, TF32, FP8 as separate benchmarks.
- Keep matrix shape fixed and record it in the benchmark name.
- Separate operand-movement energy from tensor math as much as possible:
  - tensor math loop with operands already in registers/shared memory,
  - `LDSM` shared-load loop,
  - global-to-shared async copy loop,
  - barrier-only or barrier-heavy loop.
- Treat multi-step tensor instruction sequences as one logical tensor operation only after verifying the emitted SASS sequence is stable.

## TMA And Async Copy Benchmarks

Hopper's Tensor Memory Accelerator transfers blocks between global and shared memory and supports async copies across thread-block clusters. These paths are important for H800 but harder to isolate.

Initial policy:

- Mark TMA benchmarks as a second-stage target after base `LDG/STG/LDS/STS/LDSM/WGMMA` coverage.
- Use official CUDA/Hopper examples or CUTLASS kernels that reliably emit TMA instructions.
- Build separate benchmark families for:
  - TMA bulk global-to-shared copy,
  - TMA shared-to-global copy if supported by the code path,
  - async barrier/mbarrier overhead,
  - cluster-level copy/synchronization.
- Always inspect SASS and Nsight Compute opcode counts because high-level CUDA APIs may lower differently by toolkit version.

## Benchmark Naming Convention

Use names that encode intent:

```text
<family>_<target>_<dtype-or-width>_<behavior>_<arch>
```

Examples:

- `alu_iadd3_u32_throughput_sm90`
- `fp_ffma_f32_throughput_sm90`
- `ctrl_isetp_uniform_sm90`
- `smem_lds_u64_conflictfree_sm90`
- `gmem_ldg_u128_l1hit_sm90`
- `gmem_ldg_u128_dram_sm90`
- `tensor_wgmma_f16_m64n64k16_sm90`
- `async_mbarrier_arrive_wait_sm90`

## Minimal First Suite

Build this suite before expanding:

| Family | Benchmarks |
| --- | --- |
| Baseline | idle, active NANOSLEEP, NOP loop |
| Integer | MOV, IADD3, IMAD, LOP3 |
| FP | FADD, FMUL, FFMA, DADD, DMUL, DFMA |
| Control | ISETP, BRA |
| Shared | LDS.32/64/128, STS.32/64/128 |
| Global | LDG.32/64/128 L1 hit, L2 hit, DRAM; STG.32/64/128 |
| Tensor | one WGMMA/HGMMA FP16 shape, LDSM support benchmark |
| Async | LDGSTS or equivalent async copy if emitted in target kernels |

## Acceptance Criteria

A microbenchmark is usable only if:

- target opcode is visible in SASS,
- target opcode count scales linearly with iteration count,
- target opcode is a large fraction of dynamic instructions or is otherwise necessary to constrain the system,
- GPU utilization reaches the intended level during energy mode,
- power reaches a stable plateau,
- cache hit/miss behavior matches the intended case,
- repeated energy measurements have acceptable variance,
- all metadata is logged.

## Common Failure Modes

- Compiler emits a different SASS opcode than expected.
- Dead-code elimination removes the target computation.
- Register pressure lowers occupancy and breaks SM saturation.
- Memory working set does not produce the intended cache behavior.
- Profiler mode changes runtime behavior relative to energy mode.
- Target GPU clocks drift because they were not locked or power/thermal throttling occurred.
- Tensor benchmark measures data movement more than tensor math.
