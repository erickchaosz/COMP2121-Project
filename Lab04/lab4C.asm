.include "m2560def.inc"

.macro do_lcd_command
        ldi r16, @0
        rcall lcd_command
        rcall lcd_wait
.endmacro
.macro do_lcd_data
        mov r16, @0
        rcall lcd_data
        rcall lcd_wait
.endmacro

.macro clear
        ldi YL, low(@0)
        ldi YH, high(@0)
        clr temp1
        st Y+, temp1
        st Y, temp1
.endmacro


.org 0
jmp RESET


.org OVF0addr
        jmp Timer0OVF

.def ten = r10
.def row = r17
.def col = r18
.def rmask = r19
.def cmask = r20
.def temp1 = r21
.def temp2 = r22
.def acc = r23
.def debounce = r26
.def currnum = r27
.def displayacc = r28
.def numdiv = r28
.def B = r17
.def C = r18

.equ PORTADIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F


RESET:
        ldi r16, 10
        mov r10, r16
        ldi r16, low(RAMEND)
        out SPL, r16
        ldi r16, high(RAMEND)
        out SPH, r16
        sei
        clear TempCounter
        clear SecondCounter
        ldi temp1, 0b00000000
        out TCCR0A, temp1
        ldi temp1, 0b00000010
        out TCCR0B, temp1
        ldi temp1, 1<<TOIE0
        sts TIMSK0, temp1


        ldi temp1, PORTADIR
        sts DDRL, temp1
        ser temp1
        out DDRC, temp1
        out PORTC, temp1
        ldi acc, '0'
        ser r16
        out DDRF, r16
        out DDRA, r16
        clr r16
        out PORTF, r16
        out PORTA, r16
        clr debounce
        do_lcd_command 0b00111000 ; 2x5x7
        rcall sleep_5ms
        do_lcd_command 0b00111000 ; 2x5x7
        rcall sleep_1ms
        do_lcd_command 0b00111000 ; 2x5x7
        do_lcd_command 0b00111000 ; 2x5x7
        do_lcd_command 0b00001000 ; display off?
        do_lcd_command 0b00000001 ; clear display
        do_lcd_command 0b00000110 ; increment, no display shift
        do_lcd_command 0b00001110 ; Cursor on, bar, no blink

        do_lcd_data acc

        clr acc
        clr currnum

        do_lcd_command 0b11000000

main:
        ldi cmask, INITCOLMASK
        clr col
colloop:
        cpi col, 4
        breq main
        sts PORTL, cmask
        ldi temp1, 0xFF

delay:
        dec temp1
        brne delay
        lds temp1, PINL
        andi temp1, ROWMASK
        cpi temp1, 0xF
        breq nextcol

        ldi rmask, INITROWMASK
        clr row                 ;

rowloop:
        cpi row, 4
        breq nextcol
        mov temp2, temp1
        and temp2, rmask
        breq convert
        inc row
        lsl rmask
        jmp rowloop
nextcol:
        lsl cmask
        inc col
        jmp colloop

convert:
        cpi col, 3
        breq letters

        cpi row, 3
        breq symbols
        mov temp1, row
        lsl temp1
        add temp1, row
        add temp1, col

        cpi debounce, 1
        breq main
        ldi debounce, 1


        mul currnum, ten
        mov currnum, r0
        add currnum, temp1      ;mult currnum by 10 and add temp1

        subi temp1, -'1'        ;convert to ascii

        do_lcd_data temp1

        jmp convert_end


star:
        ldi temp1, '*'

        cpi debounce, 1
        breq main
        ldi debounce, 1

        do_lcd_command 0b00000001 ; clear display
        do_lcd_command 0b00000110 ; increment, no display shift
        do_lcd_command 0b00001110 ; Cursor on, bar, no blink

        add acc, currnum
        mov displayacc, acc

        rcall displaynum

        do_lcd_command 0b11000000
        clr currnum

        jmp convert_end



letters:
        ldi temp1, 'A'
        add temp1, row
        jmp convert_end

symbols:
        cpi col, 0
        breq star
        cpi col, 1
        breq zero
        ldi temp1, '#'
        jmp convert_end


zero:
        ldi temp1, '0'

convert_end:
        out PORTC, temp1
        jmp main


halt:
        rjmp halt

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
        sbi PORTA, @0
.endmacro
.macro lcd_clr
        cbi PORTA, @0
.endmacro

        ;;
        ;;  Send a command to the LCD (r16)
        ;;

lcd_command:
        out PORTF, r16
        rcall sleep_1ms
        lcd_set LCD_E
        rcall sleep_1ms
        lcd_clr LCD_E
        rcall sleep_1ms
        ret

lcd_data:
        out PORTF, r16
        lcd_set LCD_RS
        rcall sleep_1ms
        lcd_set LCD_E
        rcall sleep_1ms
        lcd_clr LCD_E
        rcall sleep_1ms
        lcd_clr LCD_RS
        ret

lcd_wait:
        push r16
        clr r16
        out DDRF, r16
        out PORTF, r16
        lcd_set LCD_RW
lcd_wait_loop:
        rcall sleep_1ms
        lcd_set LCD_E
        rcall sleep_1ms
        in r16, PINF
        lcd_clr LCD_E
        sbrc r16, 7
        rjmp lcd_wait_loop
        lcd_clr LCD_RW
        ser r16
        out DDRF, r16
        pop r16
        ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
        ;;  4 cycles per iteration - setup/call-return overhead

sleep_1ms:
        push r24
        push r25
        ldi r25, high(DELAY_1MS)
        ldi r24, low(DELAY_1MS)
delayloop_1ms:
        sbiw r25:r24, 1
        brne delayloop_1ms
        pop r25
        pop r24
        ret

sleep_5ms:
        rcall sleep_1ms
        rcall sleep_1ms
        rcall sleep_1ms
        rcall sleep_1ms
        rcall sleep_1ms
        ret

.set delay_100ms = 100
sleep_100ms:
        push r16

delayloop_100ms:
        cpi r16, delay_100ms
        rcall sleep_1ms
        breq end_sleep_100ms
        inc r16
        rjmp delayloop_100ms

end_sleep_100ms:
        pop r16
        ldi debounce, 0
        ret


Timer0OVF:
        push temp1
        in temp1, SREG
        push temp1
        push YH
        push YL
        push r25
        push r24

        cpi debounce, 1
        brne EndIF
        lds r24, TempCounter
        lds r25, TempCounter+1
        adiw r25:r24, 1         ; Increase the temporary counter by one.
        cpi r24, low(1000)
        ldi temp1, high(1000)
        cpc r25, temp1
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
        pop temp1
        out SREG, temp1
        pop temp1
        reti



displaynum:
        push r16
        push r17
        push r18
        push r30
        push r31
        in r30, SPL
        in r31, SPH
        rcall DIV10
        mov r18, r0
        mov numdiv, r1

        rcall DIV10
        mov r17, r0
        mov numdiv, r1

        subi numdiv, -'1'
        do_lcd_data numdiv

        subi r17, -'1'
        do_lcd_data r17

        subi r18, -'1'
        do_lcd_data r18

displaynumend:
        out SPL, r30
        out SPH, r31
        pop r31
        pop r30
        pop r18
        pop r17
        pop r16
        ret



;r17 is the remainder
;counter is the divide result
; r0 result division
; r1 mod


DIV10:
        push r30
        push r31
        in r30, SPL
        in r31, SPH
        push r16
        push r17                ;currnumber
        push r18                ;counter
        clr r18
        ldi r16, 10
        mov r17, numdiv

divloop:
        inc r18
        sub r17, r16
        cpi r17, 10
        brlt enddiv
enddiv:
        mov r0, r18
        mov r1, r17
        pop r18
        pop r17
        pop r16
        out SPL, r31
        out SPH, r30
        pop r31
        pop r30
        ret

.dseg
SecondCounter:
        .byte 2
TempCounter:
        .byte 2
