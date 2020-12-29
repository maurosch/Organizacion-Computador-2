ROJO="\e[31m"
DEFAULT="\e[39m"

clear

make -C ..
if [ $? -ne 0 ]; then
    echo -e "$ROJO Compilacion con error";
    exit
fi

rm -vf ../tests/data/resultados_nuestros/*.bmp

FILE=Misery.32x16.bmp

#valgrind 
../build/tp2  ReforzarBrillo  -i c     ./data/imagenes_a_testear/$FILE 100 50 50 50 -o ./data/resultados_nuestros  -l pepe.log
#valgrind 
../build/tp2  ReforzarBrillo  -i asm   ./data/imagenes_a_testear/$FILE 100 50 50 50 -o ./data/resultados_nuestros  -l pepe.log

#valgrind 
../build/bmpdiff -v -a -i  ./data/resultados_nuestros/$FILE.ReforzarBrillo.C.bmp ./data/resultados_nuestros/$FILE.ReforzarBrillo.ASM.bmp 1  > error.txt 

if [ $? -ne 0 ]; then
    echo -e "$ROJO";
    cat error.txt
    echo -e "$DEFAULT";
fi