/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================

  Definicion de funciones del scheduler
*/

#include "screen.h"
#include "sched.h"
#include "game.h"
#include "tss.h"

extern uint32_t DEBUG;
extern uint32_t STUCK_IN_DEBUG_SCREEN;
extern uint32_t RICK_POINTS;
extern uint32_t MORTY_POINTS;
extern str_task_info_t TASK_RICK;
extern str_task_info_t TASK_MORTY;
extern str_megaseed_t MegaSeeds[NUMBER_OF_SEEDS];

ca buffer_pantalla[VIDEO_FILS][VIDEO_COLS];

void print(const char* text, uint32_t x, uint32_t y, uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; // magia
  int32_t i;
  for (i = 0; text[i] != 0; i++) {
    p[y][x].c = (uint8_t)text[i];
    p[y][x].a = (uint8_t)attr;
    x++;
    if (x == VIDEO_COLS) {
      x = 0;
      y++;
    }
  }
}

void printChar(const char c, uint32_t x, uint32_t y, uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; // magia
  p[y][x].c = (uint8_t)c;
  p[y][x].a = (uint8_t)attr;
  x++;
  if (x == VIDEO_COLS) {
    x = 0;
    y++;
  }
  
}

void print_dec(uint32_t numero, uint32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; // magia
  uint32_t i;
  uint8_t letras[16] = "0123456789";

  for (i = 0; i < size; i++) {
    uint32_t resto = numero % 10;
    numero = numero / 10;
    p[y][x + size - i - 1].c = letras[resto];
    p[y][x + size - i - 1].a = attr;
  }
}

void print_hex(uint32_t numero, int32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO; // magia
  int32_t i;
  uint8_t hexa[8];
  uint8_t letras[16] = "0123456789ABCDEF";
  hexa[0] = letras[(numero & 0x0000000F) >> 0];
  hexa[1] = letras[(numero & 0x000000F0) >> 4];
  hexa[2] = letras[(numero & 0x00000F00) >> 8];
  hexa[3] = letras[(numero & 0x0000F000) >> 12];
  hexa[4] = letras[(numero & 0x000F0000) >> 16];
  hexa[5] = letras[(numero & 0x00F00000) >> 20];
  hexa[6] = letras[(numero & 0x0F000000) >> 24];
  hexa[7] = letras[(numero & 0xF0000000) >> 28];
  for (i = 0; i < size; i++) {
    p[y][x + size - i - 1].c = hexa[i];
    p[y][x + size - i - 1].a = attr;
  }
}

void screen_draw_box(uint32_t fInit, uint32_t cInit, uint32_t fSize,
                     uint32_t cSize, uint8_t character, uint8_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])VIDEO;
  uint32_t f;
  uint32_t c;
  for (f = fInit; f < fInit + fSize; f++) {
    for (c = cInit; c < cInit + cSize; c++) {
      p[f][c].c = character;
      p[f][c].a = attr;
    }
  }
}

//--------------------------------------------------------

void buffer_print(const char* text, uint32_t x, uint32_t y, uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])buffer_pantalla; // magia
  int32_t i;
  for (i = 0; text[i] != 0; i++) {
    p[y][x].c = (uint8_t)text[i];
    p[y][x].a = (uint8_t)attr;
    x++;
    if (x == VIDEO_COLS) {
      x = 0;
      y++;
    }
  }
}

void buffer_printChar(const char c, uint32_t x, uint32_t y, uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])buffer_pantalla; // magia
  p[y][x].c = (uint8_t)c;
  p[y][x].a = (uint8_t)attr;
  x++;
  if (x == VIDEO_COLS) {
    x = 0;
    y++;
  }
  
}

void buffer_print_dec(uint32_t numero, uint32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])buffer_pantalla; // magia
  uint32_t i;
  uint8_t letras[16] = "0123456789";

  for (i = 0; i < size; i++) {
    uint32_t resto = numero % 10;
    numero = numero / 10;
    p[y][x + size - i - 1].c = letras[resto];
    p[y][x + size - i - 1].a = attr;
  }
}

void buffer_print_hex(uint32_t numero, int32_t size, uint32_t x, uint32_t y,
               uint16_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])buffer_pantalla; // magia
  int32_t i;
  uint8_t hexa[8];
  uint8_t letras[16] = "0123456789ABCDEF";
  hexa[0] = letras[(numero & 0x0000000F) >> 0];
  hexa[1] = letras[(numero & 0x000000F0) >> 4];
  hexa[2] = letras[(numero & 0x00000F00) >> 8];
  hexa[3] = letras[(numero & 0x0000F000) >> 12];
  hexa[4] = letras[(numero & 0x000F0000) >> 16];
  hexa[5] = letras[(numero & 0x00F00000) >> 20];
  hexa[6] = letras[(numero & 0x0F000000) >> 24];
  hexa[7] = letras[(numero & 0xF0000000) >> 28];
  for (i = 0; i < size; i++) {
    p[y][x + size - i - 1].c = hexa[i];
    p[y][x + size - i - 1].a = attr;
  }
}

void buffer_screen_draw_box(uint32_t fInit, uint32_t cInit, uint32_t fSize,
                     uint32_t cSize, uint8_t character, uint8_t attr) {
  ca(*p)[VIDEO_COLS] = (ca(*)[VIDEO_COLS])buffer_pantalla;
  uint32_t f;
  uint32_t c;
  for (f = fInit; f < fInit + fSize; f++) {
    for (c = cInit; c < cInit + cSize; c++) {
      p[f][c].c = character;
      p[f][c].a = attr;
    }
  }
}


//--------------------------------------------------------

extern str_task_t RickTasks[AMOUNT_MSSEEKS_PER_PLAYER];
extern str_task_t MortyTasks[AMOUNT_MSSEEKS_PER_PLAYER];
void printTasks(void){
  for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
    if(RickTasks[i].alive == 1){
      buffer_print("*", RickTasks[i].x, RickTasks[i].y+1, C_FG_LIGHT_BLUE);
    }
  }
  for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
    if(MortyTasks[i].alive == 1){
      buffer_print("*", MortyTasks[i].x, MortyTasks[i].y+1, C_FG_LIGHT_MAGENTA);
    }
  }
}

void printBackground(void){
  buffer_screen_draw_box(1, 0, SIZE_N,SIZE_M, ' ', C_BG_GREEN);
}

char getCounter(uint32_t t){
  if(t == 0) return '|';
  if(t == 1) return '/';
  if(t == 2) return '-';
  return '\\';
}

void printMeeseeksCounters(void){
  //Vemos que tarea estamos
  for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
    buffer_print_dec(i, 2, 20+4*i, 42, C_FG_LIGHT_MAGENTA);
    if(MortyTasks[i].alive == 1){
      buffer_printChar(getCounter(MortyTasks[i].counter), 20+4*i, 44, C_FG_LIGHT_MAGENTA);
    } else {
      buffer_printChar('x', 20+4*i, 44, C_FG_LIGHT_MAGENTA);
    }
  }
  for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
    buffer_print_dec(i, 2, 20+4*i, 46, C_FG_LIGHT_BLUE);
    if(RickTasks[i].alive == 1){
      buffer_printChar(getCounter(RickTasks[i].counter), 20+4*i, 48, C_FG_LIGHT_BLUE);
    } else {
      buffer_printChar('x', 20+4*i, 48, C_FG_LIGHT_BLUE);
    }
  }
  //FALTA IMPRIMIR RELOJES DE RICK Y MORTY
  buffer_printChar('M', 16, 45, C_FG_LIGHT_MAGENTA);
  buffer_printChar(getCounter(TASK_MORTY.counter), 16, 47, C_FG_LIGHT_MAGENTA);

  buffer_printChar('R', 60, 45, C_FG_LIGHT_BLUE);
  buffer_printChar(getCounter(TASK_RICK.counter), 60, 47, C_FG_LIGHT_BLUE);
}

void printMegaSeeds(void){
  for(int i = 0; i < NUMBER_OF_SEEDS; i++){
    if(MegaSeeds[i].alive == 1){
      buffer_printChar('+', MegaSeeds[i].x, MegaSeeds[i].y+1, C_FG_LIGHT_CYAN);
    }
  }
}

void printScoreBoards(void){
  buffer_screen_draw_box(42, 3,  3, 10, ' ', C_BG_RED);
  buffer_screen_draw_box(42, 65, 3, 10, ' ', C_BG_BLUE);
  //Morty a la izquierda
  buffer_print_dec(MORTY_POINTS, 8, 4, 43, C_FG_WHITE | C_BG_RED);
  //Rick a la izquierda
  buffer_print_dec(RICK_POINTS, 8, 66, 43, C_FG_WHITE | C_BG_BLUE);
}


char* exceptionDesc(uint32_t exp_number) {
  if(exp_number == 0){return "Divide Error (#DE) [0]";}
  if(exp_number == 1){return "RESERVED (#DB) [1]";}
  if(exp_number == 2){return "NMI Interrupt [2]";}
  if(exp_number == 3){return "Breakpoint (#BP) [3]";}
  if(exp_number == 4){return "Overflow (#OF) [4]";}
  if(exp_number == 5){return "BOUND Range Exceeded (#BR) [5]";}
  if(exp_number == 6){return "Invalid Opcode (#UD) [6]";}
  if(exp_number == 7){return "Device Not Available (#NM) [7]";}
  if(exp_number == 8){return "Double Fault (#DF) [8]";}
  if(exp_number == 9){return "Coprocessor Segment Overrun [9]";}
  if(exp_number == 10){return "Invalid TSS (#TS) [10]";}
  if(exp_number == 11){return "Segment Not Present (#NP) [11]";}
  if(exp_number == 12){return "Stack-Segment Fault (#SS) [12]";}
  if(exp_number == 13){return "General Protection (#GP) [13]";}
  if(exp_number == 14){return "Page Fault (#PF) [14]";}
  if(exp_number == 15){return "--- [15]";}
  if(exp_number == 16){return "Math Fault (#MF) [16]";}
  if(exp_number == 17){return "Alignment Check (#AC) [17]";}
  if(exp_number == 18){return "Machine Check (#MC) [18]";}
  if(exp_number == 19){return "SIMD Floating-Point Exception (#XM) [19]";}
  if(exp_number <= 31){return "**Intel reserved**";}
  if(exp_number <= 255){return "User Interrupt";} 
  return "0"; //no deberia llegar aca
}


void print_debug_c(
    uint32_t bt4,
    uint32_t bt3,
    uint32_t bt2,
    uint32_t bt1,
    uint32_t cr4,
    uint32_t cr3,
    uint32_t cr2,
    uint32_t cr0,
    uint32_t gs,     
    uint32_t fs,
    uint32_t es,
    uint32_t ds,
    uint32_t stack3,
    uint32_t stack2,
    uint32_t stack1,
    uint32_t edi,
    uint32_t esi,
    uint32_t ebp,
    uint32_t NO_USAR, //ESP kernel
    uint32_t ebx,
    uint32_t edx,
    uint32_t ecx,
    uint32_t eax,
    uint32_t NO_USAR2, //address return printDebug al isr que lo llamo
    uint32_t int_no,
    uint32_t ss,
    uint32_t esp,
    uint32_t eflag,
    uint32_t cs,
    uint32_t eip,
    uint32_t error_code)
{
  screen_draw_box(1, 20, SIZE_N, SIZE_M-40, ' ', C_BG_BLACK);
  NO_USAR = NO_USAR; //silenciar warning
  NO_USAR2 = NO_USAR2; //silenciar warning
  uint32_t startFirstColumn = 22;
  uint32_t startFirstColumnValues = 27;
  uint32_t startSecondColumn = 42;

  print(exceptionDesc(int_no), startFirstColumn, 3, C_BG_RED | C_FG_WHITE);

  print("eax", startFirstColumn, 6, C_BG_BLACK | C_FG_WHITE);
  print("ebx", startFirstColumn, 8, C_BG_BLACK | C_FG_WHITE);
  print("ecx", startFirstColumn, 10, C_BG_BLACK | C_FG_WHITE);
  print("edx", startFirstColumn, 12, C_BG_BLACK | C_FG_WHITE);
  print("esi", startFirstColumn, 14, C_BG_BLACK | C_FG_WHITE);
  print("edi", startFirstColumn, 16, C_BG_BLACK | C_FG_WHITE);
  print("ebp", startFirstColumn, 18, C_BG_BLACK | C_FG_WHITE);
  print("esp", startFirstColumn, 20, C_BG_BLACK | C_FG_WHITE);
  print("eip", startFirstColumn, 22, C_BG_BLACK | C_FG_WHITE);
  print("cs", startFirstColumn, 24, C_BG_BLACK | C_FG_WHITE);
  print("ds", startFirstColumn, 26, C_BG_BLACK | C_FG_WHITE);
  print("es", startFirstColumn, 28, C_BG_BLACK | C_FG_WHITE);
  print("fs", startFirstColumn, 30, C_BG_BLACK | C_FG_WHITE);
  print("gs", startFirstColumn, 32, C_BG_BLACK | C_FG_WHITE);
  print("ss", startFirstColumn, 34, C_BG_BLACK | C_FG_WHITE);
  print("eflags", startFirstColumn, 36, C_BG_BLACK | C_FG_WHITE);

  print("cr0", startSecondColumn, 6, C_BG_BLACK | C_FG_WHITE);
  print("cr2", startSecondColumn, 8, C_BG_BLACK | C_FG_WHITE);
  print("cr3", startSecondColumn, 10, C_BG_BLACK | C_FG_WHITE);
  print("cr4", startSecondColumn, 12, C_BG_BLACK | C_FG_WHITE);
  print("err", startSecondColumn, 14, C_BG_BLACK | C_FG_WHITE);

  print("stack", 42, 18, C_BG_BLACK | C_FG_WHITE);
  print("backtrace", 42, 26, C_BG_BLACK | C_FG_WHITE);

  print_hex(eax, 8, startFirstColumnValues, 6, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(ebx, 8, startFirstColumnValues, 8, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(ecx, 8, startFirstColumnValues, 10, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(edx, 8, startFirstColumnValues, 12, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(esi, 8, startFirstColumnValues, 14, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(edi, 8, startFirstColumnValues, 16, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(ebp, 8, startFirstColumnValues, 18, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(esp, 8, startFirstColumnValues, 20, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(eip, 8, startFirstColumnValues, 22, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(cs, 8, startFirstColumnValues, 24, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(ds, 8, startFirstColumnValues, 26, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(es, 8, startFirstColumnValues, 28, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(fs, 8, startFirstColumnValues, 30, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(gs, 8, startFirstColumnValues, 32, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(ss, 8, startFirstColumnValues, 34, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(eflag, 8, startFirstColumnValues+2, 36, C_BG_BLACK | C_FG_LIGHT_GREEN);

  print_hex(cr0, 8, 47, 6, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(cr2, 8, 47, 8, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(cr3, 8, 47, 10, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(cr4, 8, 47, 12, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(error_code, 8, 47, 14, C_BG_BLACK | C_FG_LIGHT_GREEN);

  print_hex(stack1, 8, startSecondColumn, 20, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(stack2, 8, startSecondColumn, 22, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(stack3, 8, startSecondColumn, 24, C_BG_BLACK | C_FG_LIGHT_GREEN);

  print_hex(bt1, 8, startSecondColumn, 28, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(bt2, 8, startSecondColumn, 30, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(bt3, 8, startSecondColumn, 32, C_BG_BLACK | C_FG_LIGHT_GREEN);
  print_hex(bt4, 8, startSecondColumn, 34, C_BG_BLACK | C_FG_LIGHT_GREEN);

  STUCK_IN_DEBUG_SCREEN = 1;
}

/**
 * Tenemos un buffer asi el juego no titilea
*/
void printBuffer(){
  ca (*p)[VIDEO_COLS] = (ca (*)[VIDEO_COLS]) VIDEO;
  for(int i = 0; i < VIDEO_FILS; i++){
    for(int j = 0; j < VIDEO_COLS; j++){
      p[i][j].c = buffer_pantalla[i][j].c;
      p[i][j].a = buffer_pantalla[i][j].a;
    }
  }
}

void printGame(void){
  printBackground();
  printTasks();
  printMeeseeksCounters();
  printMegaSeeds();
  printScoreBoards();
  printBuffer();
}
