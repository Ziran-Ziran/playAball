"""等待真正的 Windows Godot/Release 子进程，并保留输入或生命周期证据。"""
import argparse
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
import queue
import subprocess
import sys
import threading
import time


class MemoryCounters(ctypes.Structure):
    _fields_ = [("cb", wintypes.DWORD), ("faults", wintypes.DWORD)] + [
        (name, ctypes.c_size_t) for name in ["peak_ws", "working_set", "peak_paged", "paged",
                                            "peak_nonpaged", "nonpaged", "pagefile", "peak_pagefile", "private_bytes"]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--program", type=Path, required=True, help="当前设备 Godot 4.7.1 或已导出的样板 EXE")
    parser.add_argument("--project", type=Path, help="使用编辑器二进制时的隔离工程目录；Release 时省略")
    parser.add_argument("--mode", choices=["verify", "lifecycle", "capture"], default="verify")
    parser.add_argument("--cycles", type=int, default=120)
    parser.add_argument("--resolution", default="1280x720")
    parser.add_argument("--out", type=Path, required=True, help="证据文件的绝对前缀")
    args = parser.parse_args()
    if not 1 <= args.cycles <= 200:
        parser.error("cycles 必须在 1–200 之间")
    prefix = args.out.resolve()
    prefix.parent.mkdir(parents=True, exist_ok=True)
    if Path(str(prefix) + "_process.json").exists():
        parser.error("证据前缀已经使用；请换一个 --out，保留旧结果")
    command = [str(args.program.resolve())]
    if args.project:
        command += ["--path", str(args.project.resolve())]
    command += ["--max-fps", "60", "--resolution", args.resolution, "--"]
    if args.mode == "capture":
        command += ["--capture=" + str(prefix) + ".png"]
    else:
        command += ["--" + args.mode, "--out=" + str(prefix)]
        if args.mode == "lifecycle": command += ["--cycles=" + str(args.cycles)]
    start = time.monotonic()
    process = subprocess.Popen(command, cwd=args.program.resolve().parent,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    messages = queue.Queue()

    def read_output():
        for line in process.stdout:
            messages.put(line.decode("utf-8", errors="replace"))
        messages.put(None)

    threading.Thread(target=read_output, daemon=True).start()
    logs, samples = [], []
    timed_out = False
    try:
        while True:
            if time.monotonic() - start > 360:
                timed_out = True
                process.kill()
                break
            try:
                line = messages.get(timeout=0.5)
            except queue.Empty:
                continue
            if line is None: break
            logs.append(line)
            if line.startswith("CHAN_CYCLE "):
                sample = json.loads(line.removeprefix("CHAN_CYCLE "))
                counters = MemoryCounters()
                counters.cb = ctypes.sizeof(counters)
                ok = ctypes.windll.psapi.GetProcessMemoryInfo(
                    wintypes.HANDLE(int(process._handle)), ctypes.byref(counters), counters.cb)
                if not ok: raise ctypes.WinError()
                sample.update(private_bytes=counters.private_bytes, working_set=counters.working_set)
                samples.append(sample)
                print(f'cycle {sample["cycle"]}: private={sample["private_bytes"]}', flush=True)
        process.wait(timeout=10)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait(timeout=10)
        Path(str(prefix) + ".log").write_text("".join(logs), encoding="utf-8")
    summary = {"command": command, "exit_code": process.returncode,
               "seconds": round(time.monotonic() - start, 2), "timed_out": timed_out,
               "errors": sum(line.startswith(("ERROR:", "SCRIPT ERROR:")) for line in logs),
               "warnings": sum("WARNING:" in line for line in logs), "memory_samples": len(samples),
               "sampling_note": "PrivateUsage is asynchronous to the after-release Godot marker, not exact retained allocation size"}
    if samples:
        Path(str(prefix) + "_memory.json").write_text(json.dumps(samples, indent=2), encoding="utf-8")
    expected = Path(str(prefix) + (".png" if args.mode == "capture" else ".json"))
    summary["result_exists"] = expected.is_file()
    failure = timed_out or process.returncode != 0 or summary["errors"] or not expected.is_file()
    if args.mode != "capture" and expected.is_file():
        summary["reported_failures"] = json.loads(expected.read_text(encoding="utf-8"))["failures"]
        failure = failure or summary["reported_failures"] != 0
    Path(str(prefix) + "_process.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary))
    return int(bool(failure))


if __name__ == "__main__":
    sys.exit(main())
