.include "m2560def.inc"

.def input_increment = r20;
.def num_div = r23
.def sec_counter = r17;
.def temp = r18;
.def stack_count = r19;
.def remainder = r17
.def div_result = r18

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


.macro do_lcd_command

	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait

.endmacro

.macro do_lcd_data

	mov r16, @0	;ldi
	rcall lcd_data
	rcall lcd_wait

.endmacro


		jmp RESET
.org	INT2addr
		jmp EXT_INT2


RESET:
	clr sec_counter;
	clr input_increment;
	clr temp;

	ldi temp,(2 << ISC10)
	sts EICRA, temp

	in temp, EIMSK
	ori temp, (1<<INT2)
	out EIMSK, temp

	sei

	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
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

	clr temp
	jmp main

main:
	rcall sleep_250ms
call_lcd:
	;do_lcd_data temp ;;
	clr temp
	clr stack_count
	mov num_div, input_increment
	rcall CALC_DIV
	rcall sleep_250ms
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	clr input_increment
	rjmp main


;
; Send a command to the LCD (r16)
;

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
; 4 cycles per iteration - setup/call-return overhead

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

sleep_250ms:
	push temp
	clr temp

loop_250ms:
	inc temp
	cpi temp, 50
	rcall sleep_1ms
	brlt loop_250ms
end_sleep_250ms:
	pop temp
	ret

EXT_INT2:	;called 4 times a rotation on the motor
	inc input_increment;
	reti

CALC_DIV: 	;called by main loop
	rcall DIV10
	mov num_div, r21

	;do_lcd_data r20

	push r22 ;remainder from div10
	inc stack_count

	cpi num_div, 0
	breq SHOW_LCD
	rjmp CALC_DIV

SHOW_LCD:
	pop num_div ;r22
	dec stack_count

	cpi stack_count, 0
	breq END_LCD

	subi num_div, -'0'
	do_lcd_data num_div ;r22
	rjmp SHOW_LCD

END_LCD:
	clr num_div
	clr sec_counter
	;pop stack_count
	clr stack_count
	clr temp

	ret


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
