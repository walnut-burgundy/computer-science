# Algorithms

Algorithm records describe semantic operations and concrete variants without assuming one machine representation.

A record should preserve:

- the operation's meaning, preconditions, invariants, and acceptable approximation or error;
- provenance and the distinction between a mathematical idea, paper pseudocode, and an actual implementation;
- shape relations, computable dimension expressions, raggedness, algebraic identities, and padding identities that may enable later transformations; dimensions are not restricted to literals known before execution;
- alternative representations and variants without flattening them into one package name;
- reference cases or tests that allow a selected implementation to be checked.

Performance claims belong with an explicit target and workload. They should not be copied into a target-independent algorithm record as universal facts.

## Executable example

- [Reflow](reflow.md): two Idriç implementations behind one `reflow` verb, selected by adverb, with explicitly recorded tradeoffs and unmeasured target choices.
