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

Polynomial term counts measured: 8, 16, 24, 26, 28, 30, 32, 48, 64.

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

## First green result

Fourier-sound benchmark commit:
`da4d436d24f006e6c90c6de5b2957b43687ca1aa`.

Toolchain receipt:

- `arm-linux-gnueabi-gcc 13.3.0`;
- `qemu-arm 8.2.2`;
- ELF attributes: ARMv7-A, Thumb-2, VFPv4, NEONv1 with fused MAC, IEEE
  binary16 format;
- disassembly contains explicit NEON loads/stores and vector
  `vmul.f32`, `vmla.f32`, `vmls.f32`, `vadd.f32`, and
  `vsub.f32` in the SIMD lanes.

The two QEMU CPU models produced similar direction but are not independent
hardware measurements. Their timing differences should not be read as a
Cortex-A7-versus-Cortex-A15 performance comparison; TCG is not cycle accurate.

### Current-shape headroom

| Kernel/lane | Cortex-A7 speed ratio | Cortex-A15 speed ratio | Same-budget measured headroom | Error versus f64 |
| --- | ---: | ---: | --- | ---: |
| polynomial f32 scalar | 1.124× | 1.147× | 26 terms vs 24 | ~5.35e-8 relative checksum |
| polynomial f32 NEON4 | 1.134× | 1.209× | 26 terms on A7; 28 on A15 vs 24 | ~5.35e-8 |
| polynomial FP16 storage → f32 math | 0.713× | 0.735× | slower; 24 terms exceed baseline | ~2.71e-4 |
| polynomial E4M3 storage → f32 math | 0.916× | 0.983× | slightly slower at 24 terms | ~1.87e-2 |
| polynomial E5M2 storage → f32 math | 0.777× | 0.827× | slower at 24 terms | ~1.94e-2 |
| FFT f32 scalar, N=1024 | 1.086× | 1.094× | same N=1024; ~9% more transforms/time | ~7.00e-7 max component error |
| FFT f32 NEON2 SoA, N=1024 | 1.286× | 1.290× | same N=1024; ~29% more transforms/time | ~7.00e-7 |
| FFT FP16 stage storage → f32 math | 0.560× | 0.569× | only N=512 fits f64/N=1024 time | ~9.82e-5 |

The most useful first result is that **smaller storage is not automatically
faster** on this ARMv7 path. Repeated FP16/fp8 conversion can cost more than
the binary32 arithmetic it saves. Binary32 plus explicit NEON is the only lane
in this first matrix that clearly buys compute headroom without a material
numerical penalty.

For the polynomial renderer, the measured SIMD headroom is roughly **+2 to +4
terms** at the same QEMU time as the current 24-term f64 frame. That is a
screening result, not yet a MIRO limit.

For the FFT, the structure-of-arrays NEON version is about **29% faster** at
N=1024. That is not enough to make N=2048 fit inside the *old N=1024
FFT-only* time budget: the measured N=2048 NEON transform is about 0.93–0.94 ms
versus about 0.52 ms for f64 N=1024. But the FFT remains much cheaper than a
96×192 polynomial frame in this emulator, so a larger transform may still fit
the actual application frame budget after physical-phone measurement.

### E5M3 result

Current ICK E5M3 remains unsigned storage, so a signed complex FFT lane is not
defined. Its decode-only probe processed 4096 stored values in about 33–35 µs
under QEMU, roughly 118–124 million decodes/s in emulator time. Do not turn
that number into a MIRO throughput prediction.

The raw green summary is committed beside this note. Physical MIRO timing is
the next gate before adopting f32/NEON or changing coefficient count.
