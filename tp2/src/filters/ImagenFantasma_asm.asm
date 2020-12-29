section .rodata
align 16

flt_1210  : dd  1.0 , 2.0 , 1.0 , 0.0
flt_8881  : dd  8.0 , 8.0 , 8.0 , 1.0
flt_9991  : dd  0.9 , 0.9 , 0.9 , 1.0
mask1000  : dd  0xFFFFFFFF,  0  ,  0  ,  0

section .text
; extern ImagenFantasma_c
global ImagenFantasma_asm

ImagenFantasma_asm:
%ifdef ROLINGA
    jmp ImagenFantasma_rolinga_asm
    ret
%endif
;rdi = uint8_t *src,
;rsi = uint8_t *dst,
;edx = int width,
;ecx = int height,
;R8d  = int src_row_size,
;R9d  = int dst_row_size,
;DWORD [RBP + 16] = int offsetx,
;DWORD [RBP + 24] = int offsety)

push rbp
mov  rbp,rsp
push rbx ; j
push r12 ; i 
push r13

mov eax,r8d
xor r8,r8
mov r8d,eax

mov eax,r9d
xor r9,r9
mov  r9d, eax
  
xor rbx,rbx
.loop_j:

; r10 = jj
xor r10  , r10
mov r10d , ebx ; j
shr r10d , 1   ; j / 2
add r10d , dword [rbp + 24] ; j / 2 + offset
imul r10 , r8 ;; ii * row_sz

xor r12,r12 
.loop_i:

; r11 = ii
lea r11 , [ r12 + 0]
shr r11 , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11 * 4 ] ;; jj * 4bytes

; xmm0 = b | g | r | a <--- ii,jj
pmovzxbd  xmm0 , [rdi + r13 ]

lea r11  , [ r12 + 1]
shr r11  , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11 * 4]

; xmm1 = b | g | r | a <--- ii+1,jj
pmovzxbd  xmm1 , [rdi + r13 ]

lea  r11 , [ r12 + 2 ]
shr  r11 , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11* 4]

; xmm2 = b | g | r | a <--- ii+2,jj
pmovzxbd  xmm2 , [rdi + r13 ]

lea  r11 , [ r12 + 3 ]
shr  r11 , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11* 4]

; xmm3 = b | g | r | a <--- ii+3,jj
pmovzxbd  xmm3 , [rdi + r13 ]

CVTDQ2PS  xmm0 , xmm0
CVTDQ2PS  xmm1 , xmm1
CVTDQ2PS  xmm2 , xmm2
CVTDQ2PS  xmm3 , xmm3

mulps xmm0,[flt_1210]
mulps xmm1,[flt_1210]
mulps xmm2,[flt_1210]
mulps xmm3,[flt_1210]

;xmm0 = src[ii,jj].b*1 | src[ii,jj].g*2 | src[ii,jj].r*1 | src[ii,jj].a*0

haddps xmm0,xmm0
haddps xmm0,xmm0
haddps xmm1,xmm1
haddps xmm1,xmm1
haddps xmm2,xmm2
haddps xmm2,xmm2
haddps xmm3,xmm3
haddps xmm3,xmm3

;xmm0 = src[ii,jj].b * 1 + src[ii,jj].g *2 +  src[ii,jj].r *1 + src[ii,jj].a * 0  |  ... = b | b | b | b 
;xmm0 = 		b  |          b |	   b | 		b
;     =         8  |          8|	   8 | 		1

divps xmm0,[flt_8881]
divps xmm1,[flt_8881]
divps xmm2,[flt_8881]
divps xmm3,[flt_8881]

;xmm0 = b/8 | b/8 | b/8 | 1

mov  rax , rbx
imul rax , r8 ;; i * row_sz
lea  r13 , [ r12*4 + rax]

pmovzxbd  xmm4 , [rdi + r13 + 4*0] 
pmovzxbd  xmm5 , [rdi + r13 + 4*1] 
pmovzxbd  xmm6 , [rdi + r13 + 4*2] 
pmovzxbd  xmm7 , [rdi + r13 + 4*3] 

CVTDQ2PS  xmm4 , xmm4
CVTDQ2PS  xmm5 , xmm5
CVTDQ2PS  xmm6 , xmm6
CVTDQ2PS  xmm7 , xmm7

;   =        0.9  | 	    0.9 |       0. 9 |          1
;xmm4 =  src[i,j].b | src[i,j].g | src[i,j].r | src[i,j].a

mulps xmm4,[flt_9991] 	
mulps xmm5,[flt_9991] 	
mulps xmm6,[flt_9991]
mulps xmm7,[flt_9991]

;xmm4 =  src[i,j].b * 0.9 | src[i,j].g * 0.9 | src[i,j].r*0.9 | src[i,j].a*1
;xmm0 = b / 2 | b / 2  | b / 2 | b / 2
;xmm4  = src[i,j].b * 0.9 + b/2 | src[i,j].g * 0.9 + b/2 | src[i,j].r*0.9 + b/2 | src[i,j].a*1 + b/2

addps xmm4,xmm0
addps xmm5,xmm1
addps xmm6,xmm2
addps xmm7,xmm3

cvttps2dq xmm4,xmm4 ;  ---> valores truncados de b,g,r,a
packusdw  xmm4,xmm4 ; ---> DWORD  -> WORD
packuswb  xmm4,xmm4  ;  ---> WORD -> BYTE 

cvttps2dq xmm5,xmm5 ;  ---> valores truncados de b,g,r,a
packusdw  xmm5,xmm5 ; ---> DWORD  -> WORD
packuswb  xmm5,xmm5  ;  ---> WORD -> BYTE 

cvttps2dq xmm6,xmm6 ;  ---> valores truncados de b,g,r,a
packusdw  xmm6,xmm6 ; ---> DWORD  -> WORD
packuswb  xmm6,xmm6  ;  ---> WORD -> BYTE 

cvttps2dq xmm7,xmm7 ;  ---> valores truncados de b,g,r,a
packusdw  xmm7,xmm7 ; ---> DWORD  -> WORD
packuswb  xmm7,xmm7  ;  ---> WORD -> BYTE 

mov  rax , rbx
imul rax , r9 ;; i * row_sz
lea  r13 , [ r12 * 4 + rax]

pand    xmm4,[mask1000]
pand    xmm5,[mask1000]
pand    xmm6,[mask1000]
pand    xmm7,[mask1000]

PSLLDQ  xmm5,4*1
PSLLDQ  xmm6,4*2
PSLLDQ  xmm7,4*3

por     xmm5,xmm7
por     xmm5,xmm6
por     xmm5,xmm4

movdqa  [rsi + r13] , xmm5

add r12d,4
cmp r12d,edx
jb .loop_i

inc ebx
cmp ebx,ecx ; ebx < height
jb .loop_j

pop r13
pop r12
pop rbx
pop rbp
ret



;---------------------EXPERIMENTO_DESENROLLAR_LOOPS---------------------
ImagenFantasma_rolinga_asm:
;rdi = uint8_t *src,
;rsi = uint8_t *dst,
;edx = int width,
;ecx = int height,
;R8d  = int src_row_size,
;R9d  = int dst_row_size,
;DWORD [RBP + 16] = int offsetx,
;DWORD [RBP + 24] = int offsety)

push rbp
mov  rbp,rsp
push rbx ; j
push r12 ; i 
push r13

mov eax,r8d
xor r8,r8
mov r8d,eax

mov eax,r9d
xor r9,r9
mov  r9d, eax
  
xor rbx,rbx
.loop_j:

; r10 = jj
xor r10  , r10
mov r10d , ebx ; j
shr r10d , 1   ; j / 2
add r10d , dword [rbp + 24] ; j / 2 + offset
imul r10 , r8 ;; ii * row_sz

xor r12,r12 
.loop_i:

; r11 = ii
lea r11 , [ r12 + 0]
shr r11 , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11 * 4 ] ;; jj * 4bytes

; xmm0 = b | g | r | a <--- ii,jj
pmovzxbd  xmm0 , [rdi + r13 ]

lea r11  , [ r12 + 1]
shr r11  , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11 * 4]

; xmm1 = b | g | r | a <--- ii+1,jj
pmovzxbd  xmm1 , [rdi + r13 ]

lea  r11 , [ r12 + 2 ]
shr  r11 , 1
add r11d , dword [rbp + 16]
lea  r13 , [ r10 + r11* 4]

CVTDQ2PS  xmm0 , xmm0
CVTDQ2PS  xmm1 , xmm1

mulps xmm0,[flt_1210]
mulps xmm1,[flt_1210]

;xmm0 = src[ii,jj].b*1 | src[ii,jj].g*2 | src[ii,jj].r*1 | src[ii,jj].a*0

haddps xmm0,xmm0
haddps xmm0,xmm0
haddps xmm1,xmm1
haddps xmm1,xmm1

;xmm0 = src[ii,jj].b * 1 + src[ii,jj].g *2 +  src[ii,jj].r *1 + src[ii,jj].a * 0  |  ... = b | b | b | b 
;xmm0 = 		b  |          b |	   b | 		b
;     =         8  |          8|	   8 | 		1

divps xmm0,[flt_8881]
divps xmm1,[flt_8881]

;xmm0 = b/8 | b/8 | b/8 | 1

mov  rax , rbx
imul rax , r8 ;; i * row_sz
lea  r13 , [ r12*4 + rax]

pmovzxbd  xmm4 , [rdi + r13 + 4*0] 
pmovzxbd  xmm5 , [rdi + r13 + 4*1] 

CVTDQ2PS  xmm4 , xmm4
CVTDQ2PS  xmm5 , xmm5

;   =        0.9  | 	    0.9 |       0. 9 |          1
;xmm4 =  src[i,j].b | src[i,j].g | src[i,j].r | src[i,j].a

mulps xmm4,[flt_9991] 	
mulps xmm5,[flt_9991] 	

;xmm4 =  src[i,j].b * 0.9 | src[i,j].g * 0.9 | src[i,j].r*0.9 | src[i,j].a*1
;xmm0 = b / 2 | b / 2  | b / 2 | b / 2
;xmm4  = src[i,j].b * 0.9 + b/2 | src[i,j].g * 0.9 + b/2 | src[i,j].r*0.9 + b/2 | src[i,j].a*1 + b/2

addps xmm4,xmm0
addps xmm5,xmm1

cvttps2dq xmm4,xmm4 ; ---> valores truncados de b,g,r,a
packusdw  xmm4,xmm4 ; ---> DWORD  -> WORD
packuswb  xmm4,xmm4 ; ---> WORD -> BYTE 

cvttps2dq xmm5,xmm5 ; ---> valores truncados de b,g,r,a
packusdw  xmm5,xmm5 ; ---> DWORD  -> WORD
packuswb  xmm5,xmm5 ; ---> WORD -> BYTE 

mov  rax , rbx
imul rax , r9 ;; i * row_sz
lea  r13 , [ r12 * 4 + rax]

pand    xmm4,[mask1000]
pand    xmm5,[mask1000]

PSLLDQ  xmm5,4*1

por     xmm5,xmm4

movq    [rsi + r13], xmm5

add r12d,2
cmp r12d,edx
jb .loop_i

inc ebx
cmp ebx,ecx ; ebx < height
jb .loop_j

pop r13
pop r12
pop rbx
pop rbp
ret
