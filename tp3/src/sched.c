/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del scheduler
*/

#include "sched.h"
#include "mmu.h"
#include "tss.h"
#include "defines.h"
#include "i386.h"

extern void delete_rick_meeseek(uint32_t index);
extern void delete_morty_meeseek(uint32_t index);
void delete_meesek(uint32_t cr3, paddr_t virt, uint32_t gdt_index);
paddr_t calcVirtAddressWithMeeseekIndex(int32_t);
uint32_t updateCounter(uint32_t t);
uint32_t updateTick(uint32_t t);
void kill_current_task(void);
uint32_t KILL_CURRENT_TASK = 0;

//----------------IMPORTAR VARIABLES GLOBALES----------------

extern str_task_info_t TASK_RICK;
extern str_task_info_t TASK_MORTY;
extern uint32_t GAME_ENDED_WON_MORTY;
extern uint32_t GAME_ENDED_WON_RICK;
extern str_task_t RickTasks[AMOUNT_MSSEEKS_PER_PLAYER];
extern str_task_t MortyTasks[AMOUNT_MSSEEKS_PER_PLAYER];
extern int currentTaskIsMortyOrMortyMeeseekTask; 
extern int currentMeeseekTask; 
extern int currentTaskIsMortyOrMortyMeeseekTask; 
extern int currentMeeseekTask; 

//------------------------------------------------------------


void sched_init(void) {
  for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
    MortyTasks[i].alive = 0;
    RickTasks[i].alive = 0;
    RickTasks[i].counter = 0;
  }
}

uint16_t sched_next_task(void) {
  if(currentTaskIsMortyOrMortyMeeseekTask == 1){
    currentTaskIsMortyOrMortyMeeseekTask = 0;
    
    for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
      if(RickTasks[i].alive == 1 && RickTasks[i].seen == 0){
        RickTasks[i].seen = 1;
        RickTasks[i].counter = updateCounter(RickTasks[i].counter);
        RickTasks[i].ticks_lived = updateTick(RickTasks[i].ticks_lived);
        
        currentMeeseekTask = i;
        return RickTasks[i].gdt_index;
      }
    }

    //Reseteamos todos los vistos
    for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
      RickTasks[i].seen = 0;
    }

    TASK_RICK.counter = updateCounter(TASK_RICK.counter);
    currentMeeseekTask = NOT_IN_MEESEEK_TASK;
    return TASK_RICK.gdt_index;
    
  } else {
    currentTaskIsMortyOrMortyMeeseekTask = 1;
    
    for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
      if(MortyTasks[i].alive == 1 && MortyTasks[i].seen == 0){
        MortyTasks[i].seen = 1;
        MortyTasks[i].counter = updateCounter(MortyTasks[i].counter);
        MortyTasks[i].ticks_lived = updateTick(MortyTasks[i].ticks_lived);
        currentMeeseekTask = i;
        return MortyTasks[i].gdt_index;
      }
    }

    //Reseteamos todos los vistos
    for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
      MortyTasks[i].seen = 0;
    }

    TASK_MORTY.counter = updateCounter(TASK_MORTY.counter);
    currentMeeseekTask = NOT_IN_MEESEEK_TASK;
    return TASK_MORTY.gdt_index;
  }

  //Nunca llega acá
  return -1;
}

void check_killed_tasks(void){
  if(KILL_CURRENT_TASK == 1){
    kill_current_task();
    KILL_CURRENT_TASK = 0;
  }
}

void kill_current_task(void){
  if(currentMeeseekTask == NOT_IN_MEESEEK_TASK){
    if(currentTaskIsMortyOrMortyMeeseekTask){
      GAME_ENDED_WON_RICK = 1;
    } else {
      GAME_ENDED_WON_MORTY = 1;
    }
    return;
  }
  if(currentTaskIsMortyOrMortyMeeseekTask){
    delete_morty_meeseek(currentMeeseekTask);
  } else {
    delete_rick_meeseek(currentMeeseekTask);
  }
}

uint32_t updateCounter(uint32_t t){
  if(t > 3) return 0;
  return t+1;
}

uint32_t updateTick(uint32_t t){
  if(t > 50) return 50;
  return t+1;
}