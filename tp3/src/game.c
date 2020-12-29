/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#include "game.h"
#include "defines.h"
#include "screen.h"
#include "tss.h"
#include "prng.h"
#include "types.h"
#include "mmu.h"
#include "i386.h"
#include "sched.h"

//---------------------VARIABLES GLOBALES---------------------

str_megaseed_t MegaSeeds[NUMBER_OF_SEEDS];
str_task_info_t TASK_RICK = { .gdt_index = 0, .cr3 = 0, .counter = 0 };
str_task_info_t TASK_MORTY = { .gdt_index = 0, .cr3 = 0, .counter = 0 };

//Nos guardamos 2 variables para saber que tarea estamos ejecutando
int currentTaskIsMortyOrMortyMeeseekTask = 0; 
//0 = La tarea ejecutada actualmente es Morty/MeeseeksMorty; 1 = La tarea ejecutada actualmente es Rick/MeeseeksRick;
int currentMeeseekTask = NOT_IN_MEESEEK_TASK; 
//NOT_IN_MEESEEK_TASK significa que estamos en la tarea RICK o MORTY

uint32_t GAME_ENDED_WON_MORTY = 0;
uint32_t GAME_ENDED_WON_RICK = 0;
uint32_t MORTY_POINTS = 0;
uint32_t RICK_POINTS = 0;
uint32_t DEBUG = 1;
uint32_t STUCK_IN_DEBUG_SCREEN = 0;
str_task_t RickTasks[AMOUNT_MSSEEKS_PER_PLAYER];
str_task_t MortyTasks[AMOUNT_MSSEEKS_PER_PLAYER];
extern uint32_t KILL_CURRENT_TASK;

//------------------------------------------------------------

void game_init(void) {
    
    TASK_MORTY.gdt_index = make_user_task(PHY_CODE_MORTY, VIRT_CODE_MORTY, KERNEL_CODIGO_MORTY, PLACER_TASK_PAGES, &(TASK_MORTY.cr3));
    TASK_RICK.gdt_index = make_user_task(PHY_CODE_RICK, VIRT_CODE_RICK, KERNEL_CODIGO_RICK, PLACER_TASK_PAGES, &(TASK_RICK.cr3));

    for(int i = 0; i < NUMBER_OF_SEEDS; i++){
        MegaSeeds[i].alive = 1;
        MegaSeeds[i].x = rand()%80;
        MegaSeeds[i].y = rand()%40;
    }
}
void check_end_game(void){
    if(GAME_ENDED_WON_MORTY || GAME_ENDED_WON_RICK){
        screen_draw_box(0, 0, SIZE_N+1, SIZE_M, ' ', C_FG_BLACK | C_BG_BLACK);
        print("JUEGO TERMINADO", SIZE_M/2-10, SIZE_N/2, C_FG_WHITE | C_BG_BLACK);

        if(GAME_ENDED_WON_MORTY && GAME_ENDED_WON_RICK){
            print("EMPATE", SIZE_M/2-6, SIZE_N/2+5, C_FG_WHITE | C_BG_BLACK);
        } else if(GAME_ENDED_WON_RICK){
            print("GANO RICK", SIZE_M/2-8, SIZE_N/2+5, C_FG_WHITE | C_BG_BLACK);
        } else {
            print("GANO MORTY", SIZE_M/2-8, SIZE_N/2+5, C_FG_WHITE | C_BG_BLACK);
        }
        while(1){}
    }
}

/**
 * ----------------------------------------------------------------------
 * ---------------------------SYSCALLS-----------------------------------
 * ----------------------------------------------------------------------
*/

int32_t abs(int32_t);
int8_t abs8(int8_t);
int32_t outOfBounds(int32_t,int32_t);
paddr_t calcPhyAddressWithCoords(int32_t,int32_t);
paddr_t calcVirtAddressWithMeeseekIndex(int32_t);
uint32_t x_round_map_position(int32_t);
uint32_t y_round_map_position(int32_t);
void move_morty_meeseek(int32_t newX, int32_t newY, int index_meeseek);
void move_rick_meeseek(int32_t newX, int32_t newY, int index_meeseek);
void move_memory_meeseek(uint32_t cr3, paddr_t oldPhy, paddr_t newPhy, paddr_t virt);
void check_and_delete_meesek_in_position(uint32_t x, uint32_t y);
void delete_rick_meeseek(uint32_t index);
void delete_morty_meeseek(uint32_t index);
int32_t check_megaseed(uint32_t x, uint32_t y);

/**
 * ---------------------------------------------------------------------
 * MEESEEK SYSCALL
 * ---------------------------------------------------------------------
*/
paddr_t RETURN_MEESEEK = 0;
void create_meeseek_c(uint32_t code_start, uint32_t x, uint32_t y){
    if(currentMeeseekTask != NOT_IN_MEESEEK_TASK){
        //Desalojamos la tarea porque nos llamo un meeseeks
        KILL_CURRENT_TASK = 1;
        RETURN_MEESEEK = 0;
        return;
    }

    uint32_t newX = x_round_map_position(x);
    uint32_t newY = y_round_map_position(y);
    uint32_t phy_place = calcPhyAddressWithCoords(newX,newY);

    if(outOfBounds(x,y) == 1){
        KILL_CURRENT_TASK = 1;
        RETURN_MEESEEK = 0;
        return;
    }
    if(currentTaskIsMortyOrMortyMeeseekTask){
        if(code_start < VIRT_CODE_MORTY || code_start > VIRT_CODE_MORTY_END){
            KILL_CURRENT_TASK = 1;
            RETURN_MEESEEK = 0;
            return;
        }

        //Matamos al meeseek si habia uno en esa posicion
        check_and_delete_meesek_in_position(newX, newY);

        //Chequeamos si hay una semilla en el lugar
        int32_t indexMegaseed = check_megaseed(newX, newY);
        if(indexMegaseed != -1){
            MegaSeeds[indexMegaseed].alive = 0;
            MORTY_POINTS += POINTS_MEGASEEDS;
            RETURN_MEESEEK = 0;
            return;
        }

        //Chequeamos que pueda crearlo (la cantidad de meeseeks sea menor a 10)
        int index = 0;
        while(MortyTasks[index].alive == 1 && index < AMOUNT_MSSEEKS_PER_PLAYER){ index++; }
        if(index == AMOUNT_MSSEEKS_PER_PLAYER){
            RETURN_MEESEEK = 0;
            return;
        }

        //Creamos la tarea (mismo cr3 asi comparte la memoria)
        uint32_t virt_place = calcVirtAddressWithMeeseekIndex(index); 
        MortyTasks[index].alive = 1;
        MortyTasks[index].gdt_index = make_user_task(phy_place, virt_place, code_start, MEESEEK_TASK_PAGES, &TASK_MORTY.cr3);
        MortyTasks[index].x = newX;
        MortyTasks[index].y = newY;
        MortyTasks[index].portal_gun_used = 0;
        MortyTasks[index].ticks_lived = 0;
        RETURN_MEESEEK = virt_place;
        return;

    } else {
        if(code_start < VIRT_CODE_RICK || code_start > VIRT_CODE_RICK_END){
            KILL_CURRENT_TASK = 1;
            RETURN_MEESEEK = 0;
            return;
        }

        //Matamos al meeseek si habia uno en esa posicion
        check_and_delete_meesek_in_position(newX, newY);

        //Chequeamos si hay una semilla en el lugar
        int32_t indexMegaseed = check_megaseed(newX, newY);
        if(indexMegaseed != -1){
            MegaSeeds[indexMegaseed].alive = 0;
            RICK_POINTS += POINTS_MEGASEEDS;
            RETURN_MEESEEK = 0;
            return;
        }

        //Chequeamos que pueda crearlo (la cantidad de meeseeks sea menor a 10)
        int index = 0;
        while(RickTasks[index].alive == 1 && index < AMOUNT_MSSEEKS_PER_PLAYER){ index++; }
        if(index == AMOUNT_MSSEEKS_PER_PLAYER){
            RETURN_MEESEEK = 0;
            return;
        }
        //Creamos la tarea (mismo cr3 asi comparte la memoria)
        uint32_t virt_place = calcVirtAddressWithMeeseekIndex(index); 
        RickTasks[index].alive = 1;
        RickTasks[index].gdt_index = make_user_task(phy_place, virt_place, code_start, MEESEEK_TASK_PAGES, &TASK_RICK.cr3);
        RickTasks[index].x = newX;
        RickTasks[index].y = newY;
        RickTasks[index].portal_gun_used = 0;
        RickTasks[index].ticks_lived = 0;
        RETURN_MEESEEK = virt_place;
        return;
    }
    //Nunca llega aca
    return;
}

/**
 * ---------------------------------------------------------------------
 * LOOK SYSCALL
 * ---------------------------------------------------------------------
*/
int RETURN_X_LOOK = 0;
int RETURN_Y_LOOK = 0;
void look_c(){
    //No nos puede llamar rick/morty
    if(currentMeeseekTask == NOT_IN_MEESEEK_TASK){
        RETURN_X_LOOK = -1;
        RETURN_Y_LOOK = -1;
        return;
    }
    int xMeeseek;
    int yMeeseek;
    if(currentTaskIsMortyOrMortyMeeseekTask){
        xMeeseek = MortyTasks[currentMeeseekTask].x;
        yMeeseek = MortyTasks[currentMeeseekTask].y;
    } else {
        xMeeseek = RickTasks[currentMeeseekTask].x;
        yMeeseek = RickTasks[currentMeeseekTask].y;
    }
    
    int moveX, moveY;
    int minDistance = 1000;
    for(int i = 0; i < NUMBER_OF_SEEDS; i++){
        if(MegaSeeds[i].alive == 1){
            int dx = MegaSeeds[i].x - xMeeseek;
            if (dx > SIZE_M/2)
                dx = -(SIZE_M - dx);
            if (dx < -SIZE_M/2)
                dx = SIZE_M + dx;
            
            int dy = MegaSeeds[i].y - yMeeseek;
            if (dy > SIZE_N/2)
                dy = -(SIZE_N - dy);
            if (dy < -SIZE_N/2)
                dy = SIZE_N + dy;

            int distance = abs(dx)+abs(dy);
            if(distance < minDistance){
                minDistance = distance;
                moveX = dx;
                moveY = dy;
            }
        }
    }
    RETURN_X_LOOK = moveX;
    RETURN_Y_LOOK = moveY;

    return;
}

/**
 * ---------------------------------------------------------------------
 * USE_PORTAL_GUN SYSCALL
 * ---------------------------------------------------------------------
*/
void use_portal_gun_c(void){
    if(currentMeeseekTask == NOT_IN_MEESEEK_TASK){
        KILL_CURRENT_TASK = 1;      
        return;
    }
    if(currentTaskIsMortyOrMortyMeeseekTask){
        //Check de que no haya usado el portl antes
        if(MortyTasks[currentMeeseekTask].portal_gun_used == 1){
            return;
        } 
        //Check de que haya alguno vivo
        int32_t alive_count = 0;
        for (int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
            if(RickTasks[i].alive==1){
                alive_count++;
            }
        }
        if(alive_count==0){
            return;
        } 
        //Buscamos random 
        uint32_t meeseek_index;
        do{                
            meeseek_index = rand() % AMOUNT_MSSEEKS_PER_PLAYER;
        } while(RickTasks[meeseek_index].alive==0);

        //Obtengo nueva phy y virt
        int32_t newX = rand() % SIZE_M;
        int32_t newY = rand() % SIZE_N;
        move_rick_meeseek(newX, newY, meeseek_index);
        MortyTasks[currentMeeseekTask].portal_gun_used = 1;

    } else {
        //Check de que no haya usado el portl antes
        if(RickTasks[currentMeeseekTask].portal_gun_used == 1){
            return;
        }
        //Check de que haya alguno vivo
        int32_t alive_count = 0;
        for (int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
            if(MortyTasks[i].alive==1){
                alive_count++;
            }
        }
        if(alive_count==0){
            return;
        } 
        //Buscamos random 
        uint32_t meeseek_index;
        do{                
            meeseek_index = rand() % AMOUNT_MSSEEKS_PER_PLAYER;
        } while(MortyTasks[meeseek_index].alive==0);

        //Obtengo nueva phy y virt
        int32_t newX = rand() % SIZE_M;
        int32_t newY = rand() % SIZE_N;
        move_morty_meeseek(newX, newY, meeseek_index);
        RickTasks[currentMeeseekTask].portal_gun_used = 1;
    }
    return;
}

/**
 * ---------------------------------------------------------------------
 * MOVE SYSCALL
 * ---------------------------------------------------------------------
*/
int RETURN_MOVE = 0;
void move_c(int32_t x, int32_t y){
    if(currentMeeseekTask == NOT_IN_MEESEEK_TASK){
        KILL_CURRENT_TASK = 1;    
        RETURN_MOVE = 0;
        return;
    }
    if(currentTaskIsMortyOrMortyMeeseekTask){
        //Chequeamos que se pueda mover tanto
        int32_t maxAmountMoves = 7 - MortyTasks[currentMeeseekTask].ticks_lived/2; 
        if(maxAmountMoves < 1)
            maxAmountMoves = 1;
        if(abs(x)+abs(y) > maxAmountMoves){
            RETURN_MOVE = 0;
            return;
        }
        //Movemos el meeseek
        move_morty_meeseek((int32_t)MortyTasks[currentMeeseekTask].x+x, (int32_t)MortyTasks[currentMeeseekTask].y+y, currentMeeseekTask);
    } else {
        //Chequeamos que se pueda mover tanto
        int32_t maxAmountMoves = 7 - RickTasks[currentMeeseekTask].ticks_lived/2; 
        if(maxAmountMoves < 1)
            maxAmountMoves = 1;
        if(abs(x)+abs(y) > maxAmountMoves){
            RETURN_MOVE = 0;
            return;
        }
        //Movemos el meeseek
        int32_t newX = (int32_t)(RickTasks[currentMeeseekTask].x) + x;
        int32_t newY = (int32_t)(RickTasks[currentMeeseekTask].y) + y;
        move_rick_meeseek(newX, newY, currentMeeseekTask);
    }
    RETURN_MOVE = 1;
}

void move_morty_meeseek(int32_t _newX, int32_t _newY, int index_meeseek){
    uint32_t newX = x_round_map_position(_newX);
    uint32_t newY = y_round_map_position(_newY);

    if(MortyTasks[index_meeseek].x == newX && MortyTasks[index_meeseek].y == newY)
        return;

    //Obtengo nueva phy y virt
    paddr_t oldPhy = calcPhyAddressWithCoords(MortyTasks[index_meeseek].x, MortyTasks[index_meeseek].y);
    paddr_t newPhy = calcPhyAddressWithCoords(newX, newY);
    paddr_t virt = calcVirtAddressWithMeeseekIndex(index_meeseek);

    int32_t indexMegaseed = check_megaseed(newX, newY);
    if(indexMegaseed != -1){
        delete_morty_meeseek(currentMeeseekTask);
        MegaSeeds[indexMegaseed].alive = 0;
        MORTY_POINTS += POINTS_MEGASEEDS;
        return;
    }
    check_and_delete_meesek_in_position(newX, newY);
    move_memory_meeseek(TASK_MORTY.cr3, oldPhy, newPhy, virt);
    MortyTasks[index_meeseek].x = newX;
    MortyTasks[index_meeseek].y = newY;
}
void move_rick_meeseek(int32_t _newX, int32_t _newY, int index_meeseek){
    uint32_t newX = x_round_map_position(_newX);
    uint32_t newY = y_round_map_position(_newY);
    
    if(RickTasks[index_meeseek].x == newX && RickTasks[index_meeseek].y == newY)
        return;

    //Obtengo nueva phy y virt
    paddr_t oldPhy = calcPhyAddressWithCoords(RickTasks[index_meeseek].x, RickTasks[index_meeseek].y);
    paddr_t newPhy = calcPhyAddressWithCoords(newX, newY);
    paddr_t virt = calcVirtAddressWithMeeseekIndex(index_meeseek);

    int32_t indexMegaseed = check_megaseed(newX, newY);
    if(indexMegaseed != -1){
        delete_rick_meeseek(currentMeeseekTask);
        MegaSeeds[indexMegaseed].alive = 0;
        RICK_POINTS += 425;
        return;
    }
    check_and_delete_meesek_in_position(newX, newY);
    move_memory_meeseek(TASK_RICK.cr3, oldPhy, newPhy, virt);
    RickTasks[index_meeseek].x = newX;
    RickTasks[index_meeseek].y = newY;
}

void move_memory_meeseek(uint32_t cr3, paddr_t oldPhy, paddr_t newPhy, paddr_t virt){
    //1.mapeamos nuevo lugar en kernel identity para copiar
    mmu_map_page(rcr3(), newPhy, newPhy, MMU_W);
    mmu_map_page(rcr3(), newPhy+PAGE_SIZE, newPhy+PAGE_SIZE, MMU_W);
    mmu_map_page(rcr3(), oldPhy, oldPhy, MMU_W);
    mmu_map_page(rcr3(), oldPhy+PAGE_SIZE, oldPhy+PAGE_SIZE, MMU_W);
    
    //2.copiamos el codigo
    __builtin_memcpy((void*)newPhy, (void*)oldPhy, PAGE_SIZE*2);

    //3.desmapeamos y mapeamos en la tarea morty/rick
    mmu_unmap_page(cr3, virt);
    mmu_unmap_page(cr3, virt+PAGE_SIZE);
    mmu_map_page(cr3, virt, newPhy, MMU_U | MMU_W);
    mmu_map_page(cr3, virt+PAGE_SIZE, newPhy+PAGE_SIZE, MMU_U | MMU_W);

    //4.desmapeamos en kernel
    mmu_unmap_page(rcr3(), newPhy);
    mmu_unmap_page(rcr3(), newPhy+PAGE_SIZE);
    mmu_unmap_page(rcr3(), oldPhy);
    mmu_unmap_page(rcr3(), oldPhy+PAGE_SIZE);
}

/**
 * --------------------------------------------------------------------------
 * -----------------------FUNCIONES AUXILIARES-------------------------------
 * --------------------------------------------------------------------------
*/
int32_t abs(int32_t x){return x < 0 ? -x : x;}
int8_t abs8(int8_t x){return x < 0 ? -x : x;}

//Lo colocamos fisicamente en el mapa como nos dice el enunciado
paddr_t calcPhyAddressWithCoords(int32_t x, int32_t y){
    return PHY_CODE_MAP + x*CELL_MAP_SIZE + y*SIZE_M*CELL_MAP_SIZE;
}

//La colocamos en un lugar fijo en la memoria virtual
paddr_t calcVirtAddressWithMeeseekIndex(int32_t indexMeeseek){
    return VIRT_CODE_MEESEEKS_START + indexMeeseek*MEESEEK_TASK_PAGES*PAGE_SIZE;
}

uint32_t x_round_map_position(int32_t p){
    if(p < 0)
        return SIZE_M + p; //es un + porque p es negativo
    if(p >= SIZE_M)
        return p % SIZE_M;
    return p; 
}
uint32_t y_round_map_position(int32_t p){
    if(p < 0)
        return SIZE_N + p; //es un + porque p es negativo
    if(p >= SIZE_N)
        return p % SIZE_N;
    return p;
}

int32_t outOfBounds(int32_t x, int32_t y){
    if(x < 0)
        return 1;
    if(x >= SIZE_M)
        return 1;

    if(y < 0)
        return 1;
    if(y >= SIZE_N)
        return 1;

    return 0;
}

void delete_rick_meeseek(uint32_t index){
    paddr_t virt = calcVirtAddressWithMeeseekIndex(index);
    mmu_unmap_page(TASK_RICK.cr3, virt);
    mmu_unmap_page(TASK_RICK.cr3, virt+PAGE_SIZE);
    gdt[RickTasks[index].gdt_index].p = 0;
    RickTasks[index].alive = 0;
}
void delete_morty_meeseek(uint32_t index){
    paddr_t virt = calcVirtAddressWithMeeseekIndex(index);
    mmu_unmap_page(TASK_MORTY.cr3, virt);
    mmu_unmap_page(TASK_MORTY.cr3, virt+PAGE_SIZE);
    gdt[MortyTasks[index].gdt_index].p = 0;
    MortyTasks[index].alive = 0;
}


void check_and_delete_meesek_in_position(uint32_t x, uint32_t y){
    //Buscamos si hay un meeseek en la posicion pasada
    for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
        if(RickTasks[i].alive == 1 && RickTasks[i].x == x && RickTasks[i].y == y){
            delete_rick_meeseek(i);
        }
    }
    for(int i = 0; i < AMOUNT_MSSEEKS_PER_PLAYER; i++){
        if(MortyTasks[i].alive == 1 && MortyTasks[i].x == x && MortyTasks[i].y == y){
            delete_morty_meeseek(i);
        }
    }
}

int32_t check_megaseed(uint32_t x, uint32_t y){
    uint32_t countAliveSeeds = 0;
    for(int i = 0; i < NUMBER_OF_SEEDS; i++){
        if(MegaSeeds[i].alive == 1){
            if(MegaSeeds[i].x == x && MegaSeeds[i].y == y){
                return i;
            }
            countAliveSeeds++;
        }
    }
    if(countAliveSeeds == 0){
        if(MORTY_POINTS > RICK_POINTS){
            GAME_ENDED_WON_MORTY = 1;
        } else if(RICK_POINTS > MORTY_POINTS){
            GAME_ENDED_WON_RICK = 1;
        } else {
            GAME_ENDED_WON_MORTY = 1;
            GAME_ENDED_WON_RICK = 1;
        }
    }
    return -1;
}

