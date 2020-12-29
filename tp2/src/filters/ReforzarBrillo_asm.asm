section .rodata
align 16
word_1210_1210: dw 1 , 2 , 1 , 0 , 1 , 2 , 1 , 0  

section .text

global ReforzarBrillo_asm

ReforzarBrillo_asm:
; rdi = uint8_t *src,
; rsi = uint8_t *dst,
; edx = int width,
; ecx = int height,
; R8d = int src_row_size,
; R9d = int dst_row_size,
; DWORD [RBP + 16] = int umbralSup,
; DWORD [RBP + 24] = int umbralInf,
; DWORD [RBP + 32] = int brilloSup,
; DWORD [RBP + 40] = int brilloInf

push rbp
mov  rbp,rsp

push rbx ; i
push r12 ; j 
push r13 ; 

movsx rdx, edx
movsx rcx, ecx
movsx r8 , r8d
movsx r9 , r9d

; creo la mascara umbralSup en xmm9
mov eax , DWORD[ rbp + 16]
shl rax , 32 
mov r10d, DWORD[ rbp + 16]
or  rax , r10
movq xmm0, rax
movq xmm9, rax
pslldq xmm0, 8
por  xmm9 , xmm0
; xmm9 [int32 x 4] = umbralSup | umbralSup | umbralSup | umbralSup

; creo la mascara umbralInf en xmm8
mov eax , DWORD[ rbp + 24]
shl rax , 32 
mov r10d, DWORD[ rbp + 24]
or  rax,r10
movq xmm0, rax
movq xmm8, rax
pslldq xmm0, 8
por  xmm8 , xmm0
; xmm8 [int32 x 4] = umbralInf | umbralInf | UmbralInf | umbralInf

; creo brilloSup en xmm7
pxor xmm0,xmm0
pxor xmm7,xmm7 
mov eax , DWORD[ rbp + 32]
shl rax,32
mov r10d, DWORD[ rbp + 32]
or  rax,r10
movq xmm7, rax
movq xmm0, r10
pslldq xmm0, 8
por  xmm7 , xmm0
PACKUSDW  xmm7,xmm7

; xmm7 [ uint16 x 8] = brilloSup|brilloSup|brilloSup|0|brilloSup|brilloSup|brilloSup|0
; creo brilloInf en xmm6 
pxor xmm0,xmm0
pxor xmm6,xmm6 
mov eax , DWORD[ rbp + 40]
shl rax,32
mov r10d, DWORD[ rbp + 40]
or  rax,r10
movq xmm6, rax
movq xmm0, r10
pslldq xmm0, 8
por  xmm6 , xmm0
PACKUSDW  xmm6,xmm6


; xmm6 [ uint16 x 8] = brilloInf|brilloInf|brilloInf|0|brilloInf|brilloInf|brilloInf|0

xor rbx,rbx ;i = 0
.loop_i:

mov  r10 , rbx ; i
imul r10 , r8  ; i * src_row_size
lea  r10 , [rdi + r10] ; r10  = src[i][......]

mov r11  , rbx ; i
imul r11 , r9  ; i * dst_row_size
lea  r11 , [rsi + r11] ; r11 =  dst[i][......]

xor r12,r12 ; j = 0
.loop_j:

pmovzxbw xmm0 , [ r10 + r12 * 4 ] ; src[i][j] -> xmm0 [uint16 x 8] = b0 | g0 | r0 | a0 | b1 | g1 | r1 | a1
movdqa   xmm1 , xmm0              ; xmm1 [uint16 x 8]              = b0 | g0 | r0 | a0 | b1 | g1 | r1 | a1

; Calculo b
pmaddwd xmm0 , [ word_1210_1210 ] ; xmm0 [int32 x 4] = b0*1 + g0*2 | r0*1 + a0*0 | b1*1 + g1*2 | r1*1 + a1*0
phaddd  xmm0 , xmm0 ; xmm0 [int32 x 4] =  b0 | b1 | b0 | b1  = b0*1 + g0*2 + r0*1 + a0*0 | b1*1 + g1*2 + r1*1 + a1*0 | b0*1 + g0*2 + r0*1 + a0*0 | b1*1 + g1*2 + r1*1 + a1*0 
psrld   xmm0 , 2

; Mascara con brillo superior
movdqa    xmm11 , xmm0 ; xmm11 [int32 x 4]  = b0 | b1 | b0 | b1
pcmpgtd   xmm11 , xmm9 ; xmm11 [int32 x 4]  = b0 > umbrSup | b1 > umbrSup | .. | ... 
punpckldq xmm11 , xmm11 ;xmm11 [int32 x 4] =
pand      xmm11  , xmm7  ; xmm11 [int16 x 8] = brilloSup|brilloSup|brilloSup|brilloSup|brilloSup|brilloSup|brilloSup|brilloSup

; Mascara con brillo inferior
movdqa    xmm12 , xmm8 ; xmm12 = b0 | b1 | b0 | b1
pcmpgtd   xmm12 , xmm0 ; xmm12 = umbrInf > b0 | umbrInf > b1  | umbrInf > b0 | umbrInf > b1
punpckldq xmm12 , xmm12 ; xmm12 = umbrInf > b0 |umbrInf > b0 | umbrInf >b1 | umbrInf >b1
pand      xmm12 , xmm6  ; xmm12 [int16 x 8] = brilloInf|brilloInf|brilloInf|brilloInf|brilloInf|brilloInf|brilloInf|brilloInf 

; Calculo fila de dst
paddusw  xmm1 , xmm11; xmm1  = xmm1 + xmm11 =  b0 + brilloSup | g0 + brilloSup| r0+ brilloSup | a0+ brilloSup | b1 + brilloSup| g1 + brilloSup| r1 + brilloSup| a1 + brilloSup
psubusw  xmm1 , xmm12; xmm1  = xmm1 + xmm11 - xmm11 = b0 + brilloSup - brilloInf | g0 + brilloSup  - brilloInf  .....
packuswb xmm1 , xmm1 ; xmm1  [int16 x 8] => xmm1 [int8 x 16] = b0|g0|r0|a0|b1|g1|r1|a1|.......  

movq [ r11 + r12 * 4 ], xmm1 

add r12,2
cmp r12,rdx  ; j < width
jl .loop_j

inc rbx
cmp rbx,rcx ; i < height
jl .loop_i

pop r13
pop r12
pop rbx
pop rbp

ret
