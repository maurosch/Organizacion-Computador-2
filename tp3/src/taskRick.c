#include "stddef.h"
#include "syscall.h"

#define SIZE_N 40
#define SIZE_M 80

void meeseks1_func(void);
void meeseks2_func(void);
int8_t GLOBAL_X = 0;
int8_t GLOBAL_Y = 0;

void task(void) {
  int8_t aux, aux2;
  while(1){
    syscall_meeseeks((uint32_t)&meeseks1_func, 0, 0);
    syscall_look(&aux, &aux2); //Paso turno
    if(GLOBAL_X < 0){
      GLOBAL_X = SIZE_M + GLOBAL_X;
    }
    if(GLOBAL_Y < 0){
      GLOBAL_Y = SIZE_N + GLOBAL_Y;
    }
    syscall_meeseeks((uint32_t)&meeseks2_func, GLOBAL_X, GLOBAL_Y);
  }
}

/*
 * Meeseek que solo mira
 */
void meeseks1_func(void) {
  while (1) {
    syscall_look(&GLOBAL_X, &GLOBAL_Y);
    syscall_meeseeks(0, 0, 0); //Nos matamos
  }
}

/*
 * Meeseek que solo se va a usar para agarrar semilla
 */
void meeseks2_func(void) {
  syscall_meeseeks(0, 0, 0); //Nos matamos
  while (1) {}
}