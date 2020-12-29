section .data
NULL_MSG db 'NULL', 0
STR_MSG db '%s', 0
INT_SIZE EQU 4
PTR_SIZE EQU 8
STR_PRINT db '%s', 0
ABRO_PARENTESIS db '(', 0
CIERRO_PARENTESIS_Y_FLECHA db ')->', 0
;Byte 8-bits 1byte
;Word 16-bits 2bytes
;dword 32-bits 4bytes
;qword 64-bits 8bytes
;dqword 128-bits 16bytes

section .text

extern malloc
extern free
extern fileno
extern fprintf

extern getCompareFunction
extern getCloneFunction
extern getDeleteFunction
extern getPrintFunction

extern intCmp
extern intClone
extern intDelete
extern intPrint

extern floatPrint

extern docNew
extern docCmp
extern docPrint

extern listNew
extern listRemove
extern listClone
extern listDelete
extern listPrint

extern treeNew
extern treeGet
extern treeRemove
extern treeDelete

global floatCmp
global floatClone
global floatDelete

global strClone
global strLen
global strCmp
global strDelete
global strPrint

global docClone
global docDelete

global listAdd

global treeInsert
global treePrint


%define NULL 0

;*** Float ***

floatCmp: ; rdi, rsi <- puntero float al primer parámetro
    push rbp        ;STACKFRAME
    mov rbp, rsp    ;STACKFRAME
    movss xmm0, [rdi]
    comiss xmm0, [rsi]
    mov rax, -1
    je .equal
    jc .smaller
    jmp .end
.equal:
    mov rax, 0
    jmp .end
.smaller:
    mov rax, 1
.end:
    pop rbp         ;STACKFRAME
    ret             

floatClone:
    ; float* floatClone(float* a)
    ; RDI = float* a
    push rbp
    mov rbp, rsp
    push r12
    sub rsp, 8

    mov r12, [rdi]
    mov rdi, 4
    call malloc
    mov [rax], r12d     ; Uso r12d pues el float es de 4 Bytes

    add rsp, 8
    pop r12
    pop rbp
    ret

floatDelete:
    ; void floatDelete(float* a)
    ; RDI = float* a
    push rbp
    mov rbp, rsp

    call free

    pop rbp
    ret

;*** String ***

strClone:
    ; char* strClone(char* a)
    ; RDI = char*
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push rbx

    mov r12, rdi
    call strLen
    mov r13, rax

    mov rdi, r13
    inc rdi
    call malloc

    mov r14, rax
    xor rbx, rbx

.loop:
    cmp rbx, r13
    je .fin
    mov r8b, [r12 + rbx]
    mov [r14 + rbx], r8b
    inc rbx
    jmp .loop

.fin:
    mov BYTE [r14 + rbx], 0
    pop rbx
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

strLen:
    push rbp
    mov rbp, rsp
    
    mov rax, 0

.loop:
    cmp BYTE [rdi], 0
    je .end
    inc rdi
    inc rax
    jmp .loop

.end:
    pop rbp
    ret

strCmp:
    ; int32_t strCmp(char* a, char* b)
    ; a == b -> 0
    ; a < b -> 1
    ; a > b -> -1
    ; a -> rdi
    ; b -> rsi

    ; Armo el Stack Frame
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15

    ; Calculo los largos de las palabras
    mov r12, rdi        ; r12 = a
    mov r13, rsi        ; r13 = b
    call strLen
    mov r14, rax         ; r14 = strLen(a)
    mov rdi, r13
    call strLen
    mov r15, rax         ; r15 = strLen(b)
    
    ; Preparo los registros para el ciclo
    xor rax, rax        ; rax = 0
    cmp r14, r15        ; Veo cual es mas larga y guardo ese largo en rcx
    jg .aEsMasLarga
    mov rcx, r15

.loop:
    cmp rcx, 0
    je .end
    mov r8b, [r12]
    mov r9b, [r13]
    cmp r8b, r9b
    jl .aEsMasChica
    jg .aEsMasGrande
    inc r12
    inc r13
    dec rcx
    jmp .loop

.aEsMasLarga:
    mov rcx, r14
    jmp .loop

.aEsMasChica:
    mov rax, 1
    jmp .end

.aEsMasGrande:
    mov rax, -1
    jmp .end

    ; Desarmo el stack frame
.end:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

strDelete:
    ; void floatDelete(float* a)
    ; RDI = char* a
    push rbp
    mov rbp, rsp

    call free

    pop rbp
    ret

strPrint:
    ;void strPrint(char* a, FILE *pFile)
    ; RDI = char* a
    ; RSI = FILE* pFile
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi            ; r12 = a
    mov r13, rsi            ; r13 = pFile
    call strLen             ; rax = strLen(a)
    cmp DWORD eax, 0        ; if (strLen(a) == 0) -> print NULL
    jne .noEsVacio
    mov rdi, r13            ; rdi = pFile
    mov rsi, NULL_MSG       ; rsi = 'NULL'
    mov rdx, r12            ; rdx = a
    call fprintf

.noEsVacio:
    mov rdi, r13        ; rdi = pFile
    mov rsi, STR_PRINT  ; rsi = "%s"
    mov rdx, r12        ; rdx = a

    call fprintf

    pop r13
    pop r12
    pop rbp
    ret

;*** Document ***

docClone: ; rdi <- document_t* 
    push rbp         ;STACKFRAME
    mov rbp, rsp     ;STACKFRAME
    push r12         ;STACKFRAME
    push r13
    push r14
    push r15

    %define offset_doc_count 0
    %define offset_doc_values 8

    %define offset_docElem_type 0
    %define offset_docElem_data 8

    xor r12, r12
    mov DWORD r12d, [rdi + offset_doc_count]       ; r12 = a->count
    xor r11, r11

    mov r13, [rdi+ offset_doc_values]       ; r13 = ptr a values (original) 

    mov rdi, 16         ;MEMORIA PARA LA ESTRUCTURA DE DOCUMENTO
    call malloc
    mov r15, rax                            ; r15 = ptr al doc clon
    mov [r15 + offset_doc_count], r12d      ; r15->count = a->count

    mov rdi, r12                            ; rdi = a->count
    imul rdi, 16                            ; rdi = a->count * 16 , memoria que vamos a pedir con malloc
    call malloc                             ; rax = ptr al nuevo values
    mov [r15 + offset_doc_values], rax      ; r15->values = rax

    mov r14, rax                            ; r14 = ptr al nuevo values   

.ciclo:   ;Vamos moviendonos por cada elemento del documento y clonando
    mov edi, [r13 + offset_docElem_type]    ; edi = a->values.type
    mov DWORD [r14], edi                    ; newValues = valuesOriginal

    call getCloneFunction                   ; rax = ptr a funcion clon del tipo de data
    mov rdi, [r13 + offset_docElem_data]    ; rdi = ptr a data
    call rax                                ; rax = ptr al clon de data
    mov [r14 + offset_docElem_data], rax    ; r14->data = ptr al clon de data
    
    dec r12                                 ; r12--
    cmp r12, 0                              ; if count == 0
    jz .finCiclo                            ; if count == 0 termino -- if count > 0 sigo
    lea r13, [r13 + 16]                     ; r13 = values[i + 1] (original)
    lea r14, [r14 + 16]                     ; r14 = values[i + 1] (copia)
    jmp .ciclo

.finCiclo:
    mov rax, r15                            ; rax = ptr al nuevo doc
    pop r15
    pop r14
    pop r13
    pop r12         ;STACKFRAME
    pop rbp         ;STACKFRAME
    ret

docDelete:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    ; void docDelete(document_t* a)     --> RDI = a
    %define offset_doc_count 0
    %define offset_doc_values 8

    %define offset_docElem_type 0
    %define offset_docElem_data 8
    
    mov r12, rdi                            ; r12 = a
    xor rbx, rbx                            ; rbx = 0

.loop:
    cmp DWORD ebx, [r12 + offset_doc_count] ; if (rbx >= a->count) fin -- if (rbx < a->count) stay
    jge .fin                                
    mov r13, [r12 + offset_doc_values]      ; r13 = ptr a values
    mov r8, rbx                             ; r8 = rbx
    imul r8, 16                             ; r8 = rbx * 16
    lea r14, [r13 + r8]                     ; r14 = ptr a values[i]
    mov rdi, [r14 + offset_docElem_type]    ; rdi = values[i]->type
    call getDeleteFunction                  ; rax = ptr a la funcion delete del tipo
    cmp rax, 0                              ; if (funcDel == 0) termino -- else stay
    je .loopEnd                             ; 
    mov rdi, [r14 + offset_docElem_data]    ; rdi = 
    call rax                                ; llamo a la funcion delete del tipo para liberar values[i]data

.loopEnd:
    inc rbx                                 ; rbx++
    jmp .loop                               ; volvemos a loopear

.fin:
    mov rdi, [r12 + offset_doc_values]      ; rdi = a->values
    call free                               ; liberamos a->values
    mov rdi, r12                            ; rdi = a
    call free                               ; liberamos a 
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

;*** List ***

listAdd:
    ; void listAdd(list_t* l, void* data)
    ; RDI = list_t* l
    ; RSI = void* data
    %define offset_list_type 0
    %define offset_list_size 4
    %define offset_list_first 8
    %define offset_list_last 16

    %define offset_listNode_data 0
    %define offset_listNode_next 8
    %define offset_listNode_prev 16
    
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi                                ; r12 = l
    mov rbx, rsi                                ; rbx = data
    mov rdi, 24                                 ; rdi = 24 = sizeof(listElem_t)
    call malloc                                 ; rax = list_t* newNode = malloc(24)
    mov r13, rax                                ; r13 = newNode
    mov [r13 + offset_listNode_data], rbx       ; newNode->data = data

    ; Me fijo si la lista esta vacia
    cmp DWORD [r12 + offset_list_size], 0
    jne .listaNoVacia                               ; l->size == 0 => el elemento sera first y last
    mov [r12 + offset_list_first], r13              ; l->first = newNode
    mov [r12 + offset_list_last], r13               ; l->last = newNode
    mov QWORD [r13 + offset_listNode_prev], NULL    ; newNode->prev = NULL
    mov QWORD [r13 + offset_listNode_next], NULL    ; newNode->next = NULL
    jmp .fin

.listaNoVacia:
    mov rdi, [r12 + offset_list_type]           ; rdi = l->type
    call getCompareFunction                     ; rax = funCmp_t* fComp = getCompareFunction(l->type)
    mov rbx, rax                                ; rbx = fComp

    ; Me fijo si el nuevo nodo debe ser first
    mov r14, [r12 + offset_list_first]          ; r14 = l->first
    mov rdi, [r14 + offset_listNode_data]       ; rdi = l->first->data
    mov rsi, [r13 + offset_listNode_data]       ; rsi = data
    call rbx                                    ; rax = fComp(l->first->data, data)
    cmp eax, 0
    jg .chequeoSiEsLast                               ; (rax <= 0) l->first->data >= data ==> newNode debe ser first
    mov [r14 + offset_listNode_prev], r13             ; l->first->prev = newNode
    mov QWORD [r13 + offset_listNode_prev], NULL      ; newNode->prev = NULL
    mov [r13 + offset_listNode_next], r14             ; newNode->next = l->first
    mov [r12 + offset_list_first], r13                ; l->first = newNode
    jmp .fin

.chequeoSiEsLast:
    ; Me fijo si el nuevo nodo debe ser last
    mov r14, [r12 + offset_list_last]                 ; r14 = l->last
    mov rdi, [r14 + offset_listNode_data]             ; rdi = l->last->data
    mov rsi, [r13 + offset_listNode_data]             ; rsi = data
    call rbx                                          ; rax = fComp(l->last->data, data)
    cmp eax, 0
    jl .vaEnElMedio                                   ; (rax >= 0) l->last->data <= data ==> newNode debe ser last
    mov [r14 + offset_listNode_next], r13             ; l->last->next = newNode
    mov [r13 + offset_listNode_prev], r14             ; newNode->prev = l->last
    mov QWORD [r13 + offset_listNode_next], NULL      ; newNode->next = NULL
    mov [r12 + offset_list_last], r13                 ; l->last = newNode
    jmp .fin

.vaEnElMedio:
    mov r14, [r12 + offset_list_first]          ; r14 = current = l->first
.loop:
    mov rdi, [r14 + offset_listNode_data]       ; rdi = current->data
    mov rsi, [r13 + offset_listNode_data]       ; rsi = data
    call rbx
    cmp eax, 1
    jne .fueraDelLoop
    mov r14, [r14 + offset_listNode_next]       ; r14 = r14->next ==> = current = current->next
    jmp .loop                                    ; (rax != 1) current->data >= data ==> newNode va antes que current
.fueraDelLoop:
    mov r8, [r14 + offset_listNode_prev]        ; r8 = current->prev
    mov [r8 + offset_listNode_next], r13        ; current->prev->next = newNode
    mov [r13 + offset_listNode_prev], r8        ; newNode->prev = current->prev
    mov [r13 + offset_listNode_next], r14       ; newNode->next = current
    mov [r14 + offset_listNode_prev], r13       ; current->prev = newNode

.fin:
    inc DWORD [r12 + offset_list_size]
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

;*** Tree ***

treeInsert: ; rdi: tree_t* tree, rsi: void* key, rdx: void* data
    push rbp        ;STACKFRAME
    mov rbp, rsp    ;STACKFRAME
    push rbx        ;STACKFRAME
    push r12        ;STACKFRAME
    push r13        ;STACKFRAME
    push r14        ;STACKFRAME
    push r15        ;STACKFRAME
    push rsi        ;STACKFRAME

    ; Defino offsets de tree
    %define offset_tree_first_child 0
    %define offset_tree_size 8
    %define offset_tree_typekey 12
    %define offset_tree_duplicate 16
    %define offset_tree_typeData 20

    ; Defino offsets de treeNode
    %define offset_treeNode_key 0
    %define offset_treeNode_values 8
    %define offset_treeNode_left 16
    %define offset_treeNode_right 24

    %define PUNTERO_KEY [rbp-48]
    

    mov r15, rdi   ;Nos guardamos la referencia del tree
    mov r12, [rdi] ;r12 va a ser el puntero que vamos moviendo en los nodos
    mov rbx, rdx   ;Nos guardamos el *data

    mov r13, r15
    cmp r12, 0     ;Nos fijamos si es el primero en agregar
    je .agregarNodo

    xor rdi, rdi
    mov edi, [r15+offset_tree_typekey] ;Obtenemos la funcion de cmp key
    CALL getCompareFunction
    mov r14, rax ;Nos guardamos en r14 la función de cmp de keys


.ciclo:
    mov rdi, PUNTERO_KEY
    mov rsi, [r12+offset_treeNode_key]
    CALL r14 ;fCmp
    cmp eax, 1
    je .izq 
    cmp eax, -1
    je .der

    cmp DWORD [r15+offset_tree_duplicate], 0 ;if duplicado:
    je .terminarSinAgregar
    mov r13, r12
    jmp .agregarElemAlista

.izq:
    lea r13, [r12+offset_treeNode_left]
    cmp QWORD [r12+offset_treeNode_left], 0
    je .agregarNodo ;Agregamos nodo
    
    mov r12, [r12+offset_treeNode_left]
    jmp .ciclo

.der:
    lea r13, [r12+offset_treeNode_right]
    cmp QWORD [r12+offset_treeNode_right], 0
    je .agregarNodo ;Agregamos nodo

    mov r12, [r12+offset_treeNode_right]
    jmp .ciclo

.agregarNodo: ;Agregamos nodo en el puntero r13
    mov rdi, 32
    CALL malloc
    mov [r13], rax
    mov r13, rax

    xor rdi, rdi 
    mov edi, [r15+offset_tree_typeData]
    CALL listNew
    
    mov [r13+offset_treeNode_values], rax     ;Agrego list
    mov QWORD [r13+offset_treeNode_left], 0   ;Agrego left
    mov QWORD [r13+offset_treeNode_right], 0  ;Agrego right

    ;------------------------CLONAMOS *key------------------------
    xor rdi, rdi
    mov edi, [r15+offset_tree_typekey]
    CALL getCloneFunction
    mov rdi, PUNTERO_KEY
    CALL rax
    ;-------------------------------------------------------------
    mov [r13+offset_treeNode_key], rax        ;Agrego key

.agregarElemAlista: ;Agregamos elemento al nodo apuntado por r13

    ;------------------------CLONAMOS *data------------------------
    xor rdi, rdi
    mov edi, [r15+offset_tree_typeData]  ;Clonamos *data
    CALL getCloneFunction
    mov rdi, rbx
    CALL rax
    mov rbx, rax ;Nos quedamos *data en rbx
    ;--------------------------------------------------------------

    mov rdi, [r13+offset_treeNode_values]
    mov rsi, rbx
    CALL listAdd

    mov rax, 1
    inc DWORD [r15+offset_tree_size]
    jmp .terminar

.terminarSinAgregar:
    mov rax, 0

.terminar:
    pop rsi         ;STACKFRAME
    pop r15         ;STACKFRAME
    pop r14         ;STACKFRAME
    pop r13         ;STACKFRAME
    pop r12         ;STACKFRAME
    pop rbx         ;STACKFRAME
    pop rbp         ;STACKFRAME
    ret


inorderPrint:
    ; Defino Offsets de treeNode
    %define offset_treeNode_key 0
    %define offset_treeNode_values 8
    %define offset_treeNode_left 16
    %define offset_treeNode_right 24
    
    ; void inorderPrint(treeNode_t* treeNode, FILE* pFile, type_t typeKey)
    ; RDI = treeNode_t* treeNode
    ; RSI = FILE* pFile
    ; RDX = type_t typeKey

    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    sub rsp, 8

    mov r12, rdi                            ; r12 = treeNode
    mov r13, rsi                            ; r13 = pFile
    mov r14, rdx                            ; r14 = typeKey

    cmp QWORD [r12 + offset_treeNode_left], NULL
    je .imprimirNodoActual
    mov rdi, [r12 + offset_treeNode_left]   ; rdi = treeNode->left ; rsi = pFile ; rdx = typeKey    

    call inorderPrint

.imprimirNodoActual:
    ; Imprimo los parentesis
    mov rdi, r13
    mov rsi, ABRO_PARENTESIS
    call fprintf

    ; Imprimo el valor de la key
    mov rdi, r14                            ; rdi = typeKey
    call getPrintFunction                   ; rax = ptr a funcion print del tipo de key
    mov rdi, [r12 + offset_treeNode_key]    ; rdi = ptr a key
    mov rsi, r13                            ; rsi = pFile
    call rax                                ; printTypeOfKey(type_t* key, FILE* pFile)

    ; Imprimo los parentesis y la flecha
    mov rdi, r13
    mov rsi, CIERRO_PARENTESIS_Y_FLECHA
    call fprintf

    ; Imprimo la lista de valores
    mov rdi, [r12 + offset_treeNode_values] ; rdi = ptr a lista con los valores del nodo
    mov rsi, r13                            ; rsi = pFile
    call listPrint                          ; imprimo la lista de valores

    ; Me fijo si el siguiente a imprimir es NULL -> sino lo imprimo
    cmp QWORD [r12 + offset_treeNode_right], NULL
    je .fin
    mov rdi, [r12 + offset_treeNode_right]
    mov rsi, r13
    mov rdx, r14 

    call inorderPrint

.fin:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

treePrint:
    ; Defino Offsets de tree
    %define offset_tree_first 0
    %define offset_tree_size 8
    %define offset_tree_typeKey 12
    %define offset_tree_duplicate 16
    %define offset_tree_typeData 20

    ; void treePrint(tree_t* tree, FILE *pFile)
    ; RDI = tree_t* tree
    ; RSI = FILE* pFile

    push rbp
    mov rbp, rsp

    cmp QWORD [rdi + offset_tree_first], NULL       ; Veo si el puntero a root es NULL
    je .fin
    xor rdx, rdx
    mov edx, [rdi + offset_tree_typeKey]            ; rdx = typeKey
    mov rdi, [rdi + offset_tree_first]              ; rdi = ptr a root
    call inorderPrint

.fin:
    pop rbp
    ret