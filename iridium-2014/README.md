# Iridium 2014 reference benchmark

## What this is

[Iridium](https://github.com/puffnfresh/iridium) is Brian McKenna's (`@puffnfresh`) 2014 Idris window-manager experiment. It is closer to an xmonad-like tiling **window manager** than a pixel compositor: the upstream README describes it as a version of xmonad with the X11-specific part abstracted away and the configuration/program logic written in Idris rather than Haskell.

This repository pins the upstream source as the git submodule [`../upstream/iridium`](../upstream/iridium) at commit:

```
2dc438475962b62f6ca8d00f0dff3add87418dec
```

The upstream repository is MIT licensed, copyright 2014 Brian McKenna. Keep the upstream license and history attached to the code; do not relabel it as code from this repository.

Brian's Strange Loop 2014 talk was **Idris: Practical Dependent Types with Practical Examples**. His surviving talk source is [`puffnfresh/stl-idris`](https://github.com/puffnfresh/stl-idris); its `slides.md` contains an Iridium slide describing the program as a window manager, abstracted, 60% Idris and 40% Objective-C. That presentation repository has no obvious license file at its root, so it is linked here rather than vendored.

## Thank you

A large and explicit thank-you to Brian McKenna. The 2014 presentation was unusually memorable and inspiring. The Iridium demonstration in particular stuck in memory for more than a decade as an example of what it might look like to use dependent types for a real graphical/system program rather than only as a theorem-proving exercise. It is delightful that the original source is still public and can now serve as a concrete historical benchmark.

The point of keeping it here is not to claim this project as ours. It is to preserve a precise pointer to work that mattered, give its author credit, and make a reproducible before/after comparison possible as the Idriç native backends mature.

## Historical build boundary

The upstream build is specifically macOS/Quartz:

- `src/Quartz.idr` links `-framework Cocoa`;
- the Idris side calls C/Objective-C through the old Idris FFI;
- `cbits/quartz.m` supplies the macOS window-system boundary;
- the upstream `Makefile` builds the package and then compiles `Quartz` with the `effects` package.

So the complete original executable is a **Mach-O macOS program**, not an ELF Android/Linux program. `readelf` is therefore not the correct inspector for the original whole-program binary. For the historical Mach-O build record use `file`, `otool -hv`, `otool -l`, `otool -L`, `size`, and `nm`. Use `readelf` on the portable Linux/Android ELF fixtures and on future ARM Thumb output.

That distinction is useful rather than annoying: it prevents us from pretending that file format, runtime, OS libraries, and generated program code are the same thing.

## Benchmark plan

Keep two related benchmarks.

### 1. Whole historical Iridium

Reconstruct the original 2014-era Idris build on macOS as closely as practical and record:

- exact Iridium commit;
- exact Idris version/commit;
- host CPU and OS;
- generated executable byte size;
- Mach-O headers, segments/sections, linked dylibs, symbols, and relocations where available;
- compile time;
- launch/startup behavior when a compatible macOS environment is available.

This is the historical artifact benchmark. It answers "what did the real program produced by the old Idris toolchain look like?"

### 2. Portable deterministic Iridium kernel

Extract no more than is necessary to exercise the pure Idris window-management logic (`StackSet`, layout selection, focus movement, swapping, rectangle calculation) without Cocoa or a real display server. Feed a fixed synthetic stream of windows/screens/events and hash or serialize the final state.

Compile the **same semantic fixture** through each usable backend:

| backend | target | inspect | timing role |
| --- | --- | --- | --- |
| historical Idris C backend | Linux ELF reference | `readelf`, `size`, `nm`, dynamic dependencies | old generated-C/runtime baseline |
| current Idriç reference backend | host/ELF where applicable | same | correctness/reference baseline |
| Idriç ARM Thumb/T32 | ARMv7 ELF or freestanding image | `readelf` plus disassembly | native CPU size/speed target |
| Idriç GPU backend | shader + host boundary | shader/interface inspection | only operations that genuinely belong on GPU |

Do **not** report a GPU speedup for the whole window manager. Most StackSet/event/control work is scalar host work. A GPU comparison only makes sense for a separately named data-parallel/layout/rendering kernel. Keeping that line explicit makes the benchmark harder to game.

## Measurements to retain

For every executable/backend result retain at least:

```
source_commit
compiler_commit
backend
target_triple
host_or_emulator
os
compile_command
compile_seconds
file_bytes
text_bytes
data_bytes
bss_bytes
needed_dynamic_libraries
run_command
iterations
wall_seconds
user_seconds
system_seconds
result_digest
```

For ELF additionally retain:

```sh
readelf -hW PROGRAM
readelf -SW PROGRAM
readelf -lW PROGRAM
readelf -dW PROGRAM
readelf -sW PROGRAM
readelf -rW PROGRAM
size PROGRAM
```

The binary's own bytes and the bytes supplied by shared libraries are separate quantities. Record both concepts rather than saying merely "the executable is N bytes" when one build is dynamically linked and another is freestanding/static.

## Fair comparison rules

1. Pin every source/compiler/toolchain revision.
2. Run an output/digest oracle before timing anything.
3. Separate compile time from run time.
4. Separate cold startup from steady-state repeated work.
5. Record native hardware separately from QEMU/emulator results; an emulator is useful for correctness and reproducibility but not evidence that one backend is intrinsically faster on the phone.
6. Compare equivalent semantics. Do not make a tiny runtime-free ARM image look magically faster/smaller by silently dropping behavior that the historical program performs.
7. Also retain the deliberately interesting "deployment footprint" comparison: if the old generated-C program requires a large shared runtime already present on the system while the native Thumb artifact does not, report both the artifact size and its external runtime dependency surface.

## Why keep this

Iridium is a particularly good historical marker because it is neither a toy `hello world` nor a giant modern application. It contains typed functional state/layout logic plus a deliberately explicit operating-system boundary. That is almost exactly the seam we now care about when asking how much machinery Idriç really needs between a typed program and native CPU/GPU execution.
