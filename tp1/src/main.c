#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include "lib.h"

char* strA = "hola";
char* strB = "achis";
char* strC = "salud";
char* strD = "achis";
char* strE = "salute";
char* strF = "cuarentena";
char* strG = "pandemia";
char* strH = "coronavirus";
char* strI = "supercalifragilisticoexpialidoso";
char* strJ = "chau";

void test_list(FILE *pfile){
    list_t* listaStringsOriginal = listNew(TypeString);
    listAdd(listaStringsOriginal, strClone(strA)); listAdd(listaStringsOriginal, strClone(strB)); listAdd(listaStringsOriginal, strClone(strC)); listAdd(listaStringsOriginal, strClone(strD)); listAdd(listaStringsOriginal, strClone(strE)); listAdd(listaStringsOriginal, strClone(strF)); listAdd(listaStringsOriginal, strClone(strG)); listAdd(listaStringsOriginal, strClone(strH)); listAdd(listaStringsOriginal, strClone(strI)); listAdd(listaStringsOriginal, strClone(strJ));
    
    list_t* listaFloatsOriginal = listNew(TypeFloat);
    float fa = (float)2.7861; float* fpA = &fa;
    float fb = (float)-12.213491; float* fpB = &fb;
    float fc = (float)31.00931; float* fpC = &fc;
    float fd = (float)-0.1222145; float* fpD = &fd;
    float fe = (float)0.431405; float* fpE = &fe;
        
    listAdd(listaFloatsOriginal, floatClone(fpA)); listAdd(listaFloatsOriginal, floatClone(fpB)); listAdd(listaFloatsOriginal, floatClone(fpC)); listAdd(listaFloatsOriginal, floatClone(fpD)); listAdd(listaFloatsOriginal, floatClone(fpE));
    
    list_t* listaStringsClonada = listClone(listaStringsOriginal);

    list_t* listaFloatsClonada = listClone(listaFloatsOriginal);
    
    fprintf(pfile, "Lista de Strings Original:\n");
    listPrint(listaStringsOriginal, pfile);

    fprintf(pfile, "\n");
    
    fprintf(pfile, "Lista de Floats Original:\n");
    listPrint(listaFloatsOriginal, pfile);

    fprintf(pfile, "\n");
        
    fprintf(pfile, "Lista de Strings Clonada:\n");
    listPrint(listaStringsClonada, pfile);

    fprintf(pfile, "\n");
    
    fprintf(pfile, "Lista de Floats Clonada:\n");
    listPrint(listaFloatsClonada, pfile);

    fprintf(pfile, "\n");

    listDelete(listaStringsOriginal);
    listDelete(listaFloatsOriginal);
    listDelete(listaStringsClonada);
    listDelete(listaFloatsClonada);
}

void test_document(FILE *pfile){
    int a = 8; int b = 10; float c = 0.2; float d = 1.8; char* e = "hola"; char* f = "chau";
    int* pA = &a; int* pB = &b; float* pC = &c; float* pD = &d;
    document_t* doc = docNew(6, TypeInt, pA, TypeInt, pB, TypeFloat, pC, TypeFloat, pD, TypeString, e, TypeString, f);
    document_t* docCloned = docClone(doc);
    docPrint(doc, pfile);
    docPrint(docCloned, pfile);

    docDelete(doc);
    docDelete(docCloned);
}

void test_tree(FILE *pfile){
    tree_t *originalTree = treeNew(TypeInt, TypeString, 1);
    int intA = 24; treeInsert(originalTree, &intA, "papanatas");
    intA = 34; treeInsert(originalTree, &intA, "rima");
    intA = 24; treeInsert(originalTree, &intA, "buscabullas");
    intA = 11; treeInsert(originalTree, &intA, "musica");
    intA = 31; treeInsert(originalTree, &intA, "Pikachu");
    intA = 11; treeInsert(originalTree, &intA, "Bulbasaur");
    intA = -2; treeInsert(originalTree, &intA, "Charmander");

    tree_t *reversedTree = treeNew(TypeInt, TypeString, 1);

    intA = -2; treeInsert(reversedTree, &intA, "Charmander");
    intA = 11; treeInsert(reversedTree, &intA, "Bulbasaur");
    intA = 31; treeInsert(reversedTree, &intA, "Pikachu");
    intA = 11; treeInsert(reversedTree, &intA, "musica");
    intA = 24; treeInsert(reversedTree, &intA, "buscabullas");
    intA = 34; treeInsert(reversedTree, &intA, "rima");
    intA = 24; treeInsert(reversedTree, &intA, "papanatas");

    treePrint(originalTree, pfile);
    treePrint(reversedTree, pfile);

    treeDelete(originalTree);
    treeDelete(reversedTree);
}

int main (void){
    FILE* fMas = fopen("testmasivo.txt", "w");
    test_list(fMas);
    test_document(fMas);
    test_tree(fMas);
    fclose(fMas);
    return 0;
}