# FP16 / PowerVR progress — 2026-08-26

This note tracks how close the Idris/Idriç GLSL ES path is to carrying deliberate
F16 semantics into algebraic-surface shaders and ultimately onto the PowerVR
Android target.

FP16 is a first-class semantic target here, not merely a late optimization of an
F32 implementation. Several different claims must remain separate: selecting a
whole-shader width, carrying width on each typed IR value, exposing width in the
source language, validating generated GLSL, and proving numerical behavior on
the actual GPU.

## Executable whole-shader mode now exists

On `idris-shader-backend:main` (merged PR #11 on top of PR #10), the compiler
now accepts `float-width=f16|f32`, with F32 remaining the default.

- F16 compilation renders the checked IR as `F16` / `F16xN` and emits
  `precision mediump float;`.
- F32 compilation renders the checked IR as `F32` / `F32xN` and emits
  `precision highp float;`.
- unsupported widths such as F64 are rejected rather than silently mapped to a
  supported precision.
- the end-to-end compiler check validates the generated F16 fragment with
  `glslangValidator`.
- PR #11 is merged; watchers now follow `main` and record the exact resolved backend SHA for each observation.

This is a substantive advance beyond the earlier precision-policy-only state.
The compiler can now select a complete shader's semantic width and carry that
selection through the checked diagnostic IR and emitter.

## What this still does not mean

The underlying shader value-type constructors are still width-erasing forms
such as `TFloat`, `TVec n`, and `AFloat`; the selected width is a compilation
mode rather than an independent width attached to every scalar, vector, and
array value. Consequently this does not yet provide mixed-width shader IR.

There are still no explicit F16->F32 or F32->F16 conversion operations in that
IR, and `Shader.Source` remains the existing `Double`-shaped source vocabulary.
A program requests F16 through the compiler directive rather than a source-level
F16 type.

Portable GLES `mediump` also remains only a precision-class contract. The
PowerVR profile records the intended native FP16 behavior, but generated
`mediump` GLSL by itself does not prove exact IEEE binary16 execution on every
GPU or even on the target device.

## Two downstream dogfood paths

SOAP PR #5 now consumes the selectable mode through Edriç. It pins the backend
head above, compiles every playable `.idric` surface with
`--directive float-width=f16`, requires mediump fragment output, matches the
fullscreen vertex precision, and records `GL_MEDIUM_FLOAT` precision-format
information from GLES. This is real application integration, but it is still
not a framebuffer numerical oracle.

Algebraic Variety Explorer PR #12 adds an independent compiler-consumer gate.
The existing app remains the Java CPU renderer; the new lane does not pretend to
replace its runtime renderer. Instead it takes the backend's bounded
`SurferRootSearch` shader, which has the algebraic-surface eight-coefficient and
fixed bracket/bisection structure, and compiles it both ways:

1. F16: require F16/F16xN checked IR, mediump GLSL, and GLSL validation;
2. F32: require F32/F32xN checked IR, highp GLSL, and GLSL validation;
3. F64: require rejection and no generated fragment.

It retains the checked IR, GLSL, validation output, backend revision, and hashes
as downstream evidence. This is intentionally a compiler dogfood gate rather
than a claim of PowerVR execution.

## AICI now distinguishes these milestones

AICI PR #14 follows `idris-shader-backend:main` after the whole-shader mode merged. Its FP16 baseline now promotes the established whole-shader
compiler facts: directive parsing, selected-width checked IR, selected-width
emission, invalid-width rejection, and the executable F16 compiler test.

The older future rows remain independent observations: per-value scalar/vector/
array width in IR, explicit conversions, source-level F16, and the real PowerVR
framebuffer oracle.

AICI also has `fp16_consumers.tsv` for the Algebraic Variety Explorer branch,
recording the exact backend pin and the F16/F32 compile, IR, GLSL-validation,
F64-rejection, and evidence-retention surfaces. These literal probes establish
that the consumer gate is present; the consumer's own CI is the stronger
compile evidence.

## ComputerScience watcher

The ComputerScience PR #12 watcher now follows:

- AICI `compiler-backend-observations`;
- `idric-arm-thumb:idric-ir-first-slice`;
- `idris-arm-backend:main`;
- `idris-shader-backend:main`;
- `algebraic-variety-explorer-mobile:dogfood/idris-shader-f16`.

It combines AICI's general backend matrix, FP16/PowerVR matrix, and downstream
FP16 consumer matrix into the deterministic change record. The interpretation
prompt explicitly distinguishes whole-shader selection from per-value typed IR
and distinguishes a downstream compile/validation gate from target numerical
proof.

The historical baseline remains unchanged. The newly watched compiler and
consumer facts should appear as changes rather than being retroactively written
into the original observation.

## Next decisive numerical layer

The next useful work is numerical rather than another textual precision marker.
At minimum, compare F16 and F32 on deliberately sensitive and boundary cases:

1. known ULP boundaries and adjacent representable values;
2. cancellation such as `(1 + epsilon) - 1`;
3. binary16 normal/subnormal, overflow, underflow, infinity, and zero boundaries;
4. division near small denominators;
5. square root and any shader transcendental operations that materially affect the renderers;
6. vector operations such as dot, length, and normalize;
7. algebraic-surface root-search cases near tangency or closely spaced roots.

The strongest target gate then compiles, links, renders, and reads back the
actual PowerVR framebuffer and compares it with a deliberately chosen CPU
reference/oracle. That is where claims about real F16 numerical behavior should
be promoted from observation to evidence.
