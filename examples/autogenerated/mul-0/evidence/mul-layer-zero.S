.syntax unified
.arch armv7-a
.fpu vfpv3-d16
.thumb
.text

@ Runtime-free Idriç numerical leaves for Android armeabi-v7a.
@ C ABI: softfp at the boundary, hardware Float32 internally.

@ Selected Idriç exports:
@ NativeLayer.difference_half -> difference_half
@ NativeLayer.sum_half -> sum_half

@ Validated Idriç leaf IR for difference_half:
@   function difference_half
@   arguments: [v0:Float32@0, v1:Float32@1, v2:Float32@2]
@     v3:Float32@3 = subtract v0:Float32@0 v1:Float32@1
@     v4:Float32@4 = multiply v3:Float32@3 v2:Float32@2
@   return v4:Float32@4
@   frame-bytes: 24

        .p2align 2
        .global difference_half
        .type difference_half, %function
        .thumb_func
difference_half:
        sub.w   sp, sp, #24
        str     r0, [sp, #0]
        str     r1, [sp, #4]
        str     r2, [sp, #8]
        vldr    s0, [sp, #0]
        vldr    s1, [sp, #4]
        vsub.f32 s0, s0, s1
        vstr    s0, [sp, #12]
        vldr    s0, [sp, #12]
        vldr    s1, [sp, #8]
        vmul.f32 s0, s0, s1
        vstr    s0, [sp, #16]
        movs    r0, #0
        add.w   sp, sp, #24
        bx      lr
        .size difference_half, .-difference_half

@ Validated Idriç leaf IR for sum_half:
@   function sum_half
@   arguments: [v0:Float32@0, v1:Float32@1, v2:Float32@2]
@     v3:Float32@3 = add v0:Float32@0 v1:Float32@1
@     v4:Float32@4 = multiply v3:Float32@3 v2:Float32@2
@   return v4:Float32@4
@   frame-bytes: 24

        .p2align 2
        .global sum_half
        .type sum_half, %function
        .thumb_func
sum_half:
        sub.w   sp, sp, #24
        str     r0, [sp, #0]
        str     r1, [sp, #4]
        str     r2, [sp, #8]
        vldr    s0, [sp, #0]
        vldr    s1, [sp, #4]
        vadd.f32 s0, s0, s1
        vstr    s0, [sp, #12]
        vldr    s0, [sp, #12]
        vldr    s1, [sp, #8]
        vmul.f32 s0, s0, s1
        vstr    s0, [sp, #16]
        movs    r0, #0
        add.w   sp, sp, #24
        bx      lr
        .size sum_half, .-sum_half

.section .note.GNU-stack,"",%progbits
