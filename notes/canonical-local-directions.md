# Canonical local directions are semantic objects

A recurring architecture problem is to turn a local request into a global function without letting an implementation heuristic define what functions are legal.

The clean pattern is

```text
admissible Hilbert space + norm + gauge
                    +
continuous local linear datum
                    |
                    v
        Riesz/reproducing representer
                    |
                    v
 unique minimum-norm admissible direction
```

## Mathematical boundary

Let `H` be a Hilbert space and let `L : H -> C` be a nonzero continuous linear functional. Use the convention that the inner product is linear in its first argument. Riesz representation supplies a unique `r_L` such that

```text
L(h) = <h, r_L>.
```

For prescribed datum `L(h) = d`, the unique minimum-norm solution is

```text
h_min = d r_L / ||r_L||^2.
```

Every other solution is `h_min + g` with `g` in `ker(L)`. Since `g` is orthogonal to `r_L`,

```text
||h_min + g||^2 = ||h_min||^2 + ||g||^2.
```

That orthogonal decomposition—not a screen-wide color score—makes the direction canonical. “Canonical” is always relative to the explicitly selected space, norm, functional, and gauge. Change any of those and the representer may change.

In a reproducing-kernel Hilbert space of holomorphic functions, point evaluation at `a` has representer `K(.,a)`. The unit-value direction is therefore `K(.,a) / K(a,a)`. Derivative evaluation and other continuous local data have their corresponding Riesz representers. A gauge such as removal of constants must be imposed on the space before its representer is computed; subtracting or restoring a mode afterward generally changes the extremal problem.

## Architecture boundary

The mathematical layer owns:

- the admissible space and proof that its elements have the required regularity;
- the norm and gauge;
- the local functional;
- the representer or a descriptor that denotes it.

Random policy may choose which local datum to request, its anchor, amplitude, sign or phase, timing, and overlap. A backend may choose evaluation order, precision under a stated error contract, parallel schedule, or descriptor encoding. Neither randomness nor backend mechanics decide admissibility.

For several simultaneous directions, finite linear combinations stay in a linear admissible space. Infinite combinations require the convergence condition appropriate to that space; “every term is legal” does not by itself make an arbitrary infinite sum legal.

## Concrete ownership

The live whole-plane application contract, including its entire-function requirement and candidate entire reproducing-kernel model, belongs to [`isomorphismes/holomorphic`](https://github.com/isomorphismes/holomorphic/blob/main/docs/holomorphic-mathematical-contract.md). The historical unit-disc Bergman example belongs to [`isomorphismes/lacunary`](https://github.com/isomorphismes/lacunary). Rendering preferences belong to [`isomorphismes/wegert`](https://github.com/isomorphismes/wegert).

This note preserves the architecture-independent pattern only. It is not a runtime implementation, a shared complex-number hierarchy, or a mandate for any particular kernel scale or visual motion.
