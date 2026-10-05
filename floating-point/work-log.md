# Floating-point work log

Historical snapshot of the August 26, 2026 investigation. Implementation and CI statements below describe that recorded revision; they do not establish current compiler, ABI, GPU, or physical-device qualification.

## 2026-08-26 — shader precision kickoff

Cross-repository working branch: `float-semantics-f16-f32`.

Related implementation: [`isomorphisms/idris-shader-backend` PR #10](https://github.com/isomorphisms/idris-shader-backend/pull/10).

### Decisions recorded

- Treat **F16** and **F32** as semantic value widths, not as synonyms for a compiler flag or ABI.
- Treat Arm **soft**, **softfp**, and **hard** as presets over separate facts:
  - arithmetic implementation (software/hardware),
  - procedure-call convention (base/core-register PCS versus VFP PCS).
- Keep vectorization independent of width and ABI: scalar F16/F32 and vector F16/F32 are all valid combinations when a target supports them.
- Keep reductions, FMA/contraction, NaN/subnormal behavior, and transcendental tolerances explicit because those can change observable rounding.
- Treat current Idris `Double` -> GLSL ES `float` lowering as **F32 semantics**, not binary64 shader semantics.
- Use GLSL ES `highp` for the current F32 production route.
- Do not equate portable GLSL ES `mediump` with exact binary16: it specifies minimum precision/range and may be implemented wider.
- Record a distinct PowerVR profile because Imagination documents `mediump` shader variables as FP16 and recommends lower precision where the range is sufficient.
- Do not globally demote a shader to F16. Precision is a typed/dataflow decision; sensitive phase/log/root/coordinate work may remain F32 while bounded color/mask/interpolation work can be candidates for F16.

### Implementation started in `idris-shader-backend`

- Added `Backend.GLSLES.FloatSemantics` with F16/F32 widths, high/medium GLSL precision policy, generic GLES versus PowerVR target profiles, and scalar/vector precision spellings.
- Kept current production output on F32/highp.
- Changed the human-readable checked shader IR so current float values are written as `F32`, `F32x2`, `F32x3`, and `F32x4` instead of width-erasing `float`/`vecN` type names.
- Regenerated the checked IR fixtures and added regression checks that reject a return to width-erasing type names.
- Added tests for F16/F32 scalar policy, vector policy, generic GLES not claiming exact F16, and the PowerVR native-F16 profile.
- Added backend documentation linking the implementation to the cross-target contract in this repository.
- Current-head GitHub CI passed the complete backend checks and the generated-output cleanliness check.

### Still deliberately not done

- F16 is not yet a complete source-to-IR dataflow type in the compiler.
- There is not yet an explicit F16↔F32 conversion operation in the shader IR.
- The existing internal `TFloat`/`TVec n` constructors still represent the current F32 path; the visible IR now exposes that fact while the width-parameterized refactor is prepared.
- CPU width-controlled F16/F32 oracle execution is not yet implemented.
- Arm soft/softfp/hard builds of that oracle are not yet wired into CI.
- PowerVR capability capture (`GL_RENDERER`, precision formats) and actual-device framebuffer comparison are not yet wired.
- No production shader has been demoted to F16, and no performance claim has been accepted without real-device profiling.

### Next implementation slice

1. Parameterize the backend numeric IR by F16/F32 without weakening vector-width checks.
2. Add explicit F16↔F32 conversion nodes and reject implicit narrowing.
3. Carry precision through fixed arrays and shader interfaces.
4. Add mixed-precision source fixtures and generated GLSL checks.
5. Add CPU F16/F32 reference arithmetic, then build it under soft/softfp/hard Arm profiles.
6. Record real PowerVR precision capabilities and compare F16/F32/mixed variants against the framebuffer oracle.
7. Profile on the actual device before selecting production precision per dataflow.
