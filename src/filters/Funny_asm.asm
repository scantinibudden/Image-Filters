extern Funny_c
global Funny_asm

;Para i de 0 a height - 1:
;   Para j de 0 a width - 1:
;       funny_r = 100 * sqrt(abs(j-i))
;       funny_g = (abs(i-j)*10) / ((j+i+1)/100)
;       funny_b = 10 * sqrt( (i*2+100) * (j*2+100))

;       dst_matrix[i][j].r = SATURAR( TRUNCAR(funny_r)/2 + src_matrix[i][j].r/2 )
;       dst_matrix[i][j].g = SATURAR( TRUNCAR(funny_g)/2 + src_matrix[i][j].g/2 )
;       dst_matrix[i][j].b = SATURAR( TRUNCAR(funny_b)/2 + src_matrix[i][j].b/2 )

;rdi -> src
;rsi -> dst
;rdx -> width
;rcx -> height
;r8 -> src_row_size
;r9 -> dst_row_size

; La proxima linea debe ser replazada por el codigo asm
section .rodata
;posiciones     0     1    2     3     4     5     6     7     8     9     10    11    12    13    14    15 
dosCincoCinco: times 4 db 0xFF, 0x00, 0x00, 0x00
mascaraR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80; -> 0x80 es 0
mascaraG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80
mascaraB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80
transparencia: times 4 db 0x00, 0x00, 0x00, 0xFF
registoInicial: db 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00
cien: times 4 db 0x64, 0x00, 0x00, 0x00
diez: times 4 db 0x0A, 0x00, 0x00, 0x00
dos: times 2 db 0x02, 0x00, 0x00, 0x00
cero: times 16 db 0x00
unos: times 16 db 0xFF


section .text
Funny_asm:
push rbp            ;pusheamos registros que necesitamos
mov rbp, rsp
push r12
push r13

xor r12, r12

.cicloH:
cmp r12d, ecx
je .finCicloH
xor r13, r13

    .cicloW:
    cmp r13d, edx
    je .finCicloW

    ;funny_r = 100 * sqrt(abs(j-i))
    .rojo:
    ;rojo = |j-i|j-i+1|j-i+2|j-i+3|
    movdqu xmm1, [registoInicial]           ;xmm1 = |0|1|2|3|
    xor r10, r10                            ;ponemos a r10 en cero
    mov r10d, r13d                          ;ponemos j en r10
    sub r10d, r12d                          ;hacemos j - i, r10 = j-i

    pinsrd xmm2, r10d, 0                    ;insertamos j-i en xmm2
    pshufd xmm2, xmm2, 0b00000000           ;lo alargamos al resto del registro xmm2 = |j-i|j-i|j-i|j-i|

    paddd xmm2, xmm1                        ;le sumamos xmm1 a xmm2
    pabsd xmm2, xmm2                        ;hacemos el valor absoluto
    cvtdq2ps xmm2, xmm2                     ;esto es muy simd de nuestra parte, convertimos a float
    sqrtps xmm2, xmm2                       ;hacemos la raiz cuadrada
    movdqu xmm3, [cien]                     ;movemos 100 a xmm3
    cvtdq2ps xmm3, xmm3                     ;esto es muy simd de nuestra parte, convertimos a float
    mulps xmm2, xmm3                        ;multiplicamos por 100
    movdqu xmm1, xmm2                       ;ponemos resultados en xmm1, XMM1 -> ROJO

    ;funny_g = (abs(i-j)*10) / ((j+i+1)/100)
    .verde:
    
    ;dividendo
    movdqu xmm2, [registoInicial]   ;ponemos 0123
    mov r10d, r12d                  ;i  
    sub r10d, r13d                  ;i - j
    movd xmm3, r10d                 ;ponemos r10 en xmm3
    pshufd xmm3, xmm3, 0b00000000   ;lo alargamos
    psubd xmm3, xmm2                ;le restamos 0123 (del j)
    movdqu xmm2, xmm3               ;movemos a xmm2
    
    pabsd xmm2, xmm2                ;hacemos el valor absoluto
    cvtdq2ps xmm2, xmm2             ;lo convertimos a float
    movdqu xmm3, [diez]             ;ponemos 10 en xmm3
    cvtdq2ps xmm3, xmm3             ;convertimos a float
    mulps xmm2, xmm3                ;multiplicamos x10
    
    ;divisor
    movdqu xmm4, [registoInicial]   ;ponemos 0123
    mov r10d, r12d                  ;i
    add r10d, r13d                  ;i + j
    inc r10d                        ;i + j + 1
    movd xmm3, r10d                 ;ponemos r10 en xmm3
    pshufd xmm3, xmm3, 0b00000000   ;alargamos
    paddd xmm3, xmm4                ;sumamos con 0123
    movdqu xmm4, [cien]             ;ponemos 100 en xmm4
    cvtdq2ps xmm3, xmm3             ;convertimos a float
    cvtdq2ps xmm4, xmm4             ;convertimos a float
    divps xmm3, xmm4                ;mult x 100
    
    ;dividimos dividendo x divisor
    divps xmm2, xmm3                ;dividimos, XMM2 -> VERDE 

    .azul:
    ;funny_b = 10 * sqrt( (i*2+100) * (j*2+100))
 
    ; i
    pxor xmm3, xmm3
    movd xmm3, r12d                 ;ponemos i en xmm3
    pshufd xmm3, xmm3, 0b00000000   ;lo alargamos, xmm3 = |i|i|i|i|
    movdqu xmm4, [dos]              ;movemos 2 a xmm4
    cvtdq2pd xmm4, xmm4             ;pasamos a float
    cvtdq2pd xmm3, xmm3             ;pasamos a float
    mulpd xmm3, xmm4                ;multiplicamos x2
    movdqu xmm4, [cien]             ;ponemos 100
    cvtdq2pd xmm4, xmm4             ;pasamos a float
    addpd xmm3, xmm4                ;le sumamos 100 

   ; j
    xor rax, rax
    mov eax, r13d
    pinsrd xmm4, eax, 0                 ;xmm4 = |j|0|
    inc rax                         
    pinsrd xmm4, eax, 1                 ;xmm4 = |j|j+1|
    inc rax
    pinsrd xmm6, eax, 0                 ;xmm6 = |j+2|0|
    inc rax
    pinsrd xmm6, eax, 1                 ;xmm6 = |j+2|j+3|
 
    movdqu xmm5, [dos]                  ;ponemos dos en xmm5
    cvtdq2pd xmm4, xmm4                 ;convertimos a float
    cvtdq2pd xmm5, xmm5                 ;convertimos a float
    cvtdq2pd xmm6, xmm6                 ;convertimos a float
    mulpd xmm4, xmm5                    ;multiplicamos x dos parte baja
    mulpd xmm6, xmm5                    ;multipliamos x dos parte alta
    movdqu xmm5, [cien]                 ;ponemos 100 en xmm5
    cvtdq2pd xmm5, xmm5                 ;convertimos a float
    addpd xmm4, xmm5                    ;sumamos 100 a parte baja
    addpd xmm6, xmm5                    ;sumamos 100 a parte alta 

    mulpd xmm4, xmm3                    ;multiplicamos i x j bajo
    mulpd xmm6, xmm3                    ;multiplicamos i x j alto
    sqrtpd xmm4, xmm4                   ;hacemos sqrt bajo
    sqrtpd xmm6, xmm6                   ;hacemos sqrt alto

    movdqu xmm5, [diez]                 ;movemos 10 a xmm5
    cvtdq2pd xmm5, xmm5                 ;convertimos xmm5 a float
    mulpd xmm4, xmm5                    ;multiplicamos x10 bajo
    mulpd xmm6, xmm5                    ;multiplixamos x10 alto


    .guardar:

    ; trunqueo redondeo
    cvttps2dq xmm1, xmm1            ;XMM1 -----> ROJOS
    cvttps2dq xmm2, xmm2            ;XMM2 -----> VERDES
    cvttpd2dq xmm4, xmm4            ;XMM4 -----> AZULES bajo
    cvttpd2dq xmm6, xmm6            ;XMM6 -----> AZULES alto

    ; trunqueo a byte
    movdqu xmm0, [dosCincoCinco]    ;ponemos ff en el menos sigifciativo de c/dword
    pand xmm1, xmm0                 ;nos quedamos con c/byte menos significativo
    pand xmm2, xmm0                 ;nos quedamos con c/byte menos significativo
    pand xmm4, xmm0
    pand xmm6, xmm0
    pslldq xmm6, 8
    por xmm4, xmm6
    movdqu xmm3, xmm4 

    ;dividimos x2
    psrld xmm1, 1
    psrld xmm2, 1
    psrld xmm3, 1

    ;xmm1 tiene pixeles procesados rojos
    movdqu xmm0, [rdi]          ;agarramos pixeles
    movdqu xmm4, [mascaraR]     ;aplicamos mascara roja
    pshufb xmm0, xmm4           ;rojos en xmm0
    psrld xmm0, 1               ;div 2
    paddusb xmm0, xmm1          ;sumados
    movdqu xmm1, xmm0           ;rojos

    ; xmm2 tiene pixeles procesados verdes
    movdqu xmm0, [rdi]          ;agarramos pixeles
    movdqu xmm4, [mascaraG]     ;aplicamos mascara verde
    pshufb xmm0, xmm4           ;verdes en xmm0
    psrld xmm0, 1               ;div 2
    paddusb xmm0, xmm2          ;sumados
    movdqu xmm2, xmm0           ;verdes

    ; xmm3 tiene pixeles procesados azules
    movdqu xmm0, [rdi]          ;agarramos pixeles
    movdqu xmm4, [mascaraB]     ;aplicamos mascara azul
    pshufb xmm0, xmm4           ;azules en xmm0
    psrld xmm0, 1               ;div 2
    paddusb xmm0, xmm3          ;sumados
    movdqu xmm3, xmm0           ;azules

    ;ubicamos verde y rojo para el merge
    pslldq xmm1, 2              ;ponemos rojos en su lugar c/shift
    pslldq xmm2, 1              ;ponemos verdes en su lugar c/shift

    ;unimos
    movdqu xmm4, [transparencia]    ;ponemos la transparencia en 255
    por xmm1, xmm2                  ;sumamos rojos con verdes
    por xmm1, xmm3                  ;sumamos azules
    por xmm1, xmm4                  ;agregamos transparencia

    movdqu [rsi], xmm1              ;ponemos en destino

    add rsi, 16     ;nos movemos a los proximos 4 pixeles en src
    add rdi, 16     ;nos movemos a los proximos 4 pixeles en dst
    add r13d, 4     ;aumentamos en 4 el contador de columnas
    jmp .cicloW

.finCicloW:
inc r12d            ;aumentamos una fila
jmp .cicloH

.finCicloH:
pop r13
pop r12
pop rbp
ret