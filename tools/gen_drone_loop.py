#!/usr/bin/env python3
"""Procedural CC0 cemetery drone for Rustgrave. Stdlib only."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SR = 22050
SECONDS = 4.0
N = int(SR * SECONDS)


def _clamp(v: float) -> int:
    return max(-32767, min(32767, int(v)))


def _drone() -> list[float]:
    samples: list[float] = []
    for i in range(N):
        t = i / float(SR)
        a = 0.11 * math.sin(2.0 * math.pi * 46.0 * t)
        b = 0.07 * math.sin(2.0 * math.pi * 69.2 * t + 0.4)
        c = 0.04 * math.sin(2.0 * math.pi * 92.5 * t + 1.1)
        breath = 0.82 + 0.18 * math.sin(t * 0.7)
        samples.append((a + b + c) * breath)
    fade = 900
    out = list(samples)
    for i in range(fade):
        k = i / float(fade)
        out[i] = samples[i] * k + samples[N - fade + i] * (1.0 - k)
        out[N - fade + i] = out[i]
    return out


def _write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        frames = b"".join(struct.pack("<h", _clamp(s * 22000.0)) for s in samples)
        wav.writeframes(frames)


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "assets" / "audio" / "ambience"
    _write(root / "cemetery_drone.wav", _drone())
    print("wrote", root / "cemetery_drone.wav")


if __name__ == "__main__":
    main()
