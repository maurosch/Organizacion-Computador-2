/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de estructuras para administrar tareas
*/

#include "tss.h"
#include "defines.h"
#include "kassert.h"
#include "mmu.h"
#include "i386.h"

uint32_t make_tss(          //devolvemos el indice de la gdt del nuevo descriptor de la tarea
  paddr_t phy_start,        //Memoria fisica
  vaddr_t virt_start,       //Memoria virtual
  paddr_t code_start,       //Referencia al codigo
  size_t pages,             //Cantidad de paginas
  uint32_t *cr3_task,       //cr3
  uint32_t cr3_code,        //crt
  uint32_t is_user_task,    //1=usuario 0=kernel
  uint32_t gdt_index_param) //0=dinamico, otro=Fijo     
{
  uint32_t gdt_idx = 10;
  if(gdt_index_param == 0){
    while(gdt[gdt_idx].p == 1){ gdt_idx++; } //Buscamos un indice
  }else{
    gdt_idx = gdt_index_param;
  }
  gdt_entry_t *gde = &(gdt[gdt_idx]);

  __builtin_memset(gde, 0, sizeof(gdt_entry_t));

  //Pedimos memoria para tabla de tss
  paddr_t tss_addr = mmu_next_free_kernel_page();

  gde->limit_15_0 = sizeof(tss_t) - 1;
  gde->base_15_0 = (tss_addr >> 00) & 0xFFFF; //Low address
  gde->base_23_16 = (tss_addr >> 16) & 0xFF;  //Medium address
  gde->base_31_24 = (tss_addr >> 24) & 0xFF;  //High address
  gde->type = 0x9;                            //10B1 --> 1001   
  gde->p = 0x1;

  uint32_t attr = (is_user_task & 0x1) ? (MMU_W | MMU_U) : MMU_W;
  paddr_t cr3 = mmu_init_task_dir(
    phy_start,
    virt_start,
    code_start,
    pages,
    *cr3_task,
    cr3_code,
    attr 
  );

  uint16_t data = (is_user_task & 0x1 ? ((GDT_IDX_DATA_USER << 3) | 0x3) : GDT_IDX_DATA_KERNEL << 3);
  uint16_t code = (is_user_task & 0x1 ? ((GDT_IDX_CODE_USER << 3) | 0x3) : GDT_IDX_CODE_KERNEL << 3);

  tss_t *tss = (tss_t *)tss_addr;

  __builtin_memset(tss, 0, PAGE_SIZE);

  tss->cr3 = cr3;
  tss->cs = code;
  tss->fs = data;
  tss->ds = data;
  tss->ss = data;
  tss->iomap = 0xFFFF; //I/O map base address field
  tss->es = data;
  tss->gs = data;
  tss->ss0 = GDT_IDX_DATA_KERNEL << 3;
  tss->eflags = 0x202;
  tss->eip = virt_start;
  tss->esp = (is_user_task & 0x1 ? (virt_start+pages*PAGE_SIZE) : KERNEL_STACK);
  tss->ebp = 0;

  if(is_user_task & 0x1){ //Seteamos pila nivel 0 para las interrupciones de la tarea
    vaddr_t esp0_addr = mmu_next_free_kernel_page();
    tss->esp0 = esp0_addr + PAGE_SIZE;
  }

  *cr3_task = cr3;
  return gdt_idx;
}

uint32_t make_user_task(
  paddr_t phy_start, //Memoria fisica
  vaddr_t virt_start,//Memoria virtual
  paddr_t code_start,//Referencia al codigo
  size_t pages,      //Cantidad de paginas
  uint32_t *cr3_task //cr3 de la tarea
)
{
  return make_tss(phy_start, virt_start, code_start, pages, cr3_task, rcr3(), IS_USER_TASK, USE_NEW_GDT_INDEX);
}

void delete_user_task(uint32_t gdt_index_param)
{
  gdt[gdt_index_param].p = 0;
}

void tss_init(void)
{
  uint32_t cr3_kernel = rcr3();
  make_tss(KERNEL_CODIGO_IDLE, KERNEL_CODIGO_IDLE, KERNEL_CODIGO_IDLE, 1, &cr3_kernel, rcr3(), 0, GDT_IDX_TASK_INICIAL);
  make_tss(KERNEL_CODIGO_IDLE, KERNEL_CODIGO_IDLE, KERNEL_CODIGO_IDLE, 1, &cr3_kernel, rcr3(), 0, GDT_IDX_TASK_IDLE);
}



