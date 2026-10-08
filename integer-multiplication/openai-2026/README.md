# Integer multiplication below n log n (OpenAI, 2026)

**Status:** primary-source intake / research reference. No proof has been independently verified here; no claimed implementation or performance improvement.

## Original paper and provenance

- **Author:** OpenAI.
- **Dated:** September 23, 2026; published in the OpenAI mathematics release on October 6, 2026.
- **Title:** *Integer multiplication below n log n*.
- **Original, pinned PDF:** https://github.com/openai/math/blob/adc7f1241b42e322a6451854ab7e4b4c146bf78a/preprints/Integer-multiplication-below-n-log-n-September-23-2026/paper.pdf
- **Upstream source, figures, and bibliography:** https://github.com/openai/math/tree/adc7f1241b42e322a6451854ab7e4b4c146bf78a/preprints/Integer-multiplication-below-n-log-n-September-23-2026
- **Upstream commit:** `adc7f1241b42e322a6451854ab7e4b4c146bf78a`.
- **Original PDF Git blob:** `dd2a4664f65aa22510ac1c568834573d3ebcc593` (binary identity check).
- **Local archived copy:** [paper.pdf](paper.pdf).
- **License:** Apache License 2.0, copied from the original repository in [LICENSE](LICENSE). The paper remains credited to OpenAI. The local note is not part of the original manuscript.

Citation: OpenAI, *Integer multiplication below n log n*, OpenAI Math Release preprint (2026), `OAI:Integer-multiplication-below-n-log-n-September-23-2026`.

## What the paper claims

For all input lengths, exact multiplication of two `n`-bit unsigned integers in deterministic worst-case
`O(n (lg n)^(1 - κ))` time with `κ = 2^(-182)`, on **one fixed finite-alphabet multitape Turing machine**, with a fixed number of one-dimensional tapes. The output is the exact `2n`-bit product.

That complexity model is part of the claim. It must not be silently translated into a claim about word-RAM instructions, C libraries, hardware multipliers, SIMD, GPU execution, or Android latency. The paper itself says its constants and thresholds are extremely large; this is an asymptotic bit-complexity result, **not** a practical multiplication benchmark.

The main technical themes in the source introduction are:

- transform-based multiplication through radix-digit convolution, Gaussian resampling, power-of-two multidimensional transforms, and synthetic polynomial transforms;
- sublinear-exponent cost (in selected address field widths) for exact address-field interchanges, using linear-network/XOR intermediates;
- lower-cost simultaneous butterfly layers `((u+v)/2, (u-v)/2)` through framed linear networks, with controlled Gaussian-dyadic fixed-point arithmetic and truncation;
- recursive savings from the networks' smaller-call accounting; and
- exact recovery of coefficients with rounding and carry propagation. A known `O(n log n)` multiplier appears as a subroutine, not as the algorithm's claimed final bound.

These are descriptions of the manuscript, **not independent validation of its lemmas**. See the original source for the precise hypotheses and cost accounting.

## From paper to code: staged work, not automatic compilation

The same mathematical operation can have several implementations. ComputerScience should first register the *semantic contract*:

```text
multiply_exact(x : n-bit unsigned integer, y : n-bit unsigned integer)
    -> exact 2n-bit unsigned product
```

Then keep separate candidate realizations and evidence levels:

1. **Mathematical audit:** identify the lemmas for address shear/interchange, linear networks, simultaneous butterfly layers, precision bounds, layout changes, and final exactness. Record unresolved assumptions rather than importing a theorem as a performance fact.
2. **Small executable models:** implement tiny exact versions of the address permutations, XOR-based auxiliary-state restoration, `H₀` butterfly, Gaussian-dyadic precision behavior, and digit/carry recovery. Compare with independent direct oracles exhaustively at small sizes. Model the **actual operations**: a regular in-memory transpose does not test a fixed-tape complexity claim.
3. **Assembly of the reduction:** represent intermediate shapes, coefficient widths, layouts and parameter inequalities explicitly; implement the published transformation chain only as far as the checked lemmas support. Keep fixed-point arithmetic exact until the paper authorizes truncation, and verify the claimed < 1/2 coefficient error before rounding.
4. **Complexity evidence:** define and instrument the claimed fixed-tape computation model, count tape steps and bit volume by stage, and independently verify the recurrences and hidden dependence on parameters. Do not infer the asymptotic theorem from a few machine timings.
5. **Practical candidate evaluation (separate):** only after the reduction is executable and correct, measure native word-oriented implementations against a clear existing baseline on named targets and sizes. Record revisions, compiler, ABI, memory/energy/crossover, and failed experiments; the asymptotically faster algorithm may never win at feasible sizes.

**Build policy for maintained executable experiments:** use qualified ICK, or the Android NDK with an explicitly recorded ICK capability gap. Experiments, proofs, host simulations, and physical-device performance evidence are distinct. A simpler verification model can establish correctness of a component without establishing the paper's time bound.

## Placement in the architectural planner

This belongs in the algorithm/source evidence catalogue of [ComputerScience](../../README.md). The semantic operation stays separate from its multiplication candidates. A paper gives mathematical and algorithmic obligations; pseudocode alone does not specify layout, storage, fixed-point representation, compiler lowering, target or measured cost.

Do not select this candidate merely because its big-O exponent is smaller. Its validity, applicable cost model, parameter thresholds, and real target performance must all remain visible. Related general principles: [architectural compilation](../../notes/architectural-compilation.md).
