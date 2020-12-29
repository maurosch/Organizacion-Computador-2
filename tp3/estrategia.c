#include "stddef.h"
#include "syscall.h"

void meeseks1_func(void);
void meeseks2_func(void);
uint8_t GLOBAL_X = 0;
uint8_t GLOBAL_Y = 0;

void task(void) {
  int8_t deltaX, deltaY;
  while(1){
    syscall_meeseeks((uint32_t)&meeseks1_func, 0, 0);
    syscall_look(&deltaX, &deltaY); //Pasar turno
    syscall_meeseeks((uint32_t)&meeseks2_func, GLOBAL_X, GLOBAL_Y);
    syscall_look(&deltaX, &deltaY); //Pasar turno
  }
}

/*
 * Meeseek que solo mira
 */
void meeseks1_func(void) {
  int8_t deltaX, deltaY;
  while (1) {
    syscall_look(&deltaX, &deltaY);
    GLOBAL_X = deltaX;
    GLOBAL_Y = deltaY;

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