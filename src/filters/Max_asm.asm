extern Max_c
global Max_asm

section .rodata

;posiciones     0     1    2     3     4     5     6     7     8     9     10    11    12    13    14    15 
mascaraR: db 0x02, 0x80, 0x80, 0x80, 0x06, 0x80, 0x80, 0x80, 0x0A, 0x80, 0x80, 0x80, 0x0E, 0x80, 0x80, 0x80
mascaraG: db 0x01, 0x80, 0x80, 0x80, 0x05, 0x80, 0x80, 0x80, 0x09, 0x80, 0x80, 0x80, 0x0D, 0x80, 0x80, 0x80
mascaraB: db 0x00, 0x80, 0x80, 0x80, 0x04, 0x80, 0x80, 0x80, 0x08, 0x80, 0x80, 0x80, 0x0C, 0x80, 0x80, 0x80
mascaraPixel1: db 0x0C, 0x0D, 0x0E, 0x0F, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 
mascaraPixel2: db 0x08, 0x09, 0x0A, 0x0B, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 
mascaraPixel3: db 0x04, 0x05, 0x06, 0x07, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 
mascaraPixel4: db 0x00, 0x01, 0x02, 0x03, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80 
mascaraColores: db 0x00, 0x01, 0x02, 0x80, 0x04, 0x05, 0x06, 0x80, 0x08, 0x09, 0x0A, 0x80, 0x0C, 0x0D, 0x0E, 0x80
blanco: dd 0xFFFFFFFF
transparencia: times 4 db 0x00, 0x00, 0x00, 0xFF
todosUnos: times 4 db 0xFF, 0xFF, 0xFF, 0xFF

section .text
Max_asm:

push rbp            ;pusheamos registros que necesitamos
mov rbp, rsp
push r12
push r13
push r15
push rbx

xor rbx, rbx        ;en rbx vamos a guardar rdx pues mul modifica ese registro
xor r10, r10        ;contador para ciclos internos (ii)   
xor r12, r12        ;contador cicloH (i)

mov ebx, edx        ;movemos rdx a rbx
sub ebx, 2          ;le restamos 2 a width
sub ecx, 2          ;le restamos 2 a height

.cicloH:            ;Para i de 0 a height - 3 (inclusive) como i=i+2:
cmp r12d, ecx       ;comparamos el contadorH con height menos 2
jge .fin            ;si son iguales entonces termina el programa
xor r13, r13        ;ponemos el registro r13 en cero para que comience el ciclo vacio, este es el contador de cicloW

    .cicloW:        ;Para j de 0 a width - 3 (inclusive) como j=j+2:
    cmp r13d, ebx   ;comparamos el contadorW con width menos 2
    jge .finH       ;termina el cicloW    
    mov r10d, r12d  ;movemos r12 a r10 = r12 = i para comenzar el ciclo de la matriz 4x4
    pxor xmm5, xmm5 ;max matrix
    pxor xmm7, xmm7 ;max pixel matrix
    pxor xmm6, xmm6
    
        .buscarMaximo:           ;Para ii de i a i+3 (inclusive), primer pixel del 4x4 -> i + 3

            xor rax, rax         ;ponemos a rax en cero para asegurarnos de que no quede basura en su parte alta
            mov eax, r12d        ;ponemos en rax, r12 ahora rax = i
            add eax, 4           ;le sumamos 4 a rax para hacer la comparacion de ii con i+4
            cmp r10d, eax        ;comparamos r10(ii) con rax(i+4)
            jge .ponerEnDestino  ;si r10 = i+4 ==> terminamos con la matriz
            
            ;necesitamos en xmm0 la direccion de memoria [rdi + r10*r8 + r13*4]
            ;primero ponemos en rax =  rdi + r10*r8

            mov rax, r10                    ;ponemos a r10(ii) en rax
            mul r8d                         ;lo multiplicmos por la parte baja de r8 que contiene el row size
            add rax, rdi                    ;ahora sumamos la multiplicacion a rdi

            ;ponemos la primer fila de pixeles de la matriz en xmm0

            movdqu xmm0, [rax + r13*4]      ;ponemos los 4 pixeles que necesitamos en xmm0
            
            ;mov rax, [rax + r13*4]          ;para el debugger
            ;hacemos el calculo guardando cada color de cada pixel en xmmi para despues hacer summa entre esos registros
            ;ponemos los pixeles en los registros que vamos a usar para la suma

            movdqu xmm1, xmm0               ;preparamos xmm1 para el shuffle
            movdqu xmm2, xmm0               ;preparamos xmm2 para el shuffle
            movdqu xmm3, xmm0               ;preparamos xmm3 para el shuffle

            ;guardamos en cada registro un color

            movdqu xmm4, [mascaraB]         ;guardamos la mascara azul en xmm4
            pshufb xmm1, xmm4               ;aplicamos la mascara azul a xmm1 con un shuffle
            movdqu xmm4, [mascaraG]         ;guardamos la mascara verde en xmm4 
            pshufb xmm2, xmm4               ;aplicamos la mascara verde a xmm2 con un shuffle
            movdqu xmm4, [mascaraR]         ;guardamos la mascara roja en xmm4    
            pshufb xmm3, xmm4               ;aplicamos la mascara roja a xmm3 con un shuffle

            paddd xmm1, xmm2                ;sumamos azul con verde
            paddd xmm1, xmm3                ;sumamos el rojo y en xmm1 nos quedan las 3 sumas

            ;xmm0 -> pixeles
            ;xmm1 -> sumas de los pixeles
            ;ahora aislamos cada suma en un registro para poder compararlas
            movdqu xmm3, xmm1               ;nos guardamos en xmm3 las sumas

            pshufd xmm2, xmm1, 0b00111001   ;en xmm2 ahora tenemos los maximos corridos un pixel a la derecha
            pmaxud xmm1, xmm2               ;comparamos xmm1 con xmm2 una vez, ahora en xmm1 tenemos al menos 2 veces el maximo

            pshufd xmm2, xmm1, 0b00111001   ;en xmm2 ahora tenemos los maximos corridos un pixel a la derecha
            pmaxud xmm1, xmm2               ;comparamos xmm1 con xmm2 de nuevo, ahora en xmm1 tenemos al menos 3 veces el maximo

            pshufd xmm2, xmm1, 0b00111001   ;en xmm2 ahora tenemos los maximos corridos un pixel a la derecha
            pmaxud xmm1, xmm2               ;volvemos a comparar y ahora en xmm1 tenemos el maximo en los 4 lugares

            ;obtuvimos el maximo, xmm1 = |max|max|max|max|

            pcmpeqd xmm3, xmm1              ;comparamos cada suma con el maximo y en xmm3 queda mascara para pixel
            movdqu xmm4, xmm0               ;guardamos pixeles en xmm4
            movdqu xmm2, xmm3               ;guardo mascara en xmm2
            pand xmm3, xmm4                 ;queda en xmm3 el pixel, xmm3 = |0|0|pixel|0| (ej)
            movdqu xmm4, xmm1               ;guardamos xmm1
            pand xmm2, xmm4                 ;aplicamos mascara a los max, xmm2 = |0|0|max|0|
            pcmpgtd xmm1, xmm5              ;vemos si el nuevo max es mayor al otro max, quedan todos ff si tenemos q cambiar y todos 0 si no
            pand xmm3, xmm1                 ;aplicamos mascara al pixel, xmm1 = mascara, xmm3 = pixel
            pand xmm2, xmm1
            pxor xmm1, [todosUnos]          ;invertimos la mascara
            pand xmm7, xmm1                 ;aplicamos al pixel completo
            pand xmm6, xmm1
            paddd xmm7, xmm3                ;sumamos los dos resultados en xmm7 queda el pixel max
            paddd xmm6, xmm2
            pmaxud xmm5, xmm4               ;xmm5 tiene el maximo
            
            ;en xmm7 queda el pixel q necesitamos y en xmm5 el max
            inc r10             ;increseamos r10(ii)
            jmp .buscarMaximo   ;continuamos el ciclo de recorrer la matriz

        ;una vez terminado el ciclo de la matriz nos queda en r11 el pixel que debemos poner en la matriz 2x2 de la 
        ;foto destino

        .ponerEnDestino:                    ;Para ii de i+1 a i+2:

            ;xmm7 -> pixel    
            xor r11, r11                       ;en r11 vamos a guardar el pixel con mayor suma por matriz   
            movdqu xmm4, xmm6                  ;guardamos xmm6 en xmm4
            pandn xmm4, [todosUnos]            ;nos queda en xmm4 el pixel, solo falta aislarlo
            phminposuw xmm2, xmm4              ;minimo horizontal de xmm4, en la seond lowest word de xmm2 tengo el index
            psrldq xmm2, 2
            psrld xmm2, 1
            pextrd r11d, xmm2, 0
  
            .shifts:
            cmp r11b, 0
            je .finMax
            psrldq xmm7, 4
            dec r11b
            jmp .shifts

            .finMax:
            pextrd r11d, xmm7, 0            ;guardamos el el pixel
            or r11d, 0xFF000000 
            xor r10, r10                    ;ponemos a r10 en 0 por si tiene basura
            mov r10d, r12d                  ;iniciamos a r10 en i pues la matriz inicia en i+1
            inc r10d                        ;le sumamos uno a r10

            ;queremos acceder a la posicion de memoria [rsi + i*r9 + j*4]

            mov rax, r10                    ;ponemos a r10(ii) en rax
            mul r9d                         ;lo multiplicmos por la parte baja de r9 que contiene el row size
            add rax, rsi                    ;ahora sumamos la multiplicacion a rsi 

            ;ponemos el pixel max en los 4 pixeles de la matriz 2x2
            pinsrd xmm2, r11d, 0
            pinsrd xmm2, r11d, 1
            movq r11, xmm2

            mov r10, r13                    ;movemos j a r10    
            inc r10                         ;le sumamos 1 a j, para empezar en j+1
            mov [rax + r10*4], r11          ;lo ponemos en el (0,0) de la matriz                        
            add rax, r9                     ;pasamos a la siguiente fila  
            mov [rax + r10*4], r11          ;lo ponemos en el (1,0) de la matriz

    .finW:
    add r13d, 2 ;increseamos la j en 2
    jmp .cicloW ;empezamos de nuevo el ciclo

.finH:
add r12d, 2 ;increseamos la i en 2
jmp .cicloH ;empezamos de nuevo el ciclo

;antes de terminar ponemos el padding en los bordes
.fin:
xor r10, r10         ;volvemos a poner el contador en cero
xor r15, r15         ;ponemos en 0 a r15 ya que lo vamos a usar para el color blanco
xor r12, r12
xor r13, r13

mov r15d, [blanco]
mov r12d, ecx       ;height
mov r13d, ebx       ;width

;guardamos en rax la direccion de comienzo de la ultima fila

inc r12                         ;necesitamos la altura - 1 para acceder a la ultima fila
mov rax, r12                    ;ponemos a height en rax
mul r9                          ;lo multiplicmos por la parte baja de r9 que contiene el row size
add rax, rsi                    ;ahora sumamos la multiplicacion a rsi

mov ecx, r13d                   ;ponemos ancho - 2 en el contador
add ecx, 2                      ;volvemos a tener el ancho original

.paddingHorizontal:
mov [rsi + r10*4], r15d         ;ponemos blanco en el pixel de la primera fila
mov [rax + r10*4], r15d         ;ponemos blanco en el pixel de la ultima fila
inc r10                         ;incresemos r10 para continuar a la siguiente columna
loop .paddingHorizontal

mov ecx, r12d                   ;ponemos la altura - 1 en el contador
inc ecx                         ;le sumamos 1 para vover a la altura original
xor r10, r10                    ;vaciamos r10    

.paddingVertical:
mov [rsi + r10], r15d           ;ponemos blanco en el pixel de la primer columna
add r10, r9                     ;nos movemos hasta la siguiente fila
mov [rsi + r10 - 4], r15d       ;ponemos blanco en el pixel de la ultima columna
loop .paddingVertical

pop rbx
pop r15
pop r13
pop r12
pop rbp
ret