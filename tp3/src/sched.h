/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Declaracion de funciones del scheduler.
*/

#ifndef __SCHED_H__
#define __SCHED_H__

#include "types.h"

void sched_init();
uint16_t sched_next_task();

typedef struct str_task {
  uint32_t x;
  uint32_t y;
  uint32_t alive;
  uint32_t seen;
  uint32_t gdt_index;
  uint32_t counter;
  uint32_t ticks_lived; //(does not count more than: 50)
  uint32_t portal_gun_used;
} str_task_t;

#endif //  __SCHED_H__
