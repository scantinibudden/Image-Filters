extern Broken_c
global Broken_asm

mascaraR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80; -> 0x80 es 0
mascaraG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80
mascaraB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80
mascaraB2: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80
mascaraG2: db 0x80, 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0X80, 0X80
mascaraR2: db 0x80, 0x80, 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80
transparencia: times 4 db 0x00, 0x00, 0x00, 0xFF
sacarTransparentes: db 0x00, 0x01, 0x02, 0x80, 0x04, 0x05, 0x06, 0x80, 0x08, 0x09, 0x0A, 0x08, 0x0C, 0x0D, 0x0E, 0x08
todosUnos: times 4 db 0xFF, 0xFF, 0xFF, 0xFF
transparente: times 2 db 0x00, 0x00, 0x00, 0xFF
blanco: times 2 db 0xFF, 0xFF, 0xFF, 0xFF

Broken_asm:

push rbp            ;stack frameee
mov rbp, rsp
push r12
push r13
push r14
push r15

mov r9, rdx
mov rdx, rcx
mov rcx, r9

mov r10, rdi
mov r11, rsi
mov r14, rdx
mov r15, rcx
;calculo nxm, el total de pixeles
mov r12d, edx       ;guardo n en r12d pues mul modifica a rdx
xor rax, rax        ;limpio a rax de basura
mov eax, edx        ;pongo edx en eax para multiplicarlo x exc
mul ecx             ;multiplico por ecx, tengo en rax nxm

mov edx, r12d       ;vuelvo a poner en edx a n
mov r12, rdi        ;paso rdi a un registro cosa de no perder el puntero original
mov r13, rsi        ;paso rsi a un registro para no perder el puntero original
mov r9d, eax        ;guardo el total de pixeles en r9d

;hago el calculo de donde empezar con el cambio para r12 y r13

mov r8d, 4          ;pongo 4 en r8d
mov eax, ecx        ;pongo m (columnas) en eax
mul r8d             ;multiplico las columas x 4 para tener el row size en bytes

add r12, rax        ;le sumo a r12 una fila
add r13, rax        ;hago lo mismocon r13
sub r9d, ecx        ;total de pixeles - 1 fila
sub r9d, ecx        ;total de pixeles - 2 filas

;voy a cambiar toda la imagen excepto la primera y ultima fila xq sino mis accesos a memoria van a ser invalios jeje
;despues la primera y ultima columna las sobreescribo al final

;calculo cuando tengo que terminar el ciclo

xor r8, r8          ;pongo a mi contador (r8) en cero

.ciclo:
cmp r8d, r9d        ;si r8d = r9d ya recorri la imagen
je .fin

movdqu xmm0, [r12]              ;pongo los primeros 4 pixeles en xmm0
movdqu xmm1, [sacarTransparentes]
pshufb xmm0, xmm1               ;me deshago de las transparencias    
movdqu xmm1, xmm0               ;pongo xmm0 en xmm1 para aislar el azul
movdqu xmm2, xmm0               ;pongo xmm0 en xmm1 para aislar el verde
movdqu xmm3, xmm0               ;pongo xmm0 en xmm1 para aislar el rojo

;pongo en cada registro un color

movdqu xmm4, [mascaraB]         ;guardo la mascara azul en xmm4
pshufb xmm1, xmm4               ;aplico la mascara azul a xmm1 con un shuffle
movdqu xmm4, [mascaraG]         ;guardo la mascara verde en xmm4 
pshufb xmm2, xmm4               ;aplico la mascara verde a xmm2 con un shuffle
movdqu xmm4, [mascaraR]         ;guardo la mascara roja en xmm4    
pshufb xmm3, xmm4               ;aplico la mascara roja a xmm3 con un shuffle

pcmpeqd xmm1, xmm2              ;me fijo si azul = verde
pcmpeqd xmm2, xmm3              ;me fijo si verde = rojo

pand xmm1, xmm2                 ;hago un and de las dos mascaras asi me queda la mascara para ver que pixeles cambio

sub r12, rax                    ;le resto una fila a r12 porque no me rejaba hacer r12 - rax
movdqu xmm2, [r12]              ;los 4 pixeles de arriba
add r12, rax                    ;le vuelvo a sumar una fila
movdqu xmm3, [r12 + rax]        ;los 4 pixeles de abajo
movdqu xmm4, [r12 - 4]          ;los 4 pixeles de la izquierda
movdqu xmm5, [r12 + 4]          ;los 4 pixeles de la derecha

;suma de azules y div x4

movdqu xmm6, xmm2
movdqu xmm7, xmm3
movdqu xmm8, xmm4
movdqu xmm9, xmm5

movdqu xmm10, [mascaraB]         ;guardo la mascara azul en xmm4
pshufb xmm6, xmm10               ;aplico la mascara azul a xmm1 con un shuffle
pshufb xmm7, xmm10               ;aplico la mascara verde a xmm2 con un shuffle    
pshufb xmm8, xmm10               ;aplico la mascara roja a xmm3 con un shuffle
pshufb xmm9, xmm10

paddd xmm6, xmm7
paddd xmm6, xmm8
paddd xmm6, xmm9

psrld xmm6, 2                   ;divido x4

movdqu xmm11, xmm6

;suma de verdes y div x 4

movdqu xmm6, xmm2
movdqu xmm7, xmm3
movdqu xmm8, xmm4
movdqu xmm9, xmm5

movdqu xmm10, [mascaraG]         ;guardo la mascara azul en xmm4
pshufb xmm6, xmm10               ;aplico la mascara azul a xmm1 con un shuffle
pshufb xmm7, xmm10               ;aplico la mascara verde a xmm2 con un shuffle    
pshufb xmm8, xmm10               ;aplico la mascara roja a xmm3 con un shuffle
pshufb xmm9, xmm10

paddd xmm6, xmm7
paddd xmm6, xmm8
paddd xmm6, xmm9

psrld xmm6, 2                   ;divido por 4

movdqu xmm10, [mascaraG2]       ;pongo a los verdes de nuevo en su lugar
pshufb xmm6, xmm10
por xmm11, xmm6                 ;junto azules con verdes

;suma de rojos y div x4

movdqu xmm6, xmm2
movdqu xmm7, xmm3
movdqu xmm8, xmm4
movdqu xmm9, xmm5

movdqu xmm10, [mascaraR]         ;guardo la mascara azul en xmm4
pshufb xmm6, xmm10               ;aplico la mascara azul a xmm1 con un shuffle
pshufb xmm7, xmm10               ;aplico la mascara verde a xmm2 con un shuffle    
pshufb xmm8, xmm10               ;aplico la mascara roja a xmm3 con un shuffle
pshufb xmm9, xmm10

paddd xmm6, xmm7
paddd xmm6, xmm8
paddd xmm6, xmm9

psrld xmm6, 2                   ;divido por 4

movdqu xmm10, [mascaraR2]       ;pongo a los verdes de nuevo en su lugar
pshufb xmm6, xmm10
por xmm11, xmm6                 ;junto junto rojos con azules y verdes

pand xmm11, xmm1                 ;aplico la mascara a los nuevos pixeles
movdqu xmm3, [todosUnos]
pxor xmm1, xmm3                 ;invierto la mascara
pand xmm0, xmm1                 ;aplico la mascara a los viejos pixeles

por xmm0, xmm11                  ;junto los nuevos con los viejos

movdqu xmm1, [transparencia]    ;les pongo la transparencia en 255
por xmm0, xmm1 

movdqu [r13], xmm0              ;pongo los pixeles en destino
add r8d, 4                      ;aumento en 4 el contador
add r12, 16                     ;avanzo 16 bytes en source
add r13, 16                     ;avanzo 16 bytes en dest

jmp .ciclo
;para la parte del borde es como lo que hiciste para el padding

.fin:
;r10->rdi principio
;r11->rsi principio
;r12->rdi ultima fila
;r13->rsi ultima fila
;r14->rdx filas
;r15->rcx columnas

xor rcx, rcx
xor r8, r8
mov ecx, r15d
shr ecx, 1
mov r9, [blanco]

.copiaHorizontal:
;mov r9, [r10 + r8*4]               ;pongo en r9d el pixel de src
;or r9, [transparente] 
mov [r11 + r8*4], r9         ;ponemos blanco en el pixel de la primera fila
;mov r9, [r12 + r8*4]               ;pongo en r9d el pixel de src
;or r9, [transparente] 
mov [r13 + r8*4], r9         ;ponemos blanco en el pixel de la ultima fila
add r8, 2                             ;incresemos r10 para continuar a la siguiente columna
loop .copiaHorizontal

xor r8, r8
mov ecx, r14d
dec ecx

;mov r9, [r10 + r8]           ;pongo en r9d el pixel de src
;or r9, [transparente] 
mov [r11 + r8], r9           ;ponemos blanco en el pixel de la primer columna

.copiaVertical:
add r8d, eax                  ;nos movemos hasta la siguiente fila
;mov r9, [r10 + r8 - 4]            ;pongo en r9d el pixel de src
;or r9, [transparente] 
mov [r11 + r8 - 4], r9           ;ponemos blanco en el pixel de la ultima columna
loop .copiaVertical

pop r15
pop r14
pop r13
pop r12
pop rbp
ret