# Numeric types are maps, not just bit layouts

This note records a recurring architectural-planning mistake exposed by the
Cortex-A55 / FP16 / FP8 investigation.

## The mistake

It is tempting to say "implement binary16", "implement E4M3", or "implement
E5M2" as though choosing a carrier and bit layout nearly determines the rest.

It does not.

A useful numeric type is largely a family of maps:

```text
bits -> value
value -> bits

A × A -> A          addition
A × A -> A          multiplication
A -> A              negation
A × A -> order      comparison

A -> B              widening / embedding
B -> A              rounding / projection
A^n -> C            accumulation
source operation -> ISA sequence -> microarchitectural execution
```

The carrier matters, but it does not determine these maps automatically. At the
machine level there can be several circuits or instruction sequences that
realize related semantics with different latency, throughput, area, power,
rounding, subnormal, and accumulation tradeoffs.

The programmer should not be asked to guess those implementation choices unless
they are themselves semantically important.

## High-to-low control should be jagged

The goal is not to expose every layer all the time.

Most programs should be able to request a semantic operation and let the
planner/compiler select an implementation from target evidence. But when an
implementation choice changes the meaning of the program, the programmer must
be able to descend through the stack and constrain it.

Examples:

- a request to fetch data should not normally require reasoning about TLS record
  framing or socket negotiation;
- a low-precision statistical value may require explicit control of widening,
  rounding, accumulation, and storage width because those choices affect what
  distinctions the program can represent;
- a backend investigation may need to descend from a source operation through
  Arm T32/AArch32 instructions to Cortex-A55 execution resources.

So the useful model is not uniformly high-level or uniformly low-level. It is a
jagged path through the stack determined by semantic relevance.

## Planner responsibility

For a request such as "implement this numeric operation on Cortex-A55", the
ComputerScience layer should try to answer:

1. What semantic maps are required?
2. What target instructions or instruction sequences can realize each map?
3. What circuit/resource facts are publicly known for those instructions?
4. What alternatives exist?
5. What are the measurable tradeoffs in latency, throughput, code size, memory,
   energy proxies, and semantic complexity?
6. Which differences are observable in the language semantics and which are
   implementation-only?
7. Can the system choose automatically, or is there a genuine semantic policy
   that requires a human decision?

The default should be to compute or measure these choices where possible rather
than asking the programmer to invent a low-level mechanism.

"Why are you asking me? Can't you figure out the tradeoffs?" is a useful design
test for this repository.

## Low precision is not one uncertainty mechanism

The spirit-level example makes the distinction concrete.

Suppose the physical setup supports, at best, roughly quarter- or eighth-scale
resolution. Storing the result in a very fine float can create machine-visible
distinctions that the observation never supported. A coarse numeric type can
make that limitation difficult to forget.

But many other facts about an observation are not numerical precision at all:

- the setup may have moved;
- the reading may have been taken at a different position;
- the observer may have miscoded a category;
- a value may be missing, censored, not applicable, not asked, or suspect;
- a clinical record can contain a plainly wrong classification whose downstream
  consequence is large.

A wrong category is not "the right number plus epsilon". It is a different data
state.

Therefore keep at least these axes separate:

```text
numeric resolution / represented significant bits
arithmetic rounding
measurement procedure and provenance
data-quality / coding status
missingness or applicability status
model uncertainty
```

A language may represent some of these with sum types, tagged values, records,
or explicit status channels. Do not force all of them into NaN or a generic
error bar.

## Relation to R-like missingness

R is useful precedent because it makes several exceptional states ordinary in
data analysis: `NA`, typed NA constants, `NaN`, `Inf`, `-Inf`, and `NULL`
all exist as distinct mechanisms. But semantic reasons such as "not applicable",
"not asked", "miscoded", or "review required" still need explicit data modeling.

The architectural lesson is not to copy R's exact set. It is to permit
non-numeric state to travel with data rather than pretending every cell is just
a precise scalar.

## Category-theoretic angle

There may be useful language in treating formats as objects and conversions or
operations as maps, especially when checking whether diagrams commute.

For example, with an exact embedding `i : E5M2 -> F16` and a rounding map
`q : F16 -> E5M2`, the law

```text
q ∘ i = id
```

is an executable property to check over the finite E5M2 carrier.

Arithmetic gives a more interesting diagram:

```text
E5M2 × E5M2 --add8--> E5M2
     |                 ^
     v                 |
F16 × F16 ----add16---> F16
```

Whether widening, adding, and rounding agrees with strict E5M2 addition is a
specific question, not something implied by the existence of the formats.

Category theory is useful only if it helps state or test such relationships more
clearly. Ordinary algebra/type theory is preferable when it says the same thing
more directly.

## Current motivating case

The active motivating case is the comparison among:

- Armv7-A Thumb/VFP behavior;
- Armv8.2-A binary16 instructions;
- Cortex-A55 FP/Advanced-SIMD execution resources;
- prospective E4M3 and E5M2 language primitives.

That case should be used as a worked example for architectural search: enumerate
candidate lowerings, preserve semantic differences, measure tradeoffs, and avoid
asking the programmer to choose circuit-level details that the system can derive
or benchmark itself.
