.include "m2560def.inc"

start:
        ldi ZH, high(result<<1)
        ldi ZL, low(result<<1)
        
main:
        ldi r16, 1
        ldi r17, 2
        ldi r18, 3
        ldi r19, 4
        ldi r20, 5
        ldi r21, 5
        ldi r22, 4
        ldi r23, 3
        ldi r24, 2
        ldi r25, 1
        add r16, r21
        add r17, r22
        add r18, r23
        add r19, r24
        add r20, r25
        st z+, r16
        st z+, r17
        st z+, r18
        st z+, r19
        st z+, r20

        
halt:
        jmp halt


.dseg
result: .byte 5
