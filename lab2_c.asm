.include "m2560def.inc"

.set NEXT_INT = 0x0000
.macro defint
        .set T = PC
        .dw NEXT_INT << 1
        .set NEXT_INT = T
        .dw @0
.endmacro

.cseg
        rjmp start
        defint 1
        defint 2
        defint 11
		defint 9


start:
        ldi YH, high(RAMEND)
        ldi YL, low(RAMEND)
        out SPH, YH
        out SPL, YL

        ldi ZH, high(NEXT_INT << 1)
        ldi ZL, low(NEXT_INT << 1)

;; X largest int
;; r16, r17  smallest int
        
main:
        ldi r16, high(0)
        ldi r17, high(0)
        movw r0, r16
        movw r24, r30
        lpm r16, Z+
        lpm r16, Z+
        
        lpm r26, Z+
        lpm r27, Z
        movw r30, r24

        lpm r16, Z+
        lpm r16, Z+
        lpm r16, Z+
        lpm r17, Z
        movw r30, r24
        rcall find_minmax
end:
        rjmp end

find_minmax:
        push r20
        push r21
        push r22
        push r23
        in r28, SPL
        in r29, SPH
        sbiw r29:r28, 2
        out SPH, r29
        out SPL, r28
        
        movw r24, r30
        cp r24, r0
        cpc r25, r1
        breq end_find
        
        lpm r20, Z+             ;next memory
        lpm r21, Z+
        
        lpm r22, Z+             ;curr number
        lpm r23, Z
        
        cp r22, r16             ;compare with min
        cpc r23, r17
        brge max_comp
        movw r16, r22
        
max_comp:
        cp r26, r22             ;compare with max
        cpc r27, r23
        brge after_comp
        movw r26, r22

after_comp:
        movw r30, r20
        rcall find_minmax

end_find:
		in r28, SPL
        in r29, SPH
		adiw r29:r28, 2
        out SPH, r29
        out SPL, r28
        movw r28, r16
        pop r23
        pop r22
        pop r21
        pop r20
        ret
