# Power Sampling

NVML power and energy collection code belongs here.

Measurement policy is configured in `configs/power/nvml_policy.yaml`.

Keep baseline, microbenchmark, and operator validation power collection separate:

- Phase 02 baseline traces go under `experiments/static_power/raw/`.
- Phase 08 microbenchmark traces go under `experiments/raw/microbench_power/`.
- Phase 11 operator ground truth goes under `experiments/raw/operator_power/`.

Do not collect validation ground truth from NCU/Nsys-instrumented runs.

## Minimal Sampler

Use `src/power/nvml_sampler.py` as the single base sampler for power data.

Runtime dependency:

```bash
python -c "import pynvml"
```

If `pynvml` is missing, record the missing dependency in the phase report. Do not change the runtime package state during a measurement run.

### Wrap A Command

```bash
python src/power/nvml_sampler.py \
  --config configs/power/nvml_policy.yaml \
  --gpu-id 0 \
  --output-dir experiments/raw/operator_power/gemm/smoke_fp16_square \
  --label operator_gemm_smoke_fp16_square \
  --metadata operator=gemm \
  --metadata shape_id=smoke_fp16_square \
  -- ./run_gemm --m 4096 --n 4096 --k 4096 --dtype fp16
```

For operator ground truth, prefer the shell wrapper because it logs the original command and exports `CUDA_VISIBLE_DEVICES=$GPU_ID` by default:

```bash
GPU_ID=0 SHAPE_ID=smoke_fp16_square \
scripts/05_collect_operator_power.sh configs/operators/gemm.yaml configs/power/nvml_policy.yaml -- \
  ./run_gemm --m 4096 --n 4096 --k 4096 --dtype fp16
```

### Fixed-Duration Sampling

Use this for idle or active-no-op baseline windows:

```bash
python src/power/nvml_sampler.py \
  --config configs/power/nvml_policy.yaml \
  --gpu-id 0 \
  --output-dir experiments/static_power/raw/idle_001 \
  --label idle_baseline \
  --duration-sec 60 \
  --repeat 5
```

By default the sampler records GPU utilization but does not fail the run for low utilization. Add `--require-saturation` for saturation microbenchmarks that should keep the GPU busy.

### Outputs

Each run writes:

- `metadata.yaml`: command, GPU identity, driver/NVML metadata, config path, extra metadata.
- `power_trace.csv`: timestamped samples of power, energy counter, temperature, clocks, utilization, pstate, throttle reasons.
- `summary.yaml`: per-repeat runtime, median power, integrated energy, energy-counter delta, temperature and clock ranges.
- `repeatability.yaml`: CV/drift checks against `configs/power/nvml_policy.yaml`.
