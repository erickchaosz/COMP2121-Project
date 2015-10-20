.include "m2560def.inc"

.equ size = 7
.equ compare_num = size - 1
.def counter = r17
.def inner_counter = r16
.def temp = r18
        
.cseg rjmp start
numbers:        .db 1,4,2,7,6,3,5
        
start:
        ldi ZH, high(numbers<<1)
        ldi ZL, low(numbers<<1)
        ldi YH, high(result<<1)
        ldi YL, low(result<<1)
        clr counter
        
load:
        lpm r20, Z+
        st Y+, r20
        inc counter
        cpi counter, size
        brlt load  
        clr inner_counter
        clr counter
                
        
sort:
        ldi ZH, high(result<<1)
        ldi ZL, low(result<<1)
        ldi YH, high(result<<1)
        ldi YL, low(result<<1)
        ld r20, Y+
        cpi counter, compare_num
        breq end
        clr inner_counter
        inc counter
        
inner_loop:
        cpi inner_counter, compare_num
        breq sort
        inc inner_counter
        
        ld r20, Z
        ld r21, Y
        cp r20, r21
        brge my_swap
        rjmp else
        
my_swap:   
        mov temp, r20
        mov r20, r21
        mov r21, temp
        
else:
        st Z+, r20
        st Y+, r21
        rjmp inner_loop
        
end:
        rjmp end

        
.dseg
result: .byte size
