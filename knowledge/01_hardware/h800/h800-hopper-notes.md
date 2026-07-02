# Hopper And H800 Hardware Notes

## Sources

- NVIDIA Hopper architecture technical blog: `https://developer.nvidia.com/blog/nvidia-hopper-architecture-in-depth/`
- NVIDIA CUDA C++ and PTX documentation: `https://docs.nvidia.com/cuda/`
- NVIDIA `nvidia-smi` documentation: `https://docs.nvidia.com/deploy/nvidia-smi/index.html`
- NVIDIA NVML API documentation: `https://docs.nvidia.com/deploy/nvml-api/`
- Local machine query during planning showed RTX 5090 GPUs, not H800. H800 fields below must be confirmed on the actual target machine.

## Scope

The reproduction target is H800 SXM/HGX first. PCIe differences are lower priority.

Important rule:

> Do not hard-code H800-specific numeric specifications unless they are confirmed from the target system or a reliable official source.

H800 public documentation is less complete than H100 public documentation. Use Hopper/H100 documentation to understand architectural features, but confirm H800 counts and limits on the actual machine.

## Hopper Features Relevant To Wattchmen

### Fourth-Generation Tensor Cores

Hopper adds fourth-generation Tensor Cores with support for modern AI/HPC data types, including FP8 paths. For energy modeling, this means the benchmark suite must include tensor instruction families rather than treating tensor work as generic FP ALU.

Relevant SASS/PTX families to watch:

- `HMMA`,
- `MMA`,
- `WGMMA`,
- SASS-displayed `HGMMA` forms,
- tensor operand movement instructions such as `LDSM`.

### WGMMA / Warp-Group Matrix Multiply

Hopper introduces warp-group matrix multiply behavior. A warp group involves multiple warps cooperating on a matrix operation. Energy attribution is more complex than older per-warp HMMA sequences because:

- the logical operation may emit multiple SASS instructions,
- operand movement and synchronization are tightly coupled,
- instruction counts may be reported at warp or thread level depending on metric.

H800 microbenchmarks should include at least one stable WGMMA/HGMMA shape early.

### Tensor Memory Accelerator

Hopper includes Tensor Memory Accelerator (TMA) support for large block transfers between global memory and shared memory, including cluster-related transfers.

For Wattchmen-style modeling:

- TMA should not be hidden inside generic memory energy.
- Build separate benchmarks for TMA/async copy and barriers after base global/shared memory benchmarks work.
- Inspect SASS for the actual instructions emitted by the CUDA version in use.

### Thread-Block Clusters

Hopper supports thread-block clusters and cluster-level cooperation. This can introduce:

- cluster synchronization,
- distributed shared-memory-like access patterns,
- additional barrier and async transaction instructions.

Initial H800 model can ignore cluster-specific behavior unless target workloads use it. If used, cluster benchmarks must be separate from normal single-block shared-memory benchmarks.

### Async Transaction Barriers

Hopper async data movement uses barrier mechanisms. The model should include barrier-heavy benchmarks if target workloads use TMA, WGMMA pipelines, or async copy.

Likely instruction families:

- `MBARRIER` variants,
- async arrive/wait forms,
- `BAR`/`BSSY`/`BSYNC` style control synchronization if emitted.

## H800 Specification Tracking

Use this table as a tracking template. Fill only after confirmation.

| Field | H800 SXM/HGX value | Source | Status |
| --- | --- | --- | --- |
| GPU architecture | Hopper-class | NVIDIA product naming / CUDA device query | Confirm on target |
| Compute capability | likely `sm_90` class | CUDA device query required | TODO |
| SM count | TODO | `deviceQuery`, `nvidia-smi -q`, CUDA runtime | TODO |
| HBM capacity | TODO | `nvidia-smi --query-gpu=memory.total` | TODO |
| HBM type | TODO | official source or system vendor docs | TODO |
| HBM bandwidth | TODO | official source or bandwidth microbenchmark | TODO |
| L2 cache size | TODO | official source, profiler properties, or microbenchmark | TODO |
| Shared memory per SM | TODO | CUDA device query | TODO |
| Max SM clock | TODO | `nvidia-smi --query-gpu=clocks.max.sm` | TODO |
| Max memory clock | TODO | `nvidia-smi --query-gpu=clocks.max.memory` | TODO |
| Default power limit | TODO | `nvidia-smi --query-gpu=power.default_limit` | TODO |
| Current power limit | TODO | `nvidia-smi --query-gpu=power.limit` | TODO |
| NVLink bandwidth/topology | TODO | `nvidia-smi topo -m`, vendor docs | TODO |
| MIG support/state | TODO | `nvidia-smi -q` | TODO |

## Commands To Confirm Target H800

Run on the actual H800 machine:

```bash
nvidia-smi -L
```

```bash
nvidia-smi --query-gpu=index,name,uuid,driver_version,memory.total,power.limit,power.default_limit,clocks.max.sm,clocks.max.memory,clocks.current.sm,clocks.current.memory,pci.bus_id --format=csv
```

```bash
nvidia-smi -q -i <GPU_ID> > h800_nvidia_smi_q_gpu<GPU_ID>.txt
```

```bash
nvidia-smi topo -m > h800_topology.txt
```

```bash
/usr/local/cuda/samples/1_Utilities/deviceQuery/deviceQuery > h800_device_query.txt
```

If CUDA samples are not built, compile `deviceQuery` from the CUDA samples repository or write a minimal CUDA runtime property dumper.

## Commands To Confirm Tool Metrics

```bash
ncu --version
ncu --query-metrics | grep -E 'sass__inst_executed|l1tex__|lts__|dram__' > h800_ncu_metrics.txt
```

Confirm that these exist or choose fallbacks:

- `sass__inst_executed_per_opcode_with_modifier_all`
- `sass__inst_executed_per_opcode`
- `sass__inst_executed_global_loads`
- `sass__inst_executed_global_stores`
- `sass__inst_executed_shared_loads`
- `sass__inst_executed_shared_stores`

## H100 Facts That Are Useful But Not H800-Specific

From NVIDIA Hopper public material:

- H100 SXM5 supports 80 GB HBM3 and over 3 TB/s memory bandwidth.
- Hopper includes Tensor Cores with FP8 support.
- Hopper includes TMA for efficient large-block global/shared memory movement.
- Hopper supports thread-block clusters and async transaction barriers.
- Hopper NVLink/NVSwitch systems support high-bandwidth multi-GPU communication.

These facts guide which instruction families to benchmark. They do not determine H800's exact enabled SM count, clocks, power limit, or bandwidth.

## Implication For Energy Modeling

H800 reproduction must account for:

- higher static and dynamic power than older V100-style systems,
- tensor instruction families as first-class energy contributors,
- memory hierarchy bandwidth and cache behavior,
- async copy/barrier instructions used by modern Hopper kernels,
- clock and power-limit sensitivity,
- possible system-level differences between SXM/HGX and PCIe cards.

The first H800 instruction table should be tied to a specific hardware/software tuple:

```text
GPU model + UUID class
driver version
CUDA toolkit version
Nsight Compute version
SM clock
memory clock
power limit
cooling/system type
```
