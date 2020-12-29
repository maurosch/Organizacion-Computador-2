/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de las rutinas de atencion de interrupciones
*/

#include "idt.h"
#include "defines.h"
#include "isr.h"
#include "screen.h"
#include "i386.h"

#define GDT_SEL_CODE_KERNEL (0xA << 3)
#define INTERRUPT_GATE_ATTR 0x8E00     
#define INTERRUPT_GATE_USER_ATTR 0xEE00 
//0x8E00 = 1000 1110 0000 0000
//0xEE00 = 1110 1110 0000 0000

idt_entry_t idt[255] = {0};

idt_descriptor_t IDT_DESC = {sizeof(idt) - 1, (uint32_t)&idt};

/*
    La siguiente es una macro de EJEMPLO para ayudar a armar entradas de
    interrupciones. Para usar, descomentar y completar CORRECTAMENTE los
    atributos y el registro de segmento. Invocarla desde idt_inicializar() de
    la siguiene manera:

    void idt_inicializar() {
        IDT_ENTRY(0);
        ...
        IDT_ENTRY(19);
        ...
    }
*/

// attributo

#define IDT_ENTRY(numero)                                                             \
  idt[numero].offset_15_0 = (uint16_t)((uint32_t)(&_isr##numero) & (uint32_t)0xFFFF); \
  idt[numero].segsel = (uint16_t)GDT_SEL_CODE_KERNEL;                                 \
  idt[numero].attr = (uint16_t)INTERRUPT_GATE_ATTR;                                   \
  idt[numero].offset_31_16 = (uint16_t)((uint32_t)(&_isr##numero) >> 16 & (uint32_t)0xFFFF);

#define IDT_ENTRY_USER_CALLABLE(numero)                                               \
  idt[numero].offset_15_0 = (uint16_t)((uint32_t)(&_isr##numero) & (uint32_t)0xFFFF); \
  idt[numero].segsel = (uint16_t)GDT_SEL_CODE_KERNEL;                                 \
  idt[numero].attr = (uint16_t)INTERRUPT_GATE_USER_ATTR;                              \
  idt[numero].offset_31_16 = (uint16_t)((uint32_t)(&_isr##numero) >> 16 & (uint32_t)0xFFFF);

void idt_init()
{
  // Excepciones

  IDT_ENTRY(0);
  IDT_ENTRY(1);
  IDT_ENTRY(2);
  IDT_ENTRY(3);
  IDT_ENTRY(4);
  IDT_ENTRY(5);
  IDT_ENTRY(6);
  IDT_ENTRY(7);
  IDT_ENTRY(8);
  IDT_ENTRY(9);
  IDT_ENTRY(10);
  IDT_ENTRY(11);
  IDT_ENTRY(12);
  IDT_ENTRY(13);
  IDT_ENTRY(14);
  IDT_ENTRY(16);
  IDT_ENTRY(17);
  IDT_ENTRY(18);
  IDT_ENTRY(19);
  IDT_ENTRY(20);
  IDT_ENTRY(21);

  IDT_ENTRY(32);
  IDT_ENTRY(33);

  IDT_ENTRY_USER_CALLABLE(88);
  IDT_ENTRY_USER_CALLABLE(89);
  IDT_ENTRY_USER_CALLABLE(100);
  IDT_ENTRY_USER_CALLABLE(123);
}

void interruption_print(
    uint32_t int_no,
    uint32_t eflag,
    uint32_t cs,
    uint32_t eip,
    uint32_t error_code)
{
  print("#", 2, 10, C_BG_BLACK | C_FG_WHITE);
  print_hex(int_no, 6, 10, 10, C_BG_BLACK | C_FG_WHITE);
  print("eflag", 2, 12, C_BG_BLACK | C_FG_WHITE);
  print_hex(eflag, 6, 10, 12, C_BG_BLACK | C_FG_WHITE);
  print("cs", 2, 14, C_BG_BLACK | C_FG_WHITE);
  print_hex(cs, 6, 10, 14, C_BG_BLACK | C_FG_WHITE);
  print("eip", 2, 16, C_BG_BLACK | C_FG_WHITE);
  print_hex(eip, 6, 10, 16, C_BG_BLACK | C_FG_WHITE);
  print("error code", 2, 18, C_BG_BLACK | C_FG_WHITE);
  print_hex(error_code, 6, 10, 18, C_BG_BLACK | C_FG_WHITE);
}

void printScanCode(uint8_t code)
{
  code &= 0xFF;

   // 'l'
  if (code == 0x26)
  {
    print("710/18 - 459/00 - 299/19", 10, 10, C_FG_WHITE | C_BG_BLUE);
  }

  // Levante la tecla
  if ((code & 0xF0) == 0x80)
  {
    print("  ", 78, 0, C_FG_BLACK | C_BG_BLACK);
    return;
  }
  // Es una tecla del 0 al 9
  if (0 < code && code < 12)
    print_dec((code & 0xF) - 1, 2, 78, 0, C_FG_WHITE | C_BG_BLACK);
  
  

  
}