#!/usr/bin/env python3
"""Minimal NVML power sampler.

This script samples one GPU while either:

1. a command is running, or
2. a fixed duration elapses.

It writes:

- power_trace.csv
- metadata.yaml
- summary.yaml
- repeatability.yaml
- command_output_repeat_XXX.log, when a command is provided

Runtime dependency on the H800 machine:

    pip install nvidia-ml-py

The import name is `pynvml`.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import signal
import socket
import statistics
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional, Sequence, Tuple


CSV_FIELDS = [
    "repeat_index",
    "timestamp_ns",
    "time_iso",
    "elapsed_s",
    "gpu_index",
    "gpu_uuid",
    "gpu_name",
    "power_mw",
    "total_energy_mj",
    "temperature_c",
    "sm_clock_mhz",
    "mem_clock_mhz",
    "graphics_clock_mhz",
    "gpu_util_pct",
    "mem_util_pct",
    "pstate",
    "clock_throttle_reasons",
    "compute_process_count",
]


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def decode_nvml_string(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return str(value)


def load_yaml(path: Optional[Path]) -> Dict[str, Any]:
    if path is None:
        return {}
    try:
        import yaml
    except ImportError as exc:
        raise SystemExit(
            "PyYAML is required when --config is used. Install pyyaml in the H800 Docker image."
        ) from exc

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    if not isinstance(data, dict):
        raise SystemExit(f"config must be a YAML mapping: {path}")
    return data


def write_yaml(path: Path, data: Dict[str, Any]) -> None:
    try:
        import yaml

        with path.open("w", encoding="utf-8") as f:
            yaml.safe_dump(data, f, sort_keys=False, allow_unicode=False)
    except ImportError:
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, sort_keys=False)
            f.write("\n")


def get_nested(data: Dict[str, Any], keys: Sequence[str], default: Any = None) -> Any:
    cur: Any = data
    for key in keys:
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur


def bool_from_config(value: Any, default: bool) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "on"}
    return bool(value)


def parse_metadata(values: Sequence[str]) -> Dict[str, str]:
    result: Dict[str, str] = {}
    for item in values:
        if "=" not in item:
            raise SystemExit(f"--metadata expects key=value, got: {item}")
        key, value = item.split("=", 1)
        key = key.strip()
        if not key:
            raise SystemExit(f"--metadata key is empty: {item}")
        result[key] = value
    return result


def numeric_values(items: Iterable[Dict[str, Any]], key: str) -> List[float]:
    values: List[float] = []
    for item in items:
        value = item.get(key)
        if value is None or value == "":
            continue
        try:
            values.append(float(value))
        except (TypeError, ValueError):
            continue
    return values


def mean_or_none(values: Sequence[float]) -> Optional[float]:
    return statistics.mean(values) if values else None


def median_or_none(values: Sequence[float]) -> Optional[float]:
    return statistics.median(values) if values else None


def min_or_none(values: Sequence[float]) -> Optional[float]:
    return min(values) if values else None


def max_or_none(values: Sequence[float]) -> Optional[float]:
    return max(values) if values else None


def cv_percent(values: Sequence[float]) -> Optional[float]:
    if len(values) < 2:
        return None
    mean = statistics.mean(values)
    if mean == 0:
        return None
    return statistics.stdev(values) / mean * 100.0


def integrate_power_j(samples: Sequence[Dict[str, Any]]) -> Optional[float]:
    points: List[Tuple[int, float]] = []
    for sample in samples:
        ts = sample.get("timestamp_ns")
        power_mw = sample.get("power_mw")
        if ts is None or power_mw is None or power_mw == "":
            continue
        try:
            points.append((int(ts), float(power_mw)))
        except (TypeError, ValueError):
            continue
    if len(points) < 2:
        return None

    energy_j = 0.0
    for (t0, p0_mw), (t1, p1_mw) in zip(points, points[1:]):
        dt_s = (t1 - t0) / 1_000_000_000.0
        if dt_s <= 0:
            continue
        avg_power_w = ((p0_mw + p1_mw) / 2.0) / 1000.0
        energy_j += avg_power_w * dt_s
    return energy_j


def energy_counter_delta_j(samples: Sequence[Dict[str, Any]]) -> Optional[float]:
    values = [
        float(sample["total_energy_mj"])
        for sample in samples
        if sample.get("total_energy_mj") not in (None, "")
    ]
    if len(values) < 2:
        return None
    delta_mj = values[-1] - values[0]
    if delta_mj < 0:
        return None
    return delta_mj / 1000.0


def git_commit() -> Optional[str]:
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
        )
    except OSError:
        return None
    if proc.returncode != 0:
        return None
    return proc.stdout.strip() or None


class NvmlDevice:
    def __init__(self, gpu_id: int) -> None:
        try:
            import pynvml as nvml
        except ImportError as exc:
            raise SystemExit(
                "Missing NVML Python binding `pynvml`. Install `nvidia-ml-py` "
                "inside the H800 container, then rerun."
            ) from exc

        self.nvml = nvml
        self.nvml.nvmlInit()
        self.gpu_id = gpu_id
        self.handle = self.nvml.nvmlDeviceGetHandleByIndex(gpu_id)
        self.uuid = self._safe(lambda: decode_nvml_string(self.nvml.nvmlDeviceGetUUID(self.handle)))
        self.name = self._safe(lambda: decode_nvml_string(self.nvml.nvmlDeviceGetName(self.handle)))

    def close(self) -> None:
        self._safe(lambda: self.nvml.nvmlShutdown())

    def _safe(self, fn: Callable[[], Any], default: Any = None) -> Any:
        try:
            return fn()
        except Exception:
            return default

    def system_info(self) -> Dict[str, Any]:
        cuda_driver = self._safe(lambda: self.nvml.nvmlSystemGetCudaDriverVersion_v2())
        if cuda_driver is None:
            cuda_driver = self._safe(lambda: self.nvml.nvmlSystemGetCudaDriverVersion())
        return {
            "nvml_version": self._safe(lambda: decode_nvml_string(self.nvml.nvmlSystemGetNVMLVersion())),
            "driver_version": self._safe(lambda: decode_nvml_string(self.nvml.nvmlSystemGetDriverVersion())),
            "cuda_driver_version_raw": cuda_driver,
        }

    def compute_process_count(self) -> Optional[int]:
        for name in (
            "nvmlDeviceGetComputeRunningProcesses_v3",
            "nvmlDeviceGetComputeRunningProcesses_v2",
            "nvmlDeviceGetComputeRunningProcesses",
        ):
            fn = getattr(self.nvml, name, None)
            if fn is None:
                continue
            processes = self._safe(lambda fn=fn: fn(self.handle))
            if processes is not None:
                return len(processes)
        return None

    def sample(self, repeat_index: int, start_ns: int, start_mono: float) -> Dict[str, Any]:
        util = self._safe(lambda: self.nvml.nvmlDeviceGetUtilizationRates(self.handle))
        sm_clock_type = getattr(self.nvml, "NVML_CLOCK_SM", None)
        mem_clock_type = getattr(self.nvml, "NVML_CLOCK_MEM", None)
        graphics_clock_type = getattr(self.nvml, "NVML_CLOCK_GRAPHICS", None)

        now_ns = time.time_ns()
        sample = {
            "repeat_index": repeat_index,
            "timestamp_ns": now_ns,
            "time_iso": utc_now_iso(),
            "elapsed_s": time.monotonic() - start_mono,
            "gpu_index": self.gpu_id,
            "gpu_uuid": self.uuid,
            "gpu_name": self.name,
            "power_mw": self._safe(lambda: self.nvml.nvmlDeviceGetPowerUsage(self.handle)),
            "total_energy_mj": self._safe(lambda: self.nvml.nvmlDeviceGetTotalEnergyConsumption(self.handle)),
            "temperature_c": self._safe(
                lambda: self.nvml.nvmlDeviceGetTemperature(
                    self.handle, self.nvml.NVML_TEMPERATURE_GPU
                )
            ),
            "sm_clock_mhz": self._safe(
                lambda: self.nvml.nvmlDeviceGetClockInfo(self.handle, sm_clock_type)
                if sm_clock_type is not None
                else None
            ),
            "mem_clock_mhz": self._safe(
                lambda: self.nvml.nvmlDeviceGetClockInfo(self.handle, mem_clock_type)
                if mem_clock_type is not None
                else None
            ),
            "graphics_clock_mhz": self._safe(
                lambda: self.nvml.nvmlDeviceGetClockInfo(self.handle, graphics_clock_type)
                if graphics_clock_type is not None
                else None
            ),
            "gpu_util_pct": getattr(util, "gpu", None) if util is not None else None,
            "mem_util_pct": getattr(util, "memory", None) if util is not None else None,
            "pstate": self._safe(lambda: self.nvml.nvmlDeviceGetPerformanceState(self.handle)),
            "clock_throttle_reasons": self._safe(
                lambda: self.nvml.nvmlDeviceGetCurrentClocksThrottleReasons(self.handle)
            ),
            "compute_process_count": self.compute_process_count(),
        }
        sample["elapsed_s"] = f"{sample['elapsed_s']:.6f}"
        return sample


def terminate_process(proc: subprocess.Popen[Any]) -> None:
    if proc.poll() is not None:
        return
    try:
        os.killpg(proc.pid, signal.SIGTERM)
    except Exception:
        proc.terminate()
    try:
        proc.wait(timeout=10)
        return
    except subprocess.TimeoutExpired:
        pass
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except Exception:
        proc.kill()
    proc.wait(timeout=10)


def summarize_window(
    repeat_index: int,
    samples: Sequence[Dict[str, Any]],
    window_start_ns: int,
    window_end_ns: int,
    command_exit_code: Optional[int],
    timed_out: bool,
) -> Dict[str, Any]:
    window_samples = [
        sample
        for sample in samples
        if window_start_ns <= int(sample["timestamp_ns"]) <= window_end_ns
    ]
    window_source = "measurement_window"
    if not window_samples:
        window_samples = list(samples)
        window_source = "full_trace_fallback_no_sample_inside_window"

    power_mw = numeric_values(window_samples, "power_mw")
    temperature = numeric_values(window_samples, "temperature_c")
    sm_clock = numeric_values(window_samples, "sm_clock_mhz")
    mem_clock = numeric_values(window_samples, "mem_clock_mhz")
    gpu_util = numeric_values(window_samples, "gpu_util_pct")
    process_count = numeric_values(window_samples, "compute_process_count")

    start_temp = temperature[0] if temperature else None
    end_temp = temperature[-1] if temperature else None
    sm_min = min_or_none(sm_clock)
    sm_max = max_or_none(sm_clock)
    mem_min = min_or_none(mem_clock)
    mem_max = max_or_none(mem_clock)

    return {
        "repeat_index": repeat_index,
        "sample_count": len(samples),
        "window_sample_count": len(window_samples),
        "window_source": window_source,
        "window_start_ns": window_start_ns,
        "window_end_ns": window_end_ns,
        "runtime_s": (window_end_ns - window_start_ns) / 1_000_000_000.0,
        "command_exit_code": command_exit_code,
        "timed_out": timed_out,
        "median_power_w": (median_or_none(power_mw) / 1000.0) if power_mw else None,
        "mean_power_w": (mean_or_none(power_mw) / 1000.0) if power_mw else None,
        "min_power_w": (min_or_none(power_mw) / 1000.0) if power_mw else None,
        "max_power_w": (max_or_none(power_mw) / 1000.0) if power_mw else None,
        "power_cv_percent": cv_percent(power_mw),
        "integrated_power_j": integrate_power_j(window_samples),
        "energy_counter_delta_j": energy_counter_delta_j(window_samples),
        "temperature_start_c": start_temp,
        "temperature_end_c": end_temp,
        "temperature_min_c": min_or_none(temperature),
        "temperature_max_c": max_or_none(temperature),
        "temperature_drift_c": (max(temperature) - min(temperature)) if temperature else None,
        "sm_clock_min_mhz": sm_min,
        "sm_clock_max_mhz": sm_max,
        "sm_clock_drift_mhz": (sm_max - sm_min) if sm_min is not None and sm_max is not None else None,
        "mem_clock_min_mhz": mem_min,
        "mem_clock_max_mhz": mem_max,
        "mem_clock_drift_mhz": (
            mem_max - mem_min if mem_min is not None and mem_max is not None else None
        ),
        "median_gpu_util_pct": median_or_none(gpu_util),
        "max_compute_process_count": max_or_none(process_count),
    }


def threshold_result(value: Optional[float], threshold: Optional[float], op: str) -> str:
    if value is None or threshold is None:
        return "not_evaluated"
    if op == "<=":
        return "pass" if value <= threshold else "fail"
    if op == ">=":
        return "pass" if value >= threshold else "fail"
    raise ValueError(op)


def build_repeatability(
    summaries: Sequence[Dict[str, Any]], thresholds: Dict[str, Any], require_saturation: bool
) -> Dict[str, Any]:
    median_power = numeric_values(summaries, "median_power_w")
    runtime = numeric_values(summaries, "runtime_s")
    energy_counter = numeric_values(summaries, "energy_counter_delta_j")
    integrated_energy = numeric_values(summaries, "integrated_power_j")
    energy = energy_counter if len(energy_counter) == len(summaries) else integrated_energy
    start_temps = numeric_values(summaries, "temperature_start_c")
    temp_drifts = numeric_values(summaries, "temperature_drift_c")
    power_cvs = numeric_values(summaries, "power_cv_percent")
    sm_clock_drifts = numeric_values(summaries, "sm_clock_drift_mhz")
    mem_clock_drifts = numeric_values(summaries, "mem_clock_drift_mhz")
    gpu_utils = numeric_values(summaries, "median_gpu_util_pct")

    metrics: Dict[str, Any] = {
        "repeat_count": len(summaries),
        "median_power_cv_percent": cv_percent(median_power),
        "total_energy_cv_percent": cv_percent(energy),
        "runtime_cv_percent": cv_percent(runtime),
        "max_plateau_power_cv_percent": max_or_none(power_cvs),
        "max_plateau_temperature_drift_c": max_or_none(temp_drifts),
        "start_temperature_spread_c": (max(start_temps) - min(start_temps)) if start_temps else None,
        "max_sm_clock_drift_mhz": max_or_none(sm_clock_drifts),
        "max_mem_clock_drift_mhz": max_or_none(mem_clock_drifts),
        "min_median_gpu_util_pct": min_or_none(gpu_utils),
        "energy_source_for_cv": "nvml_total_energy_counter"
        if len(energy_counter) == len(summaries)
        else "integrated_power",
    }

    checks = {
        "median_power_cv": threshold_result(
            metrics["median_power_cv_percent"],
            thresholds.get("median_power_cv_percent_max"),
            "<=",
        ),
        "total_energy_cv": threshold_result(
            metrics["total_energy_cv_percent"],
            thresholds.get("total_energy_cv_percent_max"),
            "<=",
        ),
        "runtime_cv": threshold_result(
            metrics["runtime_cv_percent"], thresholds.get("runtime_cv_percent_max"), "<="
        ),
        "plateau_power_cv": threshold_result(
            metrics["max_plateau_power_cv_percent"],
            thresholds.get("plateau_power_cv_percent_max"),
            "<=",
        ),
        "plateau_temperature_drift": threshold_result(
            metrics["max_plateau_temperature_drift_c"],
            thresholds.get("plateau_temperature_drift_c_max"),
            "<=",
        ),
        "start_temperature_spread": threshold_result(
            metrics["start_temperature_spread_c"],
            thresholds.get("start_temperature_spread_c_max"),
            "<=",
        ),
        "sm_clock_drift_mhz": threshold_result(
            metrics["max_sm_clock_drift_mhz"], thresholds.get("sm_clock_drift_mhz_max"), "<="
        ),
        "mem_clock_drift_mhz": threshold_result(
            metrics["max_mem_clock_drift_mhz"], thresholds.get("mem_clock_drift_mhz_max"), "<="
        ),
    }
    if require_saturation:
        checks["gpu_utilization"] = threshold_result(
            metrics["min_median_gpu_util_pct"],
            thresholds.get("saturation_gpu_utilization_percent_min"),
            ">=",
        )
    else:
        checks["gpu_utilization"] = "not_required"
    failed = [name for name, status in checks.items() if status == "fail"]
    return {
        "metrics": metrics,
        "thresholds": thresholds,
        "require_saturation": require_saturation,
        "checks": checks,
        "overall_pass": not failed,
        "failed_checks": failed,
    }


def run_one_repeat(
    *,
    repeat_index: int,
    device: NvmlDevice,
    csv_writer: csv.DictWriter,
    csv_file: Any,
    command: Sequence[str],
    duration_sec: Optional[float],
    timeout_sec: Optional[float],
    sample_interval_s: float,
    pre_sample_sec: float,
    post_sample_sec: float,
    output_dir: Path,
    cwd: Optional[Path],
) -> Dict[str, Any]:
    repeat_samples: List[Dict[str, Any]] = []
    stop_event = threading.Event()
    start_ns = time.time_ns()
    start_mono = time.monotonic()

    def sampler_loop() -> None:
        next_sample = time.monotonic()
        while not stop_event.is_set():
            sample = device.sample(repeat_index, start_ns, start_mono)
            repeat_samples.append(sample)
            csv_writer.writerow(sample)
            csv_file.flush()
            next_sample += sample_interval_s
            sleep_s = next_sample - time.monotonic()
            if sleep_s > 0:
                stop_event.wait(sleep_s)

    thread = threading.Thread(target=sampler_loop, name=f"nvml-sampler-{repeat_index}", daemon=True)
    thread.start()

    command_exit_code: Optional[int] = None
    timed_out = False
    if pre_sample_sec > 0:
        time.sleep(pre_sample_sec)

    window_start_ns = time.time_ns()
    if command:
        log_path = output_dir / f"command_output_repeat_{repeat_index:03d}.log"
        with log_path.open("w", encoding="utf-8") as command_log:
            proc = subprocess.Popen(
                list(command),
                stdout=command_log,
                stderr=subprocess.STDOUT,
                cwd=str(cwd) if cwd else None,
                start_new_session=True,
            )
            try:
                command_exit_code = proc.wait(timeout=timeout_sec)
            except subprocess.TimeoutExpired:
                timed_out = True
                terminate_process(proc)
                command_exit_code = proc.returncode if proc.returncode is not None else -signal.SIGKILL
    else:
        if duration_sec is None:
            raise SystemExit("either provide a command after -- or set --duration-sec")
        time.sleep(duration_sec)
        command_exit_code = 0

    window_end_ns = time.time_ns()
    if post_sample_sec > 0:
        time.sleep(post_sample_sec)
    stop_event.set()
    thread.join(timeout=max(2.0, sample_interval_s * 4.0))

    return summarize_window(
        repeat_index=repeat_index,
        samples=repeat_samples,
        window_start_ns=window_start_ns,
        window_end_ns=window_end_ns,
        command_exit_code=command_exit_code,
        timed_out=timed_out,
    )


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Sample GPU power using NVML while a command runs.")
    parser.add_argument("--config", type=Path, default=None, help="Power policy YAML.")
    parser.add_argument("--gpu-id", type=int, default=0, help="NVML GPU index.")
    parser.add_argument("--output-dir", type=Path, required=True, help="Output directory.")
    parser.add_argument("--label", default="nvml_sample", help="Human-readable run label.")
    parser.add_argument("--sample-interval-ms", type=float, default=None, help="Sampling interval.")
    parser.add_argument("--duration-sec", type=float, default=None, help="Sample fixed duration without a command.")
    parser.add_argument("--timeout-sec", type=float, default=None, help="Command timeout per repeat.")
    parser.add_argument("--pre-sample-sec", type=float, default=0.0, help="Sample before command window.")
    parser.add_argument("--post-sample-sec", type=float, default=0.0, help="Sample after command window.")
    parser.add_argument("--repeat", type=int, default=None, help="Repeat count. Defaults to config run_policy.repeats or 1.")
    parser.add_argument("--cooldown-sec", type=float, default=None, help="Cooldown between repeats.")
    parser.add_argument("--cwd", type=Path, default=None, help="Working directory for wrapped command.")
    parser.add_argument("--metadata", action="append", default=[], help="Extra metadata key=value. Repeatable.")
    parser.add_argument(
        "--allow-existing-process",
        action="store_true",
        help="Do not fail when compute processes already exist on the target GPU.",
    )
    parser.add_argument(
        "--fail-on-repeatability",
        action="store_true",
        help="Exit non-zero when repeatability thresholds fail.",
    )
    parser.add_argument(
        "--require-saturation",
        action="store_true",
        help="Fail repeatability if median GPU utilization is below the configured saturation threshold.",
    )
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Command to run after --.")
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)
    command = list(args.command)
    if command and command[0] == "--":
        command = command[1:]

    config = load_yaml(args.config)
    sample_interval_ms = args.sample_interval_ms
    if sample_interval_ms is None:
        sample_interval_ms = float(get_nested(config, ["nvml", "sample_interval_ms"], 100))
    if sample_interval_ms <= 0:
        raise SystemExit("--sample-interval-ms must be positive")

    repeat = args.repeat
    if repeat is None:
        repeat = int(get_nested(config, ["run_policy", "repeats"], 1))
    if repeat < 1:
        raise SystemExit("--repeat must be >= 1")

    cooldown_sec = args.cooldown_sec
    if cooldown_sec is None:
        cooldown_sec = float(get_nested(config, ["run_policy", "cooldown_seconds"], 0))

    exclusive_required = bool_from_config(
        get_nested(config, ["run_policy", "exclusive_gpu_required"], None), default=False
    )
    thresholds = get_nested(config, ["repeatability_thresholds"], {}) or {}

    args.output_dir.mkdir(parents=True, exist_ok=True)
    device = NvmlDevice(args.gpu_id)
    summaries: List[Dict[str, Any]] = []
    exit_code = 0

    try:
        process_count = device.compute_process_count()
        if exclusive_required and not args.allow_existing_process and process_count not in (None, 0):
            raise SystemExit(
                f"target GPU {args.gpu_id} has {process_count} compute process(es); "
                "rerun with --allow-existing-process only for exploratory runs"
            )

        metadata = {
            "created_at": utc_now_iso(),
            "label": args.label,
            "hostname": socket.gethostname(),
            "cwd": os.getcwd(),
            "git_commit": git_commit(),
            "python": sys.version.replace("\n", " "),
            "config": str(args.config) if args.config else None,
            "gpu_id": args.gpu_id,
            "gpu_uuid": device.uuid,
            "gpu_name": device.name,
            "system": device.system_info(),
            "command": command,
            "duration_sec": args.duration_sec,
            "sample_interval_ms": sample_interval_ms,
            "repeat": repeat,
            "cooldown_sec": cooldown_sec,
            "pre_sample_sec": args.pre_sample_sec,
            "post_sample_sec": args.post_sample_sec,
            "timeout_sec": args.timeout_sec,
            "exclusive_gpu_required": exclusive_required,
            "require_saturation": args.require_saturation,
            "initial_compute_process_count": process_count,
            "extra": parse_metadata(args.metadata),
        }
        write_yaml(args.output_dir / "metadata.yaml", metadata)

        trace_path = args.output_dir / "power_trace.csv"
        with trace_path.open("w", encoding="utf-8", newline="") as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=CSV_FIELDS)
            writer.writeheader()
            for repeat_index in range(repeat):
                summary = run_one_repeat(
                    repeat_index=repeat_index,
                    device=device,
                    csv_writer=writer,
                    csv_file=csv_file,
                    command=command,
                    duration_sec=args.duration_sec,
                    timeout_sec=args.timeout_sec,
                    sample_interval_s=sample_interval_ms / 1000.0,
                    pre_sample_sec=args.pre_sample_sec,
                    post_sample_sec=args.post_sample_sec,
                    output_dir=args.output_dir,
                    cwd=args.cwd,
                )
                summaries.append(summary)
                if summary.get("command_exit_code") not in (None, 0):
                    exit_code = int(summary["command_exit_code"])
                    break
                if repeat_index != repeat - 1 and cooldown_sec > 0:
                    time.sleep(cooldown_sec)

        repeatability = build_repeatability(summaries, thresholds, args.require_saturation)
        write_yaml(
            args.output_dir / "summary.yaml",
            {
                "metadata_path": "metadata.yaml",
                "trace_path": "power_trace.csv",
                "repeat_summaries": summaries,
            },
        )
        write_yaml(args.output_dir / "repeatability.yaml", repeatability)

        if args.fail_on_repeatability and not repeatability["overall_pass"]:
            return 3
        return exit_code
    finally:
        device.close()


if __name__ == "__main__":
    raise SystemExit(main())
