.include "m2560def.inc"

ser r16
out DDRC, r16
ldi r16, 0xEF
out PORTC, r16
end:
	rjmp end
