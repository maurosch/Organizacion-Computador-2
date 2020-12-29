/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definiciones globales del sistema.
*/

#ifndef __DEFINES_H__
#define __DEFINES_H__
/* MMU */
/* -------------------------------------------------------------------------- */

#define BIT_ON (0x1)

#define MMU_P (1 << 0) //Present; must be 1 to map a 4-KByte page
#define MMU_W (1 << 1) //Read/write; if 0, writes may not be allowed to the 4-KByte page referenced by this entry (see Section 4.6)
#define MMU_U (1 << 2) //U/S 0=SUPERVISOR 1=USUARIO

#define PAGE_SIZE 4096
#define CELL_MAP_SIZE (PAGE_SIZE*2)

/* Misc */
/* -------------------------------------------------------------------------- */
// Y Filas
#define SIZE_N 40

// X Columnas
#define SIZE_M 80

/* Indices en la gdt */
/* -------------------------------------------------------------------------- */
#define GDT_IDX_NULL_DESC 0
#define GDT_COUNT         35


/* Offsets en la gdt */
/* -------------------------------------------------------------------------- */
#define GDT_OFF_NULL_DESC (GDT_IDX_NULL_DESC << 3)

/* Direcciones de memoria */
/* -------------------------------------------------------------------------- */

// direccion fisica de comienzo del bootsector (copiado)
#define BOOTSECTOR 0x00001000
// direccion fisica de comienzo del kernel
#define KERNEL 0x00001200
// direccion fisica del buffer de video
#define VIDEO 0x000B8000

/* Direcciones virtuales de código, pila y datos */
/* -------------------------------------------------------------------------- */

// direccion virtual del codigo
#define TASK_CODE_VIRTUAL 0x01D00000
#define PLACER_TASK_PAGES        4
#define MEESEEK_TASK_PAGES       2

/* Direcciones fisicas de codigos */
/* -------------------------------------------------------------------------- */
/* En estas direcciones estan los códigos de todas las tareas. De aqui se
 * copiaran al destino indicado por TASK_<X>_PHY_START.
 */

/* Direcciones fisicas de directorios y tablas de paginas del KERNEL */
/* -------------------------------------------------------------------------- */
#define KERNEL_PAGE_DIR     (0x00025000)
#define KERNEL_PAGE_TABLE_0 (0x00026000)
#define KERNEL_STACK        (0x00025000)


/****** ****/
#define KERNEL_CODIGO_IDLE  (0x18000)
#define KERNEL_CODIGO_RICK  (0x10000)
#define KERNEL_CODIGO_MORTY (0x14000)

#define PHY_CODE_RICK  (0x1D00000)
#define PHY_CODE_RICK_END  (0x1D03FFF)
#define PHY_CODE_MORTY (0x1D04000)
#define PHY_CODE_MORTY_END (0x1D07FFF)
#define PHY_CODE_MAP   (0x0400000)

#define VIRT_CODE_RICK  (0x1D00000)
#define VIRT_CODE_MORTY (0x1D00000)
#define VIRT_CODE_RICK_END  (0x1D03FFF)
#define VIRT_CODE_MORTY_END (0x1D03FFF)
#define VIRT_CODE_MEESEEKS_START (0x8000000)
#define VIRT_CODE_MEESEEKS_END (0x8014000)

#define NUMBER_OF_SEEDS 40
#define POINTS_MEGASEEDS 425

#define NOT_IN_MEESEEK_TASK -1
#define AMOUNT_MSSEEKS_PER_PLAYER 10

#endif //  __DEFINES_H__
