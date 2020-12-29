/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Declaracion de las rutinas asociadas al juego.
*/

#ifndef __GAME_H__
#define __GAME_H__

#include "types.h"

typedef enum e_task_type {
  Rick = 1,
  Morty = 2,
  Meeseeks = 3,
} task_type_t;

typedef struct str_megaseed {
  uint32_t x;
  uint32_t y;
  uint32_t alive;
} str_megaseed_t;

void game_init(void);


#endif //  __GAME_H__
