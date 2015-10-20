.include "m2560def.inc"

.def temp =r16
.def output = r17
.def count = r18
.def leds = r19
.def temp1 = r22
.def debounce = r20
.def lightcounter = r23
.def lit = r21
;;  The macro clears a word (2 bytes)   in a memory
;;  the parameter @0 is the memory address for that word
.macro clear
        ldi YL, low(@0)
        ldi YH, high(@0)
        clr temp
        st Y+, temp
        st Y, temp
.endmacro
        
jmp RESET
.cseg
.org INT0addr
	jmp EXT_INT0

.org	INT1addr
	jmp EXT_INT1

.org    OVF2addr
        jmp Timer2OVF
        
.org    OVF0addr
        jmp Timer0OVF
        
RESET:
        ldi temp, low(RAMEND)
        out SPL, temp
        ldi temp, high(RAMEND)
        out SPH, temp
	clr leds
        ser temp
        out DDRC, temp
        out PORTC, leds
        ;;  set up interrupt vectors
        ;;  initialize stack
        ;;  set Port C as output

 	ldi temp, (2 << ISC00)
	ori temp, (2 << ISC10)
        sts EICRA, temp
        in temp, EIMSK
        ori temp, (1<<INT0)
	ori temp, (1<<INT1)
        out EIMSK, temp
        sei
        clear TempCounter
        clear SecondCounter
        clear TempCounter1
        clear SecondCounter1
        ldi temp, 0b00000000
        out TCCR0A, temp
        ldi temp, 0b00000010
        out TCCR0B, temp
        ldi temp, 1<<TOIE0
        sts TIMSK0, temp
        clr count
        clr lightcounter
        jmp main

EXT_INT0:
        push temp
        in temp, SREG 
	push temp

        cpi debounce, 1
        breq END0
        ldi debounce, 1
        inc count
        lsl leds
		out PORTC, leds
END0:   
        pop temp                ; restore SREG out SREG, temp
        out SREG, temp
        pop temp                ; restore register 
        reti

EXT_INT1:
	push temp
	in temp, SREG
	push temp

        cpi debounce, 1
        breq END1
        
        ldi debounce, 1 
	inc count        
        lsl leds
	inc leds
	out PORTC, leds

END1:  
	pop temp
        out SREG, temp
	pop temp
 	reti

        ;;  main - does nothing but increment a counter	
       
main:
        cpi count, 8
        breq lightup
        rjmp main

lightup:
        clr count
        ldi lightcounter, 3
        ldi lit, 1
        rjmp main

        
Timer0OVF:
        push temp
        in temp, SREG
        push temp
        push YH
        push YL
        push r25
        push r24

        cpi debounce, 1
        brne EndIF

        ;;  interrupt subroutine to Timer0
        ;;  Prologue starts.
        ;;  Save all conflict registers in the prologue.
        ;;  Prologue ends.
        ;;  Load the value of the temporary counter.
        lds r24, TempCounter
        lds r25, TempCounter+1
        adiw r25:r24, 1         ; Increase the temporary counter by one.
        cpi r24, low(1000)
        ldi temp, high(1000)
        cpc r25, temp
        brne NotSecond

        ldi debounce, 0
        clear TempCounter
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
        pop temp
        reti
        ;;  Epilogue starts;
        ;;  Restore all conflict registers from the stack.
        ;;  Store the new value of the temporary counter.
        ;;  Return from the interrupt.

        ;; Time for 1 sec
Timer2OVF:
        push temp
        in temp, SREG
        push temp
        push YH
        push YL
        push r25
        push r24

        cpi lightcounter, 0     
        breq EndIF1
        
        lds r24, TempCounter1
        lds r25, TempCounter1+1
        adiw r25:r24, 1         ; Increase the temporary counter by one.
        cpi r24, low(7812)
        ldi temp, high(7812)
        cpc r25, temp
        brne NotSecond1

        cpi lit, 0
        breq lightsoff
        out PORTC, leds
        ldi lit, 0
        rjmp after1_sec
        
lightsoff:
        clr temp
        out PORTC, leds
        ldi lit, 1
        
after1_sec:      
        clear TempCounter1
        ;;  Reset the temporary counter. ; Load the value of the second counter.
        lds r24, SecondCounter1
        lds r25, SecondCounter1+1
        adiw r25:r24, 1         ; Increase the second counter by one.

        sts SecondCounter1, r24
        sts SecondCounter1+1, r25
        rjmp EndIF1

NotSecond1:      
        sts TempCounter1, r24
        sts TempCounter1+1, r25

EndIF1:
        
        pop r24
        pop r25
        pop YL
        pop YH
        pop temp
        out SREG, temp
        pop temp
        reti
        ;;  Epilogue starts;
        ;;  Restore all conflict registers from the stack.
        ;;  Store the new value of the temporary counter.
        ;;  Return from the interrupt.


.dseg
SecondCounter:
        .byte 2
TempCounter:
        .byte 2
SecondCounter1:
        .byte 2
TempCounter1:
        .byte 2
