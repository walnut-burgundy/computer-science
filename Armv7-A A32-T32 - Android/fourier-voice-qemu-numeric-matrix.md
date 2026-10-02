# Fourier Voice ARMv7 QEMU numeric matrix

Purpose: screen numeric/storage/SIMD choices for the MIRO A1 Fourier Voice path
before spending phone iterations on them.

The executable benchmark lives in `isomorphismes/Fourier-sound`, branch
`bench/qemu-armv7-numerics`.

## Interpretation boundary

QEMU user-mode TCG wall time is **not a hardware cycle count** and is not a
cycle-accurate model of the MIRO A1. It can answer narrower questions:

- does an ARMv7 Thumb-2 implementation execute under representative ARMv7 CPU
  models;
- what relative emulator throughput changes when the algorithm, storage width,
  or explicit NEON structure changes;
- how much larger FFT or polynomial-term count fits inside the *same emulated
  time budget* as the current f64 shape.

Any promising lane must be repeated on the physical MIRO before production
policy changes.

## Matrix

| Kernel | Lane | Storage | Arithmetic | SIMD | Main question |
| --- | --- | ---: | --- | --- | --- |
| polynomial frame, 96×192 | f64 scalar | 64-bit/component | f64 | no | current reference budget |
| polynomial frame | f32 scalar | 32-bit/component | f32 | no | value of dropping binary64 |
| polynomial frame | f32 NEON4 | 32-bit/component | f32 | explicit 4-lane NEON | pixel-parallel headroom |
| polynomial frame | FP16 storage | 16-bit/component coefficients | widen to f32 | no | smaller coefficients without half arithmetic |
| polynomial frame | E4M3 storage | 8-bit/component coefficients | widen to f32 | no | signed fp8 storage cost/error |
| polynomial frame | E5M2 storage | 8-bit/component coefficients | widen to f32 | no | signed fp8 range/precision alternative |
| FFT, N=256…4096 | f64 scalar | 64-bit/component | f64 | no | reference N=1024 budget |
| FFT | f32 scalar | 32-bit/component | f32 | no | binary32 transform headroom |
| FFT | f32 NEON2 | 32-bit/component | f32 | explicit two-butterfly NEON | SIMD butterfly headroom |
| FFT | FP16 stage storage | 16-bit/component | widen to f32, requantize each stage | no | aggressive half-storage transform |
| storage decode | E5M3 | 8-bit/component | decode only | no | cost of current unsigned Ootomo–Naruse storage |

Polynomial term counts measured: 8, 16, 24, 32, 48, 64.

FFT lengths measured: 256, 512, 1024, 2048, 4096.

ARMv7 user-mode models: `cortex-a7` and `cortex-a15`.

The benchmark is compiled as Thumb-2 with the Android-compatible softfp calling
convention and explicit NEON/VFPv4 instructions. The timed kernels themselves
do not call Android APIs.

## E5M3 caveat

Current ICK `E5M3` is the unsigned Ootomo–Naruse eight-bit storage format.
Signed complex Fourier coefficients therefore do not fit its present domain.
The matrix deliberately does **not** invent a signed full-complex E5M3 FFT.
It measures decode throughput only. E4M3 and E5M2 provide the signed fp8 lanes
for the first pass.

## Outputs to record

For each CPU model and lane:

1. median QEMU nanoseconds per complete polynomial frame or FFT;
2. speed ratio to f64 scalar at the current shape;
3. largest measured polynomial term count that fits within the f64/24-term
   time budget;
4. largest measured FFT length that fits within the f64/N=1024 time budget;
5. numerical error versus f64 reference;
6. bytes per stored component;
7. disassembly evidence that the explicit NEON lanes actually contain vector
   instructions.

Results will be appended here from the CI artifact; emulator ratios remain
screening evidence rather than MIRO cycle claims.
