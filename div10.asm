.include "m2560def.inc"

.def numdiv = r28

start:
        ldi YH, high(RAMEND)
        ldi YL, low(RAMEND)
        out SPH, YH
        out SPL, YL

main:
       
        ldi numdiv, 123
        rcall DIV10
        
end:    
        rjmp end


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
        rjmp divloop
        
enddiv:
        mov r0, r18
        mov r1, r17
        pop r18
        pop r17
        pop r16
        out SPH, r31
        out SPL, r30
        pop r31
        pop r30
        ret

        
