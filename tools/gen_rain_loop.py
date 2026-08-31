#!/usr/bin/env python3
"""Procedural CC0 rain loops for Rustgrave. Stdlib only."""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

SR = 22050
SECONDS = 3.0
N = int(SR * SECONDS)


def _clamp(v: float) -> int:
    return max(-32767, min(32767, int(v)))


def _crossfade(buf: list[float], fade: int = 1400) -> list[float]:
    out = list(buf)
    for i in range(fade):
        k = i / float(fade)
        out[i] = buf[i] * k + buf[N - fade + i] * (1.0 - k)
        out[N - fade + i] = out[i]
    return out


def _rain(seed: int, rust: bool) -> list[float]:
    rng = random.Random(seed)
    # Leaky-integrator "brown" + bright hiss; rust sits darker and grit-heavier.
    brown = 0.0
    hiss = 0.0
    mid = 0.0
    samples: list[float] = []
    drops: list[tuple[int, float, float]] = []
    for _ in range(90 if rust else 70):
        drops.append((rng.randrange(N), rng.uniform(0.08, 0.22), rng.uniform(80.0, 240.0)))
    for i in range(N):
        white = rng.uniform(-1.0, 1.0)
        brown = brown * 0.986 + white * 0.014
        hiss = hiss * 0.62 + white * 0.38
        mid = mid * 0.88 + white * 0.12
        t = i / float(SR)
        breath = 0.86 + 0.14 * math.sin(t * 1.7)
        body = brown * (0.55 if rust else 0.32)
        spray = hiss * (0.22 if rust else 0.42)
        patter = mid * (0.28 if rust else 0.18)
        acc = (body + spray + patter) * breath
        for start, amp, decay in drops:
            d = i - start
            if 0 <= d < int(SR * 0.08):
                acc += amp * math.exp(-d / decay) * (1.0 if (d % 3) else 0.45)
        samples.append(acc)
    peak = max(0.001, max(abs(x) for x in samples))
    gain = (0.42 if rust else 0.38) / peak
    return _crossfade([x * gain for x in samples])


def _write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(b"".join(struct.pack("<h", _clamp(s * 32767.0)) for s in samples))


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "assets" / "audio" / "ambience"
    _write(root / "rain.wav", _rain(0x52535431, False))
    _write(root / "rust_rain.wav", _rain(0x52535432, True))
    print(root / "rain.wav")
    print(root / "rust_rain.wav")


if __name__ == "__main__":
    main()
