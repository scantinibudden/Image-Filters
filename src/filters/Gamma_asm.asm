extern Gamma_c
global Gamma_asm

;rdi -> src
;rsi -> dst
;rdx -> width
;rcx -> height
;r8 -> src_row_size
;r9 -> dst_row_size

section .rodata

;posiciones     0     1    2     3     4     5     6     7     8     9     10    11    12    13    14    15 
dosCincoCinco: times 4 db 0xFF, 0x00, 0x00, 0x00
mascaraR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80; -> 0x80 es 0
mascaraG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80
mascaraB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80
transparencia: times 4 db 0x00, 0x00, 0x00, 0xFF
reordenarB: dq 0x00000000FFFFFFFF, 0x0000000000000000
reordenarG: dq 0xFFFFFFFF00000000, 0x0000000000000000
reordenarR: dq 0x0000000000000000,  0x00000000FFFFFFFF
mascaraShuffle: db 0x00, 0x04, 0x08, 0x80, 0x01, 0x05, 0x09, 0x80, 0x02, 0x06, 0x0A, 0x80, 0x03, 0x07, 0x0B, 0x80

section .text
Gamma_asm:
push rbp            ;pusheamos registros que necesitamos
mov rbp, rsp

; MULPS -> Multiply packed single-precision floating-point values in xmm2/m128 with xmm1 and store result in xmm1
; DIVPS -> Divide packed single-precision floating-point values in xmm1 by packed single-precision floating-point values in xmm2/mem
; SQRTPS -> Computes Square Roots of the packed single-precision floating-point values in xmm2/m128 and stores the result in xmm1.
; CVTPS2PI -> Convert two packed single-precision floating-point values from xmm/m64 to two packed signed doubleword integers in mm
; CVTPI2PS -> Convert two signed doubleword integers from mm/m64 to two single-precision floating-point values in xmm. 

;rdx*rcx/4
mov eax, ecx
mul edx
shr rax, 2
xor rcx, rcx

.ciclo:
cmp rcx, rax
je .fin
movdqu xmm0, [rdi]                              ;pixeles 1-4
add rdi, 16

movdqu xmm1, xmm0                               ;preparamos xmm1 para el shuffle
movdqu xmm2, xmm0                               ;preparamos xmm2 para el shuffle
movdqu xmm3, xmm0                               ;preparamos xmm3 para el shuffle
movdqu xmm5, [mascaraB]
movdqu xmm6, [mascaraG] 
movdqu xmm7, [mascaraR]
pshufb xmm1, xmm5                               ;aplicamos la mascara azul a xmm1 con un shuffle
pshufb xmm2, xmm6                               ;aplicamos la mascara verde a xmm2 con un shuffle
pshufb xmm3, xmm7                               ;aplicamos la mascara roja a xmm3 con un shuffle

cvtdq2ps xmm1, xmm1
cvtdq2ps xmm2, xmm2
cvtdq2ps xmm3, xmm3
movdqu xmm8, [dosCincoCinco]
cvtdq2ps xmm8, xmm8

;primero divido x 255
divps xmm1, xmm8
divps xmm2, xmm8
divps xmm3, xmm8

;xmm1 = | B/255 | B/255 | B/255 | B/255 |
;xmm2 = | G/255 | G/255 | G/255 | G/255 |
;xmm3 = | R/255 | R/255 | R/255 | R/255 |

;despues hago sqrt
sqrtps xmm1, xmm1
sqrtps xmm2, xmm2
sqrtps xmm3, xmm3

;finalmente multiplico x 255
mulps xmm1, xmm8
mulps xmm2, xmm8
mulps xmm3, xmm8

cvttps2dq xmm1, xmm1
cvttps2dq xmm2, xmm2
cvttps2dq xmm3, xmm3

packusdw xmm1, xmm1
packusdw xmm2, xmm2
packusdw xmm3, xmm3

packuswb xmm1, xmm1
packuswb xmm2, xmm2
packuswb xmm3, xmm3

;xmm1 = |B1 B2 B3 B4| B1 B2 B3 B4| B1 B2 B3 B4| B1 B2 B3 B4|

movdqu xmm4, [reordenarB]
; xmm1 = |B1 B2 B3 B4| 0000| 0000| 0000|   
movdqu xmm5, [reordenarG]
movdqu xmm6, [reordenarR]

pand xmm1, xmm4
pand xmm2, xmm5
pand xmm3, xmm6

por xmm1, xmm2 
por xmm1, xmm3

;xmm1 = |B1 B2 B3 B4| G1 G2 G3 G4| R1 R2 R3 R4| 0 0 0 0|

movdqu xmm2, [mascaraShuffle]
pshufb xmm1, xmm2
;xmm1 = |B1 G1 R1 0| B2 G2 R2 0| B3 G3 R3 0| B4 G4 R4 0| 
movdqu xmm11, [transparencia]
por xmm1, xmm11

movdqu [rsi], xmm1
add rsi, 16
inc rcx
jmp .ciclo

.fin:
pop rbp
ret