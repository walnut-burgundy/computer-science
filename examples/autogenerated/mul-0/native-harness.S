.syntax unified
.arch armv7-a
.fpu vfpv3-d16
.thumb
.text
.global _start
.thumb_func
_start:
  @ Enable access expected by existing Linux-user VFP harness, softfp arguments.
  movw r0, #0
  movt r0, #0x3fc0
  movw r1, #0
  movt r1, #0xbf00
  movw r2, #0
  movt r2, #0x3f00
  bl sum_half
  movw r3, #0
  movt r3, #0x3f00
  cmp r0, r3
  bne failure
  movw r0, #0
  movt r0, #0x3fc0
  movw r1, #0
  movt r1, #0xbf00
  movw r2, #0
  movt r2, #0x3f00
  bl difference_half
  movw r3, #0
  movt r3, #0x3f80
  cmp r0, r3
  bne failure
  @ Negative exact output: (-1.5 + -0.5)/2 = -1.
  movw r0, #0
  movt r0, #0xbfc0
  movw r1, #0
  movt r1, #0xbf00
  movw r2, #0
  movt r2, #0x3f00
  bl sum_half
  movw r3, #0
  movt r3, #0xbf80
  cmp r0, r3
  bne failure
  movs r0, #0
  b finish
failure:
  movs r0, #43
finish:
  movs r7, #1
  svc #0
.section .note.GNU-stack,"",%progbits
