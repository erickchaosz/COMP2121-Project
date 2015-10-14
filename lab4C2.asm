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

        
.org 0
jmp RESET

        
.def row = r17
.def col = r18
.def rmask = r19
.def cmask = r20
.def temp1 = r21
.def temp2 = r22
.def acc = r23
.def debounce = r26

.equ PORTADIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

        
RESET:
        ldi r16, low(RAMEND)
        out SPL, r16
        ldi r16, high(RAMEND)
        out SPH, r16


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
        subi temp1, -'1'

        cpi debounce, 1
        breq main
        ldi debounce, 1
        do_lcd_data temp1
        rcall delay_100ms
        ldi debounce, 0
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
       
star:
        ldi temp1, '*'          
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
        breq end_sleep_100ms
        rcall sleep_1ms
        inc r16
        rjmp delayloop_100ms
        
end_sleep_100ms:
        pop r16
        ldi debounce, 0
        ret
        
