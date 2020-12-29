; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"

%define GDT_OFF_CODE_KERNEL 0xA << 3
%define GDT_OFF_DATA_KERNEL 0xC << 3
%define GDT_OFF_VIDEO_KERNEL 0xE << 3
 
%define GDT_SEL_TASK_INICIAL 0xF << 3
%define GDT_SEL_TASK_IDLE 0x10 << 3

extern GDT_DESC
extern IDT_DESC
extern idt_init
extern pic_reset
extern pic_enable
extern mmu_init_kernel_dir
extern mmu_init
extern mmu_init_task_dir
extern tss_init
extern make_tss_idle
extern sched_init
extern game_init

global start



BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; Imprimir mensaje de bienvenida
    print_text_rm start_rm_msg, start_rm_len, 0x07, 0, 0


    ; Habilitar A20
    call A20_disable
    call A20_check
    call A20_enable
    call A20_check
 
    ; Cargar la GDT
    lgdt [GDT_DESC]

    ; Setear el bit PE del registro CR0
    mov eax , cr0
    or  eax , 0x1
    mov cr0 , eax

    ; Saltar a modo protegido
    jmp GDT_OFF_CODE_KERNEL:.pm

BITS 32
.pm:

    ; Establecer selectores de segmentos
    mov eax,GDT_OFF_DATA_KERNEL 
    mov ss , ax
    mov ds , ax 
    mov fs , ax
    mov es , ax

    mov eax,GDT_OFF_VIDEO_KERNEL 
    mov gs , eax

    ; Establecer la base de la pila
    mov esp,0x25000
    mov ebp,esp

    ; Imprimir mensaje de bienvenida
    print_text_pm start_pm_msg, start_pm_len, 0x07, 0, 0

    ; Inicializar pantalla
    call init_pantalla
 
    ; Inicializar el manejador de memoria
    ; Inicializar el directorio de paginas
    ; Cargar directorio de paginas
   
    call mmu_init_kernel_dir
    mov cr3,eax
    call mmu_init

    ; Habilitar paginacion
    mov eax, cr0
    or  eax, 0x80000000
    mov cr0, eax

    ; Inicializar tss
    call tss_init
   
    ; Inicializar el scheduler
    call sched_init

    ; Inicializar Game
    call game_init

    ; Inicializar la IDT
    call idt_init

    ; Cargar IDT
    lidt [IDT_DESC]

    ; Configurar controlador de interrupciones
    call pic_reset
    call pic_enable

    ; Carga tarea inicial
    mov ax, GDT_SEL_TASK_INICIAL
    ltr ax

    ; Habilitar interrupciones
    sti
    
    ; Saltar a la primera tarea: Idle    
    mov ax, GDT_SEL_TASK_IDLE

    ;xchg bx,bx
    jmp GDT_SEL_TASK_IDLE:0x0

    ; Ciclar infinitamente (por si algo sale mal...)
    mov eax, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $


;; -------------------------------------------------------------------------- ;;

extern screen_draw_box

init_pantalla:
    push ebp
    mov ebp,esp

    mov ecx , 0
    xor edi , edi
    mov ah  , 0x0
    mov al  , ' '

    ; Una linea negra
    .loop:
        mov [gs:edi],ax
        add  edi , 2
        inc  ecx
        cmp  ecx , 1*80  
        jl .loop


    ; hasta la lina 40 lineas "verdes"  
    mov ah , 0xA0
    xor ecx,ecx
    .loop2:
        mov [gs:edi],ax
        add  edi , 2
        inc  ecx
        cmp  ecx , 40*80  
        jl .loop2


    ; Aca ya probe lo de GS y ahora dibujo el resto llamando las funciones en C

    ;screen_draw_box(42,3,3,10,' ',0x4F);
    push 0x4F ; / Fondo rojo 0x4 , color blanco 0xF
    push ' '
    push 10
    push 3
    push 3
    push 42
    call screen_draw_box
    add esp, 6*4

    ;screen_draw_box(42,65,3,10,' ',0x1F);
    push 0x1F ; / Fondo rojo 0x4 , color blanco 0xF
    push ' '
    push 10
    push 3
    push 65
    push 42
    call screen_draw_box
    add esp, 6*4

    pop ebp
    ret
;; -------------------------------------------------------------------------- ;;

%include "a20.asm"


