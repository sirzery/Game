#!/usr/bin/env python3
"""Procedural soundtrack + sound effects for DOSIER.

Run from the project root:   python3 tools/gen_audio.py
Requires numpy. If ffmpeg (with libvorbis) is installed, music is encoded to .ogg,
otherwise it is written as .wav. Sound effects are always short .wav files.

Everything here is placeholder-quality but fully original, royalty-free audio,
meant to give the prologue its mood until a composer replaces it.
"""
from __future__ import annotations

import math
import os
import shutil
import subprocess
import wave
from typing import Callable, Dict, List, Optional, Sequence, Tuple

import numpy as np

SR = 32000
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
BGM = os.path.join(ROOT, "assets", "audio", "bgm")
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
AMB = os.path.join(ROOT, "assets", "audio", "ambience")
RNG = np.random.default_rng(1337)

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7,
        "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name: str) -> int:
    """'A4' -> 69, 'Eb3' -> 51."""
    pitch = name[:-1]
    octave = int(name[-1])
    return 12 * (octave + 1) + NOTE[pitch]


def hz(n) -> float:
    if isinstance(n, str):
        n = midi(n)
    return 440.0 * 2 ** ((n - 69) / 12.0)


def chord(root: str, quality: str = "m", octave: int = 3) -> List[float]:
    r = midi(f"{root}{octave}")
    iv = {"m": (0, 3, 7), "M": (0, 4, 7), "m7": (0, 3, 7, 10), "M7": (0, 4, 7, 11), "7": (0, 4, 7, 10),
          "dim": (0, 3, 6), "sus": (0, 5, 7), "6": (0, 4, 7, 9), "add9": (0, 4, 7, 14)}[quality]
    return [hz(r + i) for i in iv]


# ---------------------------------------------------------------------------
# DSP helpers
# ---------------------------------------------------------------------------
def tt(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


def env(n: int, a: float, d: float, s: float, r: float) -> np.ndarray:
    """ADSR envelope over n samples (times in seconds, release at the end)."""
    e = np.ones(n) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = min(na, n)
    e[:na] = np.linspace(0, 1, na, endpoint=False) if na else e[:na]
    end_d = min(n, na + nd)
    if end_d > na:
        e[na:end_d] = np.linspace(1, s, end_d - na, endpoint=False)
    if nr > 0:
        nr = min(nr, n)
        e[n - nr:] *= np.linspace(1, 0, nr)
    return e


def decay(n: int, tau: float) -> np.ndarray:
    return np.exp(-np.arange(n) / (tau * SR))


def saw(freq: float, n: int, phase: float = 0.0, harmonics: int = 12) -> np.ndarray:
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k in range(1, harmonics + 1):
        if freq * k > SR / 2.2:
            break
        out += np.sin(2 * np.pi * freq * k * t + phase * k) / k
    return out * 0.6


def square(freq: float, n: int, harmonics: int = 10) -> np.ndarray:
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k in range(1, harmonics * 2, 2):
        if freq * k > SR / 2.2:
            break
        out += np.sin(2 * np.pi * freq * k * t) / k
    return out * 0.8


def sine(freq, n: int, vib: float = 0.0, vib_rate: float = 5.0) -> np.ndarray:
    t = np.arange(n) / SR
    if vib:
        ph = 2 * np.pi * freq * t + (vib / vib_rate) * np.sin(2 * np.pi * vib_rate * t) * freq * 0.01 * 2 * np.pi
        return np.sin(ph)
    return np.sin(2 * np.pi * freq * t)


def noise(n: int) -> np.ndarray:
    return RNG.uniform(-1, 1, n)


def fft_filter(sig: np.ndarray, low: Optional[float] = None, high: Optional[float] = None,
               bands: Optional[Sequence[Tuple[float, float, float]]] = None) -> np.ndarray:
    """Zero-phase filter in the frequency domain.
    low: high-pass cutoff, high: low-pass cutoff, bands: [(centre, width, gain)] peaking boosts."""
    n = len(sig)
    if n == 0:
        return sig
    spec = np.fft.rfft(sig)
    f = np.fft.rfftfreq(n, 1 / SR)
    g = np.ones_like(f)
    if high is not None:
        g *= 1 / np.sqrt(1 + (f / high) ** 4)
    if low is not None:
        g *= 1 / np.sqrt(1 + (low / np.maximum(f, 1e-3)) ** 4)
    if bands:
        b = np.zeros_like(f)
        for c, w, gain in bands:
            b += gain * np.exp(-((f - c) / w) ** 2)
        g *= b
    return np.fft.irfft(spec * g, n)


def convolve(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    n = len(a) + len(b) - 1
    size = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(a, size) * np.fft.rfft(b, size), size)[:n]


def reverb(sig: np.ndarray, seconds: float = 2.2, mix_amt: float = 0.3, bright: float = 4000) -> np.ndarray:
    n = int(seconds * SR)
    ir = noise(n) * np.exp(-np.arange(n) / (seconds * SR / 6.0))
    ir = fft_filter(ir, high=bright)
    ir[: int(0.012 * SR)] = 0
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = convolve(sig, ir)
    out = np.zeros(len(sig) + n)
    out[: len(sig)] += sig * (1 - mix_amt)
    m = min(len(out), len(wet))
    out[:m] += wet[:m] * mix_amt * 1.6
    return out


def place(buf: np.ndarray, sig: np.ndarray, t0: float, gain: float = 1.0) -> None:
    i = int(t0 * SR)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i] * gain


def normalize(sig: np.ndarray, peak: float = 0.89) -> np.ndarray:
    m = np.max(np.abs(sig)) + 1e-9
    return sig / m * peak


def soft_clip(sig: np.ndarray, drive: float = 1.2) -> np.ndarray:
    return np.tanh(sig * drive) / np.tanh(drive)


def write_wav(path: str, sig: np.ndarray) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = (np.clip(sig, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def loopify(sig: np.ndarray, length: float) -> np.ndarray:
    """Fold everything after `length` back onto the start so the loop is seamless."""
    n = int(length * SR)
    out = sig[:n].copy()
    tail = sig[n:]
    k = 0
    while len(tail) > 0:
        m = min(n, len(tail))
        out[:m] += tail[:m]
        tail = tail[m:]
        k += 1
    return out


# ---------------------------------------------------------------------------
# Instruments
# ---------------------------------------------------------------------------
def pad(freqs: Sequence[float], dur: float, bright: float = 1800, attack: float = 0.8,
        release: float = 1.2) -> np.ndarray:
    n = int((dur + release) * SR)
    out = np.zeros(n)
    for f in freqs:
        for det in (-0.12, 0.0, 0.13):
            out += saw(f * 2 ** (det / 12), n, RNG.uniform(0, 6))
    out = fft_filter(out, high=bright)
    return out * env(n, attack, 0.2, 0.9, release) / (len(freqs) * 3)


def choir(freqs: Sequence[float], dur: float, vowel: str = "a", attack: float = 0.9,
          release: float = 1.4) -> np.ndarray:
    n = int((dur + release) * SR)
    out = np.zeros(n)
    t = np.arange(n) / SR
    for f in freqs:
        for det in (-0.1, 0.0, 0.1):
            vib = 1 + 0.004 * np.sin(2 * np.pi * (5 + RNG.uniform(-0.6, 0.6)) * t + RNG.uniform(0, 6))
            ph = 2 * np.pi * np.cumsum(f * 2 ** (det / 12) * vib) / SR
            s = np.zeros(n)
            for k in range(1, 18):
                if f * k > SR / 2.4:
                    break
                s += np.sin(ph * k) / k
            out += s
    formants = {"a": [(700, 120, 1.0), (1220, 140, 0.55), (2600, 200, 0.25)],
                "o": [(450, 100, 1.0), (800, 120, 0.6), (2830, 200, 0.15)],
                "u": [(325, 80, 1.0), (700, 100, 0.35), (2530, 200, 0.1)]}[vowel]
    out = fft_filter(out, bands=formants + [(160, 120, 0.4)])
    return out * env(n, attack, 0.3, 0.9, release) / (len(freqs) * 3)


def organ(freqs: Sequence[float], dur: float, release: float = 0.8) -> np.ndarray:
    n = int((dur + release) * SR)
    out = np.zeros(n)
    for f in freqs:
        for k, a in ((0.5, 0.5), (1, 1.0), (2, 0.6), (3, 0.3), (4, 0.25), (6, 0.12), (8, 0.1)):
            if f * k < SR / 2.2:
                out += a * sine(f * k, n)
    return out * env(n, 0.12, 0.1, 0.95, release) / (len(freqs) * 2.5)


def bell(freq: float, dur: float = 3.0, bright: float = 1.0) -> np.ndarray:
    n = int(dur * SR)
    out = np.zeros(n)
    for k, a, tau in ((1, 1.0, 1.2), (2.0, 0.5, 0.9), (2.76, 0.4 * bright, 0.6), (5.4, 0.25 * bright, 0.3),
                      (8.93, 0.15 * bright, 0.15)):
        if freq * k < SR / 2.2:
            out += a * sine(freq * k, n) * decay(n, tau * dur / 3)
    out[: int(0.003 * SR)] *= np.linspace(0, 1, int(0.003 * SR))
    return out * 0.4


def piano(freq: float, dur: float = 2.5) -> np.ndarray:
    n = int(dur * SR)
    out = np.zeros(n)
    for k, a in ((1, 1.0), (2, 0.45), (3, 0.25), (4, 0.12), (5, 0.08)):
        if freq * k < SR / 2.2:
            out += a * sine(freq * k * (1 + 0.0004 * k * k), n) * decay(n, 0.9 / (1 + k * 0.4))
    out += fft_filter(noise(n), low=1500, high=5000) * decay(n, 0.01) * 0.15
    out[: int(0.002 * SR)] *= np.linspace(0, 1, int(0.002 * SR))
    return out * 0.45


def pluck(freq: float, dur: float = 1.6, damp: float = 0.996, bright: float = 0.6) -> np.ndarray:
    """Karplus-Strong, vectorised one period at a time."""
    n = int(dur * SR)
    p = max(2, int(round(SR / freq)))
    buf = fft_filter(noise(p * 4), high=2000 + bright * 6000)[:p]
    out = np.zeros(n)
    out[:p] = buf
    i = p
    while i < n:
        m = min(p, n - i)
        prev = out[i - p:i - p + m + 1]
        if len(prev) < m + 1:
            prev = np.append(prev, prev[-1])
        out[i:i + m] = damp * 0.5 * (prev[:m] + prev[1:m + 1])
        i += m
    return out * 0.5


def bass(freq: float, dur: float, cutoff: float = 900) -> np.ndarray:
    n = int(dur * SR)
    s = saw(freq, n) + 0.5 * square(freq * 0.5, n)
    s = fft_filter(s, high=cutoff)
    return s * env(n, 0.005, 0.12, 0.6, 0.05) * 0.6


def brass(freqs: Sequence[float], dur: float) -> np.ndarray:
    n = int((dur + 0.15) * SR)
    out = np.zeros(n)
    for f in freqs:
        for det in (-0.06, 0.06):
            out += saw(f * 2 ** (det / 12), n)
    # filter "opening" approximated by mixing a dark and a bright version
    dark = fft_filter(out, high=700)
    brightv = fft_filter(out, high=3200)
    ramp_ = np.clip(np.arange(n) / (0.08 * SR), 0, 1)
    out = dark * (1 - ramp_) + brightv * ramp_
    return out * env(n, 0.03, 0.1, 0.8, 0.15) / (len(freqs) * 1.6)


def strings_stac(freq: float, dur: float) -> np.ndarray:
    n = int(dur * SR)
    out = sum(saw(freq * 2 ** (d / 12), n) for d in (-0.1, 0.0, 0.1))
    out = fft_filter(out, high=2600)
    return out * env(n, 0.01, 0.05, 0.5, 0.06) * 0.35


def flute(freq: float, dur: float) -> np.ndarray:
    n = int((dur + 0.2) * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.4, 0, 1)
    ph = 2 * np.pi * np.cumsum(freq * vib) / SR
    s = np.sin(ph) + 0.12 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
    s += fft_filter(noise(n), bands=[(freq * 2, 600, 0.06)])
    return s * env(n, 0.07, 0.1, 0.85, 0.2) * 0.5


def epiano(freqs: Sequence[float], dur: float) -> np.ndarray:
    n = int((dur + 0.5) * SR)
    out = np.zeros(n)
    t = np.arange(n) / SR
    for f in freqs:
        mod = np.sin(2 * np.pi * f * 2 * t) * 1.2 * decay(n, 0.25)
        out += np.sin(2 * np.pi * f * t + mod) * decay(n, 0.9)
    return out * 0.3 / max(1, len(freqs)) * 2


def lead(freq: float, dur: float, kind: str = "saw") -> np.ndarray:
    n = int((dur + 0.1) * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.008 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) / 0.2, 0, 1)
    ph = np.cumsum(freq * vib) / SR
    if kind == "saw":
        s = 2 * (ph % 1.0) - 1
        s = fft_filter(s, high=3000)
    else:
        s = np.sign(np.sin(2 * np.pi * ph)) * 0.7
        s = fft_filter(s, high=2500)
    return s * env(n, 0.01, 0.08, 0.75, 0.08) * 0.35


# drums -----------------------------------------------------------------------
def kick(dur: float = 0.45) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = 45 + 110 * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(ph) * decay(n, 0.13)
    s += fft_filter(noise(n), low=1500) * decay(n, 0.004) * 0.3
    return soft_clip(s, 1.5) * 0.9


def snare(dur: float = 0.25) -> np.ndarray:
    n = int(dur * SR)
    tone = sine(185, n) * decay(n, 0.04) * 0.6
    nz = fft_filter(noise(n), low=900, high=8000) * decay(n, 0.07)
    return (tone + nz) * 0.7


def hat(dur: float = 0.06, open_: bool = False) -> np.ndarray:
    n = int((0.3 if open_ else dur) * SR)
    return fft_filter(noise(n), low=6500) * decay(n, 0.09 if open_ else 0.014) * 0.35


def taiko(dur: float = 1.0, pitch: float = 80) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = pitch * 0.6 + pitch * 0.6 * np.exp(-t * 12)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * decay(n, 0.35)
    s += fft_filter(noise(n), high=900) * decay(n, 0.05) * 0.5
    return soft_clip(s, 1.3)


def cymbal(dur: float = 2.0) -> np.ndarray:
    n = int(dur * SR)
    return fft_filter(noise(n), low=4000) * decay(n, 0.6) * 0.25


# ---------------------------------------------------------------------------
# Tracks
# ---------------------------------------------------------------------------
def track_title() -> Tuple[np.ndarray, float]:
    bpm = 66
    bar = 4 * 60 / bpm
    bars = 8
    L = bars * bar
    buf = np.zeros(int((L + 6) * SR))
    prog = [("D", "m"), ("Bb", "M"), ("G", "m"), ("A", "M"), ("D", "m"), ("Bb", "M"), ("G", "m"), ("A", "7")]
    for i, (r, q) in enumerate(prog):
        place(buf, choir(chord(r, q, 3), bar, "a" if i % 2 == 0 else "o"), i * bar, 0.9)
        place(buf, pad([hz(f"{r}2")], bar, 600), i * bar, 0.5)
    mel = [("A4", 0, 1.5), ("F4", 1.5, 0.5), ("D5", 2, 2), ("C5", 4, 1), ("Bb4", 5, 1), ("A4", 6, 2),
           ("G4", 8, 1.5), ("A4", 9.5, 0.5), ("Bb4", 10, 2), ("A4", 12, 2), ("E4", 14, 2),
           ("A4", 16, 1.5), ("F4", 17.5, 0.5), ("D5", 18, 2), ("E5", 20, 1), ("F5", 21, 1), ("E5", 22, 2),
           ("D5", 24, 1), ("C5", 25, 1), ("Bb4", 26, 2), ("A4", 28, 1), ("C#5", 29, 1), ("D5", 30, 2)]
    beat = 60 / bpm
    for nme, b, d in mel:
        place(buf, bell(hz(nme), 3.5), b * beat, 0.35)
    for i in range(bars):
        place(buf, bell(hz("D2"), 5, 0.4), i * bar, 0.25 if i % 2 == 0 else 0.0)
    return reverb(buf, 3.0, 0.35), L


def track_tribunal() -> Tuple[np.ndarray, float]:
    bpm = 58
    bar = 4 * 60 / bpm
    bars = 8
    L = bars * bar
    buf = np.zeros(int((L + 6) * SR))
    prog = [("D", "m"), ("Eb", "M"), ("D", "m"), ("C", "M"), ("Bb", "M"), ("Eb", "M"), ("D", "m"), ("A", "M")]
    for i, (r, q) in enumerate(prog):
        place(buf, organ(chord(r, q, 3) + [hz(f"{r}2")], bar), i * bar, 0.6)
        place(buf, choir(chord(r, q, 4)[:2], bar, "u"), i * bar, 0.45)
    for i in range(0, bars, 2):
        place(buf, bell(hz("D3"), 6, 0.6), i * bar, 0.55)
    # heartbeat-like timpani
    for i in range(bars * 2):
        place(buf, taiko(0.8, 60), i * bar / 2, 0.25)
        place(buf, taiko(0.8, 60), i * bar / 2 + 0.28, 0.15)
    return reverb(buf, 3.8, 0.4, 3000), L


def track_burden() -> Tuple[np.ndarray, float]:
    bpm = 52
    beat = 60 / bpm
    bars = 8
    L = bars * 4 * beat
    buf = np.zeros(int((L + 6) * SR))
    prog = [("E", "m"), ("C", "M"), ("G", "M"), ("B", "m"), ("E", "m"), ("C", "M"), ("A", "m"), ("B", "M")]
    for i, (r, q) in enumerate(prog):
        place(buf, pad(chord(r, q, 3), 4 * beat, 900, 1.5, 2.0), i * 4 * beat, 0.35)
    notes = ["B4", "G4", "E4", None, "C5", "B4", "G4", None, "D5", "B4", "G4", "F#4", "E4", None, "B3", None,
             "B4", "G4", "E4", None, "C5", "E5", "D5", None, "C5", "B4", "A4", "G4", "F#4", "D#4", "B3", None]
    for i, nme in enumerate(notes):
        if nme:
            place(buf, piano(hz(nme), 3.0), i * beat, 0.5)
    for i in range(bars):
        place(buf, piano(hz(prog[i][0] + "2"), 4.0), i * 4 * beat, 0.35)
    return reverb(buf, 3.5, 0.45, 3500), L


def track_clash() -> Tuple[np.ndarray, float]:
    bpm = 138
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    buf = np.zeros(int((L + 4) * SR))
    prog = [("C", "m"), ("Ab", "M"), ("F", "m"), ("G", "M")]
    ost = [0, 0, 3, 0, 7, 0, 8, 7]
    for b in range(bars):
        r, q = prog[(b // 2) % 4]
        root = midi(f"{r}3")
        for k in range(8):
            place(buf, strings_stac(hz(root + ost[k] - (12 if k % 2 else 0)), beat * 0.45), (b * 4 + k * 0.5) * beat,
                  0.5)
        # taiko pattern
        for pos, g in ((0, 1.0), (1.5, 0.7), (2, 0.9), (3, 0.6), (3.5, 0.8)):
            place(buf, taiko(0.9, 70), (b * 4 + pos) * beat, 0.55 * g)
        if b % 2 == 0:
            place(buf, brass(chord(r, q, 3), beat * 1.5), (b * 4) * beat, 0.55)
            place(buf, brass(chord(r, q, 3), beat * 0.9), (b * 4 + 2.5) * beat, 0.4)
        if b >= 8:
            place(buf, choir(chord(r, q, 4), beat * 4 * 0.95, "a", 0.2, 0.4), b * 4 * beat, 0.4)
        place(buf, cymbal(1.2), b * 4 * beat, 0.15 if b % 4 == 0 else 0.0)
    return reverb(buf, 2.0, 0.25), L


def track_battle() -> Tuple[np.ndarray, float]:
    bpm = 150
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    buf = np.zeros(int((L + 3) * SR))
    prog = [(["A3", "C4", "E4", "G4"], "A1"), (["F3", "A3", "C4", "E4"], "F1"), (["G3", "B3", "D4", "E4"], "G1"),
            (["E3", "G3", "B3", "D4"], "E1")]
    bass_pat = [(0, 0, 0.4), (0.75, 12, 0.2), (1.5, 0, 0.3), (2, 7, 0.3), (2.5, 10, 0.2), (3, 12, 0.3),
                (3.5, 7, 0.4)]
    for b in range(bars):
        notes, broot = prog[(b // 2) % 4]
        r = midi(broot) + 12
        for pos, iv, d in bass_pat:
            place(buf, bass(hz(r + iv), d * beat * 2, 1100), (b * 4 + pos) * beat, 0.65)
        # drums
        for pos in (0, 1.75, 2.5):
            place(buf, kick(), (b * 4 + pos) * beat, 0.8)
        for pos in (1, 3):
            place(buf, snare(), (b * 4 + pos) * beat, 0.6)
        if b % 4 == 3:
            for pos in (3.25, 3.5, 3.75):
                place(buf, snare(0.15), (b * 4 + pos) * beat, 0.35)
        for k in range(8):
            place(buf, hat(open_=(k == 7)), (b * 4 + k * 0.5) * beat, 0.5 if k % 2 else 0.3)
        # chord stabs (jazzy electric piano)
        for pos in (0.5, 1.75, 3.0):
            place(buf, epiano([hz(x) for x in notes], beat * 0.6), (b * 4 + pos) * beat, 0.5)
    # lead melody (A minor pentatonic-ish hook) over bars 4-15
    hook = [("E5", 0, 0.5), ("G5", 0.5, 0.5), ("A5", 1, 1), ("G5", 2, 0.5), ("E5", 2.5, 0.5), ("D5", 3, 1),
            ("C5", 4, 0.5), ("D5", 4.5, 0.5), ("E5", 5, 1.5), ("A4", 6.5, 0.5), ("C5", 7, 1),
            ("E5", 8, 0.5), ("G5", 8.5, 0.5), ("A5", 9, 1), ("B5", 10, 0.5), ("A5", 10.5, 0.5), ("G5", 11, 1),
            ("E5", 12, 1), ("D5", 13, 0.5), ("E5", 13.5, 2.5)]
    for rep in (1, 2, 3):
        base = rep * 16
        for nme, pos, d in hook:
            place(buf, lead(hz(nme), d * beat * 0.95), (base + pos) * beat, 0.42)
    return reverb(soft_clip(buf, 1.1), 1.2, 0.15), L


def track_wilds() -> Tuple[np.ndarray, float]:
    bpm = 92
    beat = 60 / bpm
    bars = 16
    L = bars * 4 * beat
    buf = np.zeros(int((L + 5) * SR))
    prog = [("G", "M"), ("D", "M"), ("E", "m"), ("C", "M")]
    arp = [0, 2, 1, 2, 0, 2, 1, 2]
    for b in range(bars):
        r, q = prog[b % 4]
        ch = chord(r, q, 3)
        bassf = hz(f"{r}2")
        place(buf, pluck(bassf, 2.4, 0.997), b * 4 * beat, 0.7)
        for k in range(8):
            f = ch[arp[k]] * (2 if k in (3, 7) else 1)
            place(buf, pluck(f, 1.4, 0.995), (b * 4 + k * 0.5) * beat, 0.42)
    mel = [("B4", 0, 1.5), ("A4", 1.5, 0.5), ("G4", 2, 2), ("F#4", 4, 1), ("A4", 5, 1), ("D5", 6, 2),
           ("E5", 8, 1.5), ("D5", 9.5, 0.5), ("B4", 10, 2), ("C5", 12, 1), ("B4", 13, 1), ("A4", 14, 2)]
    for rep in (1, 2, 3):
        for nme, pos, d in mel:
            place(buf, flute(hz(nme), d * beat), (rep * 16 + pos) * beat, 0.32)
    return reverb(buf, 2.2, 0.25), L


def track_camp() -> Tuple[np.ndarray, float]:
    bpm = 72
    beat = 60 / bpm
    bars = 8
    L = bars * 4 * beat
    buf = np.zeros(int((L + 5) * SR))
    prog = [("F", "M"), ("A", "m"), ("Bb", "M"), ("C", "M"), ("F", "M"), ("D", "m"), ("Bb", "M"), ("C", "sus")]
    for i, (r, q) in enumerate(prog):
        place(buf, pad(chord(r, q, 3), 4 * beat, 1200, 1.0, 1.5), i * 4 * beat, 0.3)
        place(buf, pluck(hz(f"{r}2"), 3.0, 0.998), i * 4 * beat, 0.5)
    mel = ["A5", "C6", "F5", "A5", "G5", "E5", "C5", "E5", "F5", "D5", "Bb4", "D5", "E5", "G5", "C6", "G5",
           "A5", "F5", "C5", "F5", "A5", "D6", "C6", "A5", "Bb5", "G5", "D5", "G5", "C6", "G5", "E5", "C5"]
    for i, nme in enumerate(mel):
        place(buf, bell(hz(nme), 2.0, 0.6), i * beat, 0.22)
    return reverb(buf, 2.8, 0.35), L


def track_synod() -> Tuple[np.ndarray, float]:
    bpm = 60
    beat = 60 / bpm
    L = 32 * beat
    buf = np.zeros(int((L + 5) * SR))
    n = int((L + 2) * SR)
    drone = (saw(hz("C2"), n) + saw(hz("C2") * 1.003, n) + 0.5 * saw(hz("G2"), n)) * 0.25
    drone = fft_filter(drone, high=380)
    drone *= 0.7 + 0.3 * np.sin(2 * np.pi * np.arange(n) / SR / 8.0)
    place(buf, drone, 0, 0.6)
    clusters = [["C4", "Db4", "G4"], ["B3", "C4", "F#4"], ["C4", "Eb4", "Gb4"], ["B3", "D4", "F4"]]
    for i, cl in enumerate(clusters):
        place(buf, choir([hz(x) for x in cl], 8 * beat, "u", 2.0, 2.0), i * 8 * beat, 0.4)
    for i in range(32):
        tick = fft_filter(noise(int(0.03 * SR)), low=2000) * decay(int(0.03 * SR), 0.004)
        place(buf, tick, i * beat, 0.25)
        place(buf, tick * 0.6, i * beat + beat * 0.5, 0.15)
    for i in range(0, 32, 2):
        place(buf, taiko(0.6, 50), i * beat, 0.25)
        place(buf, taiko(0.6, 50), i * beat + 0.25, 0.18)
    return reverb(buf, 3.0, 0.35, 2500), L


def jingle_victory() -> np.ndarray:
    bpm = 160
    beat = 60 / bpm
    buf = np.zeros(int(5 * SR))
    seq = [(["A3", "C#4", "E4"], 0, 0.5), (["A3", "C#4", "E4"], 0.5, 0.5), (["A3", "C#4", "E4"], 1, 0.5),
           (["B3", "D4", "F#4"], 1.5, 0.5), (["C#4", "E4", "A4"], 2, 3)]
    for notes, pos, d in seq:
        place(buf, brass([hz(x) for x in notes], d * beat), pos * beat, 0.7)
    for nme, pos in (("E5", 2), ("A5", 2.5), ("C#6", 3)):
        place(buf, bell(hz(nme), 2.0), pos * beat, 0.3)
    place(buf, cymbal(2.5), 2 * beat, 0.5)
    place(buf, taiko(1.0, 70), 2 * beat, 0.6)
    return normalize(reverb(buf, 1.8, 0.25))


def jingle_gameover() -> np.ndarray:
    buf = np.zeros(int(6 * SR))
    for i, nme in enumerate(("E4", "D4", "C4", "B3", "A3")):
        place(buf, piano(hz(nme), 3.0), i * 0.55, 0.6)
    place(buf, choir(chord("A", "m", 3), 3.0, "u"), 2.2, 0.5)
    return normalize(reverb(buf, 3.0, 0.45))


# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------
def sfx_all() -> Dict[str, np.ndarray]:
    s: Dict[str, np.ndarray] = {}

    def tone_sweep(f0, f1, dur, kind="sine", tau=None):
        n = int(dur * SR)
        t = np.arange(n) / SR
        f = f0 * (f1 / f0) ** (t / dur)
        ph = 2 * np.pi * np.cumsum(f) / SR
        sig = np.sin(ph) if kind == "sine" else np.sign(np.sin(ph)) * 0.6
        return sig * (decay(n, tau) if tau else env(n, 0.002, 0.02, 0.7, dur * 0.4))

    s["ui_move"] = tone_sweep(900, 1300, 0.05, "square") * 0.25
    s["ui_confirm"] = np.concatenate([tone_sweep(700, 900, 0.05, "square"), tone_sweep(1100, 1500, 0.09, "square")]) * 0.3
    s["ui_cancel"] = tone_sweep(700, 380, 0.1, "square") * 0.25
    n = int(0.35 * SR)
    whoosh = fft_filter(noise(n), low=600, high=5000) * env(n, 0.12, 0.05, 0.6, 0.18)
    s["ui_open"] = whoosh * 0.5 + tone_sweep(300, 900, 0.35) * 0.1
    s["text_blip"] = tone_sweep(620, 640, 0.025, "square") * 0.12
    n = int(0.25 * SR)
    s["hit_blunt"] = soft_clip(sine(90, n) * decay(n, 0.06) + fft_filter(noise(n), high=2500) * decay(n, 0.04), 2) * 0.8
    s["hit_pierce"] = (fft_filter(noise(n), low=2500) * decay(n, 0.03) + tone_sweep(1800, 600, 0.25) * 0.3) * 0.7
    n = int(0.6 * SR)
    s["hit_fire"] = (fft_filter(noise(n), low=200, high=3000) * env(n, 0.01, 0.1, 0.5, 0.4) + sine(70, n) * decay(n, 0.1)) * 0.7
    s["hit_holy"] = (sum(sine(f, n) for f in (880, 1320, 1760)) * decay(n, 0.25) * 0.2 +
                     fft_filter(noise(n), low=3000) * decay(n, 0.1) * 0.4)
    n = int(0.5 * SR)
    s["crit"] = soft_clip(sine(70, n) * decay(n, 0.12) * 1.2 + fft_filter(noise(n), high=4000) * decay(n, 0.08), 2.5) * 0.85
    n = int(1.2 * SR)
    shards = np.zeros(n)
    for k in range(40):
        t0 = RNG.uniform(0, 0.4)
        f = RNG.uniform(2500, 7000)
        place(shards, sine(f, int(0.2 * SR)) * decay(int(0.2 * SR), 0.03), t0, RNG.uniform(0.05, 0.15))
    s["break"] = normalize(shards + sine(55, n) * decay(n, 0.25) * 0.9 + fft_filter(noise(n), low=1500) * decay(n, 0.12) * 0.4) * 0.9
    s["weak"] = np.concatenate([tone_sweep(500, 500, 0.06, "square"), tone_sweep(1000, 1000, 0.12, "square")]) * 0.3
    n = int(1.0 * SR)
    sh = np.zeros(n)
    for i, f in enumerate((880, 1108, 1318, 1760, 2217)):
        place(sh, sine(f, int(0.5 * SR)) * decay(int(0.5 * SR), 0.15), i * 0.07, 0.25)
    s["heal"] = sh
    n = int(0.4 * SR)
    s["guard"] = (sum(sine(f, n) for f in (420, 1130, 2210)) * decay(n, 0.08) * 0.3 +
                  fft_filter(noise(n), low=2000) * decay(n, 0.02) * 0.3)
    s["boost"] = tone_sweep(200, 900, 0.3) * 0.35 + fft_filter(noise(int(0.3 * SR)), low=2000) * env(int(0.3 * SR), 0.2, 0.05, 0.3, 0.05) * 0.2
    n = int(0.9 * SR)
    clank = sum(sine(f, n) * decay(n, tau) for f, tau in ((523, 0.3), (1360, 0.15), (2740, 0.08), (4100, 0.05)))
    s["chain_snap"] = normalize(clank * 0.4 + fft_filter(noise(n), low=1500) * decay(n, 0.02)) * 0.8
    n = int(3.5 * SR)
    rum = fft_filter(noise(n), high=180) * env(n, 0.05, 0.4, 0.6, 2.5)
    crack = fft_filter(noise(n), low=800, high=6000) * decay(n, 0.06)
    s["thunder"] = normalize(rum * 2 + crack * 0.6) * 0.95
    n = int(0.8 * SR)
    s["lance_whoosh"] = normalize(fft_filter(noise(n), low=1500, high=9000) * env(n, 0.3, 0.1, 0.5, 0.35) +
                                  tone_sweep(2400, 900, 0.8) * 0.2) * 0.6
    n = int(1.6 * SR)
    s["lance_impact"] = normalize(soft_clip(fft_filter(noise(n), high=1200) * decay(n, 0.3) * 2 +
                                            sine(48, n) * decay(n, 0.35) * 1.5, 2) +
                                  sum(sine(f, n) for f in (1320, 1980)) * decay(n, 0.2) * 0.2) * 0.9
    n = int(0.8 * SR)
    s["stone_crack"] = normalize(fft_filter(noise(n), low=300, high=4000) * decay(n, 0.05) +
                                 fft_filter(noise(n), high=300) * decay(n, 0.2)) * 0.8
    n = int(4.0 * SR)
    deb = np.zeros(n)
    for k in range(80):
        t0 = RNG.uniform(0.1, 3.0)
        place(deb, fft_filter(noise(int(0.1 * SR)), low=500, high=5000) * decay(int(0.1 * SR), 0.02), t0,
              RNG.uniform(0.05, 0.3))
    s["stone_shatter"] = normalize(fft_filter(noise(n), high=200) * env(n, 0.02, 0.5, 0.5, 3.0) * 2.5 + deb +
                                   sine(40, n) * decay(n, 0.8)) * 0.95
    n = int(2.5 * SR)
    t = np.arange(n) / SR
    f = 95 + 40 * np.sin(np.pi * t / 2.5)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.05 * noise(n))) / SR
    growl = np.zeros(n)
    for k in range(1, 30):
        growl += np.sin(ph * k) / k
    growl = fft_filter(growl, bands=[(450, 150, 1.0), (900, 200, 0.6), (1800, 300, 0.3)])
    rasp = fft_filter(noise(n), bands=[(700, 300, 0.8), (1500, 400, 0.4)])
    s["roar"] = normalize(soft_clip((growl * 3 + rasp * 0.6) * env(n, 0.25, 0.4, 0.7, 1.0), 2.0)) * 0.9
    n = int(1.2 * SR)
    t = np.arange(n) / SR
    ph = 2 * np.pi * np.cumsum(80 * (1 + 0.08 * noise(n))) / SR
    g = sum(np.sin(ph * k) / k for k in range(1, 20))
    s["growl"] = normalize(fft_filter(g, bands=[(400, 150, 1.0), (800, 200, 0.5)]) * env(n, 0.1, 0.2, 0.7, 0.4)) * 0.7
    n = int(0.12 * SR)
    s["footstep"] = fft_filter(noise(n), high=900) * decay(n, 0.02) * 0.5
    n = int(0.6 * SR)
    sp = np.zeros(n)
    for i, fr in enumerate((1568, 2093, 2637)):
        place(sp, sine(fr, int(0.3 * SR)) * decay(int(0.3 * SR), 0.08), i * 0.06, 0.3)
    s["pickup"] = sp
    n = int(1.0 * SR)
    s["fire_ignite"] = normalize(fft_filter(noise(n), low=150, high=2500) * env(n, 0.05, 0.3, 0.3, 0.5) +
                                 sine(60, n) * decay(n, 0.15) * 0.5) * 0.7
    n = int(0.6 * SR)
    s["gavel"] = normalize(soft_clip(sine(110, n) * decay(n, 0.08) * 2 + fft_filter(noise(n), high=3000) * decay(n, 0.015), 2) +
                           taiko(0.6, 55)[:n] * 0.5) * 0.9
    n = int(0.9 * SR)
    hb = np.zeros(n)
    place(hb, taiko(0.4, 45), 0.0, 0.8)
    place(hb, taiko(0.4, 45), 0.22, 0.55)
    s["heartbeat"] = hb * 0.8
    n = int(0.7 * SR)
    s["comedy"] = (tone_sweep(220, 110, 0.35, "square") * 0.25)
    s["comedy"] = np.concatenate([s["comedy"], tone_sweep(196, 98, 0.45, "square") * 0.25])
    n = int(0.5 * SR)
    s["goat"] = normalize(fft_filter(saw(300, n) * (1 + 0.5 * np.sin(2 * np.pi * 28 * np.arange(n) / SR)),
                                     bands=[(800, 300, 1.0), (1600, 400, 0.5)]) * env(n, 0.03, 0.1, 0.7, 0.2)) * 0.6
    n = int(0.25 * SR)
    s["crow"] = normalize(fft_filter(noise(n), bands=[(1200, 300, 1.0), (2400, 400, 0.4)]) * env(n, 0.01, 0.05, 0.6, 0.1)) * 0.5
    n = int(1.5 * SR)
    s["swoosh_big"] = normalize(fft_filter(noise(n), low=200, high=4000) * env(n, 0.5, 0.2, 0.4, 0.7)) * 0.6
    s["impact_small"] = s["hit_blunt"] * 0.6
    n = int(0.8 * SR)
    s["allout"] = normalize(soft_clip(sum(saw(f, n) for f in (110, 165, 220)) * decay(n, 0.3) +
                                      fft_filter(noise(n), low=500) * decay(n, 0.2), 2)) * 0.8
    n = int(0.4 * SR)
    s["save"] = sum(sine(f, n) * decay(n, 0.12) for f in (1046, 1568)) * 0.25
    return s


def ambience() -> Dict[str, np.ndarray]:
    a: Dict[str, np.ndarray] = {}
    L = 12.0
    n = int((L + 2) * SR)
    rain = fft_filter(noise(n), low=800, high=7000) * 0.5
    drops = np.zeros(n)
    for _ in range(900):
        t0 = RNG.uniform(0, L + 1)
        dn = int(0.02 * SR)
        place(drops, fft_filter(noise(dn), low=2500) * decay(dn, 0.004), t0, RNG.uniform(0.1, 0.4))
    a["amb_rain"] = normalize(loopify(rain + drops, L)) * 0.6
    n = int((L + 2) * SR)
    t = np.arange(n) / SR
    wind = fft_filter(noise(n), low=150, high=900) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 6.0) ** 2)
    whistle = fft_filter(noise(n), bands=[(700 + 200 * math.sin(i), 40, 0.4) for i in range(3)])
    a["amb_wind"] = normalize(loopify(wind + whistle * 0.5, L)) * 0.6
    fire = fft_filter(noise(n), high=500) * 0.4
    for _ in range(260):
        t0 = RNG.uniform(0, L + 1)
        dn = int(0.015 * SR)
        place(fire, fft_filter(noise(dn), low=1500) * decay(dn, 0.003), t0, RNG.uniform(0.2, 0.8))
    a["amb_fire"] = normalize(loopify(fire, L)) * 0.6
    forest = fft_filter(noise(n), low=300, high=2000) * 0.08
    for _ in range(18):
        t0 = RNG.uniform(0, L)
        f0 = RNG.uniform(2500, 4200)
        for k in range(RNG.integers(2, 5)):
            dn = int(0.09 * SR)
            tt_ = np.arange(dn) / SR
            chirp = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 0.25 * np.sin(2 * np.pi * 18 * tt_))) / SR)
            place(forest, chirp * env(dn, 0.01, 0.02, 0.6, 0.04), t0 + k * 0.13, 0.12)
    a["amb_forest"] = normalize(loopify(forest, L)) * 0.45
    night = fft_filter(noise(n), low=200, high=1200) * 0.05
    for _ in range(60):
        t0 = RNG.uniform(0, L)
        dn = int(0.04 * SR)
        place(night, sine(4800, dn) * env(dn, 0.005, 0.01, 0.5, 0.02), t0, 0.08)
        place(night, sine(4800, dn) * env(dn, 0.005, 0.01, 0.5, 0.02), t0 + 0.06, 0.06)
    a["amb_night"] = normalize(loopify(night, L)) * 0.4
    hall = fft_filter(noise(n), low=60, high=400) * 0.3
    for _ in range(30):
        t0 = RNG.uniform(0, L)
        dn = int(0.8 * SR)
        place(hall, fft_filter(noise(dn), bands=[(500, 200, 1), (1100, 300, 0.4)]) * env(dn, 0.2, 0.2, 0.5, 0.3), t0,
              0.05)
    a["amb_hall"] = normalize(loopify(reverb(hall, 2.5, 0.5)[:n], L)) * 0.45
    return a


def export_music(name: str, sig: np.ndarray, use_ogg: bool, folder: str = BGM) -> None:
    os.makedirs(folder, exist_ok=True)
    wav = os.path.join(folder, name + ".wav")
    write_wav(wav, sig)
    if use_ogg:
        ogg = os.path.join(folder, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg],
                       check=True)
        os.remove(wav)


def main() -> None:
    use_ogg = shutil.which("ffmpeg") is not None
    tracks: Dict[str, Callable[[], Tuple[np.ndarray, float]]] = {
        "title": track_title, "tribunal": track_tribunal, "burden": track_burden, "clash": track_clash,
        "battle": track_battle, "wilds": track_wilds, "camp": track_camp, "synod": track_synod,
    }
    for name, fn in tracks.items():
        sig, L = fn()
        sig = normalize(loopify(sig, L), 0.8)
        export_music(name, sig, use_ogg)
        print("bgm", name, f"{L:.1f}s")
    export_music("victory", jingle_victory() * 0.85, use_ogg)
    export_music("gameover", jingle_gameover() * 0.85, use_ogg)
    for name, sig in ambience().items():
        export_music(name.replace("amb_", ""), sig, use_ogg, AMB)
        print("amb", name)
    os.makedirs(SFX, exist_ok=True)
    for name, sig in sfx_all().items():
        write_wav(os.path.join(SFX, name + ".wav"), np.clip(sig, -1, 1))
    print("Audio generated.")


if __name__ == "__main__":
    main()
