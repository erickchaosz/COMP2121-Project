.include "m2560def.inc"

.def a_high = r17
.def a_low = r16
.def b_high = r19
.def b_low = r18
.def res_high = r21
.def res_low = r20
.set a = 640
.set b = 511

start:
    ldi a_high, HIGH(a)
    ldi a_low, LOW(a)
    ldi b_high, HIGH(b)
	ldi b_low, LOW(b)
    add a_low, b_low
	mov res_low , a_low
	adc a_high, b_high
	mov res_high, a_high

halt:
    jmp halt
