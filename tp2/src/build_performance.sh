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

echo -e "${GREEN}Sin optimizacion O0${NOCOLOR}"

make OPT='-O0 -mtune=native'
cp -f build/tp2  dist/tp2-O0

echo -e "${GREEN}Optimizacion O1${NOCOLOR}"
make clean
make OPT='-O1 -mtune=native'
cp -f build/tp2 dist/tp2-O1


echo -e "${GREEN}Optimizacion O2${NOCOLOR}"
make clean
make OPT='-O2 -mtune=native'
cp -f build/tp2 dist/tp2-O2

echo -e "${GREEN}Optimizacion O3${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native'
cp -f build/tp2 dist/tp2-O3

echo -e "${GREEN}Optimizacion O3 - ROL ${NOCOLOR}"
make clean
make OPT='-O3 -mtune=native' OPTASM='-dROLINGA=1'
cp -f build/tp2 dist/tp2-O3-ROL


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

        dist/tp2-O0 -t ${iters} -i c ColorBordes rez/${fname##*/}${sz}.bmp -o output -l log/O0_ColorBordes.log
        dist/tp2-O1 -t ${iters} -i c ColorBordes rez/${fname##*/}${sz}.bmp -o output -l log/O1_ColorBordes.log
        dist/tp2-O2 -t ${iters} -i c ColorBordes rez/${fname##*/}${sz}.bmp -o output -l log/O2_ColorBordes.log
        dist/tp2-O3 -t ${iters} -i c ColorBordes rez/${fname##*/}${sz}.bmp -o output -l log/O3_ColorBordes.log
        dist/tp2-O3 -t ${iters} -i asm ColorBordes rez/${fname##*/}${sz}.bmp -o output -l log/ASM_ColorBordes.log

        dist/tp2-O0 -t ${iters} -i c ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/O0_ImagenFantasma.log
        dist/tp2-O1 -t ${iters} -i c ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/O1_ImagenFantasma.log
        dist/tp2-O2 -t ${iters} -i c ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/O2_ImagenFantasma.log
        dist/tp2-O3 -t ${iters} -i c ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/O3_ImagenFantasma.log
        dist/tp2-O3 -t ${iters} -i asm ImagenFantasma rez/${fname##*/}${sz}.bmp -o output -l log/ASM_ImagenFantasma.log

        dist/tp2-O0 -t ${iters} -i c PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/O0_PixeladoDiferencial.log
        dist/tp2-O1 -t ${iters} -i c PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/O1_PixeladoDiferencial.log
        dist/tp2-O2 -t ${iters} -i c PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/O2_PixeladoDiferencial.log
        dist/tp2-O3 -t ${iters} -i c PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/O3_PixeladoDiferencial.log
        dist/tp2-O3 -t ${iters} -i asm PixeladoDiferencial rez/${fname##*/}${sz}.bmp -o output -l log/ASM_PixeladoDiferencial.log

        dist/tp2-O0 -t ${iters} -i c ReforzarBrillo rez/${fname##*/}${sz}.bmp -o output -l log/O0_ReforzarBrillo.log
        dist/tp2-O1 -t ${iters} -i c ReforzarBrillo rez/${fname##*/}${sz}.bmp -o output -l log/O1_ReforzarBrillo.log
        dist/tp2-O2 -t ${iters} -i c ReforzarBrillo rez/${fname##*/}${sz}.bmp -o output -l log/O2_ReforzarBrillo.log
        dist/tp2-O3 -t ${iters} -i c ReforzarBrillo rez/${fname##*/}${sz}.bmp -o output -l log/O3_ReforzarBrillo.log
        dist/tp2-O3 -t ${iters} -i asm ReforzarBrillo rez/${fname##*/}${sz}.bmp -o output -l log/ASM_ReforzarBrillo.log
  
    done
done
