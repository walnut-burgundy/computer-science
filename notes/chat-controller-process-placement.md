# Chat-controller process placement: analytical note

Source application: https://github.com/isomorphisms/fastchat/issues/2

This note treats process placement as a second-stage architectural decision. The semantic decomposition comes first.

## Fixed semantic decomposition

Assume explicit interfaces for:

- conversation history;
- view state;
- request/stream state;
- durable append/read storage;
- transport/session authority;
- renderer input/output.

The same decomposition may be implemented in one address space or several.

## First-order memory model

Let:

- `N` = simultaneously open views;
- `B_i` = retained serialized conversation bytes for view/conversation `i`;
- `I_i` = indexes/parser metadata;
- `V_i` = visible-window/render cache;
- `P` = incremental private/PSS cost per additional process;
- `S` = state shareable in one address space;
- `K` = live physical network connections;
- `Q` = per-connection user/kernel buffering plus TLS/application state;
- `X` = IPC state/copy buffering per active stream.

Then a deliberately crude bookkeeping model is:

```text
one process:
R_1 ≈ P + S + sum_i(B_i + I_i + V_i) + KQ

N views + shared broker:
R_b ≈ (N + 1)P
      + S_broker
      + sum_i(B_i + I_i + V_i)
      + KQ
      + active_streams * X

independent per-view processes:
R_n ≈ NP
      + sum_i(B_i + I_i + V_i + K_i Q + duplicated_shared_state_i)
```

These equations are not Android measurements. They make hidden duplication terms visible.

## Process-cost sensitivity

Before device data exists, vary `P` rather than pretending it is known.

| extra view processes | P=4 MiB | P=8 MiB | P=16 MiB | P=32 MiB |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 4 MiB | 8 MiB | 16 MiB | 32 MiB |
| 3 | 12 MiB | 24 MiB | 48 MiB | 96 MiB |
| 7 | 28 MiB | 56 MiB | 112 MiB | 224 MiB |

The value of this table is not the guessed numbers. It shows the crossover question: how much isolation/restart value must a process buy to justify repeated runtime state on a small phone?

## Token/index sensitivity

Do not automatically retain whole-thread tokenization.

For `T` tokens:

- 32-bit token IDs: `4T` bytes;
- two 32-bit byte offsets/token: `8T` bytes;
- both: `12T` bytes before allocator/object overhead.

At `T = 250000`:

- IDs ≈ 0.95 MiB;
- offsets ≈ 1.91 MiB;
- both ≈ 2.86 MiB.

A renderer that only needs UTF-8 plus local block/line indexes should not inherit token arrays merely because the model protocol uses tokens elsewhere.

## Connection intuition

The important abstraction is a transport authority, not a pool object visible to the application.

Natural reuse is keyed by account/authority, origin, protocol/network context, and policy. HTTP/2 or HTTP/3 may multiplex many logical request streams over fewer physical connections.

Therefore:

```text
conversation != request != stream != physical connection != process
```

Any architecture that equates these accidentally should be treated as suspect before benchmarking.

## Measurement role

Measurements should answer placement questions such as:

- how expensive is another Android process on A1/C67?
- how much state is genuinely shared?
- how much duplicated parser/render/index state appears when views split?
- does one broker materially reduce sockets/TLS state/wakeups?
- does process isolation improve restart behavior enough to matter?
- does the Material 3 renderer change the crossover relative to the native-surface renderer?

Measurements should not decide semantic ownership, event ordering, cancellation scope, or credential authority.

## Corpus data to copy here

When available from FastChat experiments, copy aggregate distributions and receipts rather than private text:

- serialized thread bytes;
- messages/thread;
- UTF-8 bytes/message;
- code/Markdown block sizes;
- token counts under named tokenizers;
- streaming chunk sizes and inter-arrival times;
- attachment counts/sizes;
- visible-window bytes versus whole-thread bytes;
- PSS/RSS/CPU/wakeup/jank/socket measurements by process layout.

Every copied measurement should retain source revision, artifact digest, device profile, and corpus-fixture identity.

## Architectural lesson for ComputerScience

The planner should represent **semantic decomposition** and **placement** separately.

A component graph can stay fixed while a later planner chooses:

- same process;
- same thread;
- separate worker thread;
- separate process;
- remote service;

subject to measured target costs and failure/security requirements.

That distinction is the reusable result, even if FastChat eventually uses only one of those placements.
