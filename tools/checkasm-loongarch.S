/****************************************************************************
 * checkasm-loongarch.S: assembly check tool
 *****************************************************************************
 * Copyright (C) 2024-2025 x264 project
 *
 * Authors: Xiwei Gu <guxiwei-hf@loongson.cn>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at licensing@x264.com.
 *****************************************************************************/

#include "../common/loongarch/loongson_asm.S"

const register_init, align=3
.quad 0x21f86d66c8ca00ce
.quad 0x75b6ba21077c48ad
.quad 0xed56bb2dcb3c7736
.quad 0x8bda43d3fd1a7e06
.quad 0xb64a9c9e5d318408
.quad 0xdf9a54b303f1d3a3
.quad 0x4a75479abd64e097
.quad 0x249214109d5d1c88
.quad 0x1a1b2550a612b48c
.quad 0x79445c159ce79064
.quad 0x2eed899d5a28ddcd
.quad 0x86b2536fcd8cf636
.quad 0xb0856806085e7943
.quad 0x3f2bf84fc0fcca4e
.quad 0xacbd382dcf5b8de2
.quad 0xd229e1f5b281303f
.quad 0x71aeaff20b095fd9
endconst

const error_message
.asciz "failed to preserve register"
endconst

.text

// max number of args used by any x264 asm function.
#define MAX_ARGS 15

#define CLOBBER_STACK ((8*MAX_ARGS + 15) & ~15)

// Fill dirty data at stack space
function x264_checkasm_stack_clobber
    move     t0,  sp
    addi.d   t1,  zero, CLOBBER_STACK
1:
    st.d     a0,  sp,  0x00
    st.d     a1,  sp, -0x08
    addi.d   sp,  sp, -0x10
    addi.d   t1,  t1, -0x10
    blt      zero,t1,  1b
    move     sp,  t0
endfunc

#define ARG_STACK ((8*(MAX_ARGS - 8) + 15) & ~15)

function x264_checkasm_call
    // Saved s0 - s8, fs0 - fs7
    move     t4,  sp
    addi.d   sp,  sp, -136
    st.d     s0,  sp, 0
    st.d     s1,  sp, 8
    st.d     s2,  sp, 16
    st.d     s3,  sp, 24
    st.d     s4,  sp, 32
    st.d     s5,  sp, 40
    st.d     s6,  sp, 48
    st.d     s7,  sp, 56
    st.d     s8,  sp, 64
    fst.d    fs0, sp, 72
    fst.d    fs1, sp, 80
    fst.d    fs2, sp, 88
    fst.d    fs3, sp, 96
    fst.d    fs4, sp, 104
    fst.d    fs5, sp, 112
    fst.d    fs6, sp, 120
    fst.d    fs7, sp, 128

    la.local t1,  register_init
    ld.d     s0,  t1, 0
    ld.d     s1,  t1, 8
    ld.d     s2,  t1, 16
    ld.d     s3,  t1, 24
    ld.d     s4,  t1, 32
    ld.d     s5,  t1, 40
    ld.d     s6,  t1, 48
    ld.d     s7,  t1, 56
    ld.d     s8,  t1, 64
    fld.d    fs0, t1, 72
    fld.d    fs1, t1, 80
    fld.d    fs2, t1, 88
    fld.d    fs3, t1, 96
    fld.d    fs4, t1, 104
    fld.d    fs5, t1, 112
    fld.d    fs6, t1, 120
    fld.d    fs7, t1, 128

    addi.d   sp,  sp, -16
    st.d     a1,  sp, 0 // ok
    st.d     ra,  sp, 8 // Ret address

    addi.d   sp,  sp, -ARG_STACK

    addi.d   t0,  zero, 8*8
    xor      t1,  t1, t1
.rept MAX_ARGS - 8
    // Skip the first 8 args, that are loaded into registers
    ldx.d    t2,  t4, t0
    stx.d    t2,  sp, t1
    addi.d   t0,  t0, 8
    addi.d   t1,  t1, 8
.endr
    move     t3,  a0 // Func
    ld.d     a0,  t4, 0
    ld.d     a1,  t4, 8
    ld.d     a2,  t4, 16
    ld.d     a3,  t4, 24
    ld.d     a4,  t4, 32
    ld.d     a5,  t4, 40
    ld.d     a6,  t4, 48
    ld.d     a7,  t4, 56

    jirl     ra,  t3, 0

    addi.d   sp,  sp, ARG_STACK
    ld.d     t2,  sp, 0 // ok
    ld.d     ra,  sp, 8 // Ret address
    addi.d   sp,  sp, 16

    la.local t1,  register_init
    xor      t3,  t3, t3

.macro check_reg_gr reg1
    ld.d     t0,  t1, 0
    xor      t0,  $s\reg1, t0
    or       t3,  t3, t0
    addi.d   t1,  t1, 8
.endm
    check_reg_gr 0
    check_reg_gr 1
    check_reg_gr 2
    check_reg_gr 3
    check_reg_gr 4
    check_reg_gr 5
    check_reg_gr 6
    check_reg_gr 7
    check_reg_gr 8

.macro check_reg_fr reg1
    ld.d     t0,  t1, 0
    movfr2gr.d t4,$fs\reg1
    xor      t0,  t0, t4
    or       t3,  t3, t0
    addi.d   t1,  t1, 8
.endm
    check_reg_fr 0
    check_reg_fr 1
    check_reg_fr 2
    check_reg_fr 3
    check_reg_fr 4
    check_reg_fr 5
    check_reg_fr 6
    check_reg_fr 7

    beqz     t3,  0f

    st.d     zero,t2, 0x00 // Set OK to 0
    la.local a0,  error_message
    addi.d   sp,  sp, -8
    st.d     ra,  sp, 0
    bl       puts
    ld.d     ra,  sp, 0
    addi.d   sp,  sp, 8
0:
    ld.d     s0,  sp, 0
    ld.d     s1,  sp, 8
    ld.d     s2,  sp, 16
    ld.d     s3,  sp, 24
    ld.d     s4,  sp, 32
    ld.d     s5,  sp, 40
    ld.d     s6,  sp, 48
    ld.d     s7,  sp, 56
    ld.d     s8,  sp, 64
    fld.d    fs0, sp, 72
    fld.d    fs1, sp, 80
    fld.d    fs2, sp, 88
    fld.d    fs3, sp, 96
    fld.d    fs4, sp, 104
    fld.d    fs5, sp, 112
    fld.d    fs6, sp, 120
    fld.d    fs7, sp, 128
    addi.d   sp,  sp, 136
endfunc
