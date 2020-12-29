#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <unistd.h>
#include <stdarg.h>

typedef enum e_type {
    TypeNone = 0,
    TypeInt = 1,
    TypeFloat = 2,
    TypeString = 3,
    TypeDocument = 4
} type_t;

typedef int32_t (funcCmp_t)(void*, void*);
typedef void* (funcClone_t)(void*);
typedef void (funcDelete_t)(void*);
typedef void (funcPrint_t)(void*, FILE *pFile);

/** Int **/

int32_t intCmp(int32_t* a, int32_t* b);
int32_t* intClone(int32_t* a);
void intDelete(int32_t* a);
void intPrint(int32_t* a, FILE *pFile);

/** Float **/

int32_t floatCmp(float* a, float* b);
float* floatClone(float* a);
void floatDelete(float* a);
void floatPrint(float* a, FILE *pFile);

/* String */

uint32_t strLen(char* a);
int32_t strCmp(char* a, char* b);
char* strClone(char* a);
void strDelete(char* a);
void strPrint(char* a, FILE *pFile);

/** Document **/

typedef struct s_document {
    int count;                  // Size: 4 --- Offset: 0
    struct s_docElem *values;   // Size: 8 --- Offset: 8
} document_t;                   // Size: 16

typedef struct s_docElem {
    type_t type;                // Size: 4 --- Offset: 0
    void *data;                 // Size: 8 --- Offset: 8
} docElem_t;                    // Size: 16

document_t* docNew(int32_t size, ... );
int32_t docCmp(document_t* a, document_t* b);
document_t* docClone(document_t* a);
void docDelete(document_t* a);
void docPrint(document_t* a, FILE *pFile);

/* List */

typedef struct s_list {
    type_t   type;              // Size: 4 --- Offset: 0    // REVISAR
    uint32_t size;              // Size: 4 --- Offset: 4    // REVISAR
    struct s_listElem *first;   // Size: 8 --- Offset: 8    // REVISAR
    struct s_listElem *last;    // Size: 8 --- Offset: 16   // REVISAR
} list_t;                       // Size: 24                 // REVISAR

typedef struct s_listElem {
    void *data;                 // Size: 8 --- Offset: 0
    struct s_listElem *next;    // Size: 8 --- Offset: 8
    struct s_listElem *prev;    // Size: 8 --- Offset: 16
} listElem_t;                   // Size: 24

list_t* listNew(type_t t);
void listAdd(list_t* l, void* data);
void listRemove(list_t* l, void* data);
list_t* listClone(list_t* l);
void listDelete(list_t* l);
void listPrint(list_t* l, FILE *pFile);

/** tree **/

typedef struct s_tree {
    struct s_treeNode *first;   // Size: 8 --- Offset: 0
    uint32_t size;              // Size: 4 --- Offset: 8
    type_t typeKey;             // Size: 4 --- Offset: 12
    int    duplicate;           // Size: 4 --- Offset: 16
    type_t typeData;            // Size: 4 --- Offset: 20
} tree_t;                       // Size: 24

typedef struct s_treeNode {
    void *key;                  // Size: 8 --- Offset: 0
    list_t *values;             // Size: 8 --- Offset: 8
    struct s_treeNode *left;    // Size: 8 --- Offset: 16
    struct s_treeNode *right;   // Size: 8 --- Offset: 24
} treeNode_t;                   // Size: 32

tree_t* treeNew(type_t typeKey, type_t typeData, int duplicate);
int treeInsert(tree_t* tree, void* key, void* data);
list_t* treeGet(tree_t* tree, void* key);
void treeRemove(tree_t* tree, void* key, void* data);
void treeDelete(tree_t* tree);
void treePrint(tree_t* tree, FILE *pFile);
