/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del manejador de memoria
*/

#include "mmu.h"
#include "i386.h"

#include "kassert.h"

uint32_t next_pde_free;

void mmu_init(void)
{
  next_pde_free = 0x100000;
}

paddr_t mmu_next_free_kernel_page(void)
{
  next_pde_free += 0x1000;
  return next_pde_free - 0x1000;
}

paddr_t mmu_init_kernel_dir(void)
{
  // Inicializo el directorio
  paddr_t *pdt = (paddr_t *)KERNEL_PAGE_DIR;
  __builtin_memset(pdt, 0, PAGE_SIZE);

  // El indice es 0 pq los 10 mas significativos son 0
  // Me quedo con los 12 bits mas significativos y la marco como presente
  uint32_t attr = MMU_W | MMU_P;
  pdt[0] = (KERNEL_PAGE_TABLE_0 & ~0xFFF) | (attr & 0xFFF);

  // Esto es lo mismo que arriba pq es la primera address , pero asi es mas cuentoso y sirve para reforzar la idea de como es el mapeo
  paddr_t *pt = (paddr_t *)(pdt[0] & ~0xFFF);
  uint16_t attr_pg = MMU_W | MMU_P;

  // Es un identity page frame a page frame
  for (size_t i = 0; i < 0x400; i++)
  {
    pt[i] = (i << 12) | (attr_pg & 0xFFF);
  }

  return KERNEL_PAGE_DIR;
}

/**
 * Permite mapear la pagina fisica a la direccion virtual 
 * en el esquema de paginacion de cr3 
*/
void mmu_map_page(uint32_t cr3, vaddr_t virt, paddr_t phy, uint32_t attrs)
{
  // La pdt apunta a cr3
  paddr_t *pdt = (paddr_t *)cr3;

  //virt = Indice Directorio (10bits) - Indice Tabla (10bits) - Offset(12bits)
  paddr_t pd_index = virt >> 22;
  paddr_t pt_index = (virt >> 12) & 0x3FF; //10 bits del medio

  if ((pdt[pd_index] & MMU_P) != 1)
  {
    // No esta presente , la creo con los atributos
    paddr_t newP = mmu_next_free_kernel_page();
    __builtin_memset((void *)newP, 0, PAGE_SIZE);
    pdt[pd_index] = (newP & ~0xFFF) | (attrs & 0xFFF) | MMU_P;
  }

  paddr_t *pt = (paddr_t *)(pdt[pd_index] & 0xFFFFF000);

  // Es un mapeo nuevo / piso el que existe
  pt[pt_index] = (phy & ~0xFFF) | (attrs & 0xFFF) | MMU_P;

  tlbflush();
}


/**
 * Borra el mapeo creado en la direccion virtual virtual utilizando cr3
*/
paddr_t mmu_unmap_page(uint32_t cr3, vaddr_t virt)
{
  // La pdt apunta a cr3
  paddr_t *pdt = (paddr_t *)cr3;

  // El indice en la pdt son los 10 bits mas significativos
  paddr_t pd_index = virt >> 0x16;

  // Devolvemos 0 si no está mapeada
  if (!(pdt[pd_index] & MMU_P))
    return 0;

  paddr_t *pde = (paddr_t *)(pdt[pd_index] & ~0xFFF);

  // Tengo el indice en la pde
  paddr_t pde_index = (virt >> 12) & 0x3FF;

  paddr_t phy = pde[pde_index] & ~0xFFF;

  pde[pde_index] = 0;

  tlbflush();

  return phy;
}
/*
 * Encargada de inicializar un directorio de páginas y
 * tablas de páginas para una tarea dada
*/
paddr_t mmu_init_task_dir(
    paddr_t phy_start,
    vaddr_t virt_start,
    paddr_t code_start,
    size_t pages,
    uint32_t task_cr3,
    uint32_t code_cr3,
    uint32_t attr)
{
  
  if (task_cr3 == 0)
  {
    //Creamos nuevo cr3 porque no tiene
    attr |= MMU_U;
    task_cr3 = mmu_next_free_kernel_page();
    __builtin_memset((void *)task_cr3, 0, PAGE_SIZE);

    //Mapeo con identity mapping los primeros 4MB
    for(int i = 0; i < PAGE_SIZE*0x400; i+=PAGE_SIZE){
      mmu_map_page(task_cr3, i, i, 0);
    }
  }


  for (size_t i = 0; i < pages; i++)
  {
    paddr_t p_addr = phy_start + i * PAGE_SIZE;
    paddr_t code_addr = code_start + i * PAGE_SIZE;
    vaddr_t v_addr = virt_start + i * PAGE_SIZE;

    //Hacemos identity mapping a donde queremos copiar
    mmu_map_page(code_cr3, p_addr, p_addr, 0); 
    __builtin_memcpy((void *)p_addr, (void *)(code_addr), PAGE_SIZE);
    //Desmapeamos el mapeo anterior
    mmu_unmap_page(code_cr3, p_addr);

    //Mapeamos la direccion virtual de la tarea a la fisica
    mmu_map_page(task_cr3, v_addr, p_addr, attr);
  }
  
  // devuelvo el pagedirectory de la tarea1
  return task_cr3;
}