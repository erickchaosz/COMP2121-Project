.include "m2560def.inc"

.equ size = 5
.def counter = r17
        
.cseg rjmp start
        
curr_string:    .db "helao\0" 
search_char:    .db 'f'

start:
        ldi ZH, high(search_char<<1)
        ldi ZL, low(search_char<<1)
        lpm r21, Z
        ldi ZH, high(curr_string<<1)
        ldi ZL, low(curr_string<<1)
        clr counter
        ;; find a way to load from prog memory to r21
        
main:
        lpm r20, Z+
        cp r20, r21
        breq char_found
        inc counter
        cpi counter, size
        brlt main
        ldi r16, 0xFF
        rjmp end
        
char_found:
        mov r16, counter
        rjmp end

end:
        rjmp end
