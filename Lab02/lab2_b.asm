.include "m2560def.inc"

.def length_counter=r18
        
.set NEXT_STRING = 0x0000
.macro defstring                ;str
        .set T = PC             ;set current position in program memory
        .dw NEXT_STRING << 1    ;write out address of next list node
        .set NEXT_STRING = T    ;update NEXT_STRING so it points to this node

        .if strlen(@0) & 1      ;odd length + null byte
                .db @0, 0
        .else                   ;even length + null byte, add padding byte
                .db @0, 0, 0
        .endif
.endmacro

.cseg
        rjmp start
        defstring "macros123"
        defstring "is"
        defstring "fun"

start:
        ldi YH, high(RAMEND)
        ldi YL, low(RAMEND)
        out SPH, YH
        out SPL, YL
        
        ldi ZH, high(NEXT_STRING << 1)
        ldi ZL, low(NEXT_STRING << 1)
        

        
main:
        ldi r16, high(0)
        ldi r17, low(0)
        movw r0, r16
        
        movw r20, r30
        ldi r16, high(0)
        ldi r17, low(0)
        movw r22, r20
        rcall recur_search
        
end:
        rjmp end

        ;; currnode in r20,r21  lengthsofar in r16,r17   nodesofar in r22,r23
recur_search:
        push r28
        push r29
        push r18
        push r19
        push r24
        push r25
        push r26
        push r27
        
        in r28, SPL
        in r29, SPH
        sbiw r29:r28, 2

        out SPH, r29
        out SPL, r28
        
        std Y+1, r20            ;currnode
        std Y+2, r21            
        
        ldd r24, Y+1            ;currnode
        ldd r25, Y+2
        
        cp r24, r0
        cpc r25, r1
        breq endrecurse
        movw r30, r24
        movw r26, r30
        
        lpm r24, Z+
        lpm r25, Z+
        movw r20, r24
        movw r18, r30
        rcall string_length
        cp r16, r24             ;compare string length
        cpc r17, r25
        brge recurse
        movw r16, r24           ;get max of them
        movw r22, r26           
        
recurse:
        rcall recur_search
endrecurse:
        movw r30, r22
        adiw r29:r28, 2
		out SPH, r29
		out SPL, r28
        pop r27
        pop r26
        pop r25
        pop r24
        pop r19
        pop r18
        pop r29
        pop r28
        ret

        
        ;; find length string of a node, parameter in r18,r19
string_length:
        ;; prologue
        push r28
        push r29
        push r20
        push length_counter
        push r30
        push r31
        
        in r28, SPL
        in r29, SPH
        sbiw r29:r28, 2

        out SPH, r29
        out SPL, r28
        std Y+1, r18            ;pass in pointer to the node
        std Y+2, r19
        ;; end of prologue

        ;; function body
        movw r30, r18
        clr length_counter
loop:   
        lpm r20, Z+
        cpi r20, 0
        breq done
        inc length_counter
        rjmp loop

done:
        movw r24, length_counter
        ;; end of function body

        ;; epilogue
        adiw r29:r28, 2
        out SPH, r29
        out SPL, r28
        pop r31
        pop r30
        pop length_counter
        pop r20
        pop r29
        pop r28
        ret
        
