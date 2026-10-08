# Books: number theory, curves, and multiplication experiments

This is a **reading and provenance shelf**, not a mirror of copyrighted PDFs. The purpose is to find mathematically meaningful **families of integer operands** for [integer-multiplication research](../integer-multiplication/openai-2026/README.md) and the [ICK multiplier benchmark](https://github.com/dilapidated-shed/ick/tree/main/benchmarks/bigmul). Do not represent candidate examples as already extracted, verified, or benchmarked.

## Beginning with numbers and elliptic curves

1. **Joseph H. Silverman, _A Friendly Introduction to Number Theory_, 4th ed. (Pearson).**
   [Publisher record](https://www.pearson.com/en-us/subject-catalog/p/friendly-introduction-to-number-theory-a-classic-version-/P200000006347).
   Elementary divisibility, congruences, prime arithmetic, and Diophantine problems. Start with controlled repunit, Mersenne-like, modular-reduction, and recurrence families.

2. **Avner Ash and Robert Gross, _Elliptic Tales: Curves, Counting, and Number Theory_ (Princeton University Press, 2012).**
   [Publisher-linked book record](https://doi.org/10.1515/9781400841714).
   Introduces elliptic curves, point counting, and the Birch–Swinnerton-Dyer conjecture without requiring advanced algebraic geometry. **Tales**, not "tails."

3. **William Fulton, _Algebraic Curves: An Introduction to Algebraic Geometry_ (author's revised electronic edition, 2008).**
   [Author-hosted text](https://www.math.lsa.umich.edu/~wfulton/CurveBook.pdf).
   Functions of curves and polynomial geometry suggest coefficient arrays, eliminants, resultants, discriminants, and multiplication in quotient rings. Canonical source record: [Fulton repository](https://github.com/walnut-burgundy/fulton/tree/main/sources/fulton-algebraic-curves).

4. **Joseph H. Silverman, _The Arithmetic of Elliptic Curves_, 2nd ed. (Springer, 2009).**
   [Publisher/DOI](https://doi.org/10.1007/978-0-387-09494-6).
   Computational examples should distinguish full integer multiplication from multiplication modulo a curve's field prime.

5. **Marc Hindry and Joseph H. Silverman, _Diophantine Geometry: An Introduction_ (Springer, 2000).**
   [Publisher/DOI](https://doi.org/10.1007/978-1-4612-1210-2).
   Heights, rational points, and controlled growth of numerator/denominator sizes suggest nonuniform, mathematically motivated operand distributions.

6. **Gary Cornell and Joseph H. Silverman (eds.), _Arithmetic Geometry_ (Springer, 1986).**
   [Publisher/DOI](https://doi.org/10.1007/978-1-4613-8655-1).
   Reference collection for arithmetic geometry rather than an introductory calculation manual.

## Arithmetic topology and Seifert

7. **Masanori Morishita, _Knots and Primes: An Introduction to Arithmetic Topology_, 2nd ed. (Springer, 2024).**
   [Publisher/DOI](https://doi.org/10.1007/978-981-99-9255-3).
   Prime ideals ↔ knots, linking arithmetic, Alexander/Iwasawa parallels. The established [Seifert books shelf](https://github.com/isomorphismes/seifert/tree/main/books) remains canonical for knot/topology reading, with [source papers](https://github.com/isomorphismes/seifert/tree/main/papers).
   These analogies suggest distinct algebraic data sources; they **do not** automatically give large machine integers.

## From books to benchmark cases — future study

- **Representation:** document exactly how an object becomes one or two finite integers: e.g., integer coefficients of a polynomial, an integer resultant, or residues modulo a named prime.
- **Operand features:** bit lengths, imbalance, Hamming weight, nonzero-limb density, carry propagation, coefficient size distributions, algebraic source, and whether squaring occurs.
- **Shape of the algorithm:** schoolbook partial products, Karatsuba recursion, Toom–Cook evaluations, transform/butterfly networks, address permutations, coefficient recovery, temporary precision and layout changes. A butterfly schedule can have a different cycle and locality structure even when two algorithms compute the same product.
- **Measurements:** native wall/CPU time, dispersion, allocations, bytes moved, cache behavior if available; separately record operation counts and trace statistics for qualitative comparisons.
- **No conflation:** distinguish integers from finite-field elements, polynomial multiplication from integer multiplication, and algebraic complexity from practical time. A source citation supplies a mathematical idea, not benchmark validation.

The first benchmark corpus should include **synthetic controls** (random, sparse, dense carry, squares, operand-size asymmetry, and word-boundary ±1). Later, add small *derived, documented* families, with source pages, parameter sets, generator code, and independently checked expected products. Avoid unexplained one-off large constants.

**Cross-references:** [ICK](https://github.com/dilapidated-shed/ick) · [Fulton](https://github.com/walnut-burgundy/fulton) · [Seifert](https://github.com/isomorphismes/seifert/tree/main/books) · [paper intake](../integer-multiplication/openai-2026/README.md).
