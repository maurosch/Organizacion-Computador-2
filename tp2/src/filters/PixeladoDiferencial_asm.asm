section .text

;ACLARACION IMPLEMENTACION:
;EN TODOS LOS COMENTARIOS SE MUESTRA QUE SE LEVANTAN
;DE MEMORIA ABGR EN ESE ORDEN, PERO EL ORDEN CORRECTO ES BGRA.
;ESTO NO MODIFICA EN NADA AL ALGORITMO, PERO SI A LOS COMENTARIOS.

extern PixeladoDiferencial_c
global PixeladoDiferencial_asm

PixeladoDiferencial_asm:
    %ifdef ROLINGA
        jmp PixeladoDiferencialDesenrollandoLoops_asm
        ret
    %else
        %ifdef EXPERIMENTO_ACCESOS_MEMORIA
            jmp PixeladoDiferencialAccesosMemoria_asm
            ret
        %else
            %ifdef EXPERIMENTO_ACCESOS_MEMORIA_CLFLUSH
                jmp PixeladoDiferencialAccesosMemoriaClflush_asm
                ret
            %else
                %ifdef EXPERIMENTO_ACCESOS_MEMORIA_CLFLUSH_2
                    jmp PixeladoDiferencialAccesosMemoriaClflush2_asm
                    ret
                %endif
            %endif
        %endif
    %endif
    ;rdi = uint8_t *src,
    ;rsi = uint8_t *dst,
    ;edx = int width,
    ;ecx = int height,
    ;R8d  = int src_row_size,
    ;R9d  = int dst_row_size,
    ;DWORD [RBP + 16] = int limit)

    push rbp        ;STACKFRAME
    mov  rbp,rsp    ;STACKFRAME
    push rbx        ;STACKFRAME
    push r12        ;STACKFRAME
    push r13        ;STACKFRAME
    push r14        ;STACKFRAME
    push r15        ;STACKFRAME
    sub rsp, 8      ;STACKFRAME

    %define PTR_ESQUINA_KERNEL rdi
    %define PTR_ESQUINA_KERNEL_AUX r13
    %define PTR_ESQUINA_KERNEL_DESTINO rsi
    %define PTR_ESQUINA_KERNEL_DESTINO_AUX r14
    %define DIFERENCIA r12d
    ;%define LIMITE WORD [rbp+16]
    %define ROW_SIZE r8
 
    sar ecx, 2 
    sar edx, 2
    mov r10d, ecx 
    
    .cicloFilas:
        mov r11d, edx

        .cicloColumnas:
            ;--------(1) Promedio de pixeles--------
            pxor xmm0, xmm0         ;acumulador de promedio xmm0 = |0|0|0|0|0|0|0|0|
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            .cicloPromedio:
                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                pmovzxbw xmm2, xmm1 ; packed zero byte to word
                paddw xmm0, xmm2    ; xmm0 += xmm1
                psrldq xmm1, 8      ; shift mitad del registro a la derecha
                pmovzxbw xmm2, xmm1 ; packed zero byte to word
                paddw xmm0, xmm2    ; xmm0 += xmm1

                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            loop .cicloPromedio

            ; Tenemos xmm0 = |R1|G1|B1|A1|R2|G2|B2|A2|
            movdqa xmm1, xmm0   ; xmm1 = xmm2   
            psrldq xmm1, 8      ; xmm1 = |0|0|0|0|R1|G1|B1|A1|
            paddw xmm0, xmm1    ; xmm0 = |*|*|*|*|R|G|B|A| la sumatoria de cada uno

            pslldq xmm0, 8      ; xmm0 = |R|G|B|A|0|0|0|0|
            movdqa xmm1, xmm0   ; xmm1 = xmm0
            psrldq xmm0, 8      ; xmm0 = |0|0|0|0|R|G|B|A|
            paddw xmm0, xmm1    ; xmm0 = |R|G|B|A|R|G|B|A| la sumatoria de cada uno

            psrlw xmm0, 4       ; xmm0 = |PR|PG|PB|PA|PR|PG|PB|PA| dividimos por 16 (osea shifteo cada word)
            

            ;--------(2) Calculo de diferencia--------
            pxor xmm2, xmm2 ; Contador de diferencias con promedio
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            .cicloDiferencia:
                movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 

                pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
                psubw xmm1, xmm0    ; xmm1 = datos - promedio  
                pabsw xmm1, xmm1    ; Valor abs
                paddw xmm2, xmm1    ; suma diferencia

                psrldq xmm3, 8      ; shift mitad del registro a la derecha
                pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad

                psubw xmm1, xmm0    ; xmm1 = datos - promedio  
                pabsw xmm1, xmm1    ; Valor abs
                paddw xmm2, xmm1    ; suma diferencia

                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            loop .cicloDiferencia


            ;          Tenemos xmm2 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            ;          SUMAMOS HORIZONTALMENTE MEDIANTE SHIFTEOS Y SUMAS VERTICALES

            movdqa xmm1, xmm2; xmm1 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            psrldq xmm1, 8   ; xmm1 = |  0   |  0   |  0   |  0   |dif2 r|dif2 g|dif2 b|dif2 a| 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | No nos importa dif a porque es 0
            psrldq xmm1, 4   ; xmm1 = |  0   |  0   |  *   |  *   |   *  |   *  |dif r |dif g | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 |
            psrldq xmm1, 2   ; xmm1 = |  0   |  *   |  *   |  *   |   *  |   *  |   *  |dif 3 | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |   *  |dif t | 
            
            pextrw r12d, xmm2, 0

            ;--------(3) Aplicacion segun umbral--------
            cmp r12d, DWORD [rbp+16] ;LIMITE
            ;cmp r12d, WORD [rbp+16]
            jge .aplicar
                ;copiar
                mov rcx, 4
                mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                .cicloCopia:
                    movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                    movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1

                    lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                    lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                loop .cicloCopia
                jmp .final
            
            .aplicar:
                packuswb xmm0, xmm0 ;EMPAQUETO DE NUEVO LOS DATOS

                mov rcx, 4
                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                .cicloAplicar:
                    movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0

                    lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                loop .cicloAplicar

            .final:

            lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+16]
            lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+16]
            dec r11d
            cmp r11d, 0
        jnz .cicloColumnas

    sub PTR_ESQUINA_KERNEL_DESTINO, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+ROW_SIZE*4] ;Nos movemos 3 filas para abajo
    sub PTR_ESQUINA_KERNEL, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+ROW_SIZE*4]
    dec r10d
    cmp r10d, 0 ;PROBLEMA CUANDO ALTURA NO SEA MULTIPLO DE 4
    jg .cicloFilas
    ;puede ser que queden filas al final menor q 4
    
    add rsp, 8     ;STACKFRAME
    pop r15        ;STACKFRAME
    pop r14        ;STACKFRAME         
    pop r13        ;STACKFRAME
    pop r12        ;STACKFRAME
    pop rbx        ;STACKFRAME
    pop rbp        ;STACKFRAME
    ret



;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;------------------------EXPERIMENTO ACCESOS MEMORIA--------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
PixeladoDiferencialAccesosMemoria_asm:
    push rbp        ;STACKFRAME
    mov  rbp,rsp    ;STACKFRAME
    push rbx        ;STACKFRAME
    push r12        ;STACKFRAME
    push r13        ;STACKFRAME
    push r14        ;STACKFRAME
    push r15        ;STACKFRAME
    sub rsp, 8      ;STACKFRAME

    %define PTR_ESQUINA_KERNEL rdi
    %define PTR_ESQUINA_KERNEL_AUX r13
    %define PTR_ESQUINA_KERNEL_DESTINO rsi
    %define PTR_ESQUINA_KERNEL_DESTINO_AUX r14
    %define DIFERENCIA r12d
    ;%define LIMITE WORD [rbp+16]
    %define ROW_SIZE r8
 
    sar ecx, 2 
    sar edx, 2
    mov r10d, ecx 
    
    .cicloFilas:
        mov r11d, edx

        .cicloColumnas:
            ;--------(1) Promedio de pixeles--------
            pxor xmm0, xmm0         ;acumulador de promedio xmm0 = |0|0|0|0|0|0|0|0|
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            movdqa xmm6, [PTR_ESQUINA_KERNEL_AUX]
            movdqa xmm7, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm8, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE*2]
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm9, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE*2]

            movdqa xmm1, xmm6
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1

            movdqa xmm1, xmm7
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1

            movdqa xmm1, xmm8
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1

            movdqa xmm1, xmm9
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1


            ; Tenemos xmm0 = |R1|G1|B1|A1|R2|G2|B2|A2|
            movdqa xmm1, xmm0   ; xmm1 = xmm2   
            psrldq xmm1, 8      ; xmm1 = |0|0|0|0|R1|G1|B1|A1|
            paddw xmm0, xmm1    ; xmm0 = |*|*|*|*|R|G|B|A| la sumatoria de cada uno
            pslldq xmm0, 8      ; xmm0 = |R|G|B|A|0|0|0|0|
            movdqa xmm1, xmm0   ; xmm1 = xmm0
            psrldq xmm0, 8      ; xmm0 = |0|0|0|0|R|G|B|A|
            paddw xmm0, xmm1    ; xmm0 = |R|G|B|A|R|G|B|A| la sumatoria de cada uno
            psrlw xmm0, 4       ; xmm0 = |PR|PG|PB|PA|PR|PG|PB|PA| dividimos por 16 (osea shifteo cada word)
            

            ;--------(2) Calculo de diferencia--------
            pxor xmm2, xmm2 ; Contador de diferencias con promedio
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            
            movdqa xmm3, xmm6
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia

            movdqa xmm3, xmm7
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            
            movdqa xmm3, xmm8
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            
            movdqa xmm3, xmm9
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia


            ;          Tenemos xmm2 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            ;          SUMAMOS HORIZONTALMENTE MEDIANTE SHIFTEOS Y SUMAS VERTICALES

            movdqa xmm1, xmm2; xmm1 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            psrldq xmm1, 8   ; xmm1 = |  0   |  0   |  0   |  0   |dif2 r|dif2 g|dif2 b|dif2 a| 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | No nos importa dif a porque es 0
            psrldq xmm1, 4   ; xmm1 = |  0   |  0   |  *   |  *   |   *  |   *  |dif r |dif g | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 |
            psrldq xmm1, 2   ; xmm1 = |  0   |  *   |  *   |  *   |   *  |   *  |   *  |dif 3 | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |   *  |dif t | 
            
            pextrw r12d, xmm2, 0

            ;--------(3) Aplicacion segun umbral--------
            cmp r12d, DWORD [rbp+16] ;LIMITE
            ;cmp r12d, WORD [rbp+16]
            jge .aplicar
                ;copiar
                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm6
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE], xmm7
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE*2], xmm8
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE*2], xmm9

                jmp .final
            
            .aplicar:
                packuswb xmm0, xmm0 ;EMPAQUETO DE NUEVO LOS DATOS

                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0

            .final:

            lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+16]
            lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+16]
            dec r11d
            cmp r11d, 0
        jnz .cicloColumnas

    sub PTR_ESQUINA_KERNEL_DESTINO, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+ROW_SIZE*4] ;Nos movemos 3 filas para abajo
    sub PTR_ESQUINA_KERNEL, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+ROW_SIZE*4]
    dec r10d
    cmp r10d, 0 ;PROBLEMA CUANDO ALTURA NO SEA MULTIPLO DE 4
    jg .cicloFilas
    ;puede ser que queden filas al final menor q 4
    
    add rsp, 8     ;STACKFRAME
    pop r15        ;STACKFRAME
    pop r14        ;STACKFRAME         
    pop r13        ;STACKFRAME
    pop r12        ;STACKFRAME
    pop rbx        ;STACKFRAME
    pop rbp        ;STACKFRAME
    ret



;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;---------------------EXPERIMENTO ACCESOS MEMORIA CLFLUSH---------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
PixeladoDiferencialAccesosMemoriaClflush_asm:
    push rbp        ;STACKFRAME
    mov  rbp,rsp    ;STACKFRAME
    push rbx        ;STACKFRAME
    push r12        ;STACKFRAME
    push r13        ;STACKFRAME
    push r14        ;STACKFRAME
    push r15        ;STACKFRAME
    sub rsp, 8      ;STACKFRAME

    %define PTR_ESQUINA_KERNEL rdi
    %define PTR_ESQUINA_KERNEL_AUX r13
    %define PTR_ESQUINA_KERNEL_DESTINO rsi
    %define PTR_ESQUINA_KERNEL_DESTINO_AUX r14
    %define DIFERENCIA r12d
    ;%define LIMITE WORD [rbp+16]
    %define ROW_SIZE r8
 
    sar ecx, 2 
    sar edx, 2
    mov r10d, ecx 
    
    .cicloFilas:
        mov r11d, edx

        .cicloColumnas:
            ;--------(1) Promedio de pixeles--------
            pxor xmm0, xmm0         ;acumulador de promedio xmm0 = |0|0|0|0|0|0|0|0|
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1


            ; Tenemos xmm0 = |R1|G1|B1|A1|R2|G2|B2|A2|
            movdqa xmm1, xmm0   ; xmm1 = xmm2   
            psrldq xmm1, 8      ; xmm1 = |0|0|0|0|R1|G1|B1|A1|
            paddw xmm0, xmm1    ; xmm0 = |*|*|*|*|R|G|B|A| la sumatoria de cada uno
            pslldq xmm0, 8      ; xmm0 = |R|G|B|A|0|0|0|0|
            movdqa xmm1, xmm0   ; xmm1 = xmm0
            psrldq xmm0, 8      ; xmm0 = |0|0|0|0|R|G|B|A|
            paddw xmm0, xmm1    ; xmm0 = |R|G|B|A|R|G|B|A| la sumatoria de cada uno
            psrlw xmm0, 4       ; xmm0 = |PR|PG|PB|PA|PR|PG|PB|PA| dividimos por 16 (osea shifteo cada word)
            

            ;--------(2) Calculo de diferencia--------
            pxor xmm2, xmm2 ; Contador de diferencias con promedio
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            
            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]

            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]

            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]

            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia


            ;          Tenemos xmm2 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            ;          SUMAMOS HORIZONTALMENTE MEDIANTE SHIFTEOS Y SUMAS VERTICALES

            movdqa xmm1, xmm2; xmm1 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            psrldq xmm1, 8   ; xmm1 = |  0   |  0   |  0   |  0   |dif2 r|dif2 g|dif2 b|dif2 a| 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | No nos importa dif a porque es 0
            psrldq xmm1, 4   ; xmm1 = |  0   |  0   |  *   |  *   |   *  |   *  |dif r |dif g | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 |
            psrldq xmm1, 2   ; xmm1 = |  0   |  *   |  *   |  *   |   *  |   *  |   *  |dif 3 | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |   *  |dif t | 
            
            pextrw r12d, xmm2, 0

            ;--------(3) Aplicacion segun umbral--------
            cmp r12d, DWORD [rbp+16] ;LIMITE
            ;cmp r12d, WORD [rbp+16]
            jge .aplicar
                ;copiar
                mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO

                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]

                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]

                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE


                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]

                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

                
                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1

                jmp .final
            
            .aplicar:
                packuswb xmm0, xmm0 ;EMPAQUETO DE NUEVO LOS DATOS

                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0

            .final:

            lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+16]
            lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+16]
            dec r11d
            cmp r11d, 0
        jnz .cicloColumnas

    sub PTR_ESQUINA_KERNEL_DESTINO, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+ROW_SIZE*4] ;Nos movemos 3 filas para abajo
    sub PTR_ESQUINA_KERNEL, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+ROW_SIZE*4]
    dec r10d
    cmp r10d, 0 ;PROBLEMA CUANDO ALTURA NO SEA MULTIPLO DE 4
    jg .cicloFilas
    ;puede ser que queden filas al final menor q 4
    
    add rsp, 8     ;STACKFRAME
    pop r15        ;STACKFRAME
    pop r14        ;STACKFRAME         
    pop r13        ;STACKFRAME
    pop r12        ;STACKFRAME
    pop rbx        ;STACKFRAME
    pop rbp        ;STACKFRAME
    ret



;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-------------------EXPERIMENTO ACCESOS MEMORIA CLFLUSH 2---------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
PixeladoDiferencialAccesosMemoriaClflush2_asm:
    push rbp        ;STACKFRAME
    mov  rbp,rsp    ;STACKFRAME
    push rbx        ;STACKFRAME
    push r12        ;STACKFRAME
    push r13        ;STACKFRAME
    push r14        ;STACKFRAME
    push r15        ;STACKFRAME
    sub rsp, 8      ;STACKFRAME

    %define PTR_ESQUINA_KERNEL rdi
    %define PTR_ESQUINA_KERNEL_AUX r13
    %define PTR_ESQUINA_KERNEL_DESTINO rsi
    %define PTR_ESQUINA_KERNEL_DESTINO_AUX r14
    %define DIFERENCIA r12d
    ;%define LIMITE WORD [rbp+16]
    %define ROW_SIZE r8
 
    sar ecx, 2 
    sar edx, 2
    mov r10d, ecx 
    
    .cicloFilas:
        mov r11d, edx

        .cicloColumnas:
            ;--------(1) Promedio de pixeles--------
            pxor xmm0, xmm0         ;acumulador de promedio xmm0 = |0|0|0|0|0|0|0|0|
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            movdqa xmm6, [PTR_ESQUINA_KERNEL_AUX]
            movdqa xmm7, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm8, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE*2]
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm9, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE*2]

            movdqa xmm1, xmm6
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1

            movdqa xmm1, xmm7
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1

            movdqa xmm1, xmm8
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1

            movdqa xmm1, xmm9
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1


            ; Tenemos xmm0 = |R1|G1|B1|A1|R2|G2|B2|A2|
            movdqa xmm1, xmm0   ; xmm1 = xmm2   
            psrldq xmm1, 8      ; xmm1 = |0|0|0|0|R1|G1|B1|A1|
            paddw xmm0, xmm1    ; xmm0 = |*|*|*|*|R|G|B|A| la sumatoria de cada uno
            pslldq xmm0, 8      ; xmm0 = |R|G|B|A|0|0|0|0|
            movdqa xmm1, xmm0   ; xmm1 = xmm0
            psrldq xmm0, 8      ; xmm0 = |0|0|0|0|R|G|B|A|
            paddw xmm0, xmm1    ; xmm0 = |R|G|B|A|R|G|B|A| la sumatoria de cada uno
            psrlw xmm0, 4       ; xmm0 = |PR|PG|PB|PA|PR|PG|PB|PA| dividimos por 16 (osea shifteo cada word)
            

            ;--------(2) Calculo de diferencia--------
            pxor xmm2, xmm2 ; Contador de diferencias con promedio
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            
            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

            movdqa xmm3, xmm6
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia

            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

            movdqa xmm3, xmm7
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia

            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE
            
            movdqa xmm3, xmm8
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia

            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE
            
            movdqa xmm3, xmm9
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia


            ;          Tenemos xmm2 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            ;          SUMAMOS HORIZONTALMENTE MEDIANTE SHIFTEOS Y SUMAS VERTICALES

            movdqa xmm1, xmm2; xmm1 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            psrldq xmm1, 8   ; xmm1 = |  0   |  0   |  0   |  0   |dif2 r|dif2 g|dif2 b|dif2 a| 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | No nos importa dif a porque es 0
            psrldq xmm1, 4   ; xmm1 = |  0   |  0   |  *   |  *   |   *  |   *  |dif r |dif g | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 |
            psrldq xmm1, 2   ; xmm1 = |  0   |  *   |  *   |  *   |   *  |   *  |   *  |dif 3 | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |   *  |dif t | 
            
            pextrw r12d, xmm2, 0

            ;--------(3) Aplicacion segun umbral--------
            cmp r12d, DWORD [rbp+16] ;LIMITE
            ;cmp r12d, WORD [rbp+16]
            jge .aplicar
                ;copiar
                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE
                
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm6

                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE], xmm7

                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE*2], xmm8
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]

                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                CLFLUSH [PTR_ESQUINA_KERNEL_AUX] ;<--------------------- FLUSH CACHE

                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE*2], xmm9

                jmp .final
            
            .aplicar:
                packuswb xmm0, xmm0 ;EMPAQUETO DE NUEVO LOS DATOS

                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0

            .final:

            lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+16]
            lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+16]
            dec r11d
            cmp r11d, 0
        jnz .cicloColumnas

    sub PTR_ESQUINA_KERNEL_DESTINO, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+ROW_SIZE*4] ;Nos movemos 3 filas para abajo
    sub PTR_ESQUINA_KERNEL, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+ROW_SIZE*4]
    dec r10d
    cmp r10d, 0 ;PROBLEMA CUANDO ALTURA NO SEA MULTIPLO DE 4
    jg .cicloFilas
    ;puede ser que queden filas al final menor q 4
    
    add rsp, 8     ;STACKFRAME
    pop r15        ;STACKFRAME
    pop r14        ;STACKFRAME         
    pop r13        ;STACKFRAME
    pop r12        ;STACKFRAME
    pop rbx        ;STACKFRAME
    pop rbp        ;STACKFRAME
    ret



;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------EXPERIMENTO DESENROLLANDO LOOPS-----------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
PixeladoDiferencialDesenrollandoLoops_asm:
    push rbp        ;STACKFRAME
    mov  rbp,rsp    ;STACKFRAME
    push rbx        ;STACKFRAME
    push r12        ;STACKFRAME
    push r13        ;STACKFRAME
    push r14        ;STACKFRAME
    push r15        ;STACKFRAME
    sub rsp, 8      ;STACKFRAME

    %define PTR_ESQUINA_KERNEL rdi
    %define PTR_ESQUINA_KERNEL_AUX r13
    %define PTR_ESQUINA_KERNEL_DESTINO rsi
    %define PTR_ESQUINA_KERNEL_DESTINO_AUX r14
    %define DIFERENCIA r12d
    ;%define LIMITE WORD [rbp+16]
    %define ROW_SIZE r8
 
    sar ecx, 2 
    sar edx, 2
    mov r10d, ecx 
    
    .cicloFilas:
        mov r11d, edx

        .cicloColumnas:
            ;--------(1) Promedio de pixeles--------
            pxor xmm0, xmm0         ;acumulador de promedio xmm0 = |0|0|0|0|0|0|0|0|
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1
            psrldq xmm1, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm2, xmm1 ; packed zero byte to word
            paddw xmm0, xmm2    ; xmm0 += xmm1


            ; Tenemos xmm0 = |R1|G1|B1|A1|R2|G2|B2|A2|
            movdqa xmm1, xmm0   ; xmm1 = xmm2   
            psrldq xmm1, 8      ; xmm1 = |0|0|0|0|R1|G1|B1|A1|
            paddw xmm0, xmm1    ; xmm0 = |*|*|*|*|R|G|B|A| la sumatoria de cada uno
            pslldq xmm0, 8      ; xmm0 = |R|G|B|A|0|0|0|0|
            movdqa xmm1, xmm0   ; xmm1 = xmm0
            psrldq xmm0, 8      ; xmm0 = |0|0|0|0|R|G|B|A|
            paddw xmm0, xmm1    ; xmm0 = |R|G|B|A|R|G|B|A| la sumatoria de cada uno
            psrlw xmm0, 4       ; xmm0 = |PR|PG|PB|PA|PR|PG|PB|PA| dividimos por 16 (osea shifteo cada word)
            

            ;--------(2) Calculo de diferencia--------
            pxor xmm2, xmm2 ; Contador de diferencias con promedio
            mov rcx, 4
            mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
            
            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
            movdqa xmm3, [PTR_ESQUINA_KERNEL_AUX] 
            pmovzxbw xmm1, xmm3 ; desempaquetamos primer mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia
            psrldq xmm3, 8      ; shift mitad del registro a la derecha
            pmovzxbw xmm1, xmm3 ; desempaquetamos segunda mitad
            psubw xmm1, xmm0    ; xmm1 = datos - promedio  
            pabsw xmm1, xmm1    ; Valor abs
            paddw xmm2, xmm1    ; suma diferencia


            ;          Tenemos xmm2 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            ;          SUMAMOS HORIZONTALMENTE MEDIANTE SHIFTEOS Y SUMAS VERTICALES

            movdqa xmm1, xmm2; xmm1 = |dif1 r|dif1 g|dif1 b|dif1 a|dif2 r|dif2 g|dif2 b|dif2 a| 
            psrldq xmm1, 8   ; xmm1 = |  0   |  0   |  0   |  0   |dif2 r|dif2 g|dif2 b|dif2 a| 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |dif r |dif g |dif b |dif a | No nos importa dif a porque es 0
            psrldq xmm1, 4   ; xmm1 = |  0   |  0   |  *   |  *   |   *  |   *  |dif r |dif g | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 | 

            movdqa xmm1, xmm2; xmm1 = |  *   |  *   |  *   |  *   |   *  |   *  |dif 3 |dif 4 |
            psrldq xmm1, 2   ; xmm1 = |  0   |  *   |  *   |  *   |   *  |   *  |   *  |dif 3 | 
            paddw xmm2, xmm1 ; xmm2 = |  *   |  *   |  *   |  *   |   *  |   *  |   *  |dif t | 
            
            pextrw r12d, xmm2, 0

            ;--------(3) Aplicacion segun umbral--------
            cmp r12d, DWORD [rbp+16] ;LIMITE
            ;cmp r12d, WORD [rbp+16]
            jge .aplicar
                ;copiar
                mov PTR_ESQUINA_KERNEL_AUX, PTR_ESQUINA_KERNEL
                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1
                lea PTR_ESQUINA_KERNEL_AUX, [PTR_ESQUINA_KERNEL_AUX+ROW_SIZE]
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa xmm1, [PTR_ESQUINA_KERNEL_AUX]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm1

                jmp .final
            
            .aplicar:
                packuswb xmm0, xmm0 ;EMPAQUETO DE NUEVO LOS DATOS

                mov PTR_ESQUINA_KERNEL_DESTINO_AUX, PTR_ESQUINA_KERNEL_DESTINO
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0
                lea PTR_ESQUINA_KERNEL_DESTINO_AUX, [PTR_ESQUINA_KERNEL_DESTINO_AUX+ROW_SIZE]
                movdqa [PTR_ESQUINA_KERNEL_DESTINO_AUX], xmm0

            .final:

            lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+16]
            lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+16]
            dec r11d
            cmp r11d, 0
        jnz .cicloColumnas

    sub PTR_ESQUINA_KERNEL_DESTINO, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL_DESTINO, [PTR_ESQUINA_KERNEL_DESTINO+ROW_SIZE*4] ;Nos movemos 3 filas para abajo
    sub PTR_ESQUINA_KERNEL, ROW_SIZE ;Lo volvemos al principio de la fila
    lea PTR_ESQUINA_KERNEL, [PTR_ESQUINA_KERNEL+ROW_SIZE*4]
    dec r10d
    cmp r10d, 0 ;PROBLEMA CUANDO ALTURA NO SEA MULTIPLO DE 4
    jg .cicloFilas
    ;puede ser que queden filas al final menor q 4
    
    add rsp, 8     ;STACKFRAME
    pop r15        ;STACKFRAME
    pop r14        ;STACKFRAME         
    pop r13        ;STACKFRAME
    pop r12        ;STACKFRAME
    pop rbx        ;STACKFRAME
    pop rbp        ;STACKFRAME
    ret
