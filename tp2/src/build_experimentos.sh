#!/bin/bash
set -e
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

let maxpixeles=1600*1200*60

set +e
mkdir  dist
set -e

echo -e "${GREEN}Optimizacion O3 ${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native'
cp -f build/tp2 dist/tp2-O3

echo -e "${GREEN}Optimizacion O3 - ROL ${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native' OPTASM='-D ROLINGA'
cp -f build/tp2 dist/tp2-O3-ROL

echo -e "${GREEN}Optimizacion O3 - AccesosMemoria ${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native' OPTASM='-D EXPERIMENTO_ACCESOS_MEMORIA'
cp -f build/tp2 dist/tp2-O3-AM

echo -e "${GREEN}Optimizacion O3 - AccesosMemoriaCflush ${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native' OPTASM='-D EXPERIMENTO_ACCESOS_MEMORIA_CLFLUSH'
cp -f build/tp2 dist/tp2-O3-AMCLFLUSH

echo -e "${GREEN}Optimizacion O3 - AccesosMemoriaCflush2 ${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native' OPTASM='-D EXPERIMENTO_ACCESOS_MEMORIA_CLFLUSH_2'
cp -f build/tp2 dist/tp2-O3-AMCLFLUSH2



sizes=('128x64' '256x128' '400x300' '800x600' '1024x768' '1280x960' '1600x1200')

set +e
mkdir rez
rm -rf rez/*
mkdir  output
rm -rf output/* 
mkdir log
rm -rf log/*
set -e

for entry in img/*.bmp
do
    for sz in "${sizes[@]}"
    do
        fname=${entry%.bmp}
        echo -en  "${GREEN}${fname}${NOCOLOR} de ${BLUE}${sz}${NOCOLOR} en ${GREEN}rez/${fname##*/}${sz}.bmp${NOCOLOR} ... "  
        convert -resize $sz! $entry rez/${fname##*/}${sz}.bmp
        echo -e  "${GREEN}OK${NOCOLOR}"

        IFS='x'

        read -ra xz <<< "$sz"

        IFS=' '

        let iters=maxpixeles/$((xz[0]*xz[1]))

        echo -e "Con  ${iters} iteraciones"

        #Desenrollando Loops -- Comparamos las dos versiones del ImagenFantasma
        dist/tp2-O3 -t ${iters} -i asm ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/ASM_ImagenFantasma.log
        dist/tp2-O3-ROL -t ${iters} -i asm ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/ASM_ROL_ImagenFantasma.log
        
        #Accesos de Memoria -- Comparamos las dos versiones del PixeladoDiferencial
        dist/tp2-O3 -t ${iters} -i asm PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/ASM_PixeladoDiferencial.log
        dist/tp2-O3-ROL -t ${iters} -i asm PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/ASM_ROL_PixeladoDiferencial.log
        dist/tp2-O3-AM -t ${iters} -i asm PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/ASM_AM_PixeladoDiferencial.log
        dist/tp2-O3-AMCLFLUSH -t ${iters} -i asm PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/ASM_AMCLFLUSH_PixeladoDiferencial.log
        dist/tp2-O3-AMCLFLUSH2 -t ${iters} -i asm PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/ASM_AMCLFLUSH2_PixeladoDiferencial.log
    done
done
