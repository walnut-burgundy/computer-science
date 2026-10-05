# ARMv7 `Lower` as a small analogue of architectural compilation

The [`idris-arm-backend` ARMv7 `Lower` pass](https://github.com/isomorphisms/idris-arm-backend/blob/main/src/Backend/ARMv7/Lower.idr) is worth keeping as implementation evidence for ComputerScience. It is much narrower than the proposed architectural planner, but its shape is surprisingly close to one part of the intended process.

Instead of deciding a representation as soon as each ANF expression is encountered, `Lower` first builds an intentionally unresolved description:

- every ANF local receives a dense four-byte stack home;
- operations are collected as `RawInstruction`s;
- representation facts are accumulated separately as `HasRepresentation` and `SameRepresentation` constraints;
- copies propagate equality of representation rather than forcing a representation immediately;
- the constraint graph is walked later to infer a unique representation for each local;
- missing or conflicting representation evidence is rejected;
- only after that resolution are representation-tagged `Local`s and typed leaf `Instruction`s constructed;
- unsupported calls, heap values, control flow, ambiguous representations, and malformed def-use chains are rejected before assembly emission.

The useful pattern is therefore roughly:

```text
collect unresolved structure
  -> accumulate constraints
  -> solve / reject ambiguity
  -> materialize a typed explicit plan
  -> perform mechanical target emission
```

That is a small, target-local version of an important ComputerScience idea: preserve meaningful uncertainty while enough facts are gathered, make the decision boundary explicit, and only then lower into a representation-specific plan that ordinary code generation can follow.

The analogy should not be overstated. `Lower` is not an architectural search engine. Its candidate operations and representation vocabulary are fixed in advance; it does not compare algorithms, consult measurements, optimize over a Pareto frontier, record rejected implementation alternatives, or process programmer preferences/adverbs. Its dense stack homes are also a deliberately simple backend choice rather than a globally searched storage plan.

Still, this is probably a better executable miniature of the intended *shape* than many generic compiler examples. ComputerScience can plausibly use the same separation at a larger scale:

```text
semantic goal
  -> unresolved candidate architecture + constraints/evidence
  -> resolve choices or surface conflicts/questions
  -> shared typed selected plan
  -> target-specific lowerer such as ARMv7 `Lower`
  -> assembly / object code
```

In that view, the ARMv7 backend is not ComputerScience itself. It is evidence that the "collect facts first, commit later, then make the remainder mechanical" boundary is practical even inside a very small compiler backend, and it may serve as a useful reference when the first executable ComputerScience constraint/planning slice is designed.
