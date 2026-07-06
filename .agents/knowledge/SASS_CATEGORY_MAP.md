# SASS Category Map

本文件定义 H800 动态功耗模型使用的 SASS category 初版映射。实际 opcode 名称必须来自 H800 上 `cuobjdump --dump-sass`、`nvdisasm` 和 NCU metrics；本表只是分类规则，不能替代实测 SASS。

## Required SASS Analysis Outputs

每个 microbenchmark 必须输出：

```text
experiments/dynamic_power/iter_<N>/sass_counts.csv
experiments/dynamic_power/iter_<N>/ncu_metrics.csv
```

至少记录：

- kernel name
- static SASS instruction list
- instruction category
- static instruction count
- loop body instruction count
- unroll factor
- CTA count
- warp count
- estimated dynamic instruction count
- measured runtime
- achieved occupancy
- SM utilization
- Tensor Core utilization
- DRAM throughput
- L2 hit rate
- issue rate
- warp stall reason

必须区分：

- static instruction count
- dynamic instruction count
- predicate 后实际执行次数
- loop 迭代次数
- 每 warp 执行次数
- 每 CTA 执行次数
- 全 GPU 执行次数

## Initial Categories

| Category | Example opcode families | Notes |
| --- | --- | --- |
| `fp32` | `FADD`, `FMUL`, `FFMA` | FP32 CUDA Core arithmetic |
| `fp16_bf16` | actual H800 scalar/vector half/bfloat opcodes TBD | Do not infer names without SASS |
| `int32` | `IADD3`, `IMAD`, `LOP3`, `MOV` | address arithmetic may be separate if needed |
| `conversion` | `F2F`, `I2F`, `F2I`, actual FP8/BF16 conversion opcodes TBD | Important for FlashMLA FP8 sparse decoding |
| `special_function` | `MUFU` family | softmax/exp/log approximations if emitted |
| `tensor_core` | `HMMA`, `MMA`, H800 observed `WGMMA`/`HGMMA` forms | Use observed SASS key |
| `global_load` | `LDG` variants | Split by width and cache behavior |
| `global_store` | `STG` variants | Split by width and write policy |
| `shared_memory` | `LDS`, `STS`, `LDSM` | Bank conflict may be separate behavior |
| `l2_hit` | derived behavior | Not opcode-only; from NCU cache metrics |
| `hbm_access` | derived behavior | Not opcode-only; from DRAM metrics |
| `branch_control` | `BRA`, `ISETP`, `PLOP3`, `SEL` | Split uniform/divergent if needed |
| `shuffle_vote` | `SHFL`, `VOTE`, ballot-like opcodes | Use H800 observed SASS |
| `atomic_reduction` | `ATOM`, `RED` | Separate global/shared if needed |
| `synchronization` | `BAR`, `BSYNC`, `MBARRIER`, cluster barriers | TMA/DSM critical |
| `async_copy_tma` | `LDGSTS`, TMA-lowered SASS, `CP.ASYNC` if emitted | Verify names per CUDA version |
| `residual_misc` | unsupported or low-count categories | Must shrink over iterations |

## Microbenchmark Coverage Requirements

Each iteration should report coverage by:

- direct measured category
- grouped category
- scaled category
- bucketed/residual category

If residual/misc contributes materially to E2E error, `.agents/knowledge/NEXT_ITERATION_PLAN.md` must propose new benchmark coverage.
