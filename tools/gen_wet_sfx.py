#!/usr/bin/env python3
"""Procedural CC0 splash + nest-steam beds. Stdlib only."""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

SR = 22050


def _clamp(v: float) -> int:
    return max(-32767, min(32767, int(v)))


def _write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(b"".join(struct.pack("<h", _clamp(s * 32767.0)) for s in samples))


def _crossfade(buf: list[float], fade: int = 900) -> list[float]:
    n = len(buf)
    fade = min(fade, n // 3)
    out = list(buf)
    for i in range(fade):
        k = i / float(fade)
        mixed = buf[i] * k + buf[n - fade + i] * (1.0 - k)
        out[i] = mixed
        out[n - fade + i] = mixed
    return out


def _splash(seed: int) -> list[float]:
    rng = random.Random(seed)
    n = int(SR * 0.16)
    brown = 0.0
    hiss = 0.0
    samples: list[float] = []
    for i in range(n):
        white = rng.uniform(-1.0, 1.0)
        brown = brown * 0.97 + white * 0.03
        hiss = hiss * 0.55 + white * 0.45
        t = i / float(SR)
        thud = math.sin(2.0 * math.pi * 62.0 * t) * math.exp(-t * 28.0) * 0.55
        slap = math.sin(2.0 * math.pi * 210.0 * t) * math.exp(-t * 38.0) * 0.28
        spray = hiss * math.exp(-t * 22.0) * 0.42
        body = brown * math.exp(-t * 18.0) * 0.35
        samples.append(thud + slap + spray + body)
    peak = max(0.001, max(abs(x) for x in samples))
    return [x * (0.55 / peak) for x in samples]


def _nest_hiss(seed: int) -> list[float]:
    rng = random.Random(seed)
    n = int(SR * 2.4)
    brown = 0.0
    hiss = 0.0
    mid = 0.0
    samples: list[float] = []
    pops: list[tuple[int, float, float]] = []
    for _ in range(18):
        pops.append((rng.randrange(n), rng.uniform(0.04, 0.11), rng.uniform(40.0, 90.0)))
    for i in range(n):
        white = rng.uniform(-1.0, 1.0)
        brown = brown * 0.984 + white * 0.016
        hiss = hiss * 0.58 + white * 0.42
        mid = mid * 0.90 + white * 0.10
        t = i / float(SR)
        breath = 0.82 + 0.18 * math.sin(t * 2.1)
        steam = hiss * 0.48 + mid * 0.18
        ember = brown * 0.22
        acc = (steam + ember) * breath
        for start, amp, decay in pops:
            d = i - start
            if 0 <= d < int(SR * 0.05):
                acc += amp * math.exp(-d / decay) * (0.7 if d % 2 else 0.35)
        samples.append(acc)
    peak = max(0.001, max(abs(x) for x in samples))
    return _crossfade([x * (0.36 / peak) for x in samples])


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "assets" / "audio"
    _write(root / "sfx" / "splash.wav", _splash(0x53504C31))
    _write(root / "ambience" / "nest_hiss.wav", _nest_hiss(0x4E535431))
    print(root / "sfx" / "splash.wav")
    print(root / "ambience" / "nest_hiss.wav")


if __name__ == "__main__":
    main()
