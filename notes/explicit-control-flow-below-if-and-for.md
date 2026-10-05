# Explicit control flow below `if` and `for`

Structured constructs such as `if`, `switch`, `while`, and `for` are programmer-facing ways to describe control flow. They are not the only possible shapes of control flow, and they are not generally the primitive mechanism executed by a CPU.

At the machine level, execution normally advances to the next instruction unless some control-flow operation selects a different next instruction address. A direct branch names a target encoded relative to or with the instruction. An indirect branch obtains a target from a register or memory-derived value. Calls and returns are related control-flow operations with conventions for preserving a return address.

On AArch32, `r15` is the architectural program counter, so some older ARM descriptions make this relationship unusually visible. That should not be generalized into a universal API rule: A64 does not expose its program counter as an ordinary writable general-purpose register, and other ISAs expose control flow differently. The portable low-level concept is therefore **explicit control-flow targets and edges**, not "arbitrary writes to the PC".

## `if` and `for` are useful normal forms, not the whole space

A compiler can turn a structured program into a control-flow graph whose nodes are blocks of instructions and whose edges say which block may execute next. Many graphs can be written as ordinary `if`/`else`, `switch`, and loops, but the machine does not need those source-language constructs to exist as such.

For example, these are all reasonable lower-level control patterns:

- a conditional branch to either of two blocks;
- a jump table selecting one of many targets from an integer index;
- an indirect jump whose target is a value computed earlier;
- a tail jump that transfers directly to another routine without creating another return frame;
- a state machine whose stored state determines the next continuation;
- coroutine or generator resumption at a saved continuation point;
- an unrolled loop entered at different interior positions, as in the historical family of techniques exemplified by Duff's device;
- interpreter dispatch where each bytecode operation transfers directly to the handler for the next bytecode rather than returning through one central `switch`.

These are not necessarily better than structured source code. They are reminders that `if` and `for` are convenient descriptions imposed above a more general control-flow graph.

## Would a language expose this?

Probably not as a default high-level programming feature. Arbitrary control flow makes reasoning, optimization, stack discipline, exception handling, debugging, and resource cleanup harder.

A low-level compiler IR or systems-language escape hatch can nevertheless expose a controlled version of it. Useful primitives would be things such as:

```text
label
jump label
jump_if condition label
jump_indirect target
call target
return
select continuation from a finite table
```

A more typed design could expose continuation values only when their signatures and lifetime are known, instead of exposing an untyped integer that happens to contain an instruction address.

## Where it can actually make something faster

The strongest cases are usually very hot control-flow machinery rather than ordinary numerical inner loops.

### Interpreter and virtual-machine dispatch

A bytecode interpreter traditionally does roughly:

```text
read opcode
switch opcode
execute handler
return to dispatcher
repeat
```

A direct- or indirect-threaded interpreter can instead arrange for one handler to branch directly to the next handler. On some compiler/CPU combinations this reduces dispatcher work and can improve branch prediction. On others it does not; this is an empirical optimization, not a universal law.

### Jump tables

A dense `switch` can become an indexed load of a target followed by an indirect branch. This avoids a long chain of comparisons when many cases are possible.

### Tail calls and continuation-style code

If one computation is finished and its result is simply the input to the next computation, a tail jump can avoid building another call/return layer. Functional-language runtimes and compiler transformations make heavy use of this idea.

### State machines and coroutines

A parser, protocol machine, generator, or coroutine may naturally mean "resume at one of these known continuation points." Representing that state directly can be smaller or cheaper than reconstructing the same behavior through nested source-level conditionals.

### Unrolled hot loops

Loop unrolling reduces the frequency of loop-control branches. In unusual cases it is also useful to enter an unrolled body at different internal positions. Historically programmers wrote these patterns by hand; modern optimizing compilers often synthesize equivalent control flow themselves.

## Important performance warning

Raw access to control flow is not automatically faster. Modern CPUs predict branches, execute speculatively, and impose costs on badly predicted indirect branches. Modern compilers also perform loop unrolling, jump-table formation, tail-call elimination, if-conversion, block reordering, and other transformations without source code exposing the program counter.

So the useful principle for ComputerScience is:

> Keep the lower control-flow space visible as an available implementation primitive, but do not force programmers to use it or assume it beats ordinary structured control flow.

If a measured hot path later shows that a nonstandard control-flow graph is substantially better, the architecture search should be allowed to select it and record why. Otherwise `if`, `switch`, and loops remain the clearer interface.
