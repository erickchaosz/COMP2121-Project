.include "m2560def.inc"

.def row = r16
.def col = r17
.def rmask = r18
.def cmask = r19
.def temp1 = r20
.def temp2 = r21
        
.equ PORTADIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F


RESET:
        ldi temp1, low(RAMEND)
        out SPL, temp1
        ldi temp1, high(RAMEND)
        out SPH, temp1
        ldi temp1, PORTADIR
        sts DDRL, temp1
        ser temp1
        out DDRC, temp1
        out PORTC, temp1

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
        subi temp1, -1
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
