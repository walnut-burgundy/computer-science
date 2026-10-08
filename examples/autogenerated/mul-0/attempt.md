# STAR MUL-0 bounded experiments

Purpose: distinguish executable identities in the pinned OpenAI manuscript from
its full fixed-machine construction, and observe the actual native compiler boundary.

Additional corpus type sketch: a row carries two nonnegative Integer values, two
explicit bit widths and their exact Integer product. `Corpus.idr` imports no candidate
code; the existing runtime supplies the independent oracle. This is reference generation,
not an implementation of the paper. Known zero/one/power/all-one identities check it.

Type sketch, before implementation: `Dyad = Integer × Nat` denotes numerator times
2 to the negative exponent; `GaussianDyad = Dyad × Dyad`; a scalar invocation
maps `(source, target, side, central)` to `(source, target + source, side, central)`.
An address shift maps `(control bit, integer address, integer auxiliary address)`
to `(control bit, address with its low bit toggled conditionally, auxiliary address)`.
Inputs and auxiliary values may be negative and nonzero. No fixed-width overflow
is allowed in these mathematical models. The native probe separately uses existing
Float32 primitives on exactly representable values and probes Int32 rejection.

Language choice: Idriç first, pinned to the native backend's compiler commit
081b9cde0591154839fb5d80d76e5570e0436300, Chez bootstrap. This host model is an
independent mathematical reference, not ICK or native ARM arithmetic evidence.
No new mathematical IR or user syntax is proposed. Build/tool failures and subsequent
repairs are recorded in evidence; do not erase unsuccessful substantive attempts.

The reduced h=6 invocation checks cancellation, including both Gaussian side-neighbor
classes. It does not instantiate h=100's labels, entire tensor network, or rank saving.
The exact phase identity checks algebra before rounding. The real signed-polynomial
slice checks centered extraction and negacyclic wrap, not the full Gaussian multiplier.

Bootstrap attempt 1 failed because the host lacked gmp.h while building RefC support
as part of the ordinary Chez bootstrap. This was not a switch to the RefC backend.
GMP headers/static library were extracted locally from Ubuntu's package; bootstrap
was retried with CPATH and LIBRARY_PATH. System apt installation of qemu-user also
failed at setgroups; the same official package was extracted locally instead.

Outcome: Idriç succeeded without a language fallback. The first model source attempt
used `mod` on Nat, which this pin rejects (`Integral Nat` unavailable); exact attempted
expressions and compiler output are preserved in commands.md/evidence. The corrected
finite predicates compile. Rebuilt and reran with completed exact pinned compiler.
The native Float32 probe generated, assembled and executed under QEMU. Word-result and
word-add-index probes correctly failed at different backend boundaries. No production
compiler source was changed. See final-results.json for independent statuses.
