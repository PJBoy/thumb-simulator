THUMB
    movi r0,#STACK      ;\
    movrsp sp,r0        ;} Initialise stack
    ; Test input
    movi r0,#DATA
    movi r1,#(DATA_END-DATA)/4
    svc 101             ; Dump memory before (Emulator_Assignment_Details.pdf)
    bl Sort
    svc 101             ; Dump memory after
    svc 100             ; Halt

    align 4
DATA
	dcd -4
	dcd 2
	dcd 5
	dcd 910
	dcd 10
	dcd -12
	dcd 91
	dcd 11
DATA_END

Sort
    lsli r1,r1,#2       ;\
    addr r1,r1,r0       ;} n: end address
    movi r3,#1          ; t: swapped flag
ALPHA
    subi r1,#4          ;\
    beq RETURN          ;} If --n <= 0: return
    blt RETURN          ;/
BETA
    subi r3,#0          ;\
    beq RETURN          ;} If t == 0: return
    movi r3,#0          ; t
    addr r2,r0,r3       ; a: address
GAMMA
    ldri r4,[r2]        ; l = [a]
    ldri r5,[r2,#4]     ; r = [a+4]
    subr r7,r4,r5       ;\
    blt DELTA           ;} If l > r:
    beq DELTA           ;/
    stri r5,[r2]        ; [a] = r
    stri r4,[r2,#4]     ; [a+4] = l
    movi r3,#1          ; t = 1
DELTA
    addi r2,#4          ; ++a
    subr r7,r2,r1       ;\
    beq ALPHA           ;} If a == n: outer loop
    bu GAMMA            ; Else inner loop
RETURN
    push {lr}
    pop {pc}

    align 4
    dcd 0x0
STACK                   ; Stack space needed for only one word

; Vaguely:
; void bubblesort(int* a, unsigned n)
; {
;     unsigned j;
;     int t = 1;
;     while (n-- && t)
;         for (unsigned j = t = 0; j < n; ++j)
;         {
;             if (a[j] <= a[j+1])
;                 continue;
;             t = a[j], a[j] = a[j+1], a[j+1] = t;
;             t = 1;
;         }
; }
