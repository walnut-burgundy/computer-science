# Floating-point semantics

This note separates four things that are too often collapsed into the word “float”:

1. the **value format** (`F16`, `F32`);
2. the **arithmetic implementation** (software or hardware);
3. the **procedure-call ABI** (Arm base/soft, `softfp`, or hard/VFP); and
4. the **shape of the operation** (scalar or vectorized).

They are independent axes. In particular, `soft`, `softfp`, and `hard` are not three numerical types and must not silently change the meaning of `F16` or `F32`.

This is the semantic record for the Idris/Idriç shader work and for CPU reference implementations used as shader or framebuffer oracles.

## Value formats

### F16

`F16` means IEEE-754 binary16 unless a target contract explicitly says otherwise:

- 1 sign bit;
- 5 exponent bits;
- 10 stored fraction bits (11 bits of normal-number precision including the implicit leading bit);
- largest finite magnitude `65504`;
- smallest positive normal value `2^-14`;
- smallest positive subnormal value `2^-24`.

A backend may use a wider temporary internally, but an `F16` semantic boundary must round back to binary16. An optimization may not silently retain extra precision across a boundary where source semantics require an `F16` value.

NaNs, infinities, signed zero, overflow, underflow, subnormal handling, rounding, and contraction/FMA behavior are part of the target contract. If a target cannot meet the selected contract, lowering must either select an explicitly relaxed contract or reject it; it must not pretend that `F16` was preserved.

### F32

`F32` means IEEE-754 binary32 as the storage/value format:

- 1 sign bit;
- 8 exponent bits;
- 23 stored fraction bits (24 bits of normal-number precision including the implicit leading bit).

The existing Idris-to-GLSL ES backend currently accepts Idris `Double` at the source boundary but emits GLSL ES `float`. That mapping is therefore an **F32 lowering contract**, not “Double semantics”. The compiler IR and tests should make this explicit rather than leaving the narrowing implicit.

For OpenGL ES, `highp float` has the range and precision of IEEE-754 single precision, subject to GLSL ES rules permitting implementation latitude such as subnormal flushing and bounded rounding error. See the Khronos GLSL ES specification, especially “Floats” and “Range and Precision”: https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html

## Arm 32-bit float execution and calling convention

For Armv7/AArch32 work, record both **how arithmetic is executed** and **how values cross a public call boundary**.

### soft

- Floating-point arithmetic is implemented without requiring VFP/NEON floating-point instructions, normally through software helper routines.
- Floating-point arguments and results use the AAPCS base procedure-call convention: core registers and/or the stack.
- The numerical type may still be `F16` or `F32`; “soft” does not mean a different bit format.

### softfp

This is the useful “in-between” case.

- The compiler may generate VFP/NEON floating-point instructions for arithmetic.
- Public floating-point arguments and results still use the base AAPCS convention in core registers and/or on the stack.
- It is therefore call-compatible with base/soft interfaces while still allowing hardware floating-point execution inside a function.

### hard

- The compiler may use VFP/NEON floating-point instructions.
- Eligible floating-point and vector arguments/results use the VFP variant of AAPCS and its floating-point/vector register argument rules.
- This is an ABI difference, not a change in `F16`/`F32` arithmetic meaning.

The Arm AAPCS32 specification defines the base core-register procedure-call standard and the VFP/SIMD register-argument variant, including half-, single-, double-precision and containerized-vector values: https://github.com/ARM-software/abi-aa/blob/main/aapcs32/aapcs32.rst

The Arm run-time ABI also explicitly describes software floating-point helper functions using base-standard calling conventions even when their implementation uses floating-point hardware: https://github.com/ARM-software/abi-aa/blob/main/rtabi32/rtabi32.rst

### Required representation in target metadata

Do not encode the three cases in one overloaded flag. Record at least:

```text
value_format:       F16 | F32
arithmetic_engine:  software | hardware | either
call_abi:           base | vfp
vector_engine:      scalar | SIMD
```

Common presets may be named `soft`, `softfp`, and `hard`, but the planner/compiler should retain the decomposed facts.

## Vectorized semantics

Vectorization is orthogonal to both float width and ABI.

Use a semantic shape such as:

```text
Scalar F16
Scalar F32
Vec n F16
Vec n F32
```

For ordinary componentwise operations, each lane has the same semantics as the corresponding scalar operation. A vectorized lowering must not change results merely because several lanes share one instruction.

Operations that are genuinely cross-lane (`dot`, horizontal sum/min/max, shuffle, swizzle, reduction) are separate semantic operations. Their reduction order must be explicit when it can affect rounding.

Fused multiply-add is also a separate semantic operation. A backend may contract `a*b+c` into FMA only when the selected semantics permit contraction; otherwise it must preserve the source rounding points.

For Arm, the AAPCS32 VFP variant has explicit rules for 64-bit and 128-bit containerized vectors. That call ABI question remains separate from whether the implementation actually chooses scalar VFP instructions or NEON/Advanced SIMD instructions for the body.

## GLSL ES precision and PowerVR

GLSL ES precision qualifiers are not generally identical to fixed-width source types.

### Portable GLSL ES contract

- `highp float` is the F32 route for this project.
- `mediump float` has only a **minimum** required range and precision in portable GLSL ES: roughly the range/precision associated with binary16, but an implementation may provide more.
- Therefore portable `mediump` is not, by itself, proof that every intermediate is exact IEEE binary16.

The GLSL ES specification gives `mediump` a minimum magnitude range of `2^-14` through just below `2^14` and minimum relative precision `2^-10`, while allowing implementations up to highp precision. See: https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html#precision

### PowerVR target

Imagination documents PowerVR `mediump` shader variables as 16-bit floating-point values and recommends using FP16 where its range and precision are sufficient because it can materially increase arithmetic throughput. See “Do Prefer Lower Data Precision”: https://docs.imgtec.com/starter-guides/powervr-architecture/html/topics/rules/do-prefer-lower-data-precision.html

Accordingly the target model should distinguish:

```text
GLSLESHighpF32
GLSLESMediumpRelaxed
PowerVRMediumpF16
```

`PowerVRMediumpF16` may be selected only when target evidence supports it. The runtime/device record should include the renderer/vendor strings and `glGetShaderPrecisionFormat` observations. A device framebuffer oracle remains authoritative for visual equivalence.

The backend should not globally replace every `highp` with `mediump`. Phase accumulation, logarithmic magnitude, coordinate transforms, root finding, and other numerically sensitive paths may need F32 while colors, masks, interpolation weights, or other bounded quantities may safely use F16. Precision is a type/dataflow decision.

## CPU reference/oracle semantics

The CPU oracle must be able to model the semantic width independently of the host compiler’s preferred arithmetic width.

For strict tests:

1. convert inputs to the selected semantic format;
2. perform the semantic operation;
3. round/store at each source-visible `F16` or `F32` boundary;
4. compare bit patterns for operations with exact specified behavior;
5. use operation-specific ULP/tolerance rules where the target language does not require exact transcendental results;
6. compare final rendered pixels against the framebuffer oracle for the production shader path.

A software implementation is useful even on hardware-float devices because it gives us a width-controlled reference independent of register allocation and precision promotion.

## Test matrix

At minimum, cover these axes:

| axis | cases |
| --- | --- |
| value width | F16, F32 |
| CPU ABI | soft, softfp, hard |
| execution shape | scalar, vectorized |
| GPU precision | highp, mediump |
| GPU target | portable GLES, actual PowerVR device |

Useful edge values include `+0`, `-0`, values adjacent to `1`, min/max normal values, subnormals, infinities, NaNs, and values that overflow or underflow after one operation.

Useful operations include add/subtract/multiply/divide, comparisons, conversion F16↔F32, vector component operations, dot/reductions, square root, and the production shader’s `sin`, `cos`, `log`, `atan`, and `pow` paths. Transcendentals need target-appropriate tolerances rather than a false bit-exact promise.

## Shader-backend implementation order

1. Make the existing `Double` → GLSL `highp float` path explicit as **F32** in compiler types, diagnostics, and tests.
2. Add F16 as a distinct semantic type; no implicit F32→F16 demotion.
3. Add explicit F16↔F32 conversions.
4. Lift both widths to vectors and fixed arrays.
5. Emit precision-qualified GLSL dataflow (`highp` for F32, `mediump` for the F16/relaxed route).
6. Add CPU width-controlled reference tests.
7. Add PowerVR device capability capture and framebuffer-oracle tests.
8. Only then profile F16 versus F32 and choose mixed-precision production paths.

The rule is simple: **width, ABI, vectorization, and hardware are explicit facts. None may be inferred from the spelling `float`.**
