#include "stddef.h"
#include "syscall.h"
#include "i386.h"

void meeseks1_func(void);
void calcMovimientos(int cantMov, int8_t *xDest, int8_t *yDest, int32_t *xMov, int32_t *yMov);
int cantMovs(int tiempoVivo);

void task(void) {
  //Dividimos cuadricula en 10 sectores de 16x20 => max dist a semilla = 18 (3 turnos)
  while(1){
    for(int i = 0; i < 5; i++){
      for(int j = 0; j < 2; j++){
        syscall_meeseeks((uint32_t)&meeseks1_func, 8+i*16, 12+j*16);
      }
    }
  }
}

void meeseks1_func(void) {
  int cont = 0;
  int8_t x, y;
  int32_t xMov, yMov; //No se entiende muy bien porque el move(...) pide 32bits y el look(...) pide 8 bits
  while(1){
    syscall_look(&x, &y);
    cont++;
    while(x != 0 || y != 0){
      calcMovimientos(cantMovs(cont), &x, &y, &xMov, &yMov);
      syscall_move(xMov, yMov);
      cont++;
    }

    //Molestamos al contrincante
    if(cont == 4){
      syscall_use_portal_gun();
      cont++;
    }

    //Nos matamos porque no servimos, ya somos muy lentos
    if(cantMovs(cont) < 5){
      syscall_meeseeks(0, 0, 0);
    }
  }
}

//Obtenemos cuantos movimientos podemos hacer segun la cantidad de tiempo que vivimos
int cantMovs(int tiempoVivo){
  int r = 7 - tiempoVivo/2;
  if(r < 1)
    r = 1;
  return r;
}

void calcMovimientos(int cantMov, int8_t *xDest, int8_t *yDest, int32_t *xMov, int32_t *yMov){
  *xMov = 0; 
  *yMov = 0;
  //Nos movemos diagonalmente hacia la semilla
  while(cantMov > 0 && (*yDest != 0 || *xDest != 0)){
    if(*yDest != 0){
      if(*yDest < 0){
        (*yDest)++;
        (*yMov)--;
      } else {
        (*yDest)--;
        (*yMov)++;
      }
      cantMov--;
    }
    if(*xDest != 0 && cantMov > 0){
      if(*xDest < 0){
        (*xDest)++;
        (*xMov)--;
      } else {
        (*xDest)--;
        (*xMov)++;
      }
      cantMov--;
    }
  }
}