# GPU renderer contract lab

This directory is a small executable deviation from the rest of `computer-science`: it turns renderer/backend observations into tests. It is **not** a renderer, a compiler, or a claim that every vector operation belongs on a GPU. It is a place to make the CPU/GPU boundary explicit before the Idriç shader backend and its consumers depend on implicit driver behavior.

The immediate case study is ManimGL / [`isomorphisms/manimi`](https://github.com/isomorphisms/manimi). As of 2026-08-26 its `master` includes upstream Manim commit [`9d57bcf9`](https://github.com/3b1b/manim/commit/9d57bcf9edea2486f214e190931de2a5537f23c1) and the checked Ithon rewrite. The name is now historically misleading: upstream ported the renderer from OpenGL to `wgpu`/WGSL in [`e4a7bca7`](https://github.com/3b1b/manim/commit/e4a7bca73777bdc16853f896a2525a4f03fa7687). That makes it unusually useful here: it is a real graphics program preserving the same visible semantics while changing the GPU API underneath.

## What ManimGL exposes

| Boundary | ManimGL / current `wgpu` approach | Lesson for Idriç -> GLSL and GPU consumers |
| --- | --- | --- |
| Cached record uploads | A record is re-uploaded when its payload version, offset, or derived separator role changes. `9d57bcf9` fixed a spurious curve caused by omitting the separator role from that state. | A cache key must include every fact which changes the bytes or their interpretation, not merely the source value/version. |
| CPU/GPU data layout | Record offsets are generated from the NumPy dtype; uniform-block CPU layout and WGSL declarations are generated from the same schema. | Generate host packing and shader interface from one typed description. Do not maintain two hand-written ABIs. |
| Dynamic buffers | Many objects share buffers; claims are aligned to the device's dynamic-offset limits, dirty ranges are coalesced, and uploads happen once before drawing. | Treat alignment, stride, capacity, dirty ranges, and write-before-draw ordering as backend contracts. |
| Resource binding | The `wgpu` port had to bind every declared texture; OpenGL had tolerated a declared texture left dangling when the shader did not sample it. | Test the strict interface, not only whatever one GL driver happens to accept. |
| Pipeline state | `wgpu` bakes blend/depth/stencil/sample state into pipeline objects; Manim keys and caches pipelines by the state that changes generated behavior. | Make render state explicit data in the lowering/runtime interface and include it in cache identity. |
| Pass ordering | The port split all buffer writes from all draws because writes must precede the frame's render pass. | Backend/runtime phases matter. A correct shader is insufficient if host-side ordering is illegal. |
| Batching and bundles | Manim compares merged/bundled rendering against plain drawing because those optimizations are intended to be invisible. | Every batching, fusion, and replay optimization needs an unoptimized semantic oracle. |
| Cross-API image oracle | OpenGL and `wgpu` can differ on edge pixels because rasterizers sample boundaries differently; Manim treats interior differences as the stronger failure signal. | Do not demand byte equality across different rasterizers, but do not hide interior/numerical errors behind a fuzzy visual score. |
| Asynchronous readback | Manim moved frame readback one frame behind to remove a GPU wait, then added an explicit drain test so the final frame cannot disappear silently. | Synchronization and pipeline latency need sequence tests, not only single-result tests. |
| Resource lifetime | Module, texture, layout, pipeline, and buffer caches belong to the GPU device lifetime. | Never let generated/backend resources leak across an invalid context/device lifetime. |
| Performance | Manim found redundant bind calls and synchronous readback large enough to dominate useful drawing work. | Measure upload + launch/bind + compute + synchronization + readback. Kernel throughput alone does not justify offload. |

Useful upstream evidence:

- [`451c1c07`](https://github.com/3b1b/manim/commit/451c1c071b0f4b24019444a169334992574cc781): explicit `wgpu` capability spike before the port, including storage-buffer vertex reads, uniform layout, validation failures, depth mapping, and readback alignment.
- [`2533c8ad`](https://github.com/3b1b/manim/commit/2533c8adc1c1c0f6dff567ee8889d0274691bbdb): pipeline state made explicit and all writes moved before all draws.
- [`a91f7f8c`](https://github.com/3b1b/manim/commit/a91f7f8c5f8ec2e244c4bde540ab483aaa315386): asynchronous readback, including a test for the otherwise-invisible missing-final-frame bug.
- [`901babf1`](https://github.com/3b1b/manim/commit/901babf145328dc7893efe163d562b8fd5570782): redundant bind calls measured and removed rather than weakening validation.
- [`447c64a5`](https://github.com/3b1b/manim/commit/447c64a5dbbd8456e6cc03a757299d10125aa543): renderer objects reorganized by device/material/frame/pass lifetime.
- [`9d57bcf9`](https://github.com/3b1b/manim/commit/9d57bcf9edea2486f214e190931de2a5537f23c1): derived separator state added to record invalidation after stale GPU bytes drew a spurious curve.

## Tests here

`contract.py` is intentionally dependency-free. `test_contract.py` currently checks:

1. unchanged source bytes are still invalidated when derived buffer state changes;
2. offset, record-count, separator, and layout changes participate in cache validity;
3. shared-buffer claims obey dynamic-offset alignment;
4. shader-declared and host-bound resources cannot silently drift;
5. baked pipeline state participates in cache identity;
6. a cross-rasterizer oracle may excuse edge-only changes but not interior changes;
7. one-frame-late readback must be drained and preserve the complete frame sequence;
8. GPU/CPU selection is based on end-to-end work rather than kernel time alone.

Run:

```sh
cd gpu-renderer-contract
python -m unittest -v test_contract.py
```

The suite does not need a GPU. It is the cheap semantic layer before actual compile/runtime probes.

## Next empirical layer for Idriç

The next tests should use the real Idris/Idriç shader backend and real target GPUs:

- compile and run common vector fixtures for indexed load, dot, norm, normalize, matrix-vector multiply, 2-D/3-D rotation, and reflection;
- compare generated host layouts against shader-visible sentinel records at byte/field boundaries;
- run F32 first, then capability-gated F16 with explicit error envelopes rather than merely checking that half-precision source text exists;
- compare optimized batching/fusion against the plain path;
- benchmark vectors already resident on the GPU separately from one-shot CPU->GPU->CPU round trips;
- test context/device recreation so cached modules, pipelines, buffers, and textures cannot survive the device they belong to;
- keep readback/framebuffer oracles separate from source-marker and compile-only evidence.

That gives Coxeter-style rotations/reflections, vector-index search, shader rendering, and other vector-heavy consumers a shared contract without forcing them all through one renderer or pretending that every small vector operation is automatically faster on a GPU.
