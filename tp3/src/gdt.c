/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de la tabla de descriptores globales
*/

#include "gdt.h"

gdt_entry_t gdt[GDT_COUNT] = {
    /* Descriptor nulo*/
    /* Offset = 0x00 */
    [GDT_IDX_NULL_DESC] =
        {
            .limit_15_0 = 0x0000,
            .base_15_0 = 0x0000,
            .base_23_16 = 0x00,
            .type = 0x0,
            .s = 0x00,
            .dpl = 0x00,
            .p = 0x00,
            .limit_19_16 = 0x00,
            .avl = 0x0,
            .l = 0x0,
            .db = 0x0,
            .g = 0x00,
            .base_31_24 = 0x00,
        },
    [GDT_IDX_CODE_KERNEL] =
        {
            .limit_15_0 = 0xC900, // 201 * 1024 >> 2
            .base_15_0 = 0x0000,  // Inicio de la memoria segun el mapa
            .base_23_16 = 0x00,
            .type = 0xA,         // Execute Read
            .s = 0x01,           // Code/Data
            .dpl = 0x00,         // Level 0
            .p = 0x01,           // Presente
            .limit_19_16 = 0x00, // OK
            .avl = 0x0,          //
            .l = 0x0,            // 32 bits
            .db = 0x1,           // 32 bits
            .g = 0x01,           // Pages
            .base_31_24 = 0x00,  //ok
        },
    [GDT_IDX_CODE_USER] =
        {
            .limit_15_0 = 0xC900, // 201 * 1024 >> 2
            .base_15_0 = 0x0000,  // Inicio de la memoria segun el mapa
            .base_23_16 = 0x00,
            .type = 0xA,         // Execute Read
            .s = 0x01,           // Code/Data
            .dpl = 0x03,         // Level 3
            .p = 0x01,           // Presente
            .limit_19_16 = 0x00, // OK
            .avl = 0x0,          //
            .l = 0x0,            // 32 bits
            .db = 0x1,           // 32 bits
            .g = 0x01,           // Pages
            .base_31_24 = 0x00,  //ok
        },
    [GDT_IDX_DATA_KERNEL] =
        {
            .limit_15_0 = 0xC900, // 201 * 1024 >> 2
            .base_15_0 = 0x0000,  // Inicio de la memoria segun el mapa
            .base_23_16 = 0x00,
            .type = 0x2,         // Read/Write
            .s = 0x01,           // Code/Data
            .dpl = 0x00,         // Level 0
            .p = 0x01,           // Presente
            .limit_19_16 = 0x00, // OK
            .avl = 0x0,          //
            .l = 0x0,            // 32 bits
            .db = 0x1,           // 32 bits
            .g = 0x01,           // Pages
            .base_31_24 = 0x00,  //ok
        },
    [GDT_IDX_DATA_USER] =
        {
            .limit_15_0 = 0xC900, // 201*1024 / 4 = 0xC900
            .base_15_0 = 0x0000,  // Inicio de la memoria segun el mapa
            .base_23_16 = 0x00,
            .type = 0x2,         // Read/Write
            .s = 0x01,           // Code/Data
            .dpl = 0x03,         // Level 3
            .p = 0x01,           // Presente
            .limit_19_16 = 0x00, // OK
            .avl = 0x0,          //
            .l = 0x0,            // 32 bits
            .db = 0x1,           // 32 bits
            .g = 0x01,           // Pages
            .base_31_24 = 0x00,  //ok
        },
    [GDT_IDX_VIDEO_KERNEL] =
        {
            .limit_15_0 = 0x0000,
            .base_15_0 = 0x8000, // Inicio de la memoria segun el mapa fisico es 0xB8000
            .base_23_16 = 0xB,
            .type = 0x2,        // Read/Write
            .s = 0x01,          // Code/Data
            .dpl = 0x00,        // Level 3
            .p = 0x01,          // Presente
            .limit_19_16 = 0xC, // OK
            .avl = 0x0,         //
            .l = 0x0,           // 32 bits
            .db = 0x1,          // 32 bits
            .g = 0x00,          //  Bytes
            .base_31_24 = 0x00, //ok
        },
    [GDT_IDX_TASK_INICIAL] =
        {
            .limit_15_0 = 0x0000,
            .base_15_0 = 0x0000,
            .base_23_16 = 0x00,
            .type = 0x0,        
            .s = 0x00,          
            .dpl = 0x00,          
            .p = 0x01,           
            .limit_19_16 = 0x0,  
            .avl = 0x0,         
            .l = 0x0,            
            .db = 0x0,          
            .g = 0x00,            
            .base_31_24 = 0x00, 
        },
    [GDT_IDX_TASK_IDLE] =
        {
            .limit_15_0 = 0x0000,
            .base_15_0 = 0x0000,
            .base_23_16 = 0x00,
            .type = 0x0,        
            .s = 0x00,          
            .dpl = 0x00,          
            .p = 0x01,           
            .limit_19_16 = 0x0,  
            .avl = 0x0,         
            .l = 0x0,            
            .db = 0x0,          
            .g = 0x00,            
            .base_31_24 = 0x00, 
        }
};

gdt_descriptor_t GDT_DESC = {sizeof(gdt) + MAX_AMOUNT_OF_TSS * sizeof(gdt_entry_t) - 1, (uint32_t)&gdt};
