.include "m2560def.inc"

.dseg
.org 0x200
CmdQueue: ;queue for storing user's commands
.byte 200
SecondCounter:
.byte 2
TempCounter:
.byte 2
	;Max: .db 200	;used for max size
;==================================
; macros
;==================================

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


;==========
; Setup
;==========

.cseg

rjmp RESET

.org OVF0addr
  jmp Timer0OVF

.def row = r16            ; current row number
.def col = r17            ; current column number
.def rmask = r18          ; mask for current row during scan
.def cmask = r19          ; mask for current column during scan
.def temp1 = r20
.def temp2 = r21
.def acc = r22
.def debounce = r23

;following register used in checking size of queue
.def QueueCtr = r24
;
.equ PORTADIR = 0xF0      ; PD7-4: output, PD3-0, input
.equ INITCOLMASK = 0xEF   ; scan from the rightmost column,
.equ INITROWMASK = 0x01   ; scan from the top row
.equ ROWMASK = 0x0F       ; for obtaining input from Port D

RESET:
  ldi temp1, low(RAMEND)  ; initialize the stack
  out SPL, temp1
  ldi temp1, high(RAMEND)
  out SPH, temp1

  ldi xl, low(CMDQueue)
  ldi xh, high(CMDQueue)

  ldi zl, low(CMDQueue)
  ldi zh, high(CMDQueue)



  sei                     ; initialize timer 0
  clear TempCounter
  clear SecondCounter
  ;
  ldi QueueCtr, 0

  ;KEYPAD init.
  ldi temp1, 0b00000000
  out TCCR0A, temp1
  ldi temp1, 0b00000010
  out TCCR0B, temp1
  ldi temp1, 1<<TOIE0
  sts TIMSK0, temp1

  ldi temp1, PORTADIR     ; PA7:4/PA3:0, out/in
  sts DDRL, temp1
  ser temp1               ; PORTC is output
  out DDRC, temp1
  out PORTC, temp1
  clr acc
  ser r16

  ;LCD init.
  out DDRF, r16
  out DDRA, r16
  clr r16
  out PORTF, r16
  out PORTA, r16

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

  do_lcd_command 0b11000000
  do_lcd_data r16
	
main:
  ldi cmask, INITCOLMASK  ; initial column mask
  clr col                 ; initial column

colloop:
  cpi col, 4
  breq main               ; If all keys are scanned, repeat.
  sts PORTL, cmask        ; Otherwise, scan a column.

  ldi temp1, 0xFF         ; Slow down the scan operation.


delay:
  dec temp1
  brne delay
  lds temp1, PINL         ; Read PORTL
  andi temp1, ROWMASK     ; Get the keypad output value
  cpi temp1, 0xF          ; Check if any row is low
  breq nextcol
                          ; If yes, find which row is low
  ldi rmask, INITROWMASK  ; Initialize for row check
  clr row

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

  ;subi temp1, -'1'
  	;inc acc
  	;out PORTC, acc	;<- this code not needed

;code to add value in temp1 to queue;
;first, borrow register for compare

  
  cpi QueueCtr, 200
  breq FULLQueue
  
  push r16
  st z+, temp1
  do_lcd_data temp1
  pop r16
  inc QueueCtr

convert_jump:

  jmp convert_end

;FULLQUEUE placeholder code;

 FULLQueue:

  	jmp convert_jump

;---------------------;


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
  jmp main

halt:
  rjmp halt

;; Timer for handling debouncing
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

  clr debounce
  clear TempCounter

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
  
