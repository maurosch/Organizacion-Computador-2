section .rodata

blanco   : dd 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF
white 	 : db 255, 255, 255, 255

section .text

extern ColorBordes_c
global ColorBordes_asm

ColorBordes_asm:

;rdi = uint8_t *src,
;rsi = uint8_t *dst,
;edx = int width,
;ecx = int height,
;R8d  = int src_row_size,
;R9d  = int dst_row_size,

	push rbp
	mov rbp, rsp
	sub rsp, 8
	push rbx
	push r12
	push r13
	push r15

	and r8, 0x0000FFFF  ;extiendo row_size

	mov r10, rdi        ;pixel src
	add r10, r8
	add r10, 4          ;empiezo en el (1,1)

	mov r11, rsi        ;pixel dst
	add r11, r8
	movdqu xmm8, [white]
	movd [r11], xmm8    ;un pixel blanco 
	add r11, 4          ;empiezo en el (1,1)

	mov r12d, 1         ;r12d = contador de columnas 	
	mov r13d, 2         ;r13d = contador de filas

	shr edx, 1          ;edx >> 1 divido width a la mitad porque me muevo de a 2 pixeles

.ciclo:
	mov rbx, r10
	sub rbx, r8
	sub rbx, 4

	movdqu xmm0, [rbx] 			;xmm0 = |4 |3 |2 |1 |
	movdqu xmm1, [rbx + r8]		;xmm1 = |8 |7 |6 |5 |
	movdqu xmm2, [rbx + 2*r8]	;xmm2 = |12|11|10|9 |

    pmovzxbw xmm3, xmm0         ;xmm3 = |2|1|
    psrldq xmm0, 8
    pmovzxbw xmm4, xmm0         ;xmm4 = |4|3|

    pmovzxbw xmm5, xmm1         ;xmm5 = |6|5|
    psrldq xmm1, 8
    pmovzxbw xmm6, xmm1         ;xmm6 = |8|7|
    
    pmovzxbw xmm7, xmm2         ;xmm7 = |10|9|
    psrldq xmm2, 8
    pmovzxbw xmm8, xmm2         ;xmm8 = |12|11|

    movdqa xmm0, xmm3
    psubw xmm0, xmm4            ;xmm0 = | 2 - 4 | 1 - 3 | 

    movdqa xmm1, xmm5
    psubw xmm1, xmm6            ;xmm1 = | 6 - 8 | 5 - 7 |

    movdqa xmm2, xmm7
    psubw xmm2, xmm8            ;xmm2 = |10 - 12| 9 - 11|

    psubw xmm3, xmm7            ;xmm3 = | 2 - 10| 1 - 9 |
    psubw xmm4, xmm8            ;xmm4 = | 4 - 12| 3 - 11|

    pabsw xmm0, xmm0            ;Tomo abs
    pabsw xmm1, xmm1            ;Tomo abs
    pabsw xmm2, xmm2            ;Tomo abs
    pabsw xmm3, xmm3            ;Tomo abs
    pabsw xmm4, xmm4            ;Tomo abs

    paddusw xmm0, xmm1
    paddusw xmm0, xmm2          ;xmm0 = |DIF HORIZONTALES PIXEL 2|DIF HORIZONTALES PIXEL 1|

    movdqa xmm5, xmm4           ;xmm5 = xmm4 = |4-12|3-11|
    pslldq xmm5, 8              ;xmm5 = |3-11|0|
    paddusw xmm5, xmm4          ;xmm5 = |3-11 + 4-12|*|
    paddusw xmm5, xmm3          ;xmm5 = |3-11 + 4-12 + 2-10|*|
    movdqa xmm1, xmm0           ;xmm1 = xmm0 = |DIF HORIZONTALES PIXEL 2|DIF HORIZONTALES PIXEL 1|
    paddusw xmm5, xmm1          ;xmm5 = |3-11 + 4-12 + 2-10 + DIF HORIZONTALES PIXEL 2|*|

    packuswb xmm5, xmm5         ;xmm5 = |3-11 + 4-12 + 2-10 + DIF HORIZONTALES PIXEL 2|*|*|*|
    pextrd r15d, xmm5, 3        
    or r15d, 0xFF000000         ;seteamos alpha a 255
	mov [r11 + 4], r15d

    movdqa xmm5, xmm3           ;xmm5 = xmm3 = |2-10|1-9|
    psrldq xmm5, 8              ;xmm5 = |0|2-10|
    paddusw xmm5, xmm3          ;xmm5 = |*|2-10 + 1-9|
    paddusw xmm5, xmm4          ;xmm5 = |*|2-10 + 1-9 + 3-11|
    movdqa xmm1, xmm0           ;xmm1 = xmm0 = |DIF HORIZONTALES PIXEL 2|DIF HORIZONTALES PIXEL 1|
    paddusw xmm5, xmm0          ;xmm5 = |*|2-10 + 1-9 + 3-11 + DIF HORIZONTALES PIXEL 1|

    packuswb xmm5, xmm5         ;xmm5 = |*|*|*|2-10 + 1-9 + 3-11 + DIF HORIZONTALES PIXEL 1|
    pextrd r15d, xmm5, 0
    or r15d, 0xFF000000         ;seteamos alpha a 255
	mov [r11], r15d

	inc r12d
	cmp r12d, edx
	je .nuevaFila
	lea r10, [r10+8]            ;avanzo 2 pixeles SRC
	lea r11, [r11+8]            ;avanzo 2 pixeles DST
	jmp .ciclo

.nuevaFila:
	mov r12d, 1
	inc r13d
	add r10, 16
	add r11, 8
	movdqu xmm8, [blanco]
	movq [r11], xmm8            ;dos pixeles blancos
	add r11, 8
	cmp r13d, ecx
	je .bordesBlancos
	jmp .ciclo

.bordesBlancos:
    sub r11, 4
.cicloBordesBlancos:
	movq [rsi], xmm8            ;borde superior
	movq [r11], xmm8            ;borde inferior
	add rsi, 8
	add r11, 8
	inc r14d
	cmp r14d, edx
	jl .cicloBordesBlancos

    pop r15
	pop r13
	pop r12
	pop rbx
	add rsp, 8
	pop rbp
ret
