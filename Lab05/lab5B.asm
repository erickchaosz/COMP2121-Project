.include "m2560def.inc"
.def temp = r16
.def brightness = r17

.cseg
rjmp RESET

.org OVF3addr
	jmp Timer3OVF

TIMER3OVF:
  dec brightness
  sts OCR3BL, brightness
  sts OCR3BH, brightness
  reti

RESET:
  ldi brightness, 255
  ldi temp, 0b0010000
  out DDRE, temp

  ldi temp, (1 << CS30)
  sts TCCR3B, temp
  ldi temp, (1<< WGM30)|(1<<COM3B1)
  sts TCCR3A, temp

  ldi temp, 0b00000100
	sts TCCR3B, temp
	ldi temp, 1<<TOIE3		; turns overflow interrupt bit on
	sts TIMSK3, temp


loop:
  rjmp loop
