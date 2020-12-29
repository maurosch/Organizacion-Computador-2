
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <math.h>

#include "tp2.h"
#include "helper/tiempo.h"
#include "helper/libbmp.h"
#include "helper/utils.h"
#include "helper/imagenes.h"

// ~~~ seteo de los filtros ~~~

extern filtro_t ColorBordes;
extern filtro_t ImagenFantasma;
extern filtro_t PixeladoDiferencial;
extern filtro_t ReforzarBrillo;

filtro_t filtros[4];

// ~~~ fin de seteo de filtros ~~~

int main( int argc, char** argv ) {

    filtros[0] = ColorBordes; 
    filtros[1] = ImagenFantasma;
    filtros[2] = PixeladoDiferencial;
    filtros[3] = ReforzarBrillo;

    configuracion_t config;
    config.dst.width = 0;
    config.bits_src = 32;
    config.bits_dst = 32;

    procesar_opciones(argc, argv, &config);
    
    // Imprimo info
    if (!config.nombre) {
        printf ( "Procesando...\n");
        printf ( "  Filtro             : %s\n", config.nombre_filtro);
        printf ( "  Implementación     : %s\n", C_ASM( (&config) ) );
        printf ( "  Archivo de entrada : %s\n", config.archivo_entrada);
    }

    snprintf(config.archivo_salida, sizeof  (config.archivo_salida), "%s/%s.%s.%s%s.bmp",
            config.carpeta_salida, basename(config.archivo_entrada),
            config.nombre_filtro,  C_ASM( (&config) ), config.extra_archivo_salida );

    if (config.nombre) {
        printf("%s\n", basename(config.archivo_salida));
        return 0;
    }

    filtro_t *filtro = detectar_filtro(&config);

    filtro->leer_params(&config, argc, argv);
    correr_filtro_imagen(&config, filtro->aplicador);
    filtro->liberar(&config);

    return 0;
}

filtro_t* detectar_filtro(configuracion_t *config) {
    for (int i = 0; filtros[i].nombre != 0; i++) {
        if (strcmp(config->nombre_filtro, filtros[i].nombre) == 0)
            return &filtros[i];
    }
    fprintf(stderr, "Filtro '%s' desconocido\n", config->nombre_filtro);
    exit(EXIT_FAILURE);
    return NULL;
}

void imprimir_tiempos_ejecucion(unsigned long long int start, unsigned long long int end, int cant_iteraciones) {
    unsigned long long int cant_ciclos = end-start;

    printf("Tiempo de ejecución:\n");
    printf("  Comienzo                          : %llu\n", start);
    printf("  Fin                               : %llu\n", end);
    printf("  # iteraciones                     : %d\n", cant_iteraciones);
    printf("  # de ciclos insumidos totales     : %llu\n", cant_ciclos);
    printf("  # de ciclos insumidos por llamada : %.3f\n", (float)cant_ciclos/(float)cant_iteraciones);
}

double desvio_estandar(unsigned long long* values, int n){
    double promedio = 0;
    for(int i = 0; i < n; i++){
        promedio += (double)values[i];
    }
    promedio /= n;
    double sum = 0;
    for(int i = 0; i < n; i++){
        sum += pow((double)values[i] - promedio,2);
    }
    double sd = sqrt(sum / (double)(n-1));    
    return sd;   
}

void log_tiempos_ejecucion(FILE* pFile, unsigned long long int start, unsigned long long int end, int cant_iteraciones,configuracion_t *config, double sd) {
    unsigned long long int cant_ciclos = end-start;

    fprintf(pFile,"%llu\t", start);
    fprintf(pFile,"%llu\t", end);
    fprintf(pFile,"%d\t", cant_iteraciones);
    fprintf(pFile,"%llu\t", cant_ciclos);
    fprintf(pFile,"%d\t", config->tipo_filtro);
    fprintf(pFile,"%s\t", config->nombre_filtro);
    fprintf(pFile,"%d\t", config->src.height);
    fprintf(pFile,"%d\t", config->src.width);
    fprintf(pFile,"%.3f\t", (float)cant_ciclos/(float)cant_iteraciones);
    fprintf(pFile,"%.3f\n", sd);
}

void correr_filtro_imagen(configuracion_t *config, aplicador_fn_t aplicador) {
    imagenes_abrir(config);

    unsigned long long start, end, startSingle, endSingle;

    imagenes_flipVertical(&config->src, src_img);
    imagenes_flipVertical(&config->dst, dst_img);
    if(config->archivo_entrada_2 != 0) {
        imagenes_flipVertical(&config->src_2, src_img2);
    }

    unsigned long long *tiempos = malloc(sizeof(unsigned long long)*config->cant_iteraciones);
    MEDIR_TIEMPO_START(start)
    for (int i = 0; i < config->cant_iteraciones; i++) {
            MEDIR_TIEMPO_START(startSingle);
            aplicador(config);
            MEDIR_TIEMPO_STOP(endSingle);
            tiempos[i] = endSingle-startSingle;
    }
    MEDIR_TIEMPO_STOP(end)

    float sd = desvio_estandar(tiempos, config->cant_iteraciones);

    imagenes_flipVertical(&config->dst, dst_img);

    if (config->archivo_log)
    {
        FILE* pFile = fopen(config->archivo_log,"a");
        if (pFile == NULL){
            fprintf(stderr, "Log '%s' errore de archivo\n", config->archivo_log);
            exit(EXIT_FAILURE);
        }
        log_tiempos_ejecucion(pFile,start,end,config->cant_iteraciones,config,sd);
        fclose(pFile);
    } else {
        imagenes_guardar(config);
    }
    imagenes_liberar(config);
    imprimir_tiempos_ejecucion(start, end, config->cant_iteraciones);
    free(tiempos);
}
