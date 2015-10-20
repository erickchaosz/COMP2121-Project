.include "m2560def.inc"

.equ size = 3
.def counter = r17

load: 
	ldi ZL, low(text<<1)
	ldi ZH, high(text<<1)
	ldi YL, low(reversed_string)
	ldi YH, high(reversed_string)
	clr counter

start:
	lpm r20, Z+

	;push to stack
	push r20
	
	inc counter
	cpi counter, size
	brlt start

	clr counter
reverse:
	;pop from stack
	pop r20

	st Y+, r20 
	inc counter
	cpi counter, size
	brlt reverse

end:
	rjmp end



text: .db "abc",0

.dseg
reversed_string: .byte size
