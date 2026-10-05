# Representation mismatch can dominate performance

A useful performance question is not only “is this algorithm fast?” but “does the program’s representation match the hardware and workload?”

For example, a logical `Array<T>` might be represented either as:

- a flat, contiguous, unboxed region of `T` values; or
- an array of references to separately allocated boxed `T` objects.

Those representations can have radically different costs even when the source-level operations look identical. The boxed/reference-heavy representation can add pointer chasing, extra loads, allocation and GC pressure, worse cache locality, more memory traffic, and fewer opportunities for SIMD/vectorization. For small numeric or pixel-like values, those costs may dominate the arithmetic itself.

So architecture/planner work should keep *logical data structure* separate from *physical representation*. Candidate implementations should make storage choices explicit—e.g. packed/unboxed/contiguous versus boxed/reference-based—and compare them using target facts and measurements rather than assuming one abstract `Array<T>` has one cost model.

This is a good example of a general ComputerScience question: identify when a slowdown is really a representation mismatch rather than an algorithmic one.
