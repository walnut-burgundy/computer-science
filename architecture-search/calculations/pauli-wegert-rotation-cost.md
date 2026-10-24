# Pauli and Wegert rotation: a first cost estimate

**Status:** paper arithmetic only (2026-10-24). No optimizer, numerical equivalence run, benchmark, target speedup, or acceptance is claimed.

## Decision boundary

ComputerScience should own the conservative calculation, candidate comparison, assumptions, and a traceable recommendation. Pauli and Wegert own their application math and implementations. A stable DEX emitter or native/GLSL compiler should carry out a chosen plan, not secretly choose a mathematical algorithm.

Pauli's current production viewer uses Android NativeActivity, native C, and GLES, **without application DEX**. Its direct data path therefore belongs in native code or GPU data, not DEX. Wegert also has a NativeActivity renderer. A future ART/DEX consumer may be evaluated separately.

**Pinned source:** [Pauli commit 8b8fa661](https://github.com/isomorphismes/pauli/commit/8b8fa6614efd80dd48cfe8787e800fd0446592e5), especially [volume render](https://github.com/isomorphismes/pauli/blob/8b8fa6614efd80dd48cfe8787e800fd0446592e5/android/native/pauli_volume_image.c), [orbital evaluator](https://github.com/isomorphismes/pauli/blob/8b8fa6614efd80dd48cfe8787e800fd0446592e5/android/native/pauli_orbital.c), and [native renderer notes](https://github.com/isomorphismes/pauli/blob/8b8fa6614efd80dd48cfe8787e800fd0446592e5/android/native/README.md).

## Baseline: count the work before timing it

Current Pauli volume renderer:

- 128 × 128 pixel-center positions, spanning ±1.08 on both axes.
- Pixel centers: u ≝ −1.08 + 2.16 × (pixel_x + 0.5) ÷ 128; similarly for v.
- Exactly **11,008** sample centers satisfy u² + v² < 1; others receive background.
- Every inside pixel uses **28** depth samples.
- Total: **11,008 × 28 = 308,224** field evaluations per frame.

The current rotate-into-orbital function applies yaw, then pitch, to each depth sample:

- yaw_x ≝ cos(yaw) × x + sin(yaw) × z
- yaw_z ≝ −sin(yaw) × x + cos(yaw) × z
- output_y ≝ cos(pitch) × y − sin(pitch) × yaw_z
- output_z ≝ sin(pitch) × y + cos(pitch) × yaw_z

These are **8 scalar multiplications plus 4 additions/subtractions per sample**, apart from unary sign changes, target fusing, and compiler effects. The trigonometric values for yaw/pitch are already calculated once per frame.

Paper totals for rotation alone:

| Operation | Formula | Count per frame |
|---|---|---:|
| Multiplications | 308,224 × 8 | 2,465,792 |
| Additions/subtractions | 308,224 × 4 | 1,232,896 |
| Counted scalar operations | 308,224 × 12 | **3,698,688** |

These figures exclude three scale-by-radius multiplications per sample, field evaluation, ray integration, rendering, upload and frame presentation. They are **not clock cycles or execution times**.

## Candidate A: rotate each ray once (recommended first experiment)

For fixed rotation R and ray p(t) ≝ p₀ + t d, linearity gives

R(p₀ + t d) = R p₀ + t R d.

All camera rays in this renderer share a depth direction. Rotate that direction once per frame. For each pixel rotate its first sample, scale the rotated direction by its depth step, then increment three coordinates for the remaining 27 samples.

A deliberately conservative instruction-independent arithmetic estimate:

| Operation | Formula | Count per frame |
|---|---|---:|
| Multiplications | 11,008 × (8 for first sample + 3 for depth step) | 121,088 |
| Additions | 11,008 × (4 for first sample + 27 × 3 increments) | 935,680 |
| Counted scalar operations | Sum | **1,056,768** |

Difference from current arithmetic: **2,641,920 fewer scalar operations per frame** (approximately **71.4% of rotation-specific counted arithmetic**), or **3.5× less work under this narrow count**. **This is not a prediction of 3.5× faster frame rendering.** The evaluator is likely more expensive than the rotation itself.

Incrementing repeatedly changes floating-point operation ordering and accumulates rounding differences. Compare reference field values, density, phase signs near nodes, and rendered images. If drift matters, instead form each sample from an affine base and index; that may cost more multiplications but avoids recurrent error.

## Candidate B: rotate harmonic coefficients

For angular degree ℓ, the SO(3) representation has dimension 2ℓ + 1. Its dense matrix sizes for ℓ = 0, 1, 2, 3 are respectively **1×1, 3×3, 5×5, 7×7**. Rotating a coefficient vector once per frame sounds cheap, but the resulting orbital may require evaluating up to 2ℓ + 1 angular basis terms at every sample.

For the presently displayed single sparse orbital states, especially 4f_xyz, a rotated product of coordinates is likely cheaper than evaluating a general rotated cubic expansion. Wigner coefficient rotation may win if multiple superpositions share cached basis evaluations, but reuse, cache memory, and bandwidth must then enter the model. **Do not choose this solely from the small matrix dimension.**

Initial prediction: defer as the default for the current four-state viewer; retain as a candidate for more general states.

## Candidate C: direct Cartesian evaluation (potentially larger gain)

The demonstrated real-basis orbitals admit simple forms, up to their checked normalization constants:

- 1s: exp(−r)
- 2p_x: x × exp(−r/2)
- 3d_xy: x × y × exp(−r/3)
- 4f_xyz: x × y × z × exp(−r/4)

Here r ≝ √(x² + y² + z²). Pauli currently transforms Cartesian coordinates into spherical ones and invokes its generated F64 state evaluator, including hypot, acos, atan2, and basis projection. For the four fixed demonstrations, a checked direct Cartesian specialization could avoid much of that machinery at every sample.

This potentially saves more than rotation restructuring, but normalization, phase convention, node handling, and correctness against the generated F64 oracle must be preserved. The displayed proportional forms do **not** supply the normalization constants. Try candidate A alone, C alone, then A+C.

## Wegert: distinguish the rotation being requested

For codomain rotation f(z) ↦ exp(iθ)f(z), the hue-driving phase becomes arg f(z) + θ modulo 2π. The frame needs only a phase uniform; the shader adds it per fragment. No rotation matrix or DEX table is required. Input-plane rotation z ↦ exp(−iθ)z is a **different operation**; model it separately.

Source: [Wegert shader](https://github.com/isomorphismes/wegert/blob/main/code/wegert.frag.in) and [color conversion](https://github.com/isomorphismes/wegert/blob/main/code/wegert_color.glsl). Re-pin Wegert before using this as an exact-revision benchmark comparison.

## Proposed selection trace (not implemented)

- **Decision:** pauli.rotation.lowering
- **Present implementation:** per-sample yaw/pitch coordinate rotation.
- **First candidate:** rotate ray origin/direction; increment along ray.
- **Second candidate:** checked direct Cartesian evaluator for fixed demonstrations.
- **Deferred candidate:** dense Wigner harmonic coefficient rotation, pending reused basis/superposition workload.
- **Model inputs:** image size, visible-circle membership, ray samples, arithmetic expressions, state/basis sparsity, target ABI and device.
- **Evidence:** source-derived arithmetic, not timing.
- **Measurement required:** A1 ARM32 and C67 ARM64 native render time and first/full frame; exact compiler and revision; equivalent sample values and pixel differences; node error; texture upload cost separately.
- **Status:** PROPOSED / UNMEASURED.

This belongs in calculations rather than masquerading as a planner, compiler pass, or accepted low-level implementation. Actual source selection and performance receipts belong with Pauli, with a link back to this decision model. Any eventual DEX route must be evaluated as a separate runtime/data-placement candidate, not smuggled into a native-only application.
