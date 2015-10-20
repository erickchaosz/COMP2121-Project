.include "m2560def.inc"

.def num_div = r20
.def remainder = r17
.def div_result = r18
.def temp = r24

setup:
  ldi YL, low(RAMEND)
  ldi YH, high(RAMEND)
  out SPL, YL
  out SPH, YH
  ldi num_div, 125
  ldi r16, 10
  rcall DIV10

end:
  rjmp end


DIV10:
	;do_lcd_data r20
	push r30
	push r31
	in r30, SPL
	in r31, SPH
	push r16
	push remainder               ;currnumber
	push div_result               ;counter
	clr div_result
  ldi r16, 10
  mov remainder, num_div ;numdiv

divloop:
  cpi remainder, 10
  brlt enddiv
  inc div_result
  sub remainder, r16
	;inc r18

	rjmp divloop ;forgot this?
enddiv:
  mov r21, div_result 	; r0 really? i think its the other....
  mov r22, remainder	; r1...way around
  pop div_result
  pop remainder
  pop r16
  out SPL, r30
  out SPH, r31
  pop r31
  pop r30
  ret
