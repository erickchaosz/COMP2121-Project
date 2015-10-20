        ;;  This program implements a timer that counts one second using ; Timer0 interrupt
.include "m2560def.inc"
.equ PATTERN = 0b10101010101010101
.equ TWO = 0x0002
        .def temp = r16
        .def leds = r17
	.def patternhi = r19
	.def patternlo = r18
	.def twohi = r21
	.def twolo = r20
	.def counter = r26
        ;;  The macro clears a word (2 bytes) in a memory
        ;;  the parameter @0 is the memory address for that word
        .macro clear
        ldi YL, low(@0)
        ldi YH, high(@0)
        clr temp
        st Y+, temp
        st Y, temp
        .endmacro
        ;;  load the memory address to Y
        ;;  clear the two bytes at @0 in SRAM

.dseg
PatternVar:
		.byte 2

SecondCounter:
        .byte 2
TempCounter:
        .byte 2
        .cseg
        .org 0x0000
        jmp RESET
        jmp DEFAULT
        jmp DEFAULT
        .org OVF0addr
        jmp Timer0OVF
        
        jmp DEFAULT
DEFAULT:          reti
        ;;  Two-byte counter for counting seconds.
        ;;  Temporary counter. Used to determine ; if one second has passed
        ;;  No handling for IRQ0.
        ;;  No handling for IRQ1.
        ;;  Jump to the interrupt handler for
        ;;  Timer0 overflow.
        ;;  default service for all other interrupts.
        ;;  no service

RESET:
        ldi temp, high(RAMEND)
        out SPH, temp
        ldi temp, low(RAMEND)
        out SPL, temp
        ser temp
        out DDRC, temp
		clr counter
        rjmp main
        ;;  Initialize stack pointer
        ;;  set Port C as output


Timer0OVF:
        in temp, SREG
        push temp
        push YH
        push YL
        push r25
        push r24
        ;;  interrupt subroutine to Timer0
        ;;  Prologue starts.
        ;;  Save all conflict registers in the prologue.
        ;;  Prologue ends.
        ;;  Load the value of the temporary counter.
	
        lds r24, TempCounter
        lds r25, TempCounter+1
        adiw r25:r24, 1         ; Increase the temporary counter by one.

        cpi r24, low(7812)
        ldi temp, high(7812)
        cpc r25, temp
        brne NotSecond
		
		cpi counter, 8
		breq reset_counter
		rjmp ledout
reset_counter:
		clr counter
		ldi patternhi, high(PATTERN)
		ldi patternlo, low(PATTERN)
		
ledout:
	    mov leds, patternhi
        out PORTC, leds
	 
		mul     patternlo, twolo
		movw    r23:r22, r1:r0
		mul     patternhi, twolo
		add     r23, r0
		mul     twohi, patternlo
		add     r23, r0
		movw    patternhi:patternlo, r23:r22
		inc counter
  	

        clear TempCounter
        ;;  Check if (r25:r24) = 7812 ; 7812 = 106/128
        ;;  Reset the temporary counter. ; Load the value of the second counter.
        lds r24, SecondCounter
        lds r25, SecondCounter+1
        adiw r25:r24, 1         ; Increase the second counter by one.
        sts SecondCounter, r24
        sts SecondCounter+1, r25
        rjmp EndIF

NotSecond:      
        sts TempCounter, r24
        sts TempCounter+1, r25
EndIF:
        pop r24
        pop r25
        pop YL
        pop YH
        pop temp
        out SREG, temp
        reti
        ;;  Epilogue starts;
        ;;  Restore all conflict registers from the stack.
        ;;  Store the new value of the temporary counter.
        ;;  Return from the interrupt.

main:
        ldi leds, 0xFF
        out PORTC, leds
        ldi leds, high(PATTERN)
		ldi patternhi, high(PATTERN)
		ldi patternlo, low(PATTERN)
		ldi twohi, high(two)
		ldi twolo, low(two)

		clear TempCounter
        clear SecondCounter
        ldi temp, 0b00000000
        out TCCR0A, temp
        ldi temp, 0b00000010
        out TCCR0B, temp
        ldi temp, 1<<TOIE0
        sts TIMSK0, temp
        sei
       
loop:    rjmp loop
