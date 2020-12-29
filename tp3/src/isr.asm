; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================
;
; Definicion de rutinas de atencion de interrupciones

%include "print.mac"

BITS 32

sched_task_offset:     dd 0x0
sched_task_selector:   dw 0xFFFF

;; PIC
extern pic_finish1

;; Sched
extern check_killed_tasks
extern sched_next_task
extern printGame
extern print_debug_c

extern create_meeseek_c
extern use_portal_gun_c
extern look_c
extern move_c
extern KILL_CURRENT_TASK
extern check_end_game
extern RETURN_X_LOOK
extern RETURN_Y_LOOK
extern RETURN_MOVE
extern RETURN_MEESEEK
extern DEBUG
extern STUCK_IN_DEBUG_SCREEN
%define SELECTOR_TASK_IDLE (0x10 << 3)
%define KEY_Y 0x15

;;
;; Definición de MACROS
;; -------------------------------------------------------------------------- ;;
extern interruption_print

%macro ISR 1
global _isr%1
_isr%1: 
        push DWORD 0         ; error code (pusheamos todo de nuevo para hacerlo generico)
        push DWORD [esp+4]   ; eip
        push DWORD [esp+12]  ; cs
        push DWORD [esp+20]  ; eflag
        push DWORD [esp+28]  ; esp
        push DWORD [esp+36]  ; ss
        push DWORD %1        ; int_no

        call printDebug
        
        add esp, 4*7

        mov DWORD [KILL_CURRENT_TASK], 1 ;Se va a matar en sched_next_task

        call pic_finish1

        call jumpToIdle
        iret

%endmacro

%macro ISR_WITH_ERROR_CODE 1
global _isr%1
_isr%1: 
        push DWORD [esp+0]   ; error code (pusheamos todo de nuevo para hacerlo generico)
        push DWORD [esp+8]   ; eip
        push DWORD [esp+16]  ; cs
        push DWORD [esp+24]  ; eflag
        push DWORD [esp+32]  ; esp
        push DWORD [esp+40]  ; ss
        push DWORD %1        ; int_no

        call printDebug
        
        add esp, 4*7

        mov DWORD [KILL_CURRENT_TASK], 1 ;Se va a matar en sched_next_task

        call pic_finish1

        call jumpToIdle

        add esp, 4 ;despusheamos error code
        iret

%endmacro

;; Rutina de atención de las EXCEPCIONES
;; -------------------------------------------------------------------------- ;;
ISR 0
ISR 1
ISR 2
ISR 3
ISR 4
ISR 5
ISR 6
ISR 7
ISR_WITH_ERROR_CODE 8
ISR 9
ISR_WITH_ERROR_CODE 10
ISR_WITH_ERROR_CODE 11
ISR_WITH_ERROR_CODE 12
ISR_WITH_ERROR_CODE 13
ISR_WITH_ERROR_CODE 14
ISR 16
ISR_WITH_ERROR_CODE 17
ISR 18
ISR 19
ISR 20
ISR 21

;; Rutina de atención del RELOJ
;; -------------------------------------------------------------------------- ;;
global _isr32
_isr32:
        pushad

        call pic_finish1

        call check_killed_tasks

        call check_end_game
        
        call next_clock

        call printGame

        call sched_next_task   ; obtener indice de la proxima tarea a ejecutar
        
        
        shl ax, 3              ; obtengo selector
        str cx                 ; compara con la tarea actual y salta solo si es diferente
        cmp ax, cx
       ; xchg bx,bx
        je .fin                
                mov word [sched_task_selector], ax  ; carga el selector de segmento de la tarea a saltar
                jmp far [sched_task_offset]         ; intercambio de tareas
        .fin:
        
        
        popad
        iret

;; Rutina de atención del TECLADO
;; -------------------------------------------------------------------------- ;;
extern printScanCode
global _isr33
_isr33:
        pushad

        in al, 0x60

        cmp eax, KEY_Y
        jne .noDebug
                mov DWORD [DEBUG], 1
                mov DWORD [STUCK_IN_DEBUG_SCREEN], 0
        .noDebug:
                
        push eax
        call printScanCode
        add esp, 4

        call pic_finish1
        popad
        iret

;; Rutinas de atención de las SYSCALLS
;; -------------------------------------------------------------------------- ;;
;; Funciones Auxiliares
;; -------------------------------------------------------------------------- ;;
isrNumber:           dd 0x00000000
isrClock:            db '|/-\'
next_clock:
        pushad
        inc DWORD [isrNumber]
        mov ebx, [isrNumber]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrNumber], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock
                print_text_pm ebx, 1, 0x0f, 49, 79
                popad
        ret

global _isr88   
_isr88:             ;SYSCALL MEESEEKS(uint32_t code_start, uint32_t x, uint32_t y) (SOLO LLAMABLE DESDE RICK/MORTY) 
        pushad
                push ecx ;Pusheamos tercer parametro
                push ebx ;Pusheamos segundo parametro
                push eax ;Pusheamos primer parametro
                call create_meeseek_c
                add esp, 3*4
        popad

        mov eax, [RETURN_MEESEEK]

        pushad
                call jumpToIdle
        popad
        iret


global _isr89
_isr89:             ;SYSCALL USE_PORTAL_GUN
        pushad

        call use_portal_gun_c

        call jumpToIdle

        popad
        iret



global _isr100
_isr100:            ;SYSCALL LOOK(int8_t* x, int8_t* y) 
        pushad
                call look_c 
        popad

        mov eax, [RETURN_X_LOOK]
        mov ebx, [RETURN_Y_LOOK]

        pushad
                call jumpToIdle
        popad

        iret


global _isr123
_isr123:            ;SYSCALL MOVE(int32_t x, int32_t y)
        pushad
                push ebx ;Pusheamos segundo parametro
                push eax ;Pusheamos primer parametro
                call move_c
                add esp, 2*4
        popad

        mov eax, [RETURN_MOVE]

        pushad
                call jumpToIdle
        popad

        iret

jumpToIdle:
        mov ax, SELECTOR_TASK_IDLE
        mov word [sched_task_selector], ax  ; carga el selector de segmento de la tarea a saltar
        jmp far [sched_task_offset]         ; intercambio de tareas
        ret

printDebug:
        ;Nos viene pusheado (izquierda mas lejos/mas abajo en memoria):
        ;| error code | eip | cs | eflags | esp (tarea) | ss | int_nro | DIREC_RETORNO_FUNCION_NO_USAR |
        cmp DWORD [DEBUG], 1
        jne .noDebug
                
                pushad                  ;pusheo 8 registros (Push EAX, ECX, EDX, EBX, original ESP, EBP, ESI, and EDI)

                mov eax, [esp+4*11]     ;agarro el esp pusheado antes

                cmp eax, ebp
                xor ebx, ebx
                je .seguir3 
                        mov ebx, DWORD [eax] 
                .seguir3
                push ebx                ;stack1 

                add eax, 4
                cmp eax, ebp
                xor ebx, ebx
                je .seguir4 
                        mov ebx, DWORD [eax] 
                .seguir4
                push ebx                ;stack2 

                add eax, 4
                cmp eax, ebp
                xor ebx, ebx
                je .seguir5
                        mov ebx, DWORD [eax] 
                .seguir5
                push ebx                ;stack3 

                push ds
                push es
                push fs
                push gs
                mov eax, cr0
                push eax
                mov eax, cr2
                push eax
                mov eax, cr3
                push eax
                mov eax, cr4
                push eax

                xor eax, eax           ; eax = 0
                push ebp               ; backtrace1  
                cmp ebp, 0 
                je .seguir0
                        mov eax, [ebp] ; Nos movemos uno arriba
                .seguir0:
                push eax               ; backtrace2
                
                cmp eax, 0
                je .seguir1
                        mov eax, [ebp] ; Nos movemos uno arriba
                .seguir1:
                push eax               ; backtrace3

                cmp eax, 0
                je .seguir2
                        mov eax, [ebp] ; Nos movemos uno arriba
                .seguir2:
                push eax               ; backtrace4
                      
                call print_debug_c

                .loop: ;LOOP INFINITO HASTA QUE SALGAMOS DEL DEBUG
                        in al, 0x60
                        cmp eax, KEY_Y
                        jne .fin
                        mov DWORD [STUCK_IN_DEBUG_SCREEN], 0
                .fin:        
                cmp DWORD [STUCK_IN_DEBUG_SCREEN], 1
                je .loop

                add esp, 15*4          ;despusheamos todo
                popad                  ;Despusheo los 8 registros de proposito general

        .noDebug: