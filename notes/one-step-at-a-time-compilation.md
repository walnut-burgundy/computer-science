# One step at a time: a plain-language compiler vocabulary

## Why this note exists

Compiler terminology can make a simple operation sound more mysterious than it is. In particular, the term **ANF** has repeatedly obscured the useful idea underneath it.

For this project, use **one-step-at-a-time form** in ordinary discussion and documentation. If a technical cross-reference is needed, say once that this corresponds to what compiler literature often calls *A-normal form (ANF)*, then return to the plain-language name.

The important idea is not the historical name. It is this:

> Take a nested computation and straighten it into a sequence where each line does one small piece of work and the next line can refer to that result.

For example, instead of thinking about

```text
f (g (x + 1))
```

as one nested expression, a compiler can view it as

```text
a ≝ x + 1
b ≝ g a
f b
```

That is a change in **how the computation is written down for the compiler**. It is not yet a claim about machine instructions, registers, memory writes, stack slots, or runtime cost.

## The compilation ladder

Use this vocabulary when discussing the compiler family:

```text
source
  → one-step-at-a-time form
  → backend plan
  → target code
  → package
  → run
  → measure
```

### Source

The program as written and checked according to the language rules.

### One-step-at-a-time form

The compiler rewrites nested work into small explicit steps. Intermediate results can be named so later steps can refer to them.

This is a useful shared handoff because a backend no longer has to understand all of the surface language at once.

### Backend plan

A small target-facing description of what must happen, without yet choosing exact instructions. Examples might be:

```text
add integer
compare values
choose one of several paths
write one byte
exit process
```

### Target code

Actual x86, Thumb, RISC-V, AArch64, Wasm instructions, shader operations, or another real target vocabulary.

### Package

The surrounding form the target consumes: ELF, Wasm module, shader module, APK payload, and so on.

### Run

The real target accepts the package and produces the required result.

### Measure

Only after correctness is established do code size, dependency size, compile time, runtime, instruction count, or other measurements become useful comparisons.

## A one-step line is not necessarily a STORE

This distinction is important enough to keep explicit.

Suppose the compiler writes:

```text
a ≝ x + 1
b ≝ g a
f b
```

The names `a` and `b` do **not** imply that the machine must write two values into memory.

They mean roughly:

```text
give the result of x + 1 the temporary name a
give the result of g a the temporary name b
use b in f
```

A backend may later decide that `a` and `b` never need storage at all.

For example, if the calling convention already passes and returns the relevant value in one register, the eventual machine work might be approximately:

```text
add argument_register, 1
call g
jump f
```

The temporary names have disappeared. There was no memory write corresponding to either one-step name.

Other possibilities are equally legitimate:

- a value is folded into the next instruction and never exists separately;
- a value lives briefly in a machine register;
- two names reuse the same physical register because their lifetimes do not overlap;
- a constant is inserted directly into an instruction;
- dead work is deleted;
- only when registers are insufficient or memory semantics require it does a temporary need a stack or memory location.

Therefore a long list of one-step names does **not** by itself mean `store, store, store, store` at machine level.

## Reserve the heavy black arrow for a real put/store operation

This is also why the heavy black left arrow should not automatically be used for every temporary name in one-step-at-a-time form.

Use the heavy black arrow for the meaning:

```text
place ⬅ value
```

when the semantics really say **put this value in this place / update this place**.

That is different from merely giving an intermediate result a name.

For compiler-temporary notation, a definition/name mark such as `≝`, or plain prose such as “result a is ...”, avoids suggesting a memory write that may never exist.

This gives three different ideas three different meanings:

```text
x = y        equality: x and y have the same value
x ≝ expr     name/define: use x as the name for this result
place ⬅ x    store/put: change a place so it contains x
```

The exact surface spelling can still evolve, but the semantic distinction should remain.

## When can one-step-at-a-time form actually hurt performance?

The form itself is not inherently slow. It is a compiler representation.

It becomes inefficient only if later compiler stages make poor choices. For example, a naive backend could allocate a memory slot for every temporary and emit repeated stores and loads. That would be a backend failure, not a necessary consequence of breaking the computation into explicit steps.

There is, however, a more subtle design risk: **breaking things down too early can discard useful larger structure**.

A compiler may want to retain facts such as:

- this is a polynomial expression that can be reorganized;
- this loop has a regular vector shape;
- this finite choice can become a jump table;
- this scan means “find the next one of these bytes” rather than merely a pile of individual branches;
- this matrix or complex-number operation has a stronger mathematical meaning than a collection of scalar arithmetic instructions.

If the compiler turns everything into tiny generic steps before exploiting those facts, a later backend may have to rediscover structure that was obvious earlier.

So the design question is not simply “one-step form or no one-step form.” The useful questions are:

1. Which mathematical and control-flow structure should be preserved before one-step lowering?
2. Which operations deserve a strong explicit form of their own?
3. At what point is it useful to straighten the remaining computation into one small step at a time?
4. Which target-specific decisions should remain entirely in the backend?

## What changing each stage affects

| Change | Likely consequence |
| --- | --- |
| Change the source language | Parser, checker, meaning of programs, and possibly every later stage can change. |
| Change one-step-at-a-time form | Potentially every backend changes because this is a shared compiler handoff. |
| Change the backend plan | Every target using that plan may need adjustment, but the source language need not change. |
| Change target code selection | Usually only that architecture/backend changes: registers, branches, SIMD, instruction choices. |
| Change packaging | Entry point, ABI, object/executable format, linker/runtime assumptions, imports, sections, relocations, or driver boundary may change. |
| Change runtime surface | libc, VM, JS engine, driver, OS syscall, or other dependency surface changes. |
| Change measurement method | Performance comparisons may cease to be comparable even though generated programs are identical. |

This is why compiler decisions should be located at the narrowest stage that actually needs them.

## A useful analogy: polynomial normal form

A mathematical normal form is a good way to think about this.

Rewriting a polynomial into a standard arrangement does not say which CPU register contains each coefficient. It makes the mathematical object easier to inspect and manipulate.

One-step-at-a-time form plays a similar role. It makes evaluation order, intermediate results, calls, choices, and effects explicit enough for later compiler work. It is still a description of the computation, not the final physical machine arrangement.

## Vocabulary policy

For user-facing notes across Idriç, Odriç, and the native backends:

- prefer **one-step-at-a-time form** over **ANF**;
- if literature compatibility matters, mention `A-normal form (ANF)` parenthetically once;
- do not call every temporary naming operation an **assignment**;
- use **name this result**, **temporary result**, or **definition** when no location is being changed;
- use **store** or **put** when the meaning is actually to update a place;
- reserve the heavy black arrow for that real store/put meaning rather than letting it imply that every compiler temporary becomes a memory write.

The point is not to hide technical distinctions. It is to give each distinction an ordinary name that says what is actually happening.